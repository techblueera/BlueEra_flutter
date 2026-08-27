import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/order_controllar.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/saved_address_model.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/auth/model/self_pickup_order_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_action_bar.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_find_rider_sheet.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_lifecycle_section.dart';
import 'package:BlueEra/core/api/apiService/order_service_api.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/ride_drop_location_sheet.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/payment_qr_bottom_sheet.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/pickup_otp_dialog.dart';
import 'package:BlueEra/features/chat/view/forward_screen/chat_forward_screen.dart';
import 'package:BlueEra/features/chat/view/widget/component_widgets.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/product_order_booking_rider_main.dart';
import 'package:BlueEra/features/common/connect/view/goods_multi_order_booking_main.dart';
import 'package:BlueEra/features/me/medical/repo/medical_repo.dart';
import 'package:BlueEra/features/me/product/repo/product_repo.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart' as dio;
import 'package:BlueEra/features/chat/auth/controller/call_customer_controller.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/packing_pdf_qr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../../../core/api/apiService/api_keys.dart';

/// Chat message card for `product_selfpickup` message type.
/// Mirrors [SelfPickupMsgCard] (call / payment / ride + packing PDF) but uses
/// `productPickupOrderId` / `productPickupOrder` metadata and routes the
/// "Mark as Ready" API to the inventory service.
///
/// Reused as-is for the `medical_selfpickup` message type by passing
/// [isMedical] = true — the same trick [FoodSelfPickupMsgCard] uses for its
/// home-made / tiffin variants. In that mode the order is read from
/// `medicalPickupOrder` / `medicalPickupOrderId` and "Mark as Ready" routes to
/// the medical service. See docs/backend/PHARMACY_CUSTOMER_FLOW_INTEGRATION.md.
class ProductSelfPickupMsgCard extends StatefulWidget {
  final Messages message;
  final String time;
  final String? conversationId;

  /// When true, read the pharmacy order metadata and mark-ready via the
  /// medical service (`PUT medical-service/orders/{orderId}/ready`) instead of
  /// the inventory service.
  final bool isMedical;

  const ProductSelfPickupMsgCard({
    super.key,
    required this.message,
    required this.time,
    this.conversationId,
    this.isMedical = false,
  });

  @override
  State<ProductSelfPickupMsgCard> createState() =>
      _ProductSelfPickupMsgCardState();
}

class _ProductSelfPickupMsgCardState extends State<ProductSelfPickupMsgCard> {
  bool _isMarkingReady = false;
  bool _isGeneratingPdf = false;

  bool get _isMyMessage => widget.message.myMessage ?? false;

  /// Id of the conversation person (the other party in this chat) — used to
  /// fetch their UPI for the payment QR. Falls back to the message sender.
  String? get _conversationPersonId =>
      (Get.isRegistered<ChatViewController>()
          ? Get.find<ChatViewController>().currentChatOtherUserId
          : null) ??
      widget.message.sender?.id;

  SelfPickupOrderModel? get _order =>
      (widget.isMedical ? widget.message.metadata?.medicalPickupOrder : null) ??
      widget.message.metadata?.productPickupOrder ??
      widget.message.metadata?.selfPickupOrder;

  /// The pickup order id for this card's type — used when [_order]'s own
  /// `orderId` is absent (mark-ready, payment QR, rider dispatch).
  String? get _pickupOrderId => widget.isMedical
      ? widget.message.metadata?.medicalPickupOrderId
      : widget.message.metadata?.productPickupOrderId;

  bool get _isReady =>
      _order?.isReady ?? (widget.message.metadata?.orderStatus == true);

  bool get _isCancelled => widget.message.metadata?.is_cancelled ?? false;

  // ── Server-driven lifecycle ──────────────────────────────────────────
  //
  // Everything below reads what the backend computed. There is deliberately
  // NO client-side rule about order age, cancellability or readiness here —
  // the 24-hour expiry that used to live in `_buildActionSection` disagreed
  // with the server's own (configurable, and much shorter) clock for
  // twenty-three hours at a stretch, so the shop saw a live order while the
  // customer saw a dead one. See lib/docs/FLUTTER_ORDER_FLOW_UI_GUIDE.md §0.

  /// `metadata.lifecycle`, or null on a legacy order.
  OrderLifecycle? get _lifecycle => widget.message.metadata?.lifecycle;

  /// The order id the lifecycle endpoints key on.
  String get _lifecycleOrderId => _order?.orderId ?? _pickupOrderId ?? '';

  /// Which vertical's order service owns this card.
  String get _orderService => widget.isMedical
      ? OrderServiceApi.medicalOrderService
      : OrderServiceApi.productOrderService;

  /// The shop side of the card. `myMessage` is the *customer* — they are the
  /// one who placed the order — so the owner is the other party.
  bool get _isOwnerView => !_isMyMessage;

  OrderCardContext get _cardContext => OrderCardContext(
        orderId: _lifecycleOrderId,
        service: _orderService,
        isOwner: _isOwnerView,
        conversationId: widget.conversationId,
        otherUserId: _conversationPersonId,
        otherUserName: widget.message.sender?.name,
        otherUserPhone: widget.message.seller?.contact,
        shopName: widget.message.seller?.name,
        shopAddress: widget.message.seller?.location,
        orderTotal: _order?.grandTotal,
        businessId: _order?.businessId ?? widget.message.sender?.id,
        selfpickupType: widget.message.messageType ??
            (widget.isMedical ? 'medical_selfpickup' : 'product_selfpickup'),
        orderFor: widget.isMedical ? 'medical' : 'product',
        onFindRider: _isMyMessage ? _findRiderFromCard : null,
        onChanged: _onLifecycleChanged,
      );

  /// Keep the legacy `order_status` / `is_cancelled` flags in step with the
  /// server's state so the rest of the app — chat list previews, the packing
  /// PDF, old code paths — keeps behaving, then rebuild.
  void _onLifecycleChanged(OrderActionsModel? fresh) {
    final status = fresh?.lifecycle.orderStatus;
    if (status != null) {
      final meta = widget.message.metadata;
      if (meta != null) {
        meta.lifecycle = fresh!.lifecycle;
        meta.orderStatus = status == OrderStatusValue.ready ||
            status == OrderStatusValue.dispatched ||
            status == OrderStatusValue.completed;
        meta.is_cancelled = status == OrderStatusValue.cancelled ||
            status == OrderStatusValue.expired;
      }
      if (status == OrderStatusValue.ready) _order?.isReady = true;
    }
    if (mounted) setState(() {});
  }

  /// `FIND_RIDER` runs **in the card** now (guide §5.5).
  ///
  /// The old button left the chat for a full-screen rider-booking flow and
  /// re-asked for a drop address — on an order that, for doorstep delivery,
  /// already carries one. A doorstep order never reaches this at all: it
  /// dispatches itself the moment it turns `ready` (§7.2). This is only the
  /// self-pickup customer who changed their mind.
  Future<void> _findRiderFromCard() async {
    await showFindRiderSheet(context, ctx: _cardContext);
  }

  String _itemDisplayName(SelfPickupItem item) {
    if (item.productName != null && item.productName!.isNotEmpty) {
      return item.productName!;
    }
    if (item.variantName != null && item.variantName!.isNotEmpty) {
      return item.variantName!;
    }
    return 'Product Item';
  }

  /// Seller taps "Go to Packing" → show product selection bottom sheet
  void _onMarkAsReadyTap() {
    final items = _order?.items ?? [];

    if (items.isEmpty) {
      commonSnackBar(message: 'No items found in order');
      return;
    }

    _showProductSelectionBottomSheet(items);
  }

  void _showProductSelectionBottomSheet(List<SelfPickupItem> items) {
    final selectedItems = <int>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            num selectedTotal = 0;
            for (int i in selectedItems) {
              final item = items[i];
              final price = item.sellingPrice ?? 0;
              final qty = item.quantity ?? 1;
              selectedTotal += price * qty;
            }

            final selectedCount = selectedItems.length;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            'Select Available Items',
                            fontSize: SizeConfig.size16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: Color(0xFFE5E5E5)),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = selectedItems.contains(index);
                        return _buildSelectableItemRow(
                          item,
                          isSelected,
                          () {
                            setBottomSheetState(() {
                              if (isSelected) {
                                selectedItems.remove(index);
                              } else {
                                selectedItems.add(index);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Center(
                              child: CustomText(
                                '$selectedCount items | ₹$selectedTotal',
                                fontSize: SizeConfig.size14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: selectedCount == 0
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      _submitSelectedItems(
                                        items,
                                        selectedItems,
                                        selectedTotal,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                disabledBackgroundColor: Colors.grey.shade300,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: CustomText(
                                'Submit',
                                fontSize: SizeConfig.size16,
                                fontWeight: FontWeight.w700,
                                color: selectedCount == 0
                                    ? Colors.grey
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitSelectedItems(
    List<SelfPickupItem> allItems,
    Set<int> selectedIndices,
    num selectedTotal,
  ) async {
    setState(() => _isGeneratingPdf = true);

    try {
      final packedItems = <SelfPickupItem>[];
      final missingItems = <SelfPickupItem>[];
      for (int i = 0; i < allItems.length; i++) {
        if (selectedIndices.contains(i)) {
          packedItems.add(allItems[i]);
        } else {
          missingItems.add(allItems[i]);
        }
      }

      final Map<String, pw.MemoryImage> imageCache = {};
      for (final item in allItems) {
        final imageUrl =
            (item.images != null && item.images!.isNotEmpty)
                ? item.images!.first.url
                : null;
        if (imageUrl != null && !imageCache.containsKey(imageUrl)) {
          try {
            final response = await http.get(Uri.parse(imageUrl));
            if (response.statusCode == 200) {
              imageCache[imageUrl] = pw.MemoryImage(response.bodyBytes);
            }
          } catch (e) {
            log('Failed to load image: $e');
          }
        }
      }

      final businessName = widget.message.sender?.name ?? 'Business';
      final order = _order;

      num packedMrpTotal = 0;
      num packedSellingTotal = 0;
      for (final item in packedItems) {
        final qty = item.quantity ?? 1;
        packedMrpTotal += (item.mrp ?? 0) * qty;
        packedSellingTotal += (item.sellingPrice ?? 0) * qty;
      }
      final packedSaving = packedMrpTotal - packedSellingTotal;
      final packedSavingPercent = packedMrpTotal > 0
          ? (packedSaving / packedMrpTotal * 100).toStringAsFixed(1)
          : '0.0';

      final headerStyle = pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      );
      final cellStyle = const pw.TextStyle(fontSize: 9);
      final cellBoldStyle =
          pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);

      pw.Widget buildItemTable({
        required List<SelfPickupItem> items,
        required PdfColor headerColor,
      }) {
        return pw.Column(
          children: [
            pw.Container(
              decoration: pw.BoxDecoration(
                color: headerColor,
                borderRadius: const pw.BorderRadius.vertical(
                    top: pw.Radius.circular(6)),
              ),
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8, vertical: 8),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                      width: 30,
                      child: pw.Text('S.No', style: headerStyle)),
                  pw.SizedBox(
                      width: 50,
                      child: pw.Text('Image', style: headerStyle)),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text('Product Name', style: headerStyle)),
                  pw.SizedBox(
                      width: 35,
                      child: pw.Text('Qty',
                          style: headerStyle,
                          textAlign: pw.TextAlign.center)),
                  pw.SizedBox(
                      width: 55,
                      child: pw.Text('MRP',
                          style: headerStyle,
                          textAlign: pw.TextAlign.right)),
                  pw.SizedBox(
                      width: 55,
                      child: pw.Text('Price',
                          style: headerStyle,
                          textAlign: pw.TextAlign.right)),
                ],
              ),
            ),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final qty = item.quantity ?? 0;
              final sellingPrice = item.sellingPrice ?? 0;
              final mrp = item.mrp ?? 0;
              final imageUrl =
                  (item.images != null && item.images!.isNotEmpty)
                      ? item.images!.first.url
                      : null;
              final hasImage =
                  imageUrl != null && imageCache.containsKey(imageUrl);
              final isEven = index % 2 == 0;

              return pw.Container(
                decoration: pw.BoxDecoration(
                  color: isEven
                      ? PdfColors.white
                      : PdfColor.fromHex('#F8F9FA'),
                  border: pw.Border(
                    left: pw.BorderSide(
                        color: PdfColors.grey300, width: 0.5),
                    right: pw.BorderSide(
                        color: PdfColors.grey300, width: 0.5),
                    bottom: pw.BorderSide(
                        color: PdfColors.grey200, width: 0.5),
                  ),
                ),
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 10),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.SizedBox(
                      width: 30,
                      child: pw.Text('${index + 1}',
                          style: cellBoldStyle,
                          textAlign: pw.TextAlign.center),
                    ),
                    pw.SizedBox(
                      width: 50,
                      child: hasImage
                          ? pw.Container(
                              width: 40,
                              height: 40,
                              child: pw.ClipRRect(
                                horizontalRadius: 4,
                                verticalRadius: 4,
                                child: pw.Image(
                                  imageCache[imageUrl]!,
                                  fit: pw.BoxFit.cover,
                                ),
                              ),
                            )
                          : pw.Container(
                              width: 40,
                              height: 40,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey200,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Center(
                                child: pw.Text('-',
                                    style: const pw.TextStyle(
                                        fontSize: 8,
                                        color: PdfColors.grey400)),
                              ),
                            ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.productName ?? '',
                              style: cellBoldStyle,
                              maxLines: 4,
                            ),
                            if (item.variantName != null &&
                                item.variantName!.isNotEmpty)
                              pw.Text(
                                item.variantName!,
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.grey600,
                                ),
                                maxLines: 1,
                              ),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(
                      width: 35,
                      child: pw.Text('$qty',
                          style: cellBoldStyle,
                          textAlign: pw.TextAlign.center),
                    ),
                    pw.SizedBox(
                      width: 55,
                      child: pw.Text(
                        'Rs.$mrp',
                        style: mrp > sellingPrice
                            ? pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey500,
                                decoration: pw.TextDecoration.lineThrough,
                              )
                            : cellStyle,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.SizedBox(
                      width: 55,
                      child: pw.Text(
                        'Rs.$sellingPrice',
                        style: cellBoldStyle,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.Container(
              height: 2,
              decoration: pw.BoxDecoration(
                color: headerColor,
                borderRadius: const pw.BorderRadius.vertical(
                    bottom: pw.Radius.circular(6)),
              ),
            ),
          ],
        );
      }

      final pdf = pw.Document();

      // The shop owner's Scan-&-Pay QR, printed at the end of the slip so
      // the customer can pay straight off the packing list. Null when the
      // owner has no UPI configured — the slip is then produced as before.
      final paymentQr = await buildShopOwnerPaymentQr(
        payeeName: businessName,
        orderId: widget.message.metadata?.selfpickupOrderId,
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (pw.Context context) {
            return [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#1565C0'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      businessName,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Packing Summary',
                      style: pw.TextStyle(
                        fontSize: 13,
                        color: PdfColor.fromHex('#BBDEFB'),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F5F5F5'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(
                      color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Packed: ${packedItems.length}  |  Missing: ${missingItems.length}  |  Total: ${allItems.length}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Order ID: ${order?.orderId ?? '-'}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 4, vertical: 6),
                child: pw.Text(
                  'Packed Items (${packedItems.length})',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1565C0'),
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              if (packedItems.isNotEmpty)
                buildItemTable(
                  items: packedItems,
                  headerColor: PdfColor.fromHex('#1565C0'),
                )
              else
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                        color: PdfColors.grey300, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Center(
                    child: pw.Text('No items packed',
                        style: const pw.TextStyle(color: PdfColors.grey500)),
                  ),
                ),
              pw.SizedBox(height: 16),
              if (packedItems.isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F5F5F5'),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(
                        color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Grand Total (MRP)',
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text('Rs.$packedMrpTotal',
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Net Pay',
                              style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text('Rs.$packedSellingTotal',
                              style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('#1565C0'))),
                        ],
                      ),
                      if (packedSaving > 0) ...[
                        pw.SizedBox(height: 3),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                                'Total Saving ($packedSavingPercent%)',
                                style: pw.TextStyle(
                                    fontSize: 13,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromHex('#2E7D32'))),
                            pw.Text('Rs.$packedSaving',
                                style: pw.TextStyle(
                                    fontSize: 13,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromHex('#2E7D32'))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              pw.SizedBox(height: 20),
              if (missingItems.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4, vertical: 6),
                  child: pw.Text(
                    'Missing Items (${missingItems.length})',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#C62828'),
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                buildItemTable(
                  items: missingItems,
                  headerColor: PdfColor.fromHex('#C62828'),
                ),
              ],
              if (paymentQr != null) ...[
                pw.SizedBox(height: 20),
                buildPackingPaymentQrSection(paymentQr),
              ],
            ];
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/packing_summary_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      log('Packing summary PDF generated: $filePath');

      final fileName = filePath.split('/').last;
      final multipartFile = await dio.MultipartFile.fromFile(
        filePath,
        filename: fileName,
      );

      final chatViewController = Get.find<ChatViewController>();
      Map<String, dynamic> data = {
        ApiKeys.conversation_id: widget.conversationId,
        ApiKeys.message: '',
        ApiKeys.message_type: 'document',
        ApiKeys.files: [multipartFile],
      };
      chatViewController.sendMessage(data, null, fileName);

      // The packing slip is on its way — hang the "Call Customer" button
      // over the thread so the owner can ring them about the order without
      // hunting through the chat header.
      showCallCustomerButtonFor(
        conversationId: widget.conversationId,
        orderMessage: widget.message,
      );

      await _markAsReady();
    } catch (e) {
      log('Error generating packing summary PDF: $e');
      commonSnackBar(message: 'Failed to generate PDF');
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  /// Mark the order as ready — inventory service for products, medical service
  /// for pharmacy orders.
  Future<void> _markAsReady() async {
    final orderId = _order?.orderId ?? _pickupOrderId ?? '';

    if (orderId.isEmpty) {
      commonSnackBar(message: 'Order ID not found');
      return;
    }

    setState(() => _isMarkingReady = true);

    try {
      final response = widget.isMedical
          ? await MedicalRepo().markMedicalOrderReadyRepo(orderId: orderId)
          : await ProductRepo().markProductOrderReadyRepo(orderId: orderId);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      widget.message.metadata?.orderStatus = true;
      _order?.isReady = true;
      setState(() {});

      commonSnackBar(
        message: widget.isMedical
            ? 'Pharmacy order marked as ready for pickup'
            : 'Product order marked as ready for pickup',
      );
      log('${widget.isMedical ? 'Medical' : 'Product'} self-pickup order $orderId marked as ready');
    } catch (e) {
      log('Error marking order ready: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      setState(() => _isMarkingReady = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final items = order?.items ?? [];
    final totalItems = order?.totalItems ?? items.length;
    final grandTotal = order?.grandTotal ?? 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildForwardCircle(),
        const SizedBox(width: 8),
        Container(
          margin: const EdgeInsets.only(bottom: 2),
          width: SizeConfig.screenWidth * 0.72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 28, color: AppColors.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            'Product Order',
                            fontSize: SizeConfig.size14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                          CustomText(
                            '$totalItems ${totalItems == 1 ? 'item' : 'items'} | Self-Pickup',
                            fontSize: SizeConfig.size12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(),
                  ],
                ),
              ),

              // Items List (max 3)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: items.length > 3 ? 3 : items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFE5E5E5)),
                itemBuilder: (context, index) {
                  return _buildItemRow(items[index]);
                },
              ),

              if (items.length > 3)
                Padding(
                  padding:
                      const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                  child: CustomText(
                    '+${items.length - 3} more item${items.length - 3 == 1 ? '' : 's'}...',
                    fontSize: SizeConfig.size12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grayText,
                  ),
                ),

              // Total
              const Divider(height: 1, color: Colors.grey),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      'Grand Total',
                      fontSize: SizeConfig.size14,
                      fontWeight: FontWeight.w600,
                    ),
                    CustomText(
                      '₹$grandTotal',
                      fontSize: SizeConfig.size16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
              ),

              // Server-driven lifecycle: banner, countdowns, payment
              // sub-state, refund wording and the action bar. It renders
              // `availableActions` and nothing else — a button this build
              // doesn't know is never guessed at.
              //
              // On a legacy order (no `metadata.lifecycle`) the section falls
              // straight through to the card's original status row, so old
              // orders keep working exactly as before.
              OrderLifecycleSection(
                ctx: _cardContext,
                fallbackLifecycle: _lifecycle,
                legacyFallback: _isCancelled ? null : _buildActionSection(),
              ),

              // Call / Payment / Ride row — legacy shortcuts, superseded by
              // the action bar once the server drives the card.
              if (_lifecycle == null) ...[
                const Divider(height: 1, color: Color(0xFFE5E5E5)),
                _buildForwardRow(),
              ],

              // Time
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 6),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: CustomText(
                    widget.time,
                    fontSize: SizeConfig.size10,
                    fontWeight: FontWeight.w400,
                    color: AppColors.grayText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Legacy status row — used ONLY for orders the backend has not attached a
  /// `lifecycle` block to.
  ///
  /// The 24-hour client-side expiry that used to open this method is gone.
  /// The server expires orders on its own, much shorter, configurable clocks
  /// and says so through `lifecycle.deadlines` + `availableActions`; deciding
  /// locally is what let the two sides disagree for twenty-three hours. Never
  /// reintroduce an age check here.
  Widget _buildActionSection() {
    if (_isReady) {
      return Column(
        children: [
          const Divider(height: 1, color: Colors.grey),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 6),
                CustomText(
                  'Ready for Pickup',
                  fontSize: SizeConfig.size14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Seller side — show "Go to Packing"
    if (!_isMyMessage) {
      return Column(
        children: [
          const Divider(height: 1, color: Colors.grey),
          InkWell(
            onTap: _isMarkingReady ? null : _onMarkAsReadyTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isMarkingReady)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryColor,
                      ),
                    )
                  else
                    Icon(
                      Icons.check_circle_outline,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  const SizedBox(width: 6),
                  CustomText(
                    _isMarkingReady ? 'Packing...' : 'Go to Packing',
                    fontSize: SizeConfig.size14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Customer side — show "Preparing"
    return Column(
      children: [
        const Divider(height: 1, color: Colors.grey),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              CustomText(
                'Waiting For Approval',
                fontSize: SizeConfig.size14,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Circular forward affordance shown in the left margin — shares the
  /// packing list PDF.
  Widget _buildForwardCircle() {
    return InkWell(
      onTap: _isGeneratingPdf ? null : _generateAndSharePdf,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _isGeneratingPdf
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryColor,
                ),
              )
            : const Icon(
                Icons.shortcut_rounded,
                color: AppColors.grayText,
                size: 20,
              ),
      ),
    );
  }

  /// Bottom action row — Payment, Find Rider and Pickup OTP shortcuts for the
  /// order (in that sequence). The OTP button replaced the old "Call" action.
  Widget _buildForwardRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _orderActionButton(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Payment',
            color: AppColors.primaryColor,
            // Shows the payment QR bottom sheet (dummy QR + download/share).
            onTap: () => showPaymentQrBottomSheet(
              context,
              data: _order?.orderId ?? _pickupOrderId,
              userId: _conversationPersonId,
              conversationId: widget.conversationId,
            ),
          ),
          // Find Rider — customer (card sender) only; hidden for the business.
          if (_isMyMessage)
            _orderActionButton(
              icon: Icons.two_wheeler,
              label: AppStrings.findRider.tr,
              color: Colors.deepOrange,
              onTap: () async {
                final drop = await showRideDropLocationSheet(context);
                if (drop != null) {
                  Get.to(() =>
                      GoodsMultiOrderBookingMain(dropAddress: drop));
                }
              },
            ),
          // Pickup OTP button removed: the self-pickup card's orderId is a
          // product order, NOT a RideOrder — calling the rider-service pickup
          // endpoint with it always 404s. When a rider is dispatched, the
          // dedicated rider_otp chat card handles OTP verification with the correct
          // rideOrderId. For pure self-pickup (no rider), no RideOrder exists.

        ],
      ),
    );
  }

  /// Resolves the shop (business) pickup location, sets pickup = shop and
  /// drop = the just-chosen [drop] address, kicks off the rider search, and
  /// opens the transport booking screen.
  Future<void> _startRideToDrop(SavedAddress drop) async {
    final dropLat = drop.lat ?? 0.0;
    final dropLng = drop.lng ?? 0.0;
    if (dropLat == 0.0 && dropLng == 0.0) {
      commonSnackBar(
          message:
              'Selected address has no location. Please re-select it from the suggestions.');
      return;
    }

    final businessId =
        _order?.businessId ?? widget.message.sender?.id ?? '';
    if (businessId.isEmpty) {
      commonSnackBar(message: 'Shop pickup location is unavailable.');
      return;
    }

    AppLoader.show(message: 'Finding riders...');
    try {
      final orderController = getOrPut(() => OrderNowController());
      await orderController.viewBusinessForLocation(businessId, 'BUSINESS');
      final pickupLat = double.tryParse(orderController.lat.value) ?? 0.0;
      final pickupLng = double.tryParse(orderController.long.value) ?? 0.0;
      final pickupAddress = orderController.address.value;

      if (pickupLat == 0.0 && pickupLng == 0.0) {
        AppLoader.hide();
        commonSnackBar(message: 'Could not get the shop pickup location.');
        return;
      }

      final discoverController = getOrPut(() => DiscoverController());
      discoverController.selectedFromLat?.value = pickupLat;
      discoverController.selectedFromLong?.value = pickupLng;
      discoverController.selectedFromAddress?.value = pickupAddress;
      discoverController.selectedToLat?.value = dropLat;
      discoverController.selectedToLong?.value = dropLng;
      discoverController.selectedToAddress?.value = drop.fullAddress;

      // Chat self-pickup → rider dispatch (product / pharmacy).
      discoverController.setChatDispatchContext(
        selfpickupOrderId: _order?.orderId ?? _pickupOrderId ?? '',
        selfpickupType: widget.message.messageType ??
            (widget.isMedical ? 'medical_selfpickup' : 'product_selfpickup'),
        businessId: businessId,
        orderFor: widget.isMedical ? 'medical' : 'product',
      );

      await discoverController.getBookingRidersApi();
      AppLoader.hide();
      Get.to(() =>
          const ProductOrderBookingRiderMain(vehicleType: 'TWO_WHEELER'));
    } catch (e) {
      AppLoader.hide();
      log('startRideToDrop error: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Widget _orderActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            CustomText(
              label,
              fontSize: SizeConfig.size11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndSharePdf() async {
    final order = _order;
    final items = order?.items ?? [];
    if (items.isEmpty) {
      commonSnackBar(message: 'No items found in order');
      return;
    }

    setState(() => _isGeneratingPdf = true);

    try {
      final pdf = pw.Document();

      final Map<int, pw.MemoryImage> itemImages = {};
      for (int i = 0; i < items.length; i++) {
        final imageUrl = (items[i].images != null &&
                items[i].images!.isNotEmpty)
            ? items[i].images!.first.url
            : null;
        if (imageUrl != null) {
          try {
            final response = await http.get(Uri.parse(imageUrl));
            if (response.statusCode == 200) {
              itemImages[i] = pw.MemoryImage(response.bodyBytes);
            }
          } catch (e) {
            log('Failed to load image for item $i: $e');
          }
        }
      }

      final totalItems = order?.totalItems ?? items.length;
      final businessName = widget.message.sender?.name ?? 'Business';

      num totalMrp = 0;
      num totalSellingPrice = 0;
      for (final item in items) {
        final qty = item.quantity ?? 1;
        totalMrp += (item.mrp ?? 0) * qty;
        totalSellingPrice += (item.sellingPrice ?? 0) * qty;
      }
      final pdfGrandTotal = totalMrp;
      final netPay = totalSellingPrice;
      final totalSaving = pdfGrandTotal - netPay;
      final savingPercent = pdfGrandTotal > 0
          ? (totalSaving / pdfGrandTotal * 100).toStringAsFixed(1)
          : '0.0';

      final headerStyle = pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      );
      final cellStyle = const pw.TextStyle(fontSize: 9);
      final cellBoldStyle =
          pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);

      // The shop owner's Scan-&-Pay QR, printed at the end of the slip so
      // the customer can pay straight off the packing list. Null when the
      // owner has no UPI configured — the slip is then produced as before.
      final paymentQr = await buildShopOwnerPaymentQr(
        payeeName: businessName,
        orderId: widget.message.metadata?.selfpickupOrderId,
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (pw.Context context) {
            return [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#1565C0'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      businessName,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Packing List',
                      style: pw.TextStyle(
                        fontSize: 13,
                        color: PdfColor.fromHex('#BBDEFB'),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F5F5F5'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(
                      color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Products: $totalItems',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Order ID: ${order?.orderId ?? '-'}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#1565C0'),
                  borderRadius: const pw.BorderRadius.vertical(
                      top: pw.Radius.circular(6)),
                ),
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                child: pw.Row(
                  children: [
                    pw.SizedBox(
                        width: 30,
                        child: pw.Text('S.No', style: headerStyle)),
                    pw.SizedBox(
                        width: 50,
                        child: pw.Text('Image', style: headerStyle)),
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text('Product Name', style: headerStyle)),
                    pw.SizedBox(
                        width: 35,
                        child: pw.Text('Qty',
                            style: headerStyle,
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(
                        width: 55,
                        child: pw.Text('MRP',
                            style: headerStyle,
                            textAlign: pw.TextAlign.right)),
                    pw.SizedBox(
                        width: 55,
                        child: pw.Text('Price',
                            style: headerStyle,
                            textAlign: pw.TextAlign.right)),
                  ],
                ),
              ),
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final qty = item.quantity ?? 0;
                final sellingPrice = item.sellingPrice ?? 0;
                final mrp = item.mrp ?? 0;
                final hasImage = itemImages.containsKey(index);
                final isEven = index % 2 == 0;

                return pw.Container(
                  decoration: pw.BoxDecoration(
                    color: isEven
                        ? PdfColors.white
                        : PdfColor.fromHex('#F8F9FA'),
                    border: pw.Border(
                      left: pw.BorderSide(
                          color: PdfColors.grey300, width: 0.5),
                      right: pw.BorderSide(
                          color: PdfColors.grey300, width: 0.5),
                      bottom: pw.BorderSide(
                          color: PdfColors.grey200, width: 0.5),
                    ),
                  ),
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 10),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.SizedBox(
                        width: 30,
                        child: pw.Text('${index + 1}',
                            style: cellBoldStyle,
                            textAlign: pw.TextAlign.center),
                      ),
                      pw.SizedBox(
                        width: 50,
                        child: hasImage
                            ? pw.Container(
                                width: 40,
                                height: 40,
                                child: pw.ClipRRect(
                                  horizontalRadius: 4,
                                  verticalRadius: 4,
                                  child: pw.Image(
                                    itemImages[index]!,
                                    fit: pw.BoxFit.cover,
                                  ),
                                ),
                              )
                            : pw.Container(
                                width: 40,
                                height: 40,
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.grey200,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Center(
                                  child: pw.Text('-',
                                      style: const pw.TextStyle(
                                          fontSize: 8,
                                          color: PdfColors.grey400)),
                                ),
                              ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 4),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                item.productName ?? '',
                                style: cellBoldStyle,
                                maxLines: 4,
                              ),
                              if (item.variantName != null &&
                                  item.variantName!.isNotEmpty)
                                pw.Text(
                                  item.variantName!,
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.grey600,
                                  ),
                                  maxLines: 1,
                                ),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(
                        width: 35,
                        child: pw.Text('$qty',
                            style: cellBoldStyle,
                            textAlign: pw.TextAlign.center),
                      ),
                      pw.SizedBox(
                        width: 55,
                        child: pw.Text(
                          'Rs.$mrp',
                          style: mrp > sellingPrice
                              ? pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey500,
                                  decoration: pw.TextDecoration.lineThrough,
                                )
                              : cellStyle,
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.SizedBox(
                        width: 55,
                        child: pw.Text(
                          'Rs.$sellingPrice',
                          style: cellBoldStyle,
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              pw.Container(
                height: 2,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#1565C0'),
                  borderRadius: const pw.BorderRadius.vertical(
                      bottom: pw.Radius.circular(6)),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F5F5F5'),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(
                      color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Grand Total (MRP)',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Rs.$pdfGrandTotal',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Net Pay',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Rs.$netPay',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#1565C0'),
                          ),
                        ),
                      ],
                    ),
                    if (totalSaving > 0) ...[
                      pw.SizedBox(height: 3),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Total Saving ($savingPercent%)',
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#2E7D32'),
                            ),
                          ),
                          pw.Text(
                            'Rs.$totalSaving',
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#2E7D32'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (paymentQr != null) ...[
                pw.SizedBox(height: 20),
                buildPackingPaymentQrSection(paymentQr),
              ],
            ];
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/packing_list_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      log('Packing PDF generated: $filePath');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _PackingPdfPreviewScreen(
              filePath: filePath,
              message: widget.message,
              conversationId: widget.conversationId,
            ),
          ),
        );
      }
    } catch (e) {
      log('Error generating PDF: $e');
      commonSnackBar(message: 'Failed to generate PDF');
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomText(
        label,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _buildStatusBadge() {
    String label;
    Color bgColor;
    Color textColor;

    // Prefer the server's own status word. The badge is a one-word summary of
    // `lifecycle.orderStatus`; the human sentence is `lifecycle.banner`, which
    // the lifecycle section renders verbatim below.
    final serverStatus = _lifecycle?.orderStatus;
    if (serverStatus != null) {
      switch (serverStatus) {
        case OrderStatusValue.cancelled:
          return _statusChip('Cancelled', Colors.red);
        case OrderStatusValue.expired:
          return _statusChip('Expired', AppColors.grayText);
        case OrderStatusValue.completed:
          return _statusChip('Completed', const Color(0xFF1B9E4B));
        case OrderStatusValue.ready:
          return _statusChip('Ready', const Color(0xFF1B9E4B));
        case OrderStatusValue.dispatched:
          return _statusChip('On the way', AppColors.primaryColor);
        case OrderStatusValue.accepted:
        case OrderStatusValue.inProgress:
          return _statusChip('Preparing', AppColors.primaryColor);
        case OrderStatusValue.placed:
          return _statusChip('New', Colors.orange);
        default:
          // Unknown status from a newer backend — say nothing rather than
          // guess a colour and a word.
          return const SizedBox.shrink();
      }
    }

    if (_isCancelled) {
      label = 'Cancelled';
      bgColor = Colors.red.withValues(alpha: 0.1);
      textColor = Colors.red;
    } else if (_isReady) {
      label = 'Ready';
      bgColor = Colors.green.withValues(alpha: 0.1);
      textColor = Colors.green;
    } else {
      label = 'Pending';
      bgColor = Colors.orange.withValues(alpha: 0.1);
      textColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomText(
        label,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  Widget _buildItemRow(SelfPickupItem item) {
    final imageUrl = (item.images != null && item.images!.isNotEmpty)
        ? item.images!.first.url
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey.shade200,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.inventory_2_outlined,
                          size: 20, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.inventory_2_outlined,
                        size: 20, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  _itemDisplayName(item),
                  fontSize: SizeConfig.size12,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                CustomText(
                  '${AppConstants.rupeeSymbol}${item.sellingPrice ?? item.mrp ?? 0} x ${item.quantity ?? 1}',
                  fontSize: SizeConfig.size10,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
          CustomText(
            '${AppConstants.rupeeSymbol}${(item.sellingPrice ?? item.mrp ?? 0).toDouble() * (item.quantity ?? 1)}',
            fontSize: SizeConfig.size13,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableItemRow(
      SelfPickupItem item, bool isSelected, VoidCallback onTap) {
    final imageUrl = (item.images != null && item.images!.isNotEmpty)
        ? item.images!.first.url
        : null;
    final qty = item.quantity ?? 1;
    final sellingPrice = item.sellingPrice ?? 0;
    final itemTotal = sellingPrice * qty;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (imageUrl != null)
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 44,
                        height: 44,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image,
                            color: Colors.grey, size: 18),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image,
                            color: Colors.grey, size: 18),
                      ),
                    )
                  : Container(
                      width: 44,
                      height: 44,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image,
                          color: Colors.grey, size: 18),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    item.productName ?? '',
                    fontSize: SizeConfig.size12,
                    fontWeight: FontWeight.w500,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    'Qty: $qty',
                    fontSize: SizeConfig.size10,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
            ),
            CustomText(
              '₹$itemTotal',
              fontSize: SizeConfig.size14,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primaryColor : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

/// PDF preview screen with Share within BlueEra & External Share buttons
class _PackingPdfPreviewScreen extends StatelessWidget {
  final String filePath;
  final Messages message;
  final String? conversationId;

  const _PackingPdfPreviewScreen({
    required this.filePath,
    required this.message,
    this.conversationId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomText(
          'Packing List',
          fontSize: SizeConfig.size16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: PDFView(
              filePath: filePath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: false,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _shareWithinBlueEra(context),
                        icon: Icon(
                          Icons.send,
                          size: 20,
                          color: AppColors.primaryColor,
                        ),
                        label: CustomText(
                          'Share in BlueEra',
                          fontSize: SizeConfig.size14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _externalShare(),
                        icon: const Icon(
                          Icons.share,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: CustomText(
                          'External Share',
                          fontSize: SizeConfig.size14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Share within BlueEra — open the forward screen and send this packing-list
  /// PDF as a `document` message to the conversations the user selects.
  void _shareWithinBlueEra(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatForwardScreen(
          documentFilePath: filePath,
          stopChatNav: true,
        ),
      ),
    );
  }

  Future<void> _externalShare() async {
    try {
      await SharePlus.instance.share(ShareParams(
        files: [XFile(filePath)],
        subject: 'Packing List',
      ));
    } catch (e) {
      log('Error sharing PDF: $e');
      commonSnackBar(message: 'Failed to share PDF');
    }
  }
}
