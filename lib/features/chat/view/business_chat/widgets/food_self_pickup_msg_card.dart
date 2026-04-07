import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/self_pickup_order_model.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Chat message card for `food_selfpickup` message type.
/// Mirrors [SelfPickupMsgCard] but uses `foodPickupOrderId` / `foodPickupOrder`
/// metadata fields and routes the "Mark as Ready" API to the food service.
class FoodSelfPickupMsgCard extends StatefulWidget {
  final Messages message;
  final String time;
  final String? conversationId;

  const FoodSelfPickupMsgCard({
    super.key,
    required this.message,
    required this.time,
    this.conversationId,
  });

  @override
  State<FoodSelfPickupMsgCard> createState() => _FoodSelfPickupMsgCardState();
}

class _FoodSelfPickupMsgCardState extends State<FoodSelfPickupMsgCard> {
  bool _isMarkingReady = false;

  bool get _isMyMessage => widget.message.myMessage ?? false;

  SelfPickupOrderModel? get _order =>
      widget.message.metadata?.foodPickupOrder ??
      widget.message.metadata?.selfPickupOrder;

  bool get _isReady =>
      _order?.isReady ?? (widget.message.metadata?.orderStatus == true);

  bool get _isCancelled => widget.message.metadata?.is_cancelled ?? false;

  /// Mark food order as ready via food-service API
  Future<void> _markAsReady() async {
    final orderId = _order?.orderId ??
        widget.message.metadata?.foodPickupOrderId ??
        '';

    if (orderId.isEmpty) {
      commonSnackBar(message: 'Order ID not found');
      return;
    }

    setState(() => _isMarkingReady = true);

    try {
      final response =
          await FoodRepo().markFoodOrderReadyRepo(orderId: orderId);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      widget.message.metadata?.orderStatus = true;
      _order?.isReady = true;
      setState(() {});

      commonSnackBar(message: 'Food order marked as ready for pickup');
      log('Food self-pickup order $orderId marked as ready');
    } catch (e) {
      log('Error marking food order ready: $e');
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

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      width: SizeConfig.screenWidth * 0.75,
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
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.restaurant_menu, size: 28, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'Food Order',
                        fontSize: SizeConfig.size14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
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

          // Show "+X more items..." if more than 3 items
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
                  color: Colors.orange,
                ),
              ],
            ),
          ),

          // Action section
          if (!_isCancelled) _buildActionSection(),

          // Time
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 6, top: 4),
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
    );
  }

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
                Icon(Icons.check_circle, color: Colors.green, size: 18),
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

    // Business side — show "Mark as Ready"
    if (!_isMyMessage) {
      return Column(
        children: [
          const Divider(height: 1, color: Colors.grey),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: InkWell(
                onTap: _isMarkingReady ? null : _markAsReady,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: _isMarkingReady
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : CustomText(
                          'Mark as Ready',
                          fontSize: SizeConfig.size14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                ),
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
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
              const SizedBox(width: 8),
              CustomText(
                'Preparing your food...',
                fontSize: SizeConfig.size12,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    if (_isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomText('Cancelled',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.red),
      );
    }
    if (_isReady) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomText('Ready',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.green),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomText('Pending',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.orange),
    );
  }

  Widget _buildItemRow(SelfPickupItem item) {
    final imageUrl =
        (item.images != null && item.images!.isNotEmpty)
            ? item.images!.first.url
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Item image
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
                      child: Icon(Icons.fastfood,
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
                    child: Icon(Icons.fastfood,
                        size: 20, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 10),
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  item.productName ?? item.variantName ?? '',
                  fontSize: SizeConfig.size12,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.variantName != null &&
                    item.variantName != item.productName)
                  CustomText(
                    item.variantName ?? '',
                    fontSize: SizeConfig.size10,
                    color: AppColors.secondaryTextColor,
                  ),
              ],
            ),
          ),
          // Qty x Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomText(
                'x${item.quantity ?? 1}',
                fontSize: SizeConfig.size12,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
              CustomText(
                '\u20B9${item.sellingPrice ?? item.mrp ?? 0}',
                fontSize: SizeConfig.size12,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
