import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/actions/vehicle_owner_actions.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_input_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
  State<VehicleShowroomOverview> createState() =>
      _VehicleShowroomOverviewState();
}

class _VehicleShowroomOverviewState extends State<VehicleShowroomOverview> {
  VehicleController get _ctrl => widget.controller;

  final ViewPersonalDetailsController _viewCtrl =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);
  final PersonalCreateProfileController _personalCtrl =
      getOrPut(() => PersonalCreateProfileController());

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
    _ctrl.fetchReceivedTestimonials();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: SizeConfig.size30,right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size12),
          _buildIdentity(),
          SizedBox(height: SizeConfig.size16),
          _buildCoverPhoto(),
          SizedBox(height: SizeConfig.size20),
          _buildBikes(),
          SizedBox(height: SizeConfig.size20),
          _buildFacilities(),
          SizedBox(height: SizeConfig.size20),
          _buildLivePhotos(),
          SizedBox(height: SizeConfig.size20),
          _buildGallery(),
          SizedBox(height: SizeConfig.size20),
          // _buildTestimonials(),
          // SizedBox(height: SizeConfig.size20),
          _buildContactUs(),
          SizedBox(height: SizeConfig.size12),
          _buildMap(),
          SizedBox(height: SizeConfig.size12),
        ],
      ),
    );
  }

  // ─── Shared chrome ─────────────────────────────────────────────────
  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFF4)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12001120), blurRadius: 14, offset: Offset(0, 4)),
        ],
      );

  Widget _sectionTitle(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          title,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _linkAction(String label, VoidCallback onTap, {IconData? icon}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: _blue),
              const SizedBox(width: 4),
            ],
            CustomText(label,
                fontSize: 14, fontWeight: FontWeight.w700, color: _blue),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // 1) IDENTITY  (s1)
  // ───────────────────────────────────────────────────────────────────
  Widget _buildIdentity() {
    return Obx(() {
      final user = _viewCtrl.personalProfileDetails.value.user;
      final name = (user?.name ?? '').trim();
      final avatar = user?.profileImage ?? '';
      final joined = _formatJoined(user?.createdAt ?? '');
      final category = businessCategoryGlobal.trim().isNotEmpty
          ? businessCategoryGlobal.trim()
          : AppStrings.automotive.tr;

      final rated =
          _ctrl.receivedTestimonials.where((t) => t.rating != null).toList();
      final hasRating = rated.isNotEmpty;
      final avg = hasRating
          ? rated.map((t) => t.rating!).reduce((a, b) => a + b) / rated.length
          : 0.0;

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
                  BoxShadow(
                      color: Color(0x0F001120),
                      blurRadius: 8,
                      offset: Offset(0, 2)),
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
                            name.isEmpty
                                ? AppStrings.vehicleServiceProvider.tr
                                : _capitalize(name),
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
                      const Icon(Icons.star_rounded,
                          size: 18, color: Color(0xFFF5A623)),
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
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: _blue),
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
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.verified_rounded, size: 16, color: _blue),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // 2) COVER PHOTO  (s1)
  // ───────────────────────────────────────────────────────────────────
  Widget _buildCoverPhoto() {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: _cardDecoration,
      child: Obx(() {
        final covers = _coverImages();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (covers.isEmpty)
              GestureDetector(
                onTap: _onEditCover,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 190,
                    width: double.infinity,
                    color: const Color(0xFFE3ECF7),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo_rounded,
                            size: 30, color: _blue.withValues(alpha: 0.7)),
                        SizedBox(height: SizeConfig.size6),
                        CustomText(AppStrings.uploadPhoto.tr,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _blue),
                      ],
                    ),
                  ),
                ),
              )
            else
              _CoverCarousel(images: covers),
            SizedBox(height: SizeConfig.size10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  AppStrings.coverPhoto.tr,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                _linkAction(AppStrings.edit.tr, _onEditCover,
                    icon: Icons.edit_outlined),
              ],
            ),
          ],
        );
      }),
    );
  }

  List<String> _coverImages() {
    final out = <String>[];
    final cover =
        (_viewCtrl.personalProfileDetails.value.user?.coverPicture ?? '').trim();
    if (cover.isNotEmpty) out.add(cover);
    for (final v in _ctrl.myVehicles) {
      final img = (v.coverImage?.isNotEmpty ?? false)
          ? v.coverImage!
          : (v.images.isNotEmpty ? v.images.first : null);
      if (img != null && img.isNotEmpty && !out.contains(img)) out.add(img);
    }
    return out;
  }

  Future<void> _onEditCover() async {
    final file = await _pickImage();
    if (file == null) return;
    final url = await _ctrl.uploadFile(file);
    if (url == null) return;
    await _personalCtrl.updateUserProfileDetails(
      params: {ApiKeys.coverimg: url},
      isFromProfileOnly: true,
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // 3) BIKES  (s2)
  // ───────────────────────────────────────────────────────────────────
  Widget _buildBikes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          AppStrings.bikes.tr,
          trailing: _linkAction(
            AppStrings.addVehicleLabel.tr,
            () => VehicleOwnerActions.addVehicle(context, _ctrl),
          ),
        ),
        SizedBox(height: SizeConfig.size10),
        Obx(() {
          final state = _ctrl.myVehiclesState.value.status;
          if (state == Status.LOADING && _ctrl.myVehicles.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (_ctrl.myVehicles.isEmpty) {
            return _emptyHint(
              AppStrings.noVehiclesInFleet.tr,
              cta: AppStrings.addBikeLabel.tr,
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
                    onEdit: () =>
                        VehicleOwnerActions.editVehicle(context, _ctrl, v),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // 4) FACILITIES  (s3)
  // ───────────────────────────────────────────────────────────────────
  Widget _buildFacilities() {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            AppStrings.facilities.tr,
            trailing: InkWell(
              onTap: _onAddFacility,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.edit_outlined, size: 18, color: _blue),
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          Obx(() {
            if (_ctrl.myFacilities.isEmpty) {
              return _emptyHint(
                AppStrings.noFacilitiesYet.tr,
                cta: AppStrings.add.tr,
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
      validator: (v) => (v == null || v.trim().isEmpty)
          ? AppStrings.fieldRequired.tr
          : null,
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
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            AppStrings.businessLivePhotos.tr,
            trailing: InkWell(
              onTap: () => _onAddLivePhoto(),
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.add_a_photo_rounded, size: 20, color: _blue),
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size10),
          Obx(() {
            final photos = _ctrl.myLivePhotos;
            return photos.isEmpty
                ? _buildLivePhotosEmpty()
                : _buildLivePhotosCollage(photos);
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
    return Container(
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            AppStrings.gallery.tr,
            trailing: _linkAction(AppStrings.addPhoto.tr, _onAddGalleryPhoto),
          ),
          SizedBox(height: SizeConfig.size12),
          Obx(() {
            if (_ctrl.isUploadingMedia.value && _ctrl.myGallery.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (_ctrl.myGallery.isEmpty) {
              return _galleryEmpty();
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      AppStrings.uploadPhoto.tr,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
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

  Future<void> _onAddGalleryPhoto() =>
      VehicleOwnerActions.addGalleryPhoto(_ctrl);

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
            final list = _ctrl.receivedTestimonials
                .where((t) => t.isVisible ?? true)
                .toList();
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
  // 8) CONTACT US  (s5)
  // ───────────────────────────────────────────────────────────────────
  Widget _buildContactUs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          AppStrings.contactUs.tr,
          trailing: InkWell(
            onTap: () => VehicleOwnerActions.addContact(context, _ctrl),
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.add_location_alt_outlined,
                  size: 20, color: _blue),
            ),
          ),
        ),
        SizedBox(height: SizeConfig.size12),
        Obx(() {
          final contact = _primaryContact();
          if (contact == null) {
            return _emptyHint(
              AppStrings.addContactInfoHint.tr,
              cta: AppStrings.add.tr,
              onTap: () => VehicleOwnerActions.addContact(context, _ctrl),
            );
          }
          return _ContactCard(
            contact: contact,
            businessName:
                _viewCtrl.personalProfileDetails.value.user?.name ?? '',
            avatarUrl:
                _viewCtrl.personalProfileDetails.value.user?.profileImage ?? '',
            onEdit: () => VehicleOwnerActions.editContact(context, _ctrl, contact),
          );
        }),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // 9) MAP  (s5)
  // ───────────────────────────────────────────────────────────────────
  Widget _buildMap() {
    return Obx(() {
      final c = _primaryContact();
      if (c == null || c.lat == null || c.lon == null) {
        return const SizedBox.shrink();
      }
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            // BusinessLocationWidget renders its own 180px map plus chrome,
            // so it must self-size — constraining it to a fixed 180px box
            // clips that extra height and triggers a RenderFlex overflow.
            child: BusinessLocationWidget(
              latitude: c.lat!,
              longitude: c.lon!,
              businessName: c.locationName.isNotEmpty
                  ? c.locationName
                  : (_viewCtrl.personalProfileDetails.value.user?.name ?? ''),
              isTitleShow: false,
              padding: 0,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: GestureDetector(
              onTap: () => _openExternalMap(c),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: _blue.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.navigation_rounded,
                    size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    });
  }

  Future<void> _openExternalMap(VehicleContact c) async {
    final url = (c.mapLink ?? '').trim().isNotEmpty
        ? c.mapLink!.trim()
        : 'https://www.google.com/maps/search/?api=1&query=${c.lat},${c.lon}';
    await _launch(url);
  }

  // ─── Shared helpers ────────────────────────────────────────────────
  VehicleContact? _primaryContact() {
    if (_ctrl.myContacts.isEmpty) return null;
    return _ctrl.myContacts.firstWhere(
      (c) => c.isPrimary ?? false,
      orElse: () => _ctrl.myContacts.first,
    );
  }

  Widget _emptyHint(String text, {VoidCallback? onTap, String? cta}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECF2)),
      ),
      child: Column(
        children: [
          CustomText(
            text,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
          if (cta != null && onTap != null) ...[
            SizedBox(height: SizeConfig.size10),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: Text(cta,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<File?> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 85);
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
            child: Text(AppStrings.remove.tr,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  String _capitalize(String t) =>
      t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);

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
// Cover carousel
// ─────────────────────────────────────────────────────────────────────
class _CoverCarousel extends StatefulWidget {
  final List<String> images;
  const _CoverCarousel({required this.images});

  @override
  State<_CoverCarousel> createState() => _CoverCarouselState();
}

class _CoverCarouselState extends State<_CoverCarousel> {
  final PageController _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 190,
            width: double.infinity,
            child: PageView.builder(
              controller: _page,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: widget.images[i],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: const Color(0xFFEAF2FB)),
                errorWidget: (_, __, ___) =>
                    Container(color: const Color(0xFFDCE7F2)),
              ),
            ),
          ),
        ),
        if (widget.images.length > 1) ...[
          SizedBox(height: SizeConfig.size8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF1E88FF)
                      : const Color(0xFFC4D3E6),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
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
            BoxShadow(
                color: Color(0x12001120), blurRadius: 12, offset: Offset(0, 4)),
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
                    child: const Icon(Icons.edit_outlined,
                        size: 15, color: _blue),
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
                          _spec(Icons.local_gas_station_outlined,
                              _humanFuel(vehicle.fuelType!)),
                        if (vehicle.engineCapacityCc != null) ...[
                          const SizedBox(width: 6),
                          _spec(Icons.settings_outlined,
                              '${vehicle.engineCapacityCc} ${AppStrings.ccUnit.tr}'),
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
          const Icon(Icons.check_circle_outline_rounded,
              size: 16, color: Color(0xFF1E88FF)),
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
              child:
                  Icon(Icons.close_rounded, size: 14, color: Colors.redAccent),
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
                  child: const Icon(Icons.photo_camera_rounded,
                      size: 20, color: Colors.white),
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
                child: const Icon(Icons.close_rounded,
                    size: 14, color: Colors.white),
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
    final url = (item.thumbnailUrl?.isNotEmpty ?? false)
        ? item.thumbnailUrl!
        : item.mediaUrl;
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
                child: const Icon(Icons.close_rounded,
                    size: 13, color: Colors.white),
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
          BoxShadow(
              color: Color(0x0F001120), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded,
              size: 28, color: Color(0xFF1E88FF)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
// Contact card  (s5)
// ─────────────────────────────────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final VehicleContact contact;
  final String businessName;
  final String avatarUrl;
  final VoidCallback onEdit;

  const _ContactCard({
    required this.contact,
    required this.businessName,
    required this.avatarUrl,
    required this.onEdit,
  });

  static const _blue = Color(0xFF1E88FF);

  @override
  Widget build(BuildContext context) {
    final phone = contact.phoneNumber?.number;
    final email = contact.email;
    final website = contact.website;
    final address = _addressLine();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFF4)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12001120), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              avatarUrl.isNotEmpty
                  ? CachedAvatarWidget(
                      imageUrl: avatarUrl,
                      size: 52,
                      borderRadius: 26,
                      showProfileOnFullScreen: false,
                    )
                  : Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.directions_car_rounded,
                          color: _blue),
                    ),
              const Spacer(),
              InkWell(
                onTap: onEdit,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined, size: 18, color: _blue),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          CustomText(
            contact.locationName.isNotEmpty
                ? contact.locationName
                : (businessName.isNotEmpty
                    ? businessName
                    : AppStrings.branchLabel.tr),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size12),
          if (website != null && website.isNotEmpty)
            _row(Icons.language_outlined, website,
                isLink: true, onTap: () => _launch(website)),
          if ((contact.openingHours ?? '').trim().isNotEmpty)
            _row(Icons.access_time_outlined, contact.openingHours!.trim()),
          if (email != null && email.isNotEmpty)
            _row(Icons.email_outlined, email,
                isLink: true, onTap: () => _launchEmail(email)),
          if (phone != null && phone.isNotEmpty)
            _row(Icons.phone_outlined, _formattedPhone(contact.phoneNumber),
                isLink: true, onTap: () => _launchPhone(phone)),
          if (address != null)
            _row(Icons.place_outlined, address),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text,
      {bool isLink = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 18,
                color:
                    isLink ? _blue : AppColors.secondaryTextColor),
            const SizedBox(width: 12),
            Expanded(
              child: CustomText(
                text,
                color: isLink ? _blue : AppColors.mainTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                decoration:
                    isLink ? TextDecoration.underline : TextDecoration.none,
                decorationColor: isLink ? _blue : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _addressLine() {
    final parts = <String>[
      if ((contact.address ?? '').trim().isNotEmpty) contact.address!.trim(),
      if ((contact.city ?? '').trim().isNotEmpty) contact.city!.trim(),
      if ((contact.state ?? '').trim().isNotEmpty) contact.state!.trim(),
      if (contact.pincode != null) contact.pincode!.toString(),
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  String _formattedPhone(VehiclePhoneNumber? p) {
    if (p == null) return '';
    final pre = p.pre;
    final num = p.number ?? '';
    if (pre == null || num.isEmpty) return num;
    return '+$pre $num';
  }

  Future<void> _launch(String url) async {
    var finalUrl = url.trim();
    if (!finalUrl.startsWith('http')) finalUrl = 'https://$finalUrl';
    try {
      await launchUrl(Uri.parse(finalUrl), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _launchEmail(String email) async {
    try {
      await launchUrl(Uri(scheme: 'mailto', path: email.trim()));
    } catch (_) {}
  }

  Future<void> _launchPhone(String phone) async {
    try {
      await launchUrl(
          Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s+'), '')));
    } catch (_) {}
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
