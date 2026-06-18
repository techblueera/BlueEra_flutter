import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/service/profile_click_tracker.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/repo/earn_profile_repo.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// **v2** home-service details.
///
/// Self-contained: the [service] (a [GetServiceModel]) already comes from the
/// discover list, so we DON'T refetch services here. We only fetch the
/// provider's earn-profile "store" (by userId) for the identity / gallery /
/// contact sections via `fetchEarnProfileByUserId`.
class HomeServiceDiscoverDetailsScreenV2 extends StatefulWidget {
  final GetServiceModel service;

  const HomeServiceDiscoverDetailsScreenV2({super.key, required this.service});

  @override
  State<HomeServiceDiscoverDetailsScreenV2> createState() =>
      _HomeServiceDiscoverDetailsScreenV2State();
}

class _HomeServiceDiscoverDetailsScreenV2State
    extends State<HomeServiceDiscoverDetailsScreenV2> {
  static const Color _primary = AppColors.primaryColor;
  static const Color _placeholderBg = AppColors.blue5CFF;
  static const String _profileType = 'homeService';

  GetServiceModel get service => widget.service;

  final _repo = EarnProfileRepo();
  EarnProfileModel? _store;
  bool _loadingStore = true;

  String get _userId => (service.serviceProvider?.id ??
          service.providerDetails?.id ??
          service.userId ??
          '')
      .trim();

  @override
  void initState() {
    super.initState();
    if (_userId.isNotEmpty) {
      ProfileClickTracker.track(
        userId: _userId,
        source: ChatClickSource.searchResult,
      );
    }
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (_userId.isEmpty) {
      setState(() => _loadingStore = false);
      return;
    }
    try {
      final res = await _repo.fetchEarnProfileByUserId(
        userId: _userId,
        queryParams: const {'profileType': _profileType},
      );
      final body = res.response?.data;
      // The by-userId endpoint returns a SINGLE object: { success, data: {…} }.
      if (res.isSuccess && body is Map && body['data'] is Map) {
        _store = EarnProfileModel.fromJson(
            Map<String, dynamic>.from(body['data'] as Map));
      }
    } catch (_) {/* swallow — store-only sections simply hide */}
    if (mounted) setState(() => _loadingStore = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(),
              _buildIdentity(),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildServices(),
                    _buildGallery(),
                    _buildContactCard(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero cover image + back ────────────────────────────────────────────────
  Widget _buildHero() {
    final statusBar = MediaQuery.of(context).padding.top;
    final servicePhotos = service.photos ?? const <String>[];
    final cover = servicePhotos.isNotEmpty
        ? servicePhotos.first
        : ((_store?.galleryImages.isNotEmpty ?? false)
            ? _store!.galleryImages.first
            : '');

    return SizedBox(
      height: 210 + statusBar,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cover.isNotEmpty)
            CachedNetworkImage(
              imageUrl: cover,
              fit: BoxFit.cover,
              memCacheWidth: 1000,
              placeholder: (_, __) => Container(color: _placeholderBg),
              errorWidget: (_, __, ___) => _coverFallback(),
            )
          else
            _coverFallback(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x40000000), Color(0x00000000)],
                stops: [0.0, 0.35],
              ),
            ),
          ),
          Positioned(
            top: statusBar + 8,
            left: 12,
            child: _circleButton(
              asset: AppIconAssets.back_arrow,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required String asset, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.25), width: 0.6),
        ),
        child: LocalAssets(
          imagePath: asset,
          width: 18,
          height: 18,
          imgColor: Colors.white,
        ),
      ),
    );
  }

  Widget _coverFallback() {
    return Container(
      color: _placeholderBg,
      alignment: Alignment.center,
      child: Icon(Icons.home_repair_service_rounded,
          size: 56, color: _primary.withValues(alpha: 0.45)),
    );
  }

  // ── Identity: logo + store name + provider + location + chat ───────────────
  Widget _buildIdentity() {
    final lat = _store?.latitude ?? 0.0;
    final lng = _store?.longitude ?? 0.0;
    final hasLoc = !(lat == 0.0 && lng == 0.0);
    final km = calculateDistanceKm(
        LocationService.lat, LocationService.lng, lat, lng);

    final storeName = (_store?.serviceName?.trim().isNotEmpty ?? false)
        ? _store!.serviceName!.trim()
        : (service.title ?? AppStrings.na);
    final providerName = service.providerDetails?.name?.trim() ?? '';
    final profession = service.providerDetails?.profession?.trim() ?? '';
    final logo = (_store?.serviceLogo?.trim().isNotEmpty ?? false)
        ? _store!.serviceLogo!.trim()
        : (service.providerDetails?.profileImage ?? '');
    final address = (_store?.address?.trim().isNotEmpty ?? false)
        ? _store!.address!.trim()
        : '';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                storeName,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (providerName.isNotEmpty || profession.isNotEmpty) ...[
                const SizedBox(height: 6),
                CustomText(
                  [providerName, profession]
                      .where((e) => e.isNotEmpty)
                      .join('  •  '),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [_tagPill('Home Service'), _ratingChip()],
              ),
              if (hasLoc || address.isNotEmpty) ...[
                const SizedBox(height: 12),
                _locationPill(km, hasLoc, address),
              ],
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFEDEFF4)),
              const SizedBox(height: 14),
              _buildFeatureRow(),
            ],
          ),
        ),
        Positioned(
          left: 16,
          top: -14,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CachedAvatarWidget(
              imageUrl: logo,
              size: 62,
              borderColor: Colors.transparent,
              borderRadius: 31,
            ),
          ),
        ),
        Positioned(right: 16, top: 6, child: _chatPill()),
      ],
    );
  }

  Widget _chatPill() {
    return GestureDetector(
      onTap: _openChat,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.30),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalAssets(
              imagePath: AppIconAssets.chat,
              width: 15,
              height: 15,
              imgColor: Colors.white,
            ),
            const SizedBox(width: 6),
            CustomText('Chat',
                fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _tagPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: CustomText(text,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryTextColor),
    );
  }

  // NOTE: placeholder rating — the model has no rating field yet.
  Widget _ratingChip() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LocalAssets(
          imagePath: AppIconAssets.fill_star,
          width: 14,
          height: 14,
          imgColor: AppColors.yellow,
        ),
        const SizedBox(width: 3),
        CustomText('4.8',
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor),
        const SizedBox(width: 3),
        CustomText('(48 reviews)',
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor),
      ],
    );
  }

  Widget _locationPill(double km, bool hasLoc, String address) {
    return GestureDetector(
      onTap: hasLoc ? _showMapBottomSheet : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded, size: 15, color: _primary),
            const SizedBox(width: 6),
            if (hasLoc) ...[
              CustomText('${km.toStringAsFixed(0)} KM',
                  fontSize: 12, fontWeight: FontWeight.w800, color: _primary),
              CustomText('  |  ', fontSize: 12, color: AppColors.greyE5),
            ],
            Expanded(
              child: CustomText(
                address.isNotEmpty ? address : AppStrings.na,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3-column feature strip ─────────────────────────────────────────────────
  Widget _buildFeatureRow() {
    const cellBg = Color(0xFFF6F7F9);
    const dark = AppColors.mainTextColor;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _featureCol(Icons.home_repair_service_rounded,
                  'At Your Doorstep', dark, cellBg),
            ),
            _vDivider(),
            Expanded(
              child: _featureCol(
                  Icons.schedule_rounded, 'Flexible Timing', dark, cellBg),
            ),
            _vDivider(),
            Expanded(
              child: _featureCol(
                  Icons.verified_rounded, 'Verified', _primary, cellBg),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, color: AppColors.greyE5);

  Widget _featureCol(IconData icon, String label, Color color, Color bg) {
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          CustomText(
            label,
            fontSize: 11.5,
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

  // ── Services — heading + the single service card (same as
  //    HomeServiceDiscoverDetailsScreen._buildServices). ─────────────────────
  Widget _buildServices() {
    return CustomFormCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('Services'),
          const SizedBox(height: 12),
          _serviceCard(service),
        ],
      ),
    );
  }

  // ── Service card — full-bleed image with frosted-glass info bar. ──────────
  Widget _serviceCard(GetServiceModel item) {
    final photos = item.photos ?? const <String>[];
    final imageUrl = photos.isNotEmpty ? photos.first : null;
    final min = item.priceRange?.min;
    final max = item.priceRange?.max;
    final priceLabel = (min == null && max == null)
        ? null
        : '${AppConstants.rupeeSymbol}${_formatPrice(min)}-${_formatPrice(max)}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.greyE5, width: 0.5),
        ),
        child: Stack(
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: imageUrl,
                height: SizeConfig.size265,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: SizeConfig.size265,
                  color: AppColors.greyE5,
                ),
                errorWidget: (_, __, ___) => SizedBox(
                  height: SizeConfig.size265,
                  width: double.infinity,
                  child: _cardImageFallback(),
                ),
              )
            else
              SizedBox(
                height: SizeConfig.size265,
                width: double.infinity,
                child: _cardImageFallback(),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12.0),
                  bottomRight: Radius.circular(12.0),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    padding: EdgeInsets.all(SizeConfig.size12),
                    color: const Color(0x80000000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          item.title ?? AppStrings.na,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                        if ((item.description ?? '').isNotEmpty) ...[
                          SizedBox(height: SizeConfig.size6),
                          CustomText(
                            item.description!,
                            fontSize: SizeConfig.small,
                            color: AppColors.white.withValues(alpha: 0.85),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (priceLabel != null) ...[
                          SizedBox(height: SizeConfig.size10),
                          Row(
                            children: [
                              CustomText(
                                priceLabel,
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                              SizedBox(width: SizeConfig.size6),
                              CustomText(
                                'Range',
                                fontSize: SizeConfig.small,
                                color: AppColors.white.withValues(alpha: 0.75),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int? value) {
    if (value == null) return '';
    if (value >= 1000) {
      final k = value / 1000;
      final fixed = k == k.truncateToDouble()
          ? k.toStringAsFixed(0)
          : k.toStringAsFixed(1);
      return '${fixed}K';
    }
    return value.toString();
  }

  Widget _cardImageFallback() {
    return Container(
      color: _placeholderBg,
      alignment: Alignment.center,
      child: Icon(Icons.home_repair_service_rounded,
          size: 56, color: _primary.withValues(alpha: 0.45)),
    );
  }

  // ── Gallery (from the store / earn-profile) ────────────────────────────────
  Widget _buildGallery() {
    final images =
        (_store?.galleryImages ?? const <String>[])
            .where((p) => p.trim().isNotEmpty)
            .toList();
    if (images.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(AppStrings.gallery.tr),
          const SizedBox(height: 10),
          _galleryLayout(images),
        ],
      ),
    );
  }

  // 1 image → full-width banner · 2 → side-by-side · 3+ → 2-col grid. Avoids
  // the lopsided empty cell a fixed grid leaves for a single image.
  Widget _galleryLayout(List<String> images) {
    if (images.length == 1) {
      return _galleryTile(images, 0, height: 190);
    }
    if (images.length == 2) {
      return Row(
        children: [
          Expanded(child: _galleryTile(images, 0, height: 140)),
          const SizedBox(width: 10),
          Expanded(child: _galleryTile(images, 1, height: 140)),
        ],
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      primary: false,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.3,
      ),
      itemCount: images.length,
      itemBuilder: (_, index) => _galleryTile(images, index),
    );
  }

  Widget _galleryTile(List<String> images, int index, {double? height}) {
    final tile = InkWell(
      onTap: () => navigatePushTo(
        context,
        ImageViewScreen(
          appBarTitle: _store?.serviceName ?? AppStrings.gallery.tr,
          subTitle: AppStrings.imageViewer.tr,
          imageUrls: images,
          initialIndex: index,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: images[index],
          fit: BoxFit.cover,
          width: double.infinity,
          height: height,
          placeholder: (_, __) => Container(color: Colors.grey.shade200),
          errorWidget: (_, __, ___) => LocalAssets(
            imagePath: AppIconAssets.place_holder_image,
            boxFix: BoxFit.cover,
          ),
        ),
      ),
    );
    return height != null ? SizedBox(height: height, child: tile) : tile;
  }

  // ── Contact card (store) ───────────────────────────────────────────────────
  Widget _buildContactCard() {
    if (_loadingStore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final store = _store;
    if (store == null) return const SizedBox.shrink();

    final lat = store.latitude ?? 0.0;
    final lng = store.longitude ?? 0.0;
    final hasLoc = !(lat == 0.0 && lng == 0.0);
    final website = (store.website ?? '').trim();
    final phone = (store.alternatePhoneNumber ?? '').trim();
    final email = (store.email ?? '').trim();
    final address = (store.address ?? '').trim();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeading('Contact Us'),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: (store.serviceLogo?.isNotEmpty ?? false)
                        ? CachedNetworkImage(
                            imageUrl: store.serviceLogo!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _logoFallback(),
                          )
                        : _logoFallback(),
                  ),
                ),
                const SizedBox(height: 10),
                CustomText(
                  store.serviceName ?? AppStrings.na,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                CustomText(
                  'Trusted home services delivered to your doorstep — book and '
                  'chat directly with the provider.',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                if (website.isNotEmpty)
                  _contactRow(Icons.language_rounded, website, isLink: true),
                if (email.isNotEmpty) _contactRow(Icons.email_outlined, email),
                if (phone.isNotEmpty) _contactRow(Icons.call_rounded, phone),
                if (address.isNotEmpty)
                  _contactRow(Icons.location_on_rounded, address, maxLines: 2),
                if (hasLoc) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BusinessLocationMapWidget(
                      latitude: lat,
                      longitude: lng,
                      businessName: store.serviceName ?? AppStrings.na,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _showMapBottomSheet,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: _primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_rounded,
                              size: 16, color: _primary),
                          const SizedBox(width: 6),
                          CustomText('Get Directions',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: _primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String text,
      {int maxLines = 1, bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.secondaryTextColor),
          const SizedBox(width: 12),
          Expanded(
            child: CustomText(
              text,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isLink ? _primary : AppColors.mainTextColor,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoFallback() {
    return Container(
      color: _placeholderBg,
      alignment: Alignment.center,
      child: Icon(Icons.home_repair_service_rounded,
          size: 26, color: _primary.withValues(alpha: 0.5)),
    );
  }

  Widget _sectionHeading(String text) {
    return CustomText(
      text,
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: AppColors.mainTextColor,
      letterSpacing: 0.2,
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  void _openChat() {
    final uid = _userId;
    if (uid.isEmpty) return;
    if (isGuestUser()) {
      createProfileScreen();
      return;
    }
    ChatClickTracker.track(userId: uid, source: ChatClickSource.searchResult);
    final chatViewController = getOrPut(() => ChatViewController());
    chatViewController.checkChatConnectionAndOpenChat(
      userId: uid,
      name: _store?.serviceName ?? service.providerDetails?.name,
      profile: _store?.serviceLogo ?? service.providerDetails?.profileImage,
      route: AppConstants.route_discover,
    );
  }

  void _showMapBottomSheet() {
    final store = _store;
    if (store == null) return;
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
