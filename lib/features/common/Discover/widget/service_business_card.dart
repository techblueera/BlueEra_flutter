import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/common/Discover/model/other_service_business_search_res_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/common_methods.dart';
import '../view/others_service_detail_screen.dart';

/// Service-style business card used by the "Services Near Me" screen.
///
/// Bound to [OtherServiceBusinessItem] returned by
/// `other-service/business-profile/search`. Layout: hero image with rating
/// pill + action icons + formatted category title overlay, an "Open" pill
/// straddling the hero/body boundary, then a white body (avatar/name,
/// inline distance|address, service-title chips) and a light footer
/// (Price Range + chat + Book Now). Missing values render as "N/A".
class ServiceBusinessCard extends StatelessWidget {
  final OtherServiceBusinessItem item;

  /// Category-themed placeholder shown on the hero when the business has
  /// no cover / gallery / management image. Callers on category-specific
  /// screens (e.g. Automotive) pass a themed image so the card doesn't
  /// fall back to a bare grey box. `null` keeps the old grey-box behaviour.
  final String? fallbackHeroImageUrl;

  const ServiceBusinessCard({
    super.key,
    required this.item,
    this.fallbackHeroImageUrl,
  });

  static const String _na = 'N/A';

  // ─── DERIVED VALUES ──────────────────────────────────────────────
  OtherBusinessProfile? get _profile => item.profile;

  String get _heroImage {
    final cover = _profile?.coverUrl?.trim() ?? '';
    if (cover.isNotEmpty) return cover;
    final fromGallery = item.gallery
        .expand((g) => g.imageUrls)
        .firstWhere((u) => u.trim().isNotEmpty, orElse: () => '');
    if (fromGallery.isNotEmpty) return fromGallery;
    final fromManagement = item.management
        .map((m) => m.imageUrl ?? '')
        .firstWhere((u) => u.trim().isNotEmpty, orElse: () => '');
    if (fromManagement.isNotEmpty) return fromManagement;
    return fallbackHeroImageUrl?.trim() ?? '';
  }

  String get _avatarUrl {
    final cover = _profile?.coverUrl?.trim() ?? '';
    if (cover.isNotEmpty) return cover;
    return item.management
        .map((m) => m.imageUrl ?? '')
        .firstWhere((u) => u.trim().isNotEmpty, orElse: () => '');
  }

  /// "CONSULTING_BUSINESS_SERVICES" → "Consulting Business Services".
  String get _categoryDisplay {
    final raw = (_profile?.categoryOfBusiness ?? '').trim();
    if (raw.isEmpty) return _na;
    return raw
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  String get _ratingText {
    final r = _profile?.rating ?? 0;
    return r > 0 ? r.toStringAsFixed(1) : _na;
  }

  /// Returns "Open | HH:MM - HH:MM" for today if open, else "Closed".
  ({String label, bool isOpen}) get _todayStatus {
    final today = item.timings?.forWeekday(DateTime.now().weekday);
    if (today != null && today.hasHours) {
      return (
        label: 'Open | ${today.openTime} - ${today.closeTime}',
        isOpen: true
      );
    }
    return (label: 'Closed', isOpen: false);
  }

  /// "₹1,499-2,000" / "₹1,499+" / "Up to ₹2,000" / "N/A".
  String get _priceRangeText {
    final pr = item.priceRange;
    if (pr == null || !pr.hasAnyValue) return _na;
    final min = pr.min;
    final max = pr.max;
    if (min != null && max != null) return '₹${_fmt(min)}-${_fmt(max)}';
    if (min != null) return '₹${_fmt(min)}+';
    if (max != null) return 'Up to ₹${_fmt(max)}';
    return _na;
  }

  String _fmt(num n) {
    final s = n.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && (fromEnd - 1) % 3 == 0) buf.write(',');
    }
    return buf.toString();
  }

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
    final heroImage = _heroImage;
    final status = _todayStatus;
    final pillColor = status.isOpen ? AppColors.greenShade : AppColors.grey83;

    return SizedBox(
      height: 195,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: heroImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: heroImage,
                    fit: BoxFit.cover,
                    placeholder: (ctx, _) => Container(color: Colors.grey[200]),
                    errorWidget: (ctx, _, __) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_outlined,
                          size: 40, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_outlined,
                        size: 40, color: Colors.grey),
                  ),
          ),

          // ── Rating pill (top-left) ──
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.black25,
                borderRadius: BorderRadius.circular(20),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.black.withValues(alpha: 0.08),
                //     blurRadius: 4,
                //   ),
                // ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LocalAssets(
                    imagePath: AppIconAssets.fill_star,
                    width: 14,
                    height: 14,
                    imgColor: AppColors.yellow,
                  ),
                  const SizedBox(width: 3),
                  CustomText(
                    _ratingText,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white,
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
                _circleIconBtn(AppIconAssets.share_bold, onTap: _shareBusiness),
                const SizedBox(height: 8),
                _circleIconBtn(AppIconAssets.star, onTap: () {}),
              ],
            ),
          ),

          // ── Open/Closed pill (straddles hero/body boundary) ──
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xffF2FFF2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: pillColor.withValues(alpha: 0.6)),
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
                  LocalAssets(
                    imagePath: AppIconAssets.clock_new,
                    imgColor: AppColors.green0B,
                    height: 20,
                    width: 20,
                  ),
                  // Container(
                  //   width: 7,
                  //   height: 7,
                  //   decoration: BoxDecoration(
                  //     shape: BoxShape.circle,
                  //     color: pillColor,
                  //   ),
                  // ),
                  const SizedBox(width: 6),
                  CustomText(
                    status.label,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: pillColor,
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
      color: AppColors.black25,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: LocalAssets(
            imagePath: icon,
            imgColor: AppColors.white,
            height: 14,
            width: 8,
          ),
        ),
      ),
    );
  }

  // ─── BODY ────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // _buildHeaderRow(),
        // const SizedBox(height: 8),
        // _buildAddressRow(),
        _buildHeaderSection(),
        const SizedBox(height: 10),
        Divider(height: 1, thickness: 0.5, color: Color(0xFFDDE2EE)),
        const SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: _buildServiceChips(),
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    final loc = _profile?.businessLocation;
    final hasCoords = loc?.isValid ?? false;
    final km = hasCoords ? calculateDistance(loc!.lat!, loc.lng!) : null;

    final distanceText = km != null ? "${km.toStringAsFixed(0)}KM Away" : _na;

    final address = _resolveAddress();

    return GestureDetector(
      onTap: hasCoords ? () => _showMapBottomSheet(Get.context!) : null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 8, 14, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CachedAvatarWidget(
              imageUrl: _avatarUrl,
              size: 58,
              borderRadius: 29,
              borderColor: Colors.white,
              showProfileOnFullScreen: false,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// Business Name
                  CustomText(
                    _profile?.businessName ?? _profile?.profileName ?? _na,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black22,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  /// Address Row
                  Row(
                    children: [
                      LocalAssets(
                        imagePath: AppIconAssets.location_outline,
                        imgColor: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: distanceText,
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextSpan(
                                text: "  |  ",
                                style: TextStyle(
                                  color: AppColors.secondaryTextColor,
                                  fontSize: 12,
                                ),
                              ),
                              TextSpan(
                                text: address,
                                style: TextStyle(
                                  color: AppColors.secondaryTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildHeaderRow() {
    return Column(
      children: [
        Row(
          children: [
            CachedAvatarWidget(
              imageUrl: _avatarUrl,
              size: 32,
              borderRadius: 16,
              borderColor: AppColors.whiteE0,
              showProfileOnFullScreen: false,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomText(
                _profile?.businessName ?? _profile?.profileName ?? _na,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Inline distance + " | " + address. Tappable when we have map
  /// coordinates so users can launch directions.
  Widget _buildAddressRow() {
    final loc = _profile?.businessLocation;
    final hasCoords = loc?.isValid ?? false;
    final km = hasCoords ? calculateDistance(loc!.lat!, loc.lng!) : null;

    final distanceText = km != null ? '${km.toStringAsFixed(2)} Km Away' : _na;
    final addressText = _resolveAddress();

    return Builder(
      builder: (context) => GestureDetector(
        onTap: hasCoords ? () => _showMapBottomSheet(context) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LocalAssets(
              imagePath: AppIconAssets.location_outline,
              imgColor: AppColors.primaryColor,
              height: 22,
              width: 18,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: distanceText,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: '  •  ',
                      style: TextStyle(fontSize: 12, color: AppColors.grey83),
                    ),
                    TextSpan(
                      text: addressText,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.grey83,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveAddress() {
    final locationAddress = _profile?.location?.address?.trim() ?? '';
    if (locationAddress.isNotEmpty) return locationAddress;
    // final profileAddress = _profile?.address?.trim() ?? '';
    // if (profileAddress.isNotEmpty) return profileAddress;
    // final branchName =
    //     item.contactUs.firstOrNull?.branch?.location?.name?.trim() ?? '';
    // if (branchName.isNotEmpty) return branchName;
    return AppStrings.na.tr;
  }

  void _showMapBottomSheet(BuildContext context) {
    final loc = _profile?.businessLocation;
    if (loc == null || !loc.isValid) return;
    RouteMapBottomSheet.show(
      context: context,
      destinationName: _profile?.businessName ?? '',
      destinationAddress: _resolveAddress(),
      destinationLat: loc.lat!,
      destinationLng: loc.lng!,
      livePhotos: const <String>[],
      visitCallback: _openStore,
    );
  }

  /// Chips powered by `services[].title` — the only chip source per spec.
  Widget _buildServiceChips() {
    final titles = item.services
        .where((s) => s.isDeleted != true)
        .map((s) => s.title?.trim() ?? '')
        .where((t) => t.isNotEmpty)
        .toList();

    if (titles.isEmpty) {
      return Wrap(spacing: 8, children: [_chip(_na, isMore: false)]);
    }

    const maxVisible = 3;
    final visible =
        titles.length > maxVisible ? titles.sublist(0, maxVisible) : titles;
    final extra = titles.length - visible.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...visible.map((t) => _chip(t, isMore: false)),
        if (extra > 0) _chip('+$extra More', isMore: true),
      ],
    );
  }

  Widget _chip(String label, {required bool isMore}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
          color: isMore ? const Color(0xFFFFEBEB) : AppColors.geryFC,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xffDDE2EE), width: 0.5)),
      child: CustomText(label,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isMore ? const Color(0xFFE53935) : Color(0xff66727E)),
    );
  }

  // ─── FOOTER ──────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(color: Color(0xFFF6F8FC)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Price Range',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey7E,
                ),
                const SizedBox(height: 2),
                CustomText(
                  _priceRangeText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
          // _ChatSquareBtn(
          //   onTap: () {
          //     final uid = _profile?.userId ?? '';
          //     if (uid.isEmpty) return;
          //     if (isGuestUser()) {
          //       createProfileScreen();
          //       return;
          //     }
          //     ChatClickTracker.track(
          //       userId: _profile?.id ?? uid,
          //       source: ChatClickSource.searchResult,
          //     );
          //     final chat = getOrPut(() => ChatViewController());
          //     chat.checkChatConnectionAndOpenChat(
          //       userId: uid,
          //       name: _profile?.businessName,
          //       profile: _avatarUrl,
          //       route: AppConstants.route_discover,
          //     );
          //   },
          // ),
          // const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: _BookNowBtn(onTap: _openStore),
          ),
        ],
      ),
    );
  }

  void _openStore() {
    Get.to(() => OthersServiceDetailScreen(
          visitUserId: _profile?.userId ?? '',
        ));
  }

  Future<void> _shareBusiness() async {
    final shareLink = serviceDeepLinkBusiness(
      id: _profile?.userId,
    );

    await ShareService.instance.openShareSheet(
      text:
          "Check out ${_profile?.businessName ?? 'this profile'} on BlueEra:\n$shareLink",
      subject: _profile?.businessName,
    );
  }
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
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(
              AppStrings.inquiry.tr,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18, color: AppColors.white),
          ],
        ),
      ),
    );
  }
}
