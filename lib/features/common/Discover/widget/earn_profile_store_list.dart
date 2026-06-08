import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/controller/earn_profiles_discover_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Primary accent for the Discover earn-service cards, aligned with the app
/// theme. Module-level so host screens and the card share one source of truth.
const Color kEarnProfilePrimary = AppColors.primaryColor; // 0xFF0086FF
const Color kEarnProfilePrimaryDeep = AppColors.blue5CAF; // 0xFF005CAF

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
          top: 12,
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

/// Store card: full-width hero with a rating badge + share/bookmark, a
/// logo + name + distance·address row, a 3-column feature strip
/// (delivery / payment / diet), and Chat + "view menu" action buttons.
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyE5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleRow(context),
                const SizedBox(height: 12),
                _buildFeatureRow(),
                const SizedBox(height: 12),
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero image + rating badge + share / bookmark ──────────────────────────
  Widget _buildHero() {
    return SizedBox(
      height: 170,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_hero.isNotEmpty)
            CachedNetworkImage(
              imageUrl: _hero,
              fit: BoxFit.cover,
              memCacheWidth: 800,
              placeholder: (_, __) => Container(color: AppColors.blue5CFF),
              errorWidget: (_, __, ___) => _heroFallback(),
            )
          else
            _heroFallback(),
          Positioned(top: 10, left: 10, child: _ratingBadge()),
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              children: [
                _circleIconBtn(AppIconAssets.reelShare),
                const SizedBox(height: 8),
                _circleIconBtn(AppIconAssets.star_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroFallback() {
    return Container(
      color: AppColors.blue5CFF,
      alignment: Alignment.center,
      child: Icon(Icons.storefront_rounded,
          size: 54, color: kEarnProfilePrimary.withValues(alpha: 0.45)),
    );
  }

  // NOTE: the earn-profile model has no rating field yet — this shows a
  // placeholder until the API exposes one.
  Widget _ratingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(
              imagePath: AppIconAssets.fill_star,
              width: 12,
              height: 12,
              imgColor: AppColors.yellow
          ),
          const SizedBox(width: 3),
          CustomText('4.8',
              fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
        ],
      ),
    );
  }

  Widget _circleIconBtn(String icon) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.40),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.25), width: 0.6),
      ),
      child:
      LocalAssets(
          imagePath: icon,
          width: 16,
          height: 16,
          imgColor: Colors.white
      ),
    );
  }

  // ── Logo + name + distance·address ────────────────────────────────────────
  Widget _buildTitleRow(BuildContext context) {
    final km = calculateDistanceKm(
      LocationService.lat,
      LocationService.lng,
      store.latitude ?? 0.0,
      store.longitude ?? 0.0,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.greyE5, width: 1.5),
          ),
          child: CachedAvatarWidget(
            imageUrl: store.serviceLogo ?? '',
            size: 42,
            borderColor: Colors.transparent,
            borderRadius: 21,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                store.serviceName ?? AppStrings.na,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              GestureDetector(
                onTap: () => _showMap(context),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 13, color: kEarnProfilePrimary),
                    const SizedBox(width: 3),
                    CustomText('${km.toStringAsFixed(0)}KM Away',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: kEarnProfilePrimary),
                    CustomText('  |  ',
                        fontSize: 11.5, color: AppColors.greyE5),
                    Expanded(
                      child: CustomText(
                        store.address ?? AppStrings.na,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 3-column feature strip ────────────────────────────────────────────────
  Widget _buildFeatureRow() {
    const dark = AppColors.secondaryTextColor;
    final diet = (store.foodType ?? '').trim();
    final hasDiet = diet.isNotEmpty;
    final isVeg = !diet.toLowerCase().contains('non');
    final dietColor =
        isVeg ? const Color(0xFF1E7D34) : const Color(0xFFC0341D);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5),
        color: AppColors.whiteF4
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _featureCol(Icons.delivery_dining_rounded,
                  'Home Delivery', dark),
            ),
            _vDivider(),
            Expanded(
              child: _featureCol(Icons.currency_rupee_rounded,
                  'Monthly Payment', dark),
            ),
            _vDivider(),
            Expanded(
              child: hasDiet
                  ? _featureCol(
                      Icons.check_box_rounded,
                      isVeg ? 'Veg Food' : 'Non-Veg',
                      dietColor,
                    )
                  : _featureCol(Icons.verified_rounded, 'Verified',
                      kEarnProfilePrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      width: 1, color: AppColors.greyE5);

  Widget _featureCol(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 5),
          CustomText(
            label,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Chat + view-menu buttons ──────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _openChat,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: kEarnProfilePrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: kEarnProfilePrimary.withValues(alpha: 0.4),
                    width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LocalAssets(
                      imagePath: AppIconAssets.chat,
                      width: 15,
                      height: 15,
                      imgColor: kEarnProfilePrimary
                  ),
                  const SizedBox(width: 5),
                  CustomText('Chat',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: kEarnProfilePrimary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kEarnProfilePrimaryDeep, kEarnProfilePrimary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(footerLabel,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3),
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 15, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openChat() {
    final uid = store.userId ?? '';
    if (uid.trim().isEmpty) return;
    if (isGuestUser()) {
      createProfileScreen();
      return;
    }
    final bId = store.id?.trim();
    if (bId != null && bId.isNotEmpty) {
      ChatClickTracker.track(
        userId: bId,
        source: ChatClickSource.searchResult,
      );
    }
    final chatViewController = getOrPut(() => ChatViewController());
    chatViewController.checkChatConnectionAndOpenChat(
      userId: uid,
      name: store.serviceName,
      profile: store.serviceLogo,
      route: AppConstants.route_discover,
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
