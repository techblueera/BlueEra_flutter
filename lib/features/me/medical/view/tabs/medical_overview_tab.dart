import 'dart:ui';
import 'package:BlueEra/features/me/medical/binding/medical_gallery_binding.dart';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_joined_profile_card.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/profile_share_banner.dart';
import 'package:BlueEra/features/business/widgets/website_overview_card.dart';
import 'package:BlueEra/features/me/medical/controller/medical_gallery_controller.dart';
import 'package:BlueEra/features/me/medical/model/medical_home_response_model.dart';
import 'package:BlueEra/features/me/medical/view/medical_gallery/medical_gallery_list_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// **Overview** tab of the medical merchant home: the profile the customer
/// sees — cover banner, live photos, gallery, testimonials, contact/map,
/// website, share banner and QR.
///
/// Reads the profile the host already fetched (passed in as [data]) plus the
/// permanent [ViewBusinessDetailsController], so it fires no medical API of
/// its own.
///
/// Content-only: the host wraps it in the shared scroll view. Stateful only to
/// hold the two controllers this tab talks to.
class MedicalOverviewTab extends StatefulWidget {
  /// Medical profile response owned by the host screen; null until its fetch
  /// lands.
  final MedicalHomeResponseModel? data;

  const MedicalOverviewTab({super.key, required this.data});

  @override
  State<MedicalOverviewTab> createState() => _MedicalOverviewTabState();
}

class _MedicalOverviewTabState extends State<MedicalOverviewTab> {
  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);
  // Same instance the host hydrates from the profile response.
  final _galleryController = getOrPut(() => MedicalGalleryController());

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Joined profile card (logo + name + cover banner + edit affordances),
        // same widget grocery's overview uses. It renders the cover, so the
        // old standalone medical banner section is gone.
        BusinessJoinedProfileCard(
          businessController: _businessController,
          showShadow: false,
        ),
        SizedBox(height: SizeConfig.size12),
        _buildLivePhotosSection(),
        SizedBox(height: SizeConfig.size12),
        _buildGallerySection(),
        SizedBox(height: SizeConfig.size12),
        _buildTestimonialsSection(),
        _buildContactSection(widget.data?.businessProfile),
        SizedBox(height: SizeConfig.size2),
        Obx(() => Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
              child: WebsiteOverviewCard(
                websiteUrl: _businessController
                    .businessProfileDetails.value?.data?.websiteUrl,
                onSave: (url) => _businessController
                    .updateBusinessProfileDetails({ApiKeys.websiteUrl: url}),
              ),
            )),
        SizedBox(height: SizeConfig.size2),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: const ProfileShareBanner(),
        ),
        // ── QR Code (mirrors the hospital overview QR card) ──
        SizedBox(height: SizeConfig.size2),
        Obx(() {
          final details =
              _businessController.businessProfileDetails.value?.data;
          if (details == null) return const SizedBox.shrink();
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
            child: BusinessQrCodeWidget(
              data: details,
              deepLinkOverride:
                  medicalBusinessDeepLink(medicalBusinessId: details.userId),
            ),
          );
        }),
        SizedBox(height: SizeConfig.size12),
      ],
    );
  }

  Widget _buildLivePhotosSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _SectionCard(
          title: AppStrings.businessLivePhotos.tr,
          child: GetBuilder<ViewBusinessDetailsController>(
            id: 'livePhotos',
            builder: (_) {
              final photos = _businessController
                      .businessProfileDetails.value?.data?.livePhotos ??
                  [];
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (_, index) {
                  final hasPhoto =
                      index < photos.length && photos[index].isNotEmpty;
                  return _LivePhotoSlot(
                    index: index,
                    photoUrl: hasPhoto ? photos[index] : null,
                    label: _slotLabel(index),
                    placeholderImage: _slotPlaceholder(index),
                    allPhotos: photos,
                    controller: _businessController,
                  );
                },
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          top: SizeConfig.size60,
          child: Container(
            height: SizeConfig.size40,
            width: SizeConfig.size40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Icon(Icons.edit_outlined,
                size: 18, color: AppColors.primaryColor),
          ),
        ),
      ],
    );
  }

  String _slotLabel(int index) {
    switch (index) {
      case 0:
        return AppStrings.slotRoadSideImage.tr;
      case 1:
        return AppStrings.slotReceptionCounter.tr;
      case 2:
        return AppStrings.slotInteriorOne.tr;
      case 3:
      default:
        return AppStrings.slotInteriorTwo.tr;
    }
  }

  String _slotPlaceholder(int index) {
    switch (index) {
      case 0:
        return AppImageAssets.storefrontExterior;
      case 1:
        return AppImageAssets.billingCounterReceptionArea;
      case 2:
        return AppImageAssets.interiorInsideShop;
      case 3:
      default:
        return AppImageAssets.productServiceDisplay;
    }
  }

  Widget _buildGallerySection() {
    return Obx(() {
      final all = <String>[];
      for (final entry in _galleryController.galleryList) {
        all.addAll(entry.imageUrls ?? []);
      }
      return _SectionCard(
        title: AppStrings.gallery.tr,
        trailingLabel: AppStrings.addPhoto.tr,
        onTrailingTap: () => Get.to(() => MedicalGalleryListScreen(),
            binding: MedicalGalleryBinding()),
        child: all.isEmpty ? _galleryEmptyGuide() : _galleryGrid(all),
      );
    });
  }

  /// Empty-gallery guide â€” black & white preview image overlaid with
  /// add-photo CTA so the user understands what the section will look like.
  Widget _galleryEmptyGuide() {
    return GestureDetector(
      onTap: () => Get.to(() => MedicalGalleryListScreen(),
          binding: MedicalGalleryBinding()),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: Image.asset(
                  'assets/images/other_gallery.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey.shade300),
                ),
              ),
              Container(color: Colors.black.withValues(alpha: 0.35)),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.white, size: 32),
                    SizedBox(height: SizeConfig.size6),
                    CustomText(AppStrings.medicalAddPhotos.tr,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// WhatsApp-style preview:
  ///   1 image  â†’ full
  ///   2 images â†’ side-by-side
  ///   3 images â†’ 1 large left + 2 stacked right
  ///   4 images â†’ 2Ã—2
  ///   5+       â†’ 2Ã—2 with `+N` overlay on the 4th cell
  Widget _galleryGrid(List<String> images) {
    final display = images.length > 4 ? images.sublist(0, 4) : images;
    final extra = images.length > 4 ? images.length - 4 : 0;
    const double gap = 4;

    void open(int i) => navigatePushTo(
          context,
          ImageViewScreen(
            subTitle: AppStrings.imageViewer.tr,
            appBarTitle: AppStrings.imageViewer.tr,
            imageUrls: images,
            initialIndex: i,
          ),
        );

    Widget tile(int i, {bool overlay = false}) => GestureDetector(
          onTap: () => open(i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(display[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        )),
                if (overlay && extra > 0)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    alignment: Alignment.center,
                    child: Text(
                      '+$extra',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        );

    // 1 image â€” full
    if (display.length == 1) {
      return AspectRatio(aspectRatio: 1, child: tile(0));
    }

    // 2 images â€” side by side
    if (display.length == 2) {
      return AspectRatio(
        aspectRatio: 2,
        child: Row(children: [
          Expanded(child: tile(0)),
          const SizedBox(width: gap),
          Expanded(child: tile(1)),
        ]),
      );
    }

    // 3 images â€” 1 large left + 2 stacked right
    if (display.length == 3) {
      return AspectRatio(
        aspectRatio: 1,
        child: Row(children: [
          Expanded(child: tile(0)),
          const SizedBox(width: gap),
          Expanded(
            child: Column(children: [
              Expanded(child: tile(1)),
              const SizedBox(height: gap),
              Expanded(child: tile(2)),
            ]),
          ),
        ]),
      );
    }

    // 4+ images â€” 2x2 grid, with +N overlay on last cell when more
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: [
          Expanded(
            child: Row(children: [
              Expanded(child: tile(0)),
              const SizedBox(width: gap),
              Expanded(child: tile(1)),
            ]),
          ),
          const SizedBox(height: gap),
          Expanded(
            child: Row(children: [
              Expanded(child: tile(2)),
              const SizedBox(width: gap),
              Expanded(child: tile(3, overlay: extra > 0)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection() {
    final list = widget.data?.testimonials ?? [];
    if (list.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Column(
        children: [
          CustomText(AppStrings.testimonialsTitle.tr,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor),
          SizedBox(height: SizeConfig.size12),
          Container(
            padding: EdgeInsets.all(SizeConfig.size16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: _testimonialCard(list.first),
          ),
        ],
      ),
    );
  }

  Widget _testimonialCard(dynamic raw) {
    final m = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    final text =
        (m['testimonial'] ?? m['text'] ?? m['message'] ?? '').toString();
    final name = (m['name'] ?? m['author'] ?? '').toString();
    final role = (m['role'] ?? m['designation'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.format_quote, color: AppColors.primaryColor, size: 18),
            SizedBox(width: SizeConfig.size6),
            Expanded(
              child: CustomText(text,
                  fontSize: 13,
                  color: AppColors.secondaryTextColor,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (name.isNotEmpty)
                    CustomText('-$name',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor),
                  if (role.isNotEmpty)
                    CustomText(role,
                        fontSize: 11, color: AppColors.secondaryTextColor),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16, vertical: SizeConfig.size4),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: CustomText(AppStrings.reply.tr,
                  fontSize: 12, color: AppColors.mainTextColor),
            ),
          ],
        ),
      ],
    );
  }

  // CONTACT US
  Widget _buildContactSection(BusinessProfile? profile) {
    if (profile == null) return const SizedBox.shrink();
    final loc = profile.businessLocation;
    final phone = profile.businessNumber?.formattedMobile;
    final owner = profile.ownerDetails?.firstOrNull;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(SizeConfig.size16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(AppStrings.contactUsTitle.tr,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor),
                SizedBox(height: SizeConfig.size12),
                if (profile.logo != null && profile.logo!.isNotEmpty)
                  Container(
                    width: SizeConfig.size60,
                    height: SizeConfig.size60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6)
                      ],
                      image: DecorationImage(
                        image: NetworkImage(profile.logo!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                SizedBox(height: SizeConfig.size10),
                CustomText(profile.businessName ?? '',
                    fontSize: 15, fontWeight: FontWeight.w700),
                if (profile.businessDescription?.isNotEmpty ?? false) ...[
                  SizedBox(height: SizeConfig.size4),
                  CustomText(profile.businessDescription!,
                      fontSize: 12,
                      color: AppColors.secondaryTextColor,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],
                Divider(height: SizeConfig.size20),
                if (profile.websiteUrl?.isNotEmpty ?? false)
                  _contactItem(AppIconAssets.website_click, profile.websiteUrl!,
                      AppColors.primaryColor),
                if (owner?.name?.isNotEmpty ?? false)
                  _contactItem(
                      AppIconAssets.principal, owner!.name!, Colors.grey[700]!),
                if (owner?.email?.isNotEmpty ?? false)
                  _contactItem(AppIconAssets.email, owner!.email!,
                      AppColors.secondaryTextColor),
                if (phone != null)
                  _contactItem(AppIconAssets.phone_outline, phone,
                      AppColors.secondaryTextColor),
                if (profile.address?.isNotEmpty ?? false)
                  _contactItem(AppIconAssets.location_new, profile.address!,
                      Colors.grey[700]!),
              ],
            ),
          ),
          if (loc?.lat != null && loc?.lon != null) ...[
            SizedBox(height: SizeConfig.size12),
            BusinessLocationWidget(
              locationText: "",
              latitude: loc!.lat!,
              longitude: loc.lon!,
              businessName: profile.businessName ?? "",
              padding: 0,
              isTitleShow: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _contactItem(String icon, String label, Color iconColor) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalAssets(
              imagePath: icon, imgColor: iconColor, height: 16, width: 16),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: CustomText(label,
                fontSize: 12,
                color: AppColors.mainTextColor,
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// SHARED SECTION CARD WRAPPER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SectionCard extends StatelessWidget {
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailingLabel,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(title,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor),
                if (trailingLabel != null)
                  GestureDetector(
                    onTap: onTrailingTap,
                    child: CustomText(trailingLabel!,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor),
                  ),
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            child,
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// LIVE PHOTO SLOT
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _LivePhotoSlot extends StatefulWidget {
  final int index;
  final String? photoUrl;
  final String label;
  final String placeholderImage;
  final List<String> allPhotos;
  final ViewBusinessDetailsController controller;

  const _LivePhotoSlot({
    required this.index,
    required this.photoUrl,
    required this.label,
    required this.placeholderImage,
    required this.allPhotos,
    required this.controller,
  });

  @override
  State<_LivePhotoSlot> createState() => _LivePhotoSlotState();
}

class _LivePhotoSlotState extends State<_LivePhotoSlot> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.photoUrl != null;

    return GestureDetector(
      onTap: _isLoading
          ? null
          : () async {
              if (hasPhoto) {
                navigatePushTo(
                  context,
                  ImageViewScreen(
                    appBarTitle: AppStrings.imageViewer.tr,
                    subTitle: '',
                    imageUrls: widget.allPhotos,
                    initialIndex: widget.index,
                  ),
                );
              } else {
                final imgStr = await PhotoPickerService.pickFromCamera(
                  context,
                  cropAspectRatio: CropAspectRatio(width: 1, height: 1),
                );
                if (imgStr != null) {
                  setState(() => _isLoading = true);
                  await widget.controller
                      .saveBusinessImages(imgStr, widget.controller);
                  widget.controller.update(['livePhotos']);
                  if (mounted) setState(() => _isLoading = false);
                }
              }
            },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.expand(
              child: hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: widget.photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => _placeholderError(),
                    )
                  : _blurredPlaceholder(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: CustomText(
                widget.label,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (!hasPhoto && !_isLoading)
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: LocalAssets(
                    imagePath: AppIconAssets.profile_camera_pic,
                    height: 18,
                    width: 18,
                    imgColor: Colors.white,
                  ),
                ),
              ),
            ),
          if (hasPhoto && !_isLoading)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () async {
                  setState(() => _isLoading = true);
                  final data = {ApiKeys.image_url: widget.photoUrl};
                  await widget.controller.deleteLiveStoreImage(data);
                  widget
                      .controller.businessProfileDetails.value?.data?.livePhotos
                      ?.removeAt(widget.index);
                  widget.controller.update(['livePhotos']);
                  if (mounted) setState(() => _isLoading = false);
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.grey),
                ),
              ),
            ),
          if (_isLoading)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _blurredPlaceholder() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          widget.placeholderImage,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
        ),
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              color: AppColors.black.withValues(alpha: 0.15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholderError() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
