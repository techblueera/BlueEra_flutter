import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/controller/earn_profiles_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_chat_icon.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const Color kEarnProfileWarm = Color(0xFFE8590C);
const Color kEarnProfileWarm2 = Color(0xFFF7A23B);

/// Shared "stores near me" list for the Discover earn-service surfaces
/// (home made food / product / service). Renders the editorial store cards,
/// loading and empty states. Pagination scroll is handled by the host screen
/// via [EarnProfilesDiscoverController.onScrollEnd].
class EarnProfileStoreList extends StatelessWidget {
  final EarnProfilesDiscoverController controller;
  final void Function(EarnProfileModel store) onStoreTap;
  final String footerLabel;
  final String emptyMessage;
  final double bottomPadding;

  const EarnProfileStoreList({
    super.key,
    required this.controller,
    required this.onStoreTap,
    required this.footerLabel,
    required this.emptyMessage,
    this.bottomPadding = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isFirstLoading.value && controller.stores.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.stores.isEmpty) {
        return Padding(
          padding: EdgeInsets.all(SizeConfig.size20),
          child: EmptyStateWidget(message: emptyMessage),
        );
      }

      final items = controller.stores;
      final showLoader = controller.isLoadingMore.value;

      return ListView.builder(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 10,
          bottom: bottomPadding,
        ),
        itemCount: items.length + (showLoader ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return EarnProfileStoreCard(
            store: items[index],
            footerLabel: footerLabel,
            onTap: () => onStoreTap(items[index]),
          );
        },
      );
    });
  }
}

/// Editorial store card: hero image with scrim, overlaid logo + name, frosted
/// distance pill + veg/non-veg pill, an info zone (address + delivery/payment
/// chips + chat) and a tinted "view" footer.
class EarnProfileStoreCard extends StatelessWidget {
  final EarnProfileModel store;
  final String footerLabel;
  final VoidCallback onTap;

  const EarnProfileStoreCard({
    super.key,
    required this.store,
    required this.footerLabel,
    required this.onTap,
  });

  String get _hero => store.coverImage?.isNotEmpty == true
      ? store.coverImage!
      : (store.galleryImages.isNotEmpty ? store.galleryImages.first : '');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0E7DD), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(),
            _buildInfoZone(context),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    final diet = (store.foodType ?? '').trim();
    final km = calculateDistanceKm(
      LocationService.lat,
      LocationService.lng,
      store.latitude ?? 0.0,
      store.longitude ?? 0.0,
    );

    return SizedBox(
      height: 168,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_hero.isNotEmpty)
            CachedNetworkImage(
              imageUrl: _hero,
              fit: BoxFit.cover,
              memCacheWidth: 800,
              placeholder: (_, __) => Container(color: const Color(0xFFF5E6C8)),
              errorWidget: (_, __, ___) => _heroFallback(),
            )
          else
            _heroFallback(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x00000000), Color(0xCC000000)],
                stops: [0.0, 0.42, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _frostedPill(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.near_me_rounded, size: 12, color: Colors.white),
                  const SizedBox(width: 5),
                  CustomText('${km.toStringAsFixed(1)} km',
                      fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                ],
              ),
            ),
          ),
          if (diet.isNotEmpty)
            Positioned(top: 12, right: 12, child: _dietPill(diet)),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CachedAvatarWidget(
                    imageUrl: store.serviceLogo ?? '',
                    size: 46,
                    borderColor: Colors.transparent,
                    borderRadius: 23,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomText(
                    store.serviceName ?? AppStrings.na,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroFallback() {
    return Container(
      color: const Color(0xFFF5E6C8),
      alignment: Alignment.center,
      child: Icon(Icons.storefront_rounded, size: 54, color: Colors.orange.shade300),
    );
  }

  Widget _frostedPill(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 0.6),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _dietPill(String text) {
    final isVeg = !text.toLowerCase().contains('non');
    final color = isVeg ? const Color(0xFF1E7D34) : const Color(0xFFC0341D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _vegMark(color),
          const SizedBox(width: 5),
          CustomText(text, fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
        ],
      ),
    );
  }

  Widget _vegMark(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _buildInfoZone(BuildContext context) {
    final chips = <Widget>[
      if (store.homeDelivery)
        _featureChip(Icons.delivery_dining_rounded, 'Home Delivery'),
      if (store.monthlyPayment)
        _featureChip(Icons.event_repeat_rounded, 'Monthly Payment'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _showMap(context),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalAssets(
                        imagePath: AppIconAssets.location_outline,
                        imgColor: kEarnProfileWarm,
                        height: 15,
                        width: 13,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: CustomText(
                          store.address ?? AppStrings.na,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: chips),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          DiscoverChatIcon(
            userId: store.userId ?? '',
            name: store.serviceName,
            profile: store.serviceLogo,
            businessId: store.id,
            trackingSource: ChatClickSource.searchResult,
          ),
        ],
      ),
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kEarnProfileWarm.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kEarnProfileWarm.withValues(alpha: 0.18), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kEarnProfileWarm),
          const SizedBox(width: 6),
          CustomText(label,
              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.mainTextColor),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: kEarnProfileWarm.withValues(alpha: 0.06),
        border: Border(
          top: BorderSide(color: kEarnProfileWarm.withValues(alpha: 0.12), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomText(footerLabel,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: kEarnProfileWarm,
              letterSpacing: 0.3),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_rounded, size: 15, color: kEarnProfileWarm),
        ],
      ),
    );
  }

  void _showMap(BuildContext context) {
    RouteMapBottomSheet.show(
      context: context,
      destinationName: store.serviceName ?? AppStrings.na,
      destinationAddress: store.address ?? '',
      destinationLat: store.latitude ?? 0.0,
      destinationLng: store.longitude ?? 0.0,
      livePhotos: store.galleryImages,
    );
  }
}
