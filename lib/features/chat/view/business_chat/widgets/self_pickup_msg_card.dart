import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/self_pickup_order_model.dart';
import 'package:BlueEra/features/me/grocery/repo/grocery_repo.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SelfPickupMsgCard extends StatefulWidget {
  final Messages message;
  final String time;

  const SelfPickupMsgCard({
    super.key,
    required this.message,
    required this.time,
  });

  @override
  State<SelfPickupMsgCard> createState() => _SelfPickupMsgCardState();
}

class _SelfPickupMsgCardState extends State<SelfPickupMsgCard> {
  bool _isMarkingReady = false;

  bool get _isMyMessage => widget.message.myMessage ?? false;

  bool get _isReady =>
      widget.message.metadata?.selfPickupOrder?.isReady ??
      (widget.message.metadata?.orderStatus == true);

  bool get _isCancelled => widget.message.metadata?.is_cancelled ?? false;

  /// Business taps "Mark as Ready" → PUT /api/orders/{orderId}/ready
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
                        'Self-Pickup Order',
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

          // Items List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFE5E5E5)),
            itemBuilder: (context, index) {
              return _buildItemRow(items[index]);
            },
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
    );
  }

  Widget _buildActionSection() {
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
                  _isMyMessage
                      ? 'Ready for Pickup'
                      : 'Ready for Pickup',
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
            onTap: _isMarkingReady ? null : _markAsReady,
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
                    _isMarkingReady ? 'Marking Ready...' : 'Mark as Ready',
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
                'Preparing...',
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
}
