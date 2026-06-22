import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../view/others_service_detail_screen.dart';

/// Service-style business card used by the "Services Near Me" screen.
/// Layout mirrors the design spec: hero image with rating + action icons
/// + service title overlay, an "Open" pill straddling the hero/body
/// boundary, then a white body (avatar/name, location, chips, stats)
/// and a light footer (Starting From + chat + Book Now).
/// Missing values are rendered as "N/A" instead of being hidden.
class ServiceBusinessCard extends StatelessWidget {
  final GetAllStoreResModel store;

  const ServiceBusinessCard({super.key, required this.store});

  static const String _na = 'N/A';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openStore,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.whiteED),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(context),
            _buildBody(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ─── HERO ─────────────────────────────────────────────────────────
  Widget _buildHero(BuildContext context) {
    final livePhotos = (store.livePhotos ?? const <String>[]).where((p) => p.trim().isNotEmpty).toList();
    final heroImage = livePhotos.isNotEmpty ? livePhotos.first : (store.logo ?? '');

    final rating = (store.avgRating ?? 0).toDouble();
    final ratingText = rating > 0 ? rating.toStringAsFixed(1) : _na;

    final serviceTitle =
        (store.categoryOfBusiness?.name ?? store.subCategoryOfBusiness?.name ?? store.natureOfBusiness ?? '')
            .trim();

    return SizedBox(
      height: 195,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Image + dark gradient
          Positioned.fill(
            child: heroImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: heroImage,
                    fit: BoxFit.cover,
                    placeholder: (ctx, _) => Container(color: Colors.grey[200]),
                    errorWidget: (ctx, _, __) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),

          // ── Rating pill (top-left) ──
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
                  const SizedBox(width: 3),
                  CustomText(
                    ratingText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                ],
              ),
            ),
          ),

          // ── Action icons stack (top-right) ──
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                _circleIconBtn(AppIconAssets.share_bold, onTap: () {}),
                const SizedBox(height: 8),
                _circleIconBtn(AppIconAssets.star, onTap: () {}),
              ],
            ),
          ),

          // ── Service title (bottom-left) ──
          Positioned(
            left: 14,
            right: 14,
            bottom: 28,
            child: CustomText(
              serviceTitle.isNotEmpty ? serviceTitle : _na,
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ── Open pill (straddles hero/body boundary) ──
          Positioned(
            right: 14,
            bottom: -14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.greenShade.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.greenShade,
                    ),
                  ),
                  const SizedBox(width: 6),
                  CustomText(
                    'Open | 10:00 - 16:00',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenShade,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconBtn(String icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: LocalAssets(
            imagePath: icon,
            imgColor: AppColors.black,
            height: 14,
            width: 8,
          ),
        ),
      ),
    );
  }

  // ─── BODY ────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 22, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderRow(),
          const SizedBox(height: 10),
          _buildAddressCard(),
          const SizedBox(height: 12),
          _buildCategoryChips(),
          const SizedBox(height: 14),
          _buildStatsRow(),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        CachedAvatarWidget(
          imageUrl: store.logo ?? '',
          size: 32,
          borderRadius: 16,
          borderColor: AppColors.whiteE0,
          showProfileOnFullScreen: false,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomText(
            store.businessName ?? _na,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.grey83),
      ],
    );
  }

  /// Address tile — mirrors the ProductStoreCard pattern: shadowed
  /// location icon container, "X.XX Km Away" line + address line, the
  /// whole tile is tappable and opens the RouteMapBottomSheet.
  Widget _buildAddressCard() {
    final lat = store.businessLocation?.lat?.toDouble() ?? 0.0;
    final lng = store.businessLocation?.lon?.toDouble() ?? 0.0;
    final hasCoords = lat != 0.0 && lng != 0.0;
    final km = hasCoords
        ? calculateDistanceKm(
            LocationService.lng,
            LocationService.lat,
            lng,
            lat,
          )
        : null;

    final distanceText = km != null ? '${km.toStringAsFixed(2)} Km Away' : _na;
    final addressText = (store.address?.trim().isNotEmpty ?? false) ? store.address! : AppStrings.na.tr;

    return Builder(
      builder: (context) => GestureDetector(
        onTap: hasCoords ? () => _showMapBottomSheet(context) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildShadowedLocationIcon(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    distanceText,
                    fontSize: 12,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    addressText,
                    fontSize: 11,
                    color: AppColors.grey83,
                    fontWeight: FontWeight.w400,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShadowedLocationIcon() {
    return LocalAssets(
      imagePath: AppIconAssets.location_outline,
      imgColor: AppColors.primaryColor,
      height: 22,
      width: 18,
    );
  }

  void _showMapBottomSheet(BuildContext context) {
    RouteMapBottomSheet.show(
      context: context,
      destinationName: store.businessName ?? '',
      destinationAddress: store.address ?? '',
      destinationLat: store.businessLocation?.lat?.toDouble() ?? 0.0,
      destinationLng: store.businessLocation?.lon?.toDouble() ?? 0.0,
      livePhotos: store.livePhotos,
      visitCallback: () => _openStore(),
    );
  }

  Widget _buildCategoryChips() {
    final all = (store.categories ?? const <StoreCategoryBrief>[])
        .map((c) => c.name?.trim() ?? '')
        .where((n) => n.isNotEmpty)
        .toList();

    if (all.isEmpty) {
      return Wrap(
        spacing: 8,
        children: [_chip(_na, isMore: false)],
      );
    }

    const maxVisible = 3;
    final visible = all.length > maxVisible ? all.sublist(0, maxVisible) : all;
    final extra = all.length - visible.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...visible.map((c) => _chip(c, isMore: false)),
        if (extra > 0) _chip('+$extra More', isMore: true),
      ],
    );
  }

  Widget _chip(String label, {required bool isMore}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isMore ? const Color(0xFFFFEBEB) : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        label,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isMore ? const Color(0xFFE53935) : AppColors.grey44,
      ),
    );
  }

  Widget _buildStatsRow() {
    final year = store.dateOfIncorporation?.year;
    final yrs = (year != null && year > 1900) ? DateTime.now().year - year : null;
    final products = store.totalProductCount ?? 0;

    final stats = <_StatCol>[
      _StatCol(
        value: yrs != null && yrs > 0 ? '$yrs+ Yrs' : _na,
        label: 'Experience',
      ),
      _StatCol(
        value: products > 0 ? '$products+' : _na,
        label: 'Projects',
      ),
      _StatCol(
        // No "response time" field in the model — always N/A per spec.
        value: _na,
        label: 'Response',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.whiteED),
        ),
      ),
      child: Row(
        children: List.generate(stats.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Container(width: 1, height: 32, color: AppColors.whiteED);
          }
          return Expanded(child: _statColumn(stats[i ~/ 2]));
        }),
      ),
    );
  }

  Widget _statColumn(_StatCol s) {
    return Column(
      children: [
        CustomText(
          s.value,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
        ),
        const SizedBox(height: 2),
        CustomText(s.label, fontSize: 11, color: AppColors.grey83),
      ],
    );
  }

  // ─── FOOTER ──────────────────────────────────────────────────────
  Widget _buildFooter() {
    final priceText = (store.quirkyMessage ?? '').trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8FC),
      ),
      child: Row(
        children: [
          // Starting From / price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Starting From',
                  fontSize: 11,
                  color: AppColors.grey83,
                ),
                const SizedBox(height: 2),
                CustomText(
                  priceText.isEmpty ? _na : priceText,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
              ],
            ),
          ),
          _ChatSquareBtn(
            onTap: () {
              final uid = store.userId ?? '';
              if (uid.isEmpty) return;
              if (isGuestUser()) {
                createProfileScreen();
                return;
              }
              ChatClickTracker.track(
                userId: store.id ?? uid,
                source: ChatClickSource.searchResult,
              );
              final chat = getOrPut(() => ChatViewController());
              chat.checkChatConnectionAndOpenChat(
                userId: uid,
                name: store.businessName,
                profile: store.logo,
                route: AppConstants.route_discover,
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _BookNowBtn(onTap: _openStore),
          ),
        ],
      ),
    );
  }

  void _openStore() {
    Get.to(() => OthersServiceDetailScreen(
          visitUserId: store.userId ?? '',
        ));
  }
}

class _StatCol {
  final String value;
  final String label;
  _StatCol({required this.value, required this.label});
}

class _ChatSquareBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _ChatSquareBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.all(12),
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: LocalAssets(
          imagePath: AppIconAssets.chat,
          imgColor: AppColors.primaryColor,
        ),
      ),
    );
  }
}

class _BookNowBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BookNowBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(
              AppStrings.bookNow.tr,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 16, color: AppColors.white),
          ],
        ),
      ),
    );
  }
}
