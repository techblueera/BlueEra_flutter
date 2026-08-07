import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/order_controllar.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/saved_address_model.dart';
import 'package:BlueEra/features/chat/auth/model/self_pickup_order_model.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/product_order_booking_rider_main.dart';
import 'package:BlueEra/features/common/connect/view/goods_multi_order_booking_main.dart';
import 'package:BlueEra/features/me/grocery/repo/grocery_repo.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:dio/dio.dart' as dio;
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/features/chat/view/forward_screen/chat_forward_screen.dart';
import 'package:BlueEra/features/chat/view/widget/component_widgets.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/ride_drop_location_sheet.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/payment_qr_bottom_sheet.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/pickup_otp_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../../../core/api/apiService/api_keys.dart';

class SelfPickupMsgCard extends StatefulWidget {
  final Messages message;
  final String time;
  final String? conversationId;

  const SelfPickupMsgCard({
    super.key,
    required this.message,
    required this.time,
    this.conversationId,
  });

  @override
  State<SelfPickupMsgCard> createState() => _SelfPickupMsgCardState();
}

class _SelfPickupMsgCardState extends State<SelfPickupMsgCard> {
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

  bool get _isReady =>
      widget.message.metadata?.selfPickupOrder?.isReady ??
      (widget.message.metadata?.orderStatus == true);

  bool get _isCancelled => widget.message.metadata?.is_cancelled ?? false;

  /// Business taps "Mark as Ready" → show product selection bottom sheet
  void _onMarkAsReadyTap() {
    final selfPickupOrder = widget.message.metadata?.selfPickupOrder;
    final items = selfPickupOrder?.items ?? [];

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
            // Calculate selected total
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
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Title
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

                  // Scrollable product list
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

                  // Bottom buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Info button (inactive)
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
                                '$selectedCount items | \u20B9$selectedTotal',
                                fontSize: SizeConfig.size14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Submit button (active)
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
      // Separate packed and missing items
      final packedItems = <SelfPickupItem>[];
      final missingItems = <SelfPickupItem>[];
      for (int i = 0; i < allItems.length; i++) {
        if (selectedIndices.contains(i)) {
          packedItems.add(allItems[i]);
        } else {
          missingItems.add(allItems[i]);
        }
      }

      // Download images for all items
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
              imageCache[imageUrl] =
                  pw.MemoryImage(response.bodyBytes);
            }
          } catch (e) {
            log('Failed to load image: $e');
          }
        }
      }

      final businessName = widget.message.sender?.name ?? 'Business';
      final selfPickupOrder = widget.message.metadata?.selfPickupOrder;

      // Calculate packed totals
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

      // Styles
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
            // Table header
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
                      child: pw.Text('Product Name',
                          style: headerStyle)),
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
            // Rows
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
                                borderRadius:
                                    pw.BorderRadius.circular(4),
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
                          crossAxisAlignment:
                              pw.CrossAxisAlignment.start,
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
                                decoration:
                                    pw.TextDecoration.lineThrough,
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
            // Table bottom border
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

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (pw.Context context) {
            return [
              // Business name header
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

              // Order info bar
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
                  mainAxisAlignment:
                      pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Packed: ${packedItems.length}  |  Missing: ${missingItems.length}  |  Total: ${allItems.length}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Order ID: ${selfPickupOrder?.orderId ?? '-'}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ── PACKED ITEMS ──
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
                        style: const pw.TextStyle(
                            color: PdfColors.grey500)),
                  ),
                ),

              pw.SizedBox(height: 16),

              // Summary for packed items
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
                        mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
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
                        mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Net Pay',
                              style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text('Rs.$packedSellingTotal',
                              style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  color:
                                      PdfColor.fromHex('#1565C0'))),
                        ],
                      ),
                      if (packedSaving > 0) ...[
                        pw.SizedBox(height: 3),
                        pw.Row(
                          mainAxisAlignment:
                              pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                                'Total Saving ($packedSavingPercent%)',
                                style: pw.TextStyle(
                                    fontSize: 13,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromHex(
                                        '#2E7D32'))),
                            pw.Text('Rs.$packedSaving',
                                style: pw.TextStyle(
                                    fontSize: 13,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromHex(
                                        '#2E7D32'))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

              pw.SizedBox(height: 20),

              // ── MISSING ITEMS ──
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
            ];
          },
        ),
      );

      // Save PDF
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/packing_summary_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      log('Packing summary PDF generated: $filePath');

      // Send as document message
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

      // Mark order as ready
      await _markAsReady();
    } catch (e) {
      log('Error generating packing summary PDF: $e');
      commonSnackBar(message: 'Failed to generate PDF');
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  /// Mark order as ready via API
  Future<void> _markAsReady() async {
    final orderId =
        widget.message.metadata?.selfPickupOrder?.orderId ??
        widget.message.metadata?.selfpickupOrderId ??
        '';

    if (orderId.isEmpty) {
      commonSnackBar(message: 'Order ID not found');
      return;
    }

    setState(() => _isMarkingReady = true);

    try {
      final response =
          await GroceryRepo().markSelfPickupOrderReadyRepo(orderId: orderId);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      // Update local state
      widget.message.metadata?.orderStatus = true;
      widget.message.metadata?.selfPickupOrder?.isReady = true;
      setState(() {});

      commonSnackBar(message: 'Order marked as ready for pickup');
      log('Self-pickup order $orderId marked as ready');
    } catch (e) {
      log('Error marking order ready: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      setState(() => _isMarkingReady = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selfPickupOrder = widget.message.metadata?.selfPickupOrder;
    final items = selfPickupOrder?.items ?? [];
    final totalItems = selfPickupOrder?.totalItems ?? items.length;
    final grandTotal = selfPickupOrder?.grandTotal ?? 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Forward icon shifted to the centre of the left margin.
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                LocalAssets(
                  imagePath: AppImageAssets.selfPickupIcon,
                  height: 28,
                  width: 28,
                  boxFix: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'Your Order',
                        fontSize: SizeConfig.size14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                      CustomText(
                        '$totalItems ${totalItems == 1 ? 'item' : 'items'}',
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

          // Items List (show max 3)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: items.length > 3 ? 3 : items.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFE5E5E5)),
            itemBuilder: (context, index) {
              return _buildItemRow(items[index]);
            },
          ),

          // Show "extra..." if more than 3 items
          if (items.length > 3)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  'Grand Total',
                  fontSize: SizeConfig.size14,
                  fontWeight: FontWeight.w600,
                ),
                CustomText(
                  '\u20B9$grandTotal',
                  fontSize: SizeConfig.size16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),

          // Mark as Ready button (business side only) or Ready status (customer side)
          if (!_isCancelled) _buildActionSection(),

          // Forward icon
          const Divider(height: 1, color: Color(0xFFE5E5E5)),
          _buildForwardRow(),

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

  Widget _buildActionSection() {
    // 24h after createdAt, lock the action row regardless of side. Mirrors
    // the order-chat appbar/input expiry — the order can't be progressed.
    final bool isExpired =
        isMessageOlderThan24Hours(widget.message.createdAt);
    if (isExpired && !_isReady) {
      return Column(
        children: [
          const Divider(height: 1, color: Colors.grey),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_clock, color: AppColors.grayText, size: 18),
                const SizedBox(width: 6),
                CustomText(
                  'Order Closed',
                  fontSize: SizeConfig.size14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grayText,
                ),
              ],
            ),
          ),
        ],
      );
    }
    // If already ready, show ready confirmation for both sides
    if (_isReady) {
      return Column(
        children: [
          const Divider(height: 1, color: Colors.grey),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
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

    // Business side (received message): Show "Mark as Ready" button
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

    // Customer side (my message): Show "Preparing" status
    return Column(
      children: [
        const Divider(height: 1, color: Colors.grey),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
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

  /// Circular forward affordance shown in the left margin, vertically centred
  /// beside the order card. Keeps the original forward/share-PDF action.
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
              data: widget.message.metadata?.selfPickupOrder?.orderId ??
                  widget.message.metadata?.selfpickupOrderId,
              userId: _conversationPersonId,
              conversationId: widget.conversationId,
            ),
          ),
          // Find Rider — customer (card sender) only. Dispatches a rider to
          // collect the self-pickup order from the shop and deliver it to the
          // customer. Hidden for the business owner (see chat-dispatch guide).
          if (_isMyMessage)
            _orderActionButton(
              icon: Icons.two_wheeler,
              label: AppStrings.findRider.tr,
              color: Colors.deepOrange,
              // Ask for the drop location (saved addresses + add-new), stored
              // locally, then look up the shop pickup location and open the
              // transport booking screen with riders already being searched.
              onTap: () async {
                final drop = await showRideDropLocationSheet(context);
                if (drop != null) {
                  Get.to(() =>
                      GoodsMultiOrderBookingMain(dropAddress: drop));
                }
              },
            ),
          // Pickup OTP button removed: the self-pickup card's orderId is a
          // grocery/self-pickup order, NOT a RideOrder — calling the rider-service
          // pickup endpoint with it always 404s. When a rider is dispatched, the
          // dedicated rider_otp chat card handles OTP verification with the correct
          // rideOrderId. For pure self-pickup (no rider), no RideOrder exists.

        ],
      ),
    );
  }

  /// Resolves the shop (business) pickup location, sets pickup = shop and
  /// drop = the just-chosen [drop] address on the shared [DiscoverController],
  /// kicks off the rider search, and opens the transport booking screen.
  Future<void> _startRideToDrop(SavedAddress drop) async {
    final dropLat = drop.lat ?? 0.0;
    final dropLng = drop.lng ?? 0.0;
    if (dropLat == 0.0 && dropLng == 0.0) {
      commonSnackBar(
          message:
              'Selected address has no location. Please re-select it from the suggestions.');
      return;
    }

    // The shop is the business that owns this self-pickup order.
    final businessId = widget.message.metadata?.selfPickupOrder?.businessId ??
        widget.message.sender?.id ??
        '';
    if (businessId.isEmpty) {
      commonSnackBar(message: 'Shop pickup location is unavailable.');
      return;
    }

    AppLoader.show(message: 'Finding riders...');
    try {
      // Fetch the shop's pickup coordinates + address.
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

      // Seed the transport flow: pickup = shop, drop = chosen address.
      final discoverController = getOrPut(() => DiscoverController());
      discoverController.selectedFromLat?.value = pickupLat;
      discoverController.selectedFromLong?.value = pickupLng;
      discoverController.selectedFromAddress?.value = pickupAddress;
      discoverController.selectedToLat?.value = dropLat;
      discoverController.selectedToLong?.value = dropLng;
      discoverController.selectedToAddress?.value = drop.fullAddress;

      // Mark this booking as a chat self-pickup dispatch so the booking screen
      // creates the ride via the chat-dispatch endpoint (shop = pickup,
      // customer = drop) and the two handoff OTP cards are issued.
      discoverController.setChatDispatchContext(
        selfpickupOrderId: widget.message.metadata?.selfpickupOrderId ??
            widget.message.metadata?.selfPickupOrder?.orderId ??
            '',
        selfpickupType: widget.message.messageType ?? 'selfpickup',
        businessId: businessId,
        orderFor: 'grocery',
      );

      // Search for riders between the shop and the drop, then open the screen.
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
    final selfPickupOrder = widget.message.metadata?.selfPickupOrder;
    final items = selfPickupOrder?.items ?? [];
    if (items.isEmpty) {
      commonSnackBar(message: 'No items found in order');
      return;
    }

    setState(() => _isGeneratingPdf = true);

    try {
      final pdf = pw.Document();

      // Download product images
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

      final totalItems = selfPickupOrder?.totalItems ?? items.length;
      final businessName = widget.message.sender?.name ?? 'Business';

      // Calculate totals
      // Grand Total = sum of (mrp * qty)
      // Net Pay = sum of (sellingPrice * qty)
      // Total Saving = Grand Total - Net Pay
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

      // Header style
      final headerStyle = pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      );
      final cellStyle = const pw.TextStyle(fontSize: 9);
      final cellBoldStyle = pw.TextStyle(
          fontSize: 9, fontWeight: pw.FontWeight.bold);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (pw.Context context) {
            return [
              // Business name header
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

              // Order summary bar
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
                  mainAxisAlignment:
                      pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Products: $totalItems',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Order ID: ${selfPickupOrder?.orderId ?? '-'}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // Table header
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
                        child:
                            pw.Text('Image', style: headerStyle)),
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text('Product Name',
                            style: headerStyle)),
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

              // Table rows
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
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.center,
                    children: [
                      // S.No
                      pw.SizedBox(
                        width: 30,
                        child: pw.Text('${index + 1}',
                            style: cellBoldStyle,
                            textAlign: pw.TextAlign.center),
                      ),

                      // Image
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
                                  borderRadius:
                                      pw.BorderRadius.circular(4),
                                ),
                                child: pw.Center(
                                  child: pw.Text('-',
                                      style: const pw.TextStyle(
                                          fontSize: 8,
                                          color:
                                              PdfColors.grey400)),
                                ),
                              ),
                      ),

                      // Product Name (max 4 lines)
                      pw.Expanded(
                        flex: 2,
                        child: pw.Padding(
                          padding:
                              const pw.EdgeInsets.only(left: 4),
                          child: pw.Column(
                            crossAxisAlignment:
                                pw.CrossAxisAlignment.start,
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

                      // Qty
                      pw.SizedBox(
                        width: 35,
                        child: pw.Text('$qty',
                            style: cellBoldStyle,
                            textAlign: pw.TextAlign.center),
                      ),

                      // MRP
                      pw.SizedBox(
                        width: 55,
                        child: pw.Text(
                          'Rs.$mrp',
                          style: mrp > sellingPrice
                              ? pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey500,
                                  decoration: pw
                                      .TextDecoration.lineThrough,
                                )
                              : cellStyle,
                          textAlign: pw.TextAlign.right,
                        ),
                      ),

                      // Selling Price
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

              // Table bottom border
              pw.Container(
                height: 2,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#1565C0'),
                  borderRadius: const pw.BorderRadius.vertical(
                      bottom: pw.Radius.circular(6)),
                ),
              ),

              pw.SizedBox(height: 16),

              // Summary section
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
                    // Grand Total (sum of MRP)
                    pw.Row(
                      mainAxisAlignment:
                          pw.MainAxisAlignment.spaceBetween,
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

                    // Net Pay (sum of selling price)
                    pw.Row(
                      mainAxisAlignment:
                          pw.MainAxisAlignment.spaceBetween,
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

                    // Total Saving (Grand Total - Net Pay)
                    if (totalSaving > 0) ...[
                      pw.SizedBox(height: 3),
                      pw.Row(
                        mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
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
            ];
          },
        ),
      );

      // Save PDF
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/packing_list_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      log('Packing PDF generated: $filePath');

      // Open PDF preview with share options
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

  Widget _buildStatusBadge() {
    String label;
    Color bgColor;
    Color textColor;

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
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomText(
        label,
        fontSize: SizeConfig.size12,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  Widget _buildItemRow(SelfPickupItem item) {
    final imageUrl = (item.images != null && item.images!.isNotEmpty)
        ? item.images!.first.url
        : null;
    final qty = item.quantity ?? 0;
    final mrp = item.mrp ?? 0;
    final sellingPrice = item.sellingPrice ?? 0;
    final hasDiscount = mrp > sellingPrice;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (imageUrl != null)
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image,
                          color: Colors.grey, size: 20),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image,
                          color: Colors.grey, size: 20),
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image,
                        color: Colors.grey, size: 20),
                  ),
          ),
          const SizedBox(width: 10),

          // Product Details
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
                  item.variantName ?? '',
                  fontSize: SizeConfig.size10,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CustomText(
                      '\u20B9$sellingPrice',
                      fontSize: SizeConfig.size12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 4),
                      CustomText(
                        '\u20B9$mrp',
                        fontSize: SizeConfig.size10,
                        fontWeight: FontWeight.w400,
                        color: AppColors.grayText,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ],
                    const Spacer(),
                    CustomText(
                      'Qty: $qty',
                      fontSize: SizeConfig.size12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ],
            ),
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
            // Checkbox
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 10),

            // Product Image
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

            // Product Details
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

            // Price
            CustomText(
              '\u20B9$itemTotal',
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
          // PDF viewer
          Expanded(
            child: PDFView(
              filePath: filePath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: false,
            ),
          ),

          // Bottom buttons
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
                  // Share within BlueEra
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
                  // External share
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

  /// External share via OS share sheet
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
