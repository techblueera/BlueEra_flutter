import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/features/common/order_history/service/local_order_store.dart';
import 'package:BlueEra/features/common/order_history/view/local_shop_orders_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// WhatsApp-style chat-list of the shops the user has ordered from in the
/// Discover section. One row per shop owner; tapping opens that shop's order
/// thread. Everything is read from the on-device [LocalOrderStore].
class LocalOrdersListScreen extends StatefulWidget {
  const LocalOrdersListScreen({super.key});

  @override
  State<LocalOrdersListScreen> createState() => _LocalOrdersListScreenState();
}

class _LocalOrdersListScreenState extends State<LocalOrdersListScreen> {
  late Future<List<LocalOrderShopSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = LocalOrderStore.getShops();
  }

  void _reload() {
    setState(() => _future = LocalOrderStore.getShops());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(title: AppStrings.myOrdersTitle.tr),
      body: FutureBuilder<List<LocalOrderShopSummary>>(
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
          final shops = snapshot.data ?? const [];
          if (shops.isEmpty) return _emptyState();
          // Native ads at the shared list cadence. Only the SHOP LIST carries
          // them — the thread behind each row (LocalShopOrdersScreen) is drawn
          // as message bubbles, where an ad card would read as a message the
          // shop sent.
          final rows = buildNativeAdRows(shops.length);
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: rows.length,
            separatorBuilder: (_, index) {
              // The hairline is indented 78 to clear the avatar column, so
              // against an ad card it reads as a rule starting from nowhere.
              // Plain space on either side of a slot instead.
              final touchesAd = rows[index].isAd ||
                  (index + 1 < rows.length && rows[index + 1].isAd);
              if (touchesAd) return SizedBox(height: SizeConfig.size8);
              return const Divider(
                height: 1,
                indent: 78,
                color: Color(0xFFEDEDED),
              );
            },
            itemBuilder: (context, index) {
              final row = rows[index];
              if (row.isAd) {
                return NativeAdSlot(
                  adOrdinal: row.adOrdinal,
                  keyPrefix: 'orders_native_ad',
                  margin: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size12),
                );
              }
              return _shopRow(shops[row.contentIndex]);
            },
          );
        },
      ),
    );
  }

  Widget _shopRow(LocalOrderShopSummary shop) {
    final last = shop.lastOrder;
    return InkWell(
      onTap: () async {
        await Get.to(() => LocalShopOrdersScreen(
              shopKey: shop.shopKey,
              shopName: shop.shopName,
              shopImage: shop.shopImage,
            ));
        // Returning may have cleared the thread — refresh the list.
        _reload();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CachedAvatarWidget(
              imageUrl: shop.shopImage,
              size: 50,
              borderRadius: 25,
              showProfileOnFullScreen: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          shop.shopName.isNotEmpty
                              ? shop.shopName
                              : AppStrings.unknownLabel.tr,
                          fontSize: SizeConfig.size15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomText(
                        _timeLabel(last.createdAtDate),
                        fontSize: SizeConfig.size11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.grayText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _orderTypeChip(last.orderType),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomText(
                          last.summary.isNotEmpty
                              ? last.summary
                              : '${last.totalQty} item(s)',
                          fontSize: SizeConfig.size12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (shop.orderCount > 1) ...[
                        const SizedBox(width: 6),
                        _countBadge(shop.orderCount),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderTypeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomText(
        _orderTypeLabel(type),
        fontSize: SizeConfig.size10,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryColor,
      ),
    );
  }

  Widget _countBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      alignment: Alignment.center,
      child: CustomText(
        '$count',
        fontSize: SizeConfig.size10,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            CustomText(
              AppStrings.noOrdersYet.tr,
              fontSize: SizeConfig.size16,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            CustomText(
              AppStrings.noOrdersYetDesc.tr,
              fontSize: SizeConfig.size13,
              fontWeight: FontWeight.w400,
              color: AppColors.grayText,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  String _orderTypeLabel(String type) {
    switch (type) {
      case 'food':
        return 'Food';
      case 'tiffin':
        return 'Tiffin';
      case 'product':
        return 'Product';
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
      return AppStrings.yesterdayLabel.tr;
    }
    return DateFormat('dd/MM/yy').format(dt);
  }
}
