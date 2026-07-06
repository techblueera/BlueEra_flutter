import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/me/others/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/actions/vehicle_owner_actions.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/widgets/vehicle_banner_widget.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_input_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../business/widgets/business_share_banner.dart';
import '../../../../../business/widgets/website_overview_card.dart';
import '../../../../hospital/view/v2/widgets/empty_section_placeholder.dart';

/// The automotive-showroom Overview body (reference: `assets/dummy/s1..s5`).
///
/// One source of truth for the owner storefront, rendered both inside the
/// Overview tab of [VehicleHomeScreenV2] and (optionally) as a standalone
/// preview. Every interactive element is wired to the shared
/// [VehicleController] / [VehicleOwnerActions]:
///   1. Identity header  — name, category, rating from testimonials
///   2. Cover Photo       — swipeable carousel + Edit (upload → profile cover)
///   3. Bikes             — fleet cards + Update (add) / tap (edit)
///   4. Facilities        — chips + add / delete
///   5. Business Live Photos — 2×2 capture grid + upload / delete
///   6. Gallery           — collage + Add/Upload / delete
///   7. Testimonials      — received reviews + Reply (→ inquiries)
///   8. Contact Us        — primary contact card with launchable rows
///   9. Map               — embedded Google map for the primary branch
class VehicleShowroomOverview extends StatefulWidget {
  final VehicleController controller;

  const VehicleShowroomOverview({super.key, required this.controller});

  @override
  State<VehicleShowroomOverview> createState() => _VehicleShowroomOverviewState();
}

class _VehicleShowroomOverviewState extends State<VehicleShowroomOverview> {
  VehicleController get _ctrl => widget.controller;

  final ViewPersonalDetailsController _viewCtrl =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);

  // Sourced from the business service via gRPC. Used by the QR-code card
  // at the bottom of the overview — mirrors how `SchoolOverviewTabV2` and
  // every other v2 dashboard wires the QR widget.
  final ViewBusinessDetailsController _businessCtrl =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  // Branch / Contact Us + Map both read from the shared business-profile
  // full payload — same plumbing the Others / School / Hospital overviews
  // use. Writes happen via the shared `OtherContactUs` screen which calls
  // back into this controller's `getBusinessProfileFull()`.
  final BusinessProfileFullController _otherProfileCtrl =
      getOrPut(() => BusinessProfileFullController(), permanent: true);

  final ImagePicker _picker = ImagePicker();

  static const _blue = Color(0xFF1E88FF);

  @override
  void initState() {
    super.initState();
    // Hydrate the sections this body owns that the dashboard shell does
    // not pre-fetch. Cheap + idempotent, so it's safe whether mounted in
    // the tab or in the standalone preview.
    _ctrl.fetchMyFacilities(showProgress: false);
    _ctrl.fetchMyLivePhotos(showProgress: false);
    _ctrl.fetchMyContacts(showProgress: false);
    _ctrl.fetchReceivedTestimonials();
    // The QR card (bottom of the overview) needs `businessProfileDetails`
    // off the business service. The vehicle home shell doesn't pre-fetch
    // it (unlike the school home), so do it here on first mount.
    if (_businessCtrl.businessProfileDetails.value?.data == null) {
      _businessCtrl.viewBusinessProfile();
    }
    // Contact Us + Map both read from the business-profile-full payload.
    if (_otherProfileCtrl.businessProfile.value == null) {
      _otherProfileCtrl.getBusinessProfileFull();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Outer padding removed — each section now owns its own
    // `Padding(horizontal: SizeConfig.size8)` so the card layout matches
    // the rest of the v2 dashboards (Other / Hospital / School).
    final businessController = getOrPut(() => ViewBusinessDetailsController(), permanent: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.size12),
        // Padding(
        //   padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
        //   child: _buildIdentity(),
        // ),
        // SizedBox(height: SizeConfig.size10),
        VehicleBannerWidget(controller: _otherProfileCtrl),
        SizedBox(height: SizeConfig.size10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
          child: _buildBikes(),
        ),
        SizedBox(height: SizeConfig.size10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
          child: _buildFacilities(),
        ),
        SizedBox(height: SizeConfig.size10),
        // Padding(
        //   padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
        //   child: _buildLivePhotos(),
        // ),
        // SizedBox(height: SizeConfig.size10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
          child: _buildGallery(),
        ),
        SizedBox(height: SizeConfig.size10),
        // _buildTestimonials() left disabled (was already commented out).
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
          child: CommonCardWidget(
            padding: 10,
            cardMargin: 0,
            child: Obx(() {
              final contacts = _ctrl.myContacts;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: AppStrings.contactUs.tr,
                    actionLabel: AppStrings.otherAddEdit.tr,
                    onAction: () => VehicleOwnerActions.addContact(context, _ctrl),
                  ),
                  const SizedBox(height: 10),
                  if (contacts.isNotEmpty)
                    _ContactUs(
                      contact: _primaryContact()!,
                      onEdit: () => VehicleOwnerActions.editContact(context, _ctrl, _primaryContact()!),
                      onAddMore: () => VehicleOwnerActions.addContact(context, _ctrl),
                    )
                  else
                    EmptySectionPlaceholder(
                      imageAsset: 'assets/images/other_gallery.png',
                      ctaLabel: AppStrings.contactUs.tr,
                      ctaIcon: Icons.contact_phone_outlined,
                      onTap: () => VehicleOwnerActions.addContact(context, _ctrl),
                    ),
                ],
              );
            }),
          ),
        ),
        SizedBox(height: SizeConfig.size10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
          child: WebsiteOverviewCard(
            websiteUrl: businessController.businessProfileDetails.value?.data?.websiteUrl,
            onSave: (url) => businessController.updateBusinessProfileDetails({ApiKeys.websiteUrl: url}),
          ),
        ),

        SizedBox(height: SizeConfig.size10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
          child: _buildMap(),
        ),
        SizedBox(height: SizeConfig.size10),
        const BusinessShareBanner(),
        SizedBox(height: SizeConfig.size10),

        // ── QR Code (mirrors the school / hospital QR card) ──
        _buildQrCode(),
        SizedBox(height: SizeConfig.size12),
      ],
    );
  }

  /// QR-code card at the bottom of the overview — only renders once the
  /// business profile resolves so it can hand its `data` payload to the
  /// shared [BusinessQrCodeWidget].
  Widget _buildQrCode() {
    return Obx(() {
      final details = _businessCtrl.businessProfileDetails.value?.data;
      if (details == null) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
        child: BusinessQrCodeWidget(
          data: details,
          // Encode the business/showroom deep link
          // (`https://beapp.in/app/business/<ownerUserId>`) so scanning opens
          // this vehicle showroom, mirroring how grocery stores override the
          // QR to their own store link.
          deepLinkOverride: businessProfileDeepLink(userId: details.userId),
        ),
      );
    });
  }
  // ─── Shared chrome ─────────────────────────────────────────────────
  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFF4)),
        boxShadow: const [
          BoxShadow(color: Color(0x12001120), blurRadius: 14, offset: Offset(0, 4)),
        ],
      );

  // ───────────────────────────────────────────────────────────────────
  // 1) IDENTITY  (s1)
  // ───────────────────────────────────────────────────────────────────
  Widget _buildIdentity() {
    return Obx(() {
      final user = _viewCtrl.personalProfileDetails.value.user;
      final name = (user?.name ?? '').trim();
      final avatar = user?.profileImage ?? '';
      final joined = _formatJoined(user?.createdAt ?? '');
      final category =
          businessCategoryGlobal.trim().isNotEmpty ? businessCategoryGlobal.trim() : AppStrings.automotive.tr;

      final rated = _ctrl.receivedTestimonials.where((t) => t.rating != null).toList();
      final hasRating = rated.isNotEmpty;
      final avg = hasRating ? rated.map((t) => t.rating!).reduce((a, b) => a + b) / rated.length : 0.0;

      return Column(
        children: [
          if (joined.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE3E9F2)),
                boxShadow: const [
                  BoxShadow(color: Color(0x0F001120), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: CustomText(
                '${AppStrings.joined.tr} - $joined',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
            ),
          SizedBox(height: SizeConfig.size12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(SizeConfig.size14),
            decoration: _cardDecoration,
            child: Column(
              children: [
                Row(
                  children: [
                    _identityAvatar(avatar, name),
                    SizedBox(width: SizeConfig.size12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            name.isEmpty ? AppStrings.vehicleServiceProvider.tr : _capitalize(name),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mainTextColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: SizeConfig.size2),
                          CustomText(
                            category,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryTextColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (hasRating) ...[
                  SizedBox(height: SizeConfig.size10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF5A623)),
                      const SizedBox(width: 4),
                      CustomText(
                        avg.toStringAsFixed(1),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor,
                      ),
                      const SizedBox(width: 6),
                      CustomText(
                        '(${rated.length} ${AppStrings.reviewsCount.tr})',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _identityAvatar(String url, String name) {
    final avatar = url.isNotEmpty
        ? CachedAvatarWidget(
            imageUrl: url,
            size: 50,
            borderRadius: 25,
            showProfileOnFullScreen: false,
          )
        : Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Text(
              name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _blue),
            ),
          );
    // Verified check badge, bottom-left, mirroring the reference.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          left: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.verified_rounded, size: 16, color: _blue),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // 3) BIKES  (s2)
  // ───────────────────────────────────────────────────────────────────
  Widget _buildBikes() {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: AppStrings.bikes.tr,
            actionLabel: AppStrings.addVehicleLabel,
            onAction: () => VehicleOwnerActions.addVehicle(context, _ctrl),
          ),
          const SizedBox(height: 10),
          Obx(() {
            final state = _ctrl.myVehiclesState.value.status;
            if (state == Status.LOADING && _ctrl.myVehicles.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (_ctrl.myVehicles.isEmpty) {
              return EmptySectionPlaceholder(
                imageAsset: 'assets/images/VehicleSales.png',
                ctaLabel: AppStrings.addBikeLabel.tr,
                ctaIcon: Icons.two_wheeler_outlined,
                onTap: () => VehicleOwnerActions.addVehicle(context, _ctrl),
              );
            }
            return SizedBox(
              height: 290,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _ctrl.myVehicles.length,
                separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size12),
                itemBuilder: (_, i) {
                  final v = _ctrl.myVehicles[i];
                  return SizedBox(
                    width: 260,
                    child: _BikeCard(
                      vehicle: v,
                      onEdit: () => VehicleOwnerActions.editVehicle(context, _ctrl, v),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // 4) FACILITIES  (s3)
  // ───────────────────────────────────────────────────────────────────
  Widget _buildFacilities() {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: AppStrings.facilities.tr,
            actionLabel: AppStrings.edit,
            onAction: _onAddFacility,
          ),
          const SizedBox(height: 10),
          Obx(() {
            if (_ctrl.myFacilities.isEmpty) {
              return EmptySectionPlaceholder(
                imageAsset: 'assets/images/VehicleSupport.png',
                ctaLabel: AppStrings.addFacilityTitle.tr,
                ctaIcon: Icons.build_outlined,
                onTap: _onAddFacility,
              );
            }
            return Wrap(
              spacing: SizeConfig.size10,
              runSpacing: SizeConfig.size10,
              children: _ctrl.myFacilities
                  .map((f) => _FacilityChip(
                        facility: f,
                        onDelete: () => _confirmDeleteFacility(f),
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _onAddFacility() async {
    final name = await showCommonInputDialog(
      context,
      title: AppStrings.addFacilityTitle.tr,
      hintText: AppStrings.facilityNameHint.tr,
      confirmLabel: AppStrings.add.tr,
      validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.fieldRequired.tr : null,
    );
    if (name == null || name.isEmpty) return;
    await _ctrl.addFacility(VehicleFacility(name: name));
  }

  Future<void> _confirmDeleteFacility(VehicleFacility f) async {
    if (f.id == null) return;
    final ok = await _confirm(
      title: AppStrings.remove.tr,
      message: AppStrings.removeNameCannotUndo.trParams({'N': f.name}),
    );
    if (ok) await _ctrl.deleteFacility(f.id!);
  }

  // ───────────────────────────────────────────────────────────────────
  // 5) BUSINESS LIVE PHOTOS  (s3)
  // ───────────────────────────────────────────────────────────────────
  Widget _buildLivePhotos() {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: AppStrings.businessLivePhotos.tr,
            actionLabel: AppStrings.add,
            onAction: () => _onAddLivePhoto(),
          ),
          const SizedBox(height: 10),
          Obx(() {
            final photos = _ctrl.myLivePhotos;
            return photos.isEmpty ? _buildLivePhotosEmpty() : _buildLivePhotosCollage(photos);
          }),
        ],
      ),
    );
  }

  /// Empty state — the four captioned capture slots laid out in the same
  /// fixed-height 2×2 frame the populated collage uses.
  Widget _buildLivePhotosEmpty() {
    const labels = [
      AppStrings.roadSideImage,
      AppStrings.receptionCounter,
      AppStrings.interior1,
      AppStrings.interior2,
    ];
    Widget ph(int i) => _LivePhotoPlaceholder(
          label: labels[i].tr,
          onTap: () => _onAddLivePhoto(caption: labels[i].tr),
        );
    const double gap = 4;
    return SizedBox(
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: Row(children: [
              Expanded(child: ph(0)),
              const SizedBox(width: gap),
              Expanded(child: ph(1)),
            ]),
          ),
          const SizedBox(height: gap),
          Expanded(
            child: Row(children: [
              Expanded(child: ph(2)),
              const SizedBox(width: gap),
              Expanded(child: ph(3)),
            ]),
          ),
        ],
      ),
    );
  }

  /// Photo-count-adaptive collage, mirroring the hospital gallery layout:
  /// 1 full-width · 2 side-by-side · 3 large+stacked · 4+ 2×2 with a +N
  /// overlay on the last cell. Each cell reuses [_LivePhotoTile] so the
  /// caption + delete affordance stay intact.
  Widget _buildLivePhotosCollage(List<VehicleLivePhoto> photos) {
    final display = photos.length > 4 ? photos.sublist(0, 4) : photos;
    final extra = photos.length > 4 ? photos.length - 4 : 0;
    const double height = 220;
    const double gap = 4;

    Widget cell(int index, {bool showOverlay = false}) {
      final tile = _LivePhotoTile(
        photo: display[index],
        onDelete: () => _confirmDeleteLivePhoto(display[index]),
      );
      if (!(showOverlay && extra > 0)) return tile;
      return Stack(
        fit: StackFit.expand,
        children: [
          tile,
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              alignment: Alignment.center,
              child: Text(
                '+$extra',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (display.length == 1) {
      return SizedBox(height: height, width: double.infinity, child: cell(0));
    }
    if (display.length == 2) {
      return SizedBox(
        height: height,
        child: Row(children: [
          Expanded(child: cell(0)),
          const SizedBox(width: gap),
          Expanded(child: cell(1)),
        ]),
      );
    }
    if (display.length == 3) {
      return SizedBox(
        height: height,
        child: Row(children: [
          Expanded(child: cell(0)),
          const SizedBox(width: gap),
          Expanded(
            child: Column(children: [
              Expanded(child: cell(1)),
              const SizedBox(height: gap),
              Expanded(child: cell(2)),
            ]),
          ),
        ]),
      );
    }
    return SizedBox(
      height: height,
      child: Column(children: [
        Expanded(
          child: Row(children: [
            Expanded(child: cell(0)),
            const SizedBox(width: gap),
            Expanded(child: cell(1)),
          ]),
        ),
        const SizedBox(height: gap),
        Expanded(
          child: Row(children: [
            Expanded(child: cell(2)),
            const SizedBox(width: gap),
            Expanded(child: cell(3, showOverlay: extra > 0)),
          ]),
        ),
      ]),
    );
  }

  Future<void> _onAddLivePhoto({String? caption}) async {
    final file = await _pickImage();
    if (file == null) return;
    await _ctrl.addLivePhotoFromFile(file, caption: caption);
  }

  Future<void> _confirmDeleteLivePhoto(VehicleLivePhoto p) async {
    if (p.id == null) return;
    final ok = await _confirm(
      title: AppStrings.removePhotoTitle.tr,
      message: AppStrings.removePhotoConfirm.tr,
    );
    if (ok) await _ctrl.deleteLivePhoto(p.id!);
  }

  // ───────────────────────────────────────────────────────────────────
  // 6) GALLERY  (s4)
  // ───────────────────────────────────────────────────────────────────
  Widget _buildGallery() {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: AppStrings.gallery.tr,
            actionLabel: AppStrings.addPhoto,
            onAction: _onAddGalleryPhoto,
          ),
          const SizedBox(height: 10),
          Obx(() {
            if (_ctrl.isUploadingMedia.value && _ctrl.myGallery.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (_ctrl.myGallery.isEmpty) {
              return EmptySectionPlaceholder(
                imageAsset: 'assets/images/other_gallery.png',
                ctaLabel: AppStrings.gallery.tr,
                ctaIcon: Icons.photo_album_outlined,
                onTap: () {},
              );
            }
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: SizeConfig.size8,
              crossAxisSpacing: SizeConfig.size8,
              children: _ctrl.myGallery
                  .map((g) => _GalleryTile(
                        item: g,
                        onDelete: () => _confirmDeleteGalleryItem(g),
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _galleryEmpty() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6E8BB5), Color(0xFF3E5B86)],
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    AppStrings.noGalleryPhotosLine.tr,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: SizeConfig.size10),
                  ElevatedButton(
                    onPressed: _onAddGalleryPhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      AppStrings.uploadPhoto.tr,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAddGalleryPhoto() => VehicleOwnerActions.addGalleryPhoto(_ctrl);

  Future<void> _confirmDeleteGalleryItem(VehicleGalleryItem g) =>
      VehicleOwnerActions.confirmDeleteGalleryItem(context, _ctrl, g);

  // ───────────────────────────────────────────────────────────────────
  // 7) TESTIMONIALS  (s4)
  // ───────────────────────────────────────────────────────────────────
  Widget _buildTestimonials() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F2FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CustomText(
            AppStrings.testimonials.tr,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size14),
          Obx(() {
            final list = _ctrl.receivedTestimonials.where((t) => t.isVisible ?? true).toList();
            if (list.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22),
                alignment: Alignment.center,
                child: CustomText(
                  AppStrings.noTestimonialsYet.tr,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
              );
            }
            return Column(
              children: list
                  .map((t) => _TestimonialCard(
                        testimonial: t,
                        onReply: _openInquiries,
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  void _openInquiries() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(AppStrings.inquiryTab.tr)),
          body: const BusinessChatsList(),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // 9) MAP  (s5)
  // ───────────────────────────────────────────────────────────────────
  Widget _buildMap() {
    return Obx(() {
      // Map is driven by the same vehicle-service contact list the
      // Contact Us section renders — the primary contact's `lat`/`lon`
      // becomes the pin.
      final contact = _primaryContact();
      if (contact == null || contact.lat == null || contact.lon == null) {
        return const SizedBox.shrink();
      }
      final lat = contact.lat!;
      final lon = contact.lon!;
      final businessName = contact.locationName.isNotEmpty
          ? contact.locationName
          : (_viewCtrl.personalProfileDetails.value.user?.name ?? '');

      return CommonCardWidget(
        padding: 10,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: AppStrings.location.tr,
              actionLabel: AppStrings.viewAll,
              onAction: () => _launchMapAt(lat, lon),
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  // BusinessLocationWidget renders its own 180px map plus
                  // chrome, so it must self-size — constraining it to a
                  // fixed 180px box clips that extra height and triggers a
                  // RenderFlex overflow.
                  child: BusinessLocationWidget(
                    locationText: contact.locationName,
                    latitude: lat,
                    longitude: lon,
                    businessName: businessName,
                    isTitleShow: false,
                    padding: 0,
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: GestureDetector(
                    onTap: () => _launchMapAt(lat, lon),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: _blue.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: const Icon(Icons.navigation_rounded, size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Future<void> _launchMapAt(double lat, double lon) =>
      _launch('https://www.google.com/maps/search/?api=1&query=$lat,$lon');

  /// Picks the contact card to show in the overview. Prefers the entry
  /// marked `is_primary` on the wire; falls back to the first row so a
  /// brand-new account that hasn't toggled the flag still renders.
  VehicleContact? _primaryContact() {
    if (_ctrl.myContacts.isEmpty) return null;
    return _ctrl.myContacts.firstWhere(
      (c) => c.isPrimary ?? false,
      orElse: () => _ctrl.myContacts.first,
    );
  }

  Future<File?> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      return picked == null ? null : File(picked.path);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _confirm({required String title, required String message}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.cancel.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.remove.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  String _capitalize(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);

  String _formatJoined(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      return DateFormat('d/MM/yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return '';
    }
  }

  Future<void> _launch(String url) async {
    var finalUrl = url.trim();
    if (!finalUrl.startsWith('http')) finalUrl = 'https://$finalUrl';
    try {
      await launchUrl(Uri.parse(finalUrl), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────────────
// Bike card  (s2)
// ─────────────────────────────────────────────────────────────────────
class _BikeCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onEdit;
  const _BikeCard({required this.vehicle, required this.onEdit});

  static const _blue = Color(0xFF1E88FF);

  @override
  Widget build(BuildContext context) {
    final image = (vehicle.coverImage?.isNotEmpty ?? false)
        ? vehicle.coverImage!
        : (vehicle.images.isNotEmpty ? vehicle.images.first : null);
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEFF4)),
          boxShadow: const [
            BoxShadow(color: Color(0x12001120), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: _NetworkImage(url: image),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_outlined, size: 15, color: _blue),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      vehicle.name,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((vehicle.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      CustomText(
                        vehicle.description!.trim(),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (vehicle.fuelType != null)
                          _spec(Icons.local_gas_station_outlined, _humanFuel(vehicle.fuelType!)),
                        if (vehicle.engineCapacityCc != null) ...[
                          const SizedBox(width: 6),
                          _spec(
                              Icons.settings_outlined, '${vehicle.engineCapacityCc} ${AppStrings.ccUnit.tr}'),
                        ],
                      ],
                    ),
                    const Spacer(),
                    if (vehicle.exShowroomPrice != null ||
                        vehicle.onRoadPrice != null ||
                        vehicle.price != null)
                      Row(
                        children: [
                          Expanded(
                            child: _priceCol(
                              AppStrings.exShowroomPrice.tr,
                              vehicle.exShowroomPrice ?? vehicle.price,
                            ),
                          ),
                          Expanded(
                            child: _priceCol(
                              AppStrings.onRoadPrice.tr,
                              vehicle.onRoadPrice,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spec(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: _blue),
            const SizedBox(width: 4),
            Flexible(
              child: CustomText(
                label,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceCol(String label, double? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryTextColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        CustomText(
          value != null ? _price(value) : '—',
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _price(double v) {
    final cur = (vehicle.currency ?? 'INR').toUpperCase();
    final symbol = cur == 'INR' ? '₹' : '$cur ';
    String c;
    if (v >= 1e7) {
      c = '${_trim(v / 1e7)} ${AppStrings.compactUnitCr.tr}';
    } else if (v >= 1e5) {
      c = '${_trim(v / 1e5)} ${AppStrings.compactUnitLac.tr}';
    } else if (v >= 1e3) {
      c = '${_trim(v / 1e3)}${AppStrings.compactUnitThousand.tr}';
    } else {
      c = _trim(v);
    }
    return '$symbol$c';
  }

  String _trim(double v) {
    final s = v.toStringAsFixed(2);
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
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
}

// ─────────────────────────────────────────────────────────────────────
// Facility chip  (s3)
// ─────────────────────────────────────────────────────────────────────
class _FacilityChip extends StatelessWidget {
  final VehicleFacility facility;
  final VoidCallback onDelete;
  const _FacilityChip({required this.facility, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3E9F2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF1E88FF)),
          const SizedBox(width: 6),
          CustomText(
            facility.name,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDelete,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close_rounded, size: 14, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Live photo placeholder + tile  (s3)
// ─────────────────────────────────────────────────────────────────────
class _LivePhotoPlaceholder extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LivePhotoPlaceholder({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: const BoxDecoration(color: Color(0xFFB9C4D2)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_camera_rounded, size: 20, color: Colors.white),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 10,
                child: CustomText(
                  label,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePhotoTile extends StatelessWidget {
  final VehicleLivePhoto photo;
  final VoidCallback onDelete;
  const _LivePhotoTile({required this.photo, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _NetworkImage(url: photo.imageUrl),
          Container(
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
          if ((photo.caption ?? '').trim().isNotEmpty)
            Positioned(
              left: 8,
              right: 8,
              bottom: 10,
              child: CustomText(
                photo.caption!.trim(),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          Positioned(
            top: 6,
            right: 6,
            child: InkWell(
              onTap: onDelete,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Gallery tile  (s4)
// ─────────────────────────────────────────────────────────────────────
class _GalleryTile extends StatelessWidget {
  final VehicleGalleryItem item;
  final VoidCallback onDelete;
  const _GalleryTile({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final url = (item.thumbnailUrl?.isNotEmpty ?? false) ? item.thumbnailUrl! : item.mediaUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _NetworkImage(url: url),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onDelete,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Testimonial card  (s4)
// ─────────────────────────────────────────────────────────────────────
class _TestimonialCard extends StatelessWidget {
  final VehicleTestimonial testimonial;
  final VoidCallback onReply;
  const _TestimonialCard({required this.testimonial, required this.onReply});

  @override
  Widget build(BuildContext context) {
    final author = (testimonial.from?['name'] as String?)?.trim();
    final role = (testimonial.from?['designation'] as String?)?.trim();
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: SizeConfig.size12),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x0F001120), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded, size: 28, color: Color(0xFF1E88FF)),
          SizedBox(height: SizeConfig.size6),
          Text(
            testimonial.description.trim().isNotEmpty
                ? testimonial.description.trim()
                : testimonial.title.trim(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (author != null && author.isNotEmpty)
                      CustomText(
                        '–$author',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor,
                      ),
                    if (role != null && role.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      CustomText(
                        role,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: onReply,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF1F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: CustomText(
                    AppStrings.reply.tr,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Shared network image
// ─────────────────────────────────────────────────────────────────────
class _NetworkImage extends StatelessWidget {
  final String? url;
  const _NetworkImage({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _placeholder();
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: const Color(0xFFEAF2FB)),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFEAF2FB),
        alignment: Alignment.center,
        child: Icon(Icons.directions_car_rounded,
            size: 32, color: AppColors.primaryColor.withValues(alpha: 0.5)),
      );
}

/// Standard section header — title + tappable "action" label on the right.
/// Mirrors `_SectionHeader` in `other_overview_tab_v2.dart` so every "me"
/// dashboard tab uses the same visual chrome.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ServiceHomeTitleWidget(title: title),
        InkWell(
          onTap: onAction,
          child: CustomText(
            actionLabel.tr,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Contact Us  (vehicle-service)
// ─────────────────────────────────────────────────────────────────────
// Same visual style as the Others/School/Hospital overviews, but the
// data + write path live in vehicle-service (not other-service): the
// payload is a [VehicleContact] from `VehicleController.myContacts`,
// edits route through `VehicleOwnerActions.editContact`, and the
// "Add More" CTA opens `VehicleOwnerActions.addContact`.
class _ContactUs extends StatelessWidget {
  final VehicleContact contact;
  final VoidCallback onEdit;
  final VoidCallback onAddMore;

  const _ContactUs({
    required this.contact,
    required this.onEdit,
    required this.onAddMore,
  });

  @override
  Widget build(BuildContext context) {
    final phone = contact.phoneNumber?.number ?? '';
    final website = contact.website;
    final email = contact.email;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.business_outlined, size: 16, color: AppColors.secondaryTextColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: CustomText(
                      contact.locationName,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.edit_outlined, size: 14, color: AppColors.primaryColor),
                          SizedBox(width: 4),
                          CustomText(AppStrings.edit, fontSize: 12, color: AppColors.primaryColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (website != null && website.isNotEmpty)
                _row(AppIconAssets.website_click, website, AppColors.primaryColor, isLink: true),
              if (phone.isNotEmpty) _row(AppIconAssets.phone_outline, phone, AppColors.mainTextColor),
              if (email != null && email.isNotEmpty)
                _row(AppIconAssets.email, email, AppColors.mainTextColor),
            ],
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onAddMore,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add, size: 16, color: AppColors.primaryColor),
                SizedBox(width: 6),
                CustomText(AppStrings.addMore,
                    fontSize: 13, color: AppColors.primaryColor, fontWeight: FontWeight.w600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String icon, String text, Color textColor, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: isLink == false ? AppColors.mainTextColor : null,
            height: 20,
            width: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: isLink ? () => launchUrl(Uri.parse(text)) : null,
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  decoration: isLink ? TextDecoration.underline : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
