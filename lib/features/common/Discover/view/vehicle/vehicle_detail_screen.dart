import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_profile_navigation.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/features/me/vehicle/view/booking/vehicle_bookings_screen.dart';
import 'package:BlueEra/features/me/vehicle/widget/vehicle_enquiry_sheet.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/social_gallery_grid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/common_methods.dart';
import '../../../../../core/services/share_service.dart';

/// Public detail screen for a single vehicle
/// (`GET /vehicles/get/:id`).
///
/// Reskinned to match [SelfEmployeeViewScreen]'s visual language so all
/// "discover → service detail" pages share one shape:
///
///   1. **Cover banner** — vehicle cover/first image, extends behind the
///      status bar with a translucent back/share row pinned over it.
///   2. **Overlapping avatar** — owner's profile image (with a graceful
///      car-icon fallback) so the viewer immediately sees *who* is
///      listing.
///   3. **Profile info block** — name, category pill, brand/model/year
///      secondary line, expandable description.
///   4. **Quick stats card** — three columns (Price · Year · Fuel) in
///      the same icon-circle layout the self-employee screen uses.
///   5. **Info cards** — Specifications, Location, Owner, Gallery
///      (`SocialGalleryGrid`).
///   6. **Sticky bottom CTA** — "Request Booking" opens a chat with the
///      vehicle owner via [ChatViewController.checkChatConnectionAndOpenChat],
///      identical to the self-employee handoff.
///
/// All data-loading machinery from the previous implementation is
/// preserved: hydration via [VehicleController.fetchVehicleById],
/// loading/error placeholders, and the `_dial` / `_openMaps`
/// launchers.
class VehicleDetailScreen extends StatefulWidget {
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final VehicleController _ctrl = getOrPut(() => VehicleController(), permanent: true);

  // Cover-banner slider — drives the PageView in the header so the user
  // can swipe through every vehicle photo without leaving the screen.
  // Kept local (not in the controller) because it's UI-only state that
  // resets per visit.
  final PageController _coverPageController = PageController();
  int _coverPageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _ctrl.fetchVehicleById(widget.vehicleId),
    );
  }

  @override
  void dispose() {
    _coverPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Obx(() {
        final state = _ctrl.vehicleDetailState.value;
        final v = _ctrl.selectedVehicle.value;

        if (state.status == Status.LOADING && v == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == Status.ERROR && v == null) {
          return _errorView(state.message ?? AppStrings.somethingWentWrong.tr);
        }
        if (v == null) return _errorView(AppStrings.vehicleNotFound.tr);
        return _buildBody(context, v);
      }),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context, Vehicle v) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: 80 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
              // Cover + overlapping owner avatar + profile info.
              _buildHeaderSection(context, v),

              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                child: Column(
                  children: _joinWithGap(
                    [
                      // Quick stats row — Price / Year / Fuel.
                      _buildStatsCard(v),

                      // Specifications grid.
                      if (_hasSpecs(v))
                        _buildInfoCard(
                          icon: Icons.settings_suggest_outlined,
                          title: AppStrings.specificationsTitle.tr,
                          child: _specsGrid(v),
                        ),

                      // Location block with optional "Directions" launcher.
                      if (_hasLocation(v))
                        _buildInfoCard(
                          icon: Icons.location_on_outlined,
                          title: AppStrings.location.tr,
                          child: _locationContent(v),
                        ),

                      // Owner / business card with optional call button.
                      if (v.user != null || v.business != null)
                        _buildInfoCard(
                          icon: Icons.person_outline_rounded,
                          title: AppStrings.listedByTitle.tr,
                          child: _ownerContent(v),
                        ),

                      // Gallery — uses the shared social-style grid so it
                      // matches the look in the self-employee screen.
                      if (_galleryImages(v).isNotEmpty)
                        _buildInfoCard(
                          icon: Icons.photo_library_outlined,
                          title: AppStrings.gallery.tr,
                          child: SocialGalleryGrid(
                            imageUrls: _galleryImages(v),
                          ),
                        ),
                    ],
                    gap: SizedBox(height: SizeConfig.size10),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Sticky bottom CTA — opens chat with the listing owner.
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size16,
              SizeConfig.size12,
              SizeConfig.size16,
              SizeConfig.size16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: _isOwnListing(v)
                ? CustomBtn(
                    onTap: () => _openSellerRequests(),
                    isValidate: true,
                    radius: SizeConfig.size12,
                    title: AppStrings.bookingViewRequests.tr,
                    bgColor: AppColors.primaryColor,
                  )
                : CustomBtn(
                    onTap: () => _onPlaceOrderTap(v),
                    isValidate: true,
                    radius: SizeConfig.size12,
                    title: AppStrings.inquiry.tr,
                    bgColor: AppColors.primaryColor,
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _shareVehicle(Vehicle v) async {
    final label = [v.brand, v.model, v.variant]
        .where((s) => s != null && s.trim().isNotEmpty)
        .map((s) => s!.trim())
        .join(' ');
    final name = label.isNotEmpty ? label : 'this vehicle';
    final shareLink = vehicleDeepLink(vehicleId: v.id);

    await ShareService.instance.openShareSheet(
      text: "Check out $name on BlueEra:\n$shareLink",
      subject: name,
    );
  }

  // ─── Header (cover slider + avatar + name/category/bio) ──────────
  Widget _buildHeaderSection(BuildContext context, Vehicle v) {
    // Every photo of this vehicle, cover first and de-duped against the
    // images array so the same URL never appears twice in the slider.
    final photos = _galleryImages(v);
    final ownerImage = ((v.user?['profile_image'] ?? v.business?['logo_image']) ?? '').toString();
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // Soft gradient stand-in when no cover URL is available — same idea
    // as the self-employee screen's fallback for empty profile photos.
    Widget gradientFallback() => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.directions_car_rounded,
            size: 64,
            color: AppColors.primaryColor.withValues(alpha: 0.45),
          ),
        );

    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 230 + statusBarHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Photo slider: a swipeable PageView when we have ≥1
                // image, the gradient/car-icon fallback otherwise.
                SizedBox(
                  height: 190 + statusBarHeight,
                  width: double.infinity,
                  child: photos.isEmpty
                      ? gradientFallback()
                      : PageView.builder(
                          controller: _coverPageController,
                          itemCount: photos.length,
                          onPageChanged: (i) => setState(() => _coverPageIndex = i),
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: photos[i],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => gradientFallback(),
                            errorWidget: (_, __, ___) => gradientFallback(),
                          ),
                        ),
                ),

                // Page indicators — only when there's more than one
                // photo. Positioned just above the avatar overlap so it
                // sits centred over the bottom strip of the banner
                // without clashing with the left-aligned avatar.
                if (photos.length > 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 56,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        photos.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: i == _coverPageIndex ? 18 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: i == _coverPageIndex ? 1.0 : 0.55),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: i == _coverPageIndex
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Photo counter pill — bottom-right of the banner so it
                // pairs with the centered indicators without clashing
                // with the top-bar share button. Matches the
                // marketplace convention ("3 / 8" with a small icon).
                if (photos.length > 1)
                  Positioned(
                    right: 16,
                    bottom: 52,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_outlined, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          CustomText(
                            '${_coverPageIndex + 1} / ${photos.length}',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Top bar — back + share, respects status bar height.
                Positioned(
                  top: statusBarHeight + 4,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _coverIconButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      _coverShareButton(onTap: () => _shareVehicle(v)),
                    ],
                  ),
                ),

                // Owner avatar — overlaps the cover. Uses the owner
                // profile image when hydrated; otherwise the
                // CachedAvatarWidget falls back to initials/placeholder.
                Positioned(
                  left: 16,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    // Owner avatar → that owner's profile. A vehicle can
                    // be listed by either account type, so hand both ids
                    // over and let the account type pick.
                    child: DiscoverProfileTap(
                      accountType: v.business != null
                          ? AppConstants.business
                          : AppConstants.individual,
                      userId: v.userId,
                      businessId: v.businessId,
                      child: CachedAvatarWidget(
                        imageUrl: ownerImage,
                        size: SizeConfig.size80,
                        borderColor: Colors.transparent,
                        borderRadius: SizeConfig.size40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildProfileInfoContent(v),
        ],
      ),
    );
  }

  // Name / category badge / brand-model-year line / bio.
  Widget _buildProfileInfoContent(Vehicle v) {
    final name = v.name.trim();
    final category = (v.category ?? '').trim();
    final hasName = name.isNotEmpty;
    final hasCategory = category.isNotEmpty;
    final subtitle = _brandModelYear(v);
    final bio = (v.description ?? '').trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasName)
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: CustomText(
                          name,
                          fontSize: SizeConfig.extraLarge,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (v.isVerified ?? false) ...[
                        SizedBox(width: SizeConfig.size6),
                        Icon(Icons.verified_rounded, color: AppColors.primaryColor, size: 18),
                      ],
                    ],
                  ),
                ),
              if (hasName && hasCategory) SizedBox(width: SizeConfig.size8),
              if (hasCategory)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8, vertical: SizeConfig.size3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: CustomText(
                    category,
                    fontSize: SizeConfig.small,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size6),
            CustomText(
              subtitle,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ],
          if (bio.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size8),
            ExpandableText(
              text: bio,
              trimLines: 3,
              expandMode: ExpandMode.dialog,
              style: TextStyle(
                color: AppColors.secondaryTextColor,
                fontFamily: AppConstants.OpenSans,
                fontWeight: FontWeight.w400,
                fontSize: SizeConfig.medium,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Quick stats card (Price / Year / Fuel) ───────────────────────
  Widget _buildStatsCard(Vehicle v) {
    return CustomFormCard(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.currency_rupee_rounded,
            label: AppStrings.priceLabel.tr,
            value: _priceLabel(v),
            color: AppColors.primaryColor,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.calendar_month_rounded,
            label: AppStrings.yearLabel.tr,
            value: v.year != null ? '${v.year}' : '--',
            color: Colors.green,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.local_gas_station_rounded,
            label: AppStrings.fuelLabel.tr,
            value: v.fuelType != null ? _humanFuel(v.fuelType!) : '--',
            color: AppColors.redB4,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          SizedBox(height: SizeConfig.size4),
          CustomText(value,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          CustomText(label, fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.secondaryTextColor),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(width: 1, height: 40, color: AppColors.greyE5);

  // ─── Info card scaffold (icon + title + divider + child) ──────────
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return CustomFormCard(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.primaryColor),
              ),
              SizedBox(width: SizeConfig.size8),
              CustomText(title,
                  fontSize: SizeConfig.medium, fontWeight: FontWeight.w600, color: AppColors.mainTextColor),
            ],
          ),
          Divider(color: AppColors.greyE5, height: SizeConfig.size20),
          child,
        ],
      ),
    );
  }

  // ─── Specifications grid ──────────────────────────────────────────
  Widget _specsGrid(Vehicle v) {
    final entries = <MapEntry<String, String>>[
      if ((v.subCategory ?? '').isNotEmpty) MapEntry(AppStrings.subCategoryShort.tr, v.subCategory!),
      if (v.transmission != null)
        MapEntry(AppStrings.transmissionLabel.tr, _humanTransmission(v.transmission!)),
      if (v.seatingCapacity != null) MapEntry(AppStrings.seatingLabel.tr, '${v.seatingCapacity}'),
      if ((v.mileage ?? '').isNotEmpty) MapEntry(AppStrings.mileageLabel.tr, v.mileage!),
      if ((v.color ?? '').isNotEmpty) MapEntry(AppStrings.color.tr, v.color!),
      if ((v.registrationNo ?? '').isNotEmpty) MapEntry(AppStrings.regNoLabel.tr, v.registrationNo!),
    ];
    if (entries.isEmpty) {
      return CustomText(
        AppStrings.noSpecificationsListed.tr,
        fontSize: SizeConfig.small,
        color: AppColors.secondaryTextColor,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two-column grid — each cell takes half the available width
        // minus the inter-column gap.
        const gap = 16.0;
        final cellWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: 12,
          children: entries
              .map((e) => SizedBox(
                    width: cellWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          e.key,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                        ),
                        SizedBox(height: SizeConfig.size4),
                        CustomText(
                          e.value,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  // ─── Location content (used inside its info card) ─────────────────
  Widget _locationContent(Vehicle v) {
    final loc = v.location!;
    final parts = <String>[
      if ((loc.address ?? '').isNotEmpty) loc.address!,
      if ((loc.city ?? '').isNotEmpty) loc.city!,
      if ((loc.state ?? '').isNotEmpty) loc.state!,
      if (loc.pincode != null) loc.pincode!.toString(),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomText(
            parts.isEmpty ? '--' : parts.join(', '),
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
          ),
        ),
        if (loc.lat != null && loc.lon != null) ...[
          SizedBox(width: SizeConfig.size8),
          InkWell(
            onTap: () => _openMaps(loc.lat!, loc.lon!),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10, vertical: SizeConfig.size6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_rounded, size: 14, color: AppColors.primaryColor),
                  SizedBox(width: SizeConfig.size4),
                  CustomText(
                    AppStrings.directions.tr,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Owner content (avatar + name/type + optional dial) ───────────
  Widget _ownerContent(Vehicle v) {
    final ownerName = (v.user?['name'] ?? v.business?['business_name'] ?? '').toString();
    final ownerImage = (v.user?['profile_image'] ?? v.business?['logo_image'] ?? '').toString();
    final ownerPhone = (v.user?['contact_no'] ?? '').toString();
    final ownerAccountType =
        v.business != null ? AppConstants.business : AppConstants.individual;
    return Row(
      children: [
        DiscoverProfileTap(
          accountType: ownerAccountType,
          userId: v.userId,
          businessId: v.businessId,
          child: CachedAvatarWidget(
            imageUrl: ownerImage,
            size: SizeConfig.size48,
            borderColor: Colors.transparent,
            borderRadius: SizeConfig.size24,
          ),
        ),
        SizedBox(width: SizeConfig.size12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DiscoverProfileTap(
                accountType: ownerAccountType,
                userId: v.userId,
                businessId: v.businessId,
                child: CustomText(
                  ownerName.isEmpty ? AppStrings.listedByTitle.tr : ownerName,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: SizeConfig.size3),
              CustomText(
                v.business != null ? AppStrings.business.tr : AppStrings.personal.tr,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ),
        if (ownerPhone.isNotEmpty)
          IconButton(
            tooltip: AppStrings.callTooltip.tr,
            icon: Icon(Icons.call_rounded, color: AppColors.primaryColor),
            onPressed: () => _dial(ownerPhone),
          ),
      ],
    );
  }

  // ─── Top-right cover buttons (back / share) ───────────────────────
  Widget _coverIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.appBackgroundColor, size: 18),
      ),
    );
  }

  Widget _coverShareButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: LocalAssets(
          imagePath: AppIconAssets.profile_share,
          width: 18,
          height: 18,
          imgColor: AppColors.appBackgroundColor,
        ),
      ),
    );
  }

  // ─── Error placeholder ────────────────────────────────────────────
  Widget _errorView(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: Colors.red.shade400),
              SizedBox(height: SizeConfig.size12),
              CustomText(msg, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.mainTextColor),
              SizedBox(height: SizeConfig.size16),
              ElevatedButton.icon(
                onPressed: () => _ctrl.fetchVehicleById(widget.vehicleId),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppStrings.retry.tr),
              ),
              SizedBox(height: SizeConfig.size8),
              TextButton(
                onPressed: () => Get.back<void>(),
                child: Text(AppStrings.goBack.tr),
              ),
            ],
          ),
        ),
      );

  // ─── Helpers ──────────────────────────────────────────────────────

  bool _hasSpecs(Vehicle v) =>
      (v.subCategory ?? '').isNotEmpty ||
      v.transmission != null ||
      v.seatingCapacity != null ||
      (v.mileage ?? '').isNotEmpty ||
      (v.color ?? '').isNotEmpty ||
      (v.registrationNo ?? '').isNotEmpty;

  bool _hasLocation(Vehicle v) {
    final loc = v.location;
    if (loc == null) return false;
    return (loc.address ?? '').isNotEmpty ||
        (loc.city ?? '').isNotEmpty ||
        (loc.state ?? '').isNotEmpty ||
        loc.pincode != null ||
        (loc.lat != null && loc.lon != null);
  }

  /// All photographs of the vehicle, with the cover image first so it
  /// reads top-left in the grid. De-duplicated against the cover so the
  /// banner image isn't repeated as the first gallery tile.
  List<String> _galleryImages(Vehicle v) {
    final cover = (v.coverImage ?? '').trim();
    final rest = v.images.where((u) => u.isNotEmpty && u != cover).toList();
    return [if (cover.isNotEmpty) cover, ...rest];
  }

  String _brandModelYear(Vehicle v) {
    final parts = <String>[
      if ((v.brand ?? '').isNotEmpty) v.brand!,
      if ((v.model ?? '').isNotEmpty) v.model!,
      if (v.year != null) '${v.year}',
    ];
    return parts.join(' • ');
  }

  String _priceLabel(Vehicle v) {
    if (v.price == null) return '--';
    final cur = (v.currency ?? 'INR').toUpperCase();
    final symbol = cur == 'INR' ? '₹' : cur;
    final p = v.price!;
    String formatted;
    if (p >= 1e7) {
      formatted = '${(p / 1e7).toStringAsFixed(2)} Cr';
    } else if (p >= 1e5) {
      formatted = '${(p / 1e5).toStringAsFixed(2)} L';
    } else if (p >= 1e3) {
      formatted = '${(p / 1e3).toStringAsFixed(1)}K';
    } else {
      formatted = p.toStringAsFixed(0);
    }
    return '$symbol $formatted';
  }

  String _humanFuel(VehicleFuelType f) {
    switch (f) {
      case VehicleFuelType.petrol:
        return AppStrings.fuelPetrol.tr;
      case VehicleFuelType.diesel:
        return AppStrings.fuelDiesel.tr;
      case VehicleFuelType.electric:
        return AppStrings.fuelElectric.tr;
      case VehicleFuelType.cng:
        return AppStrings.fuelCng.tr;
      case VehicleFuelType.hybrid:
        return AppStrings.fuelHybrid.tr;
      case VehicleFuelType.other:
        return AppStrings.fuelOther.tr;
    }
  }

  String _humanTransmission(VehicleTransmission t) {
    switch (t) {
      case VehicleTransmission.manual:
        return AppStrings.transmissionManual.tr;
      case VehicleTransmission.automatic:
        return AppStrings.transmissionAutomatic.tr;
      case VehicleTransmission.amt:
        return AppStrings.transmissionAmt.tr;
      case VehicleTransmission.cvt:
        return AppStrings.transmissionCvt.tr;
    }
  }

  /// Inserts [gap] between every pair of rendered children — collection-if
  /// branches that fail are dropped before they reach this list, so no
  /// gap is added for absent sections. Copied from the self-employee
  /// view to keep the spacing rule identical.
  List<Widget> _joinWithGap(List<Widget> items, {required Widget gap}) {
    if (items.isEmpty) return const [];
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) result.add(gap);
      result.add(items[i]);
    }
    return result;
  }

  // ─── CTA / launchers ──────────────────────────────────────────────

  /// True when the signed-in user is the one who listed this vehicle —
  /// they can't book their own listing (the server rejects it with 400),
  /// so we surface the seller's "received requests" inbox instead.
  bool _isOwnListing(Vehicle v) {
    final owner = (v.userId ?? '').trim();
    return owner.isNotEmpty && owner == userId.trim();
  }

  /// Buyer taps "Book Inquiry" → open the unified vehicle-enquiry sheet
  /// (`POST /vehicles/bookings`). The sheet handles the photo upload,
  /// booking POST, success snackbar and chat-open itself; the backend
  /// auto-creates the `vehicle_booking` chat card in the buyer↔seller
  /// business conversation (see lib/docs/enquiry-flows-ui-integration.md §1).
  Future<void> _onPlaceOrderTap(Vehicle v) async {
    if ((v.id ?? '').trim().isEmpty) return;
    await VehicleEnquirySheet.open(context, vehicle: v);
  }

  /// Owner taps "View Requests" → seller-side inbox (Received tab).
  void _openSellerRequests() {
    Get.to(() => const VehicleBookingsScreen(initialTab: 1));
  }

  Future<void> _dial(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMaps(double lat, double lon) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
