import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/order_history/service/local_order_store.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Conversation-style view of every order placed with one shop. Each order is
/// rendered as a chat bubble (newest at the bottom). Multiple orders from the
/// same shop stack as multiple bubbles in this single thread.
class LocalShopOrdersScreen extends StatefulWidget {
  const LocalShopOrdersScreen({
    super.key,
    required this.shopKey,
    required this.shopName,
    required this.shopImage,
  });

  final String shopKey;
  final String shopName;
  final String shopImage;

  @override
  State<LocalShopOrdersScreen> createState() => _LocalShopOrdersScreenState();
}

class _LocalShopOrdersScreenState extends State<LocalShopOrdersScreen> {
  late Future<List<LocalOrderRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = LocalOrderStore.getOrdersForShop(widget.shopKey);
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: CustomText(
          AppStrings.myOrdersTitle.tr,
          fontSize: SizeConfig.size18,
          fontWeight: FontWeight.bold,
        ),
        content: CustomText(
          'Clear all local orders for ${widget.shopName}?',
          fontSize: SizeConfig.size14,
          color: Colors.black87,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: CustomText(AppStrings.cancel.tr, color: Colors.grey),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: CustomText(AppStrings.clear.tr,
                color: AppColors.red, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    if (ok == true) {
      await LocalOrderStore.clearShop(widget.shopKey);
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EC),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
        titleSpacing: 0,
        title: Row(
          children: [
            CachedAvatarWidget(
              imageUrl: widget.shopImage,
              size: 38,
              borderRadius: 19,
              showProfileOnFullScreen: false,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomText(
                widget.shopName.isNotEmpty
                    ? widget.shopName
                    : AppStrings.unknownLabel.tr,
                fontSize: SizeConfig.size16,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: FutureBuilder<List<LocalOrderRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryColor,
              ),
            );
          }
          final orders = snapshot.data ?? const [];
          if (orders.isEmpty) {
            return Center(
              child: CustomText(
                AppStrings.noOrdersYet.tr,
                fontSize: SizeConfig.size15,
                color: AppColors.secondaryTextColor,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            itemCount: orders.length,
            itemBuilder: (context, index) => _orderBubble(orders[index]),
          );
        },
      ),
    );
  }

  Widget _orderBubble(LocalOrderRecord order) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: SizeConfig.screenWidth * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 10, left: 40),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: const BoxDecoration(
          color: Color(0xFFD9FDD3), // WhatsApp outgoing green
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: order type + status pill.
            Row(
              children: [
                Icon(_typeIcon(order.orderType),
                    size: 16, color: AppColors.primaryColor),
                const SizedBox(width: 6),
                CustomText(
                  _orderTypeLabel(order.orderType),
                  fontSize: SizeConfig.size13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.greenShade.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: CustomText(
                    AppStrings.orderPlacedStatus.tr,
                    fontSize: SizeConfig.size10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greenShade,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Divider(height: 1, color: Color(0x33000000)),
            const SizedBox(height: 6),
            // Item lines.
            ...order.items.map(_itemLine),
            const SizedBox(height: 4),
            const Divider(height: 1, color: Color(0x33000000)),
            const SizedBox(height: 4),
            // Total.
            Row(
              children: [
                CustomText(
                  AppStrings.orderTotalLabel.tr,
                  fontSize: SizeConfig.size13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
                const Spacer(),
                CustomText(
                  '${AppConstants.rupeeSymbol}${order.totalPrice.toStringAsFixed(0)}',
                  fontSize: SizeConfig.size14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: CustomText(
                _timeLabel(order.createdAtDate),
                fontSize: SizeConfig.size10,
                fontWeight: FontWeight.w400,
                color: AppColors.grayText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemLine(LocalOrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CustomText(
              '${item.name}  x${item.quantity}',
              fontSize: SizeConfig.size13,
              fontWeight: FontWeight.w500,
              color: AppColors.mainTextColor,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          CustomText(
            '${AppConstants.rupeeSymbol}${item.lineTotal.toStringAsFixed(0)}',
            fontSize: SizeConfig.size13,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'food':
        return Icons.restaurant_menu;
      case 'tiffin':
        return Icons.lunch_dining;
      case 'product':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.receipt_long;
    }
  }

  String _orderTypeLabel(String type) {
    switch (type) {
      case 'food':
        return 'Food order';
      case 'tiffin':
        return 'Tiffin order';
      case 'product':
        return 'Product order';
      default:
        return 'Order';
    }
  }

  String _timeLabel(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(dt.year, dt.month, dt.day);
    if (that == today) return DateFormat.jm().format(dt);
    if (that == today.subtract(const Duration(days: 1))) {
      return '${AppStrings.yesterdayLabel.tr}, ${DateFormat.jm().format(dt)}';
    }
    return DateFormat('dd/MM/yy, ').format(dt) + DateFormat.jm().format(dt);
  }
}
