import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_joined_profile_card.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/profile_share_banner.dart';
import 'package:BlueEra/features/business/widgets/website_overview_card.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/empty_section_placeholder.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_testimonial_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_testimonial_model.dart';
import 'package:BlueEra/features/me/laboratory/model/new_lab_full_details_res_model.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_contact_us_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_service_gallery/lab_service_photos_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/testimonials/lab_testimonials_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../testimonials/lab_testimonial_form_sheet.dart';
import '../../widgets/category_selector_widget.dart';
import '../../widgets/empty_health_camp_widget.dart';

/// Overview tab for the redesigned lab "me" profile.
///
/// Mirrors the hospital v2 overview structure: cover banner first,
/// then description, gallery, contact, location, share banner, and
/// finally the QR-code card pinned at the bottom of the tab.
class LabOverviewTabV2 extends StatelessWidget {
  final LabFullDetailsController controller;

  const LabOverviewTabV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final businessController =
        getOrPut(() => ViewBusinessDetailsController(), permanent: true);

    return Obx(() {
      final d = controller.details.value;
      final profile = d?.profile;
      final contact = d?.contactInfo;
      final galleries = d?.galleries ?? <Galleries>[];
      final loc = contact?.location;
      final hasCoords = (loc?.coordinates?.isNotEmpty ?? false) &&
          loc!.coordinates!.length >= 2 &&
          loc.coordinates![0] != 0.0 &&
          loc.coordinates![1] != 0.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Joined-date pill + identity + cover card at the very top, in
          // parity with grocery_home_screen_v2's `_buildOverviewSlivers`.
          // Rendered edge-to-edge (no outer Padding) so its own internal
          // insets drive the visual rhythm, matching the grocery layout.
          Padding(
            padding: EdgeInsets.only(
                left: SizeConfig.size20, top: SizeConfig.size10),
            child: BusinessJoinedProfileCard(
                businessController: businessController),
          ),
          SizedBox(height: SizeConfig.size12),
          // LabBannerWidget(controller: controller),
          // SizedBox(height: SizeConfig.size12),

          // ── Description ──
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
          //   child: _DescriptionCard(
          //     description: profile?.description,
          //     onEdit: () =>
          //         Get.to(() => const LabDescriptionScreen())?.then((_) => controller.fetchFullDetails()),
          //   ),
          // ),

          // SizedBox(height: SizeConfig.size12),
          Padding(
            padding: EdgeInsets.only(
                right: SizeConfig.size12, left: SizeConfig.size25),
            child: CategorySelector(),
          ),

          SizedBox(height: SizeConfig.size12),
          Padding(
            padding: EdgeInsets.only(
                right: SizeConfig.size12, left: SizeConfig.size25),
            child: EmptyHealthCampWidget(),
          ),
          SizedBox(height: SizeConfig.size12),
          // ── Gallery ──
          Padding(
            padding: EdgeInsets.only(
                right: SizeConfig.size12, left: SizeConfig.size25),
            child: _GallerySection(
              galleries: galleries,
              // Section headers below mirror the `_SectionHeader` +
              // `_ChipCta` pattern used on the Tests tab so both surfaces
              // read as one language.
              onEdit: () => Get.to(() => LabServicePhotosPhotoScreen())
                  ?.then((_) => controller.fetchFullDetails()),
            ),
          ),

          SizedBox(height: SizeConfig.size12),

          // ── Testimonials ── carousel of quote cards (design mirrors
          // assets/img_2.png). Each card carries an Edit pill that opens
          // the form sheet for that testimonial; the section header's
          // Edit button opens the full owner-side manager screen.
          Padding(
            padding: EdgeInsets.only(
                right: SizeConfig.size12, left: SizeConfig.size25),
            child: const _TestimonialsSection(),
          ),

          SizedBox(height: SizeConfig.size12),

          // ── Contact ──
          Padding(
            padding: EdgeInsets.only(
                right: SizeConfig.size12, left: SizeConfig.size25),
            child: _ContactCard(
              contact: contact,
              profile: profile,
              onEdit: () => Get.to(() => LabContactUsScreen())
                  ?.then((_) => controller.fetchFullDetails()),
            ),
          ),

          SizedBox(height: SizeConfig.size12),

          Padding(
            padding: EdgeInsets.only(
                right: SizeConfig.size12, left: SizeConfig.size25),
            child: WebsiteOverviewCard(
              websiteUrl: businessController
                  .businessProfileDetails.value?.data?.websiteUrl,
              onSave: (url) => businessController
                  .updateBusinessProfileDetails({ApiKeys.websiteUrl: url}),
            ),
          ),

          // SizedBox(height: SizeConfig.size12),

          if (hasCoords) SizedBox(height: SizeConfig.size12),
          if (hasCoords)
            Padding(
              padding: EdgeInsets.only(
                  right: SizeConfig.size12, left: SizeConfig.size25),
              child: BusinessLocationWidget(
                locationText: loc.name,
                latitude: double.parse(loc.coordinates![1].toString()),
                longitude: double.parse(loc.coordinates![0].toString()),
                businessName: profile?.name ?? '',
                padding: 0,
                isTitleShow: true,
              ),
            ),

          Padding(
            padding: EdgeInsets.only(
                right: SizeConfig.size12, left: SizeConfig.size25),
            child: const ProfileShareBanner(),
          ),
          // SizedBox(height: SizeConfig.size10),

          // ── QR Code (mirrors the hospital/food QR card) ──
          Obx(() {
            final details =
                businessController.businessProfileDetails.value?.data;
            if (details == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(
                  right: SizeConfig.size12, left: SizeConfig.size25),
              child: BusinessQrCodeWidget(data: details),
            );
          }),

          SizedBox(height: kBottomNavigationBarHeight + 10),
        ],
      );
    });
  }
}

class _DescriptionCard extends StatelessWidget {
  final String? description;
  final VoidCallback onEdit;

  const _DescriptionCard({required this.description, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final hasData = (description ?? '').isNotEmpty;
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(AppStrings.description.tr,
                  fontWeight: FontWeight.w700),
              _EditButton(onTap: onEdit),
            ],
          ),
          SizedBox(height: SizeConfig.size8),
          if (hasData)
            CustomText(
              description!,
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            )
          else
            EmptySectionPlaceholder(
              imageAsset: 'assets/images/other_gallery.png',
              ctaLabel: AppStrings.labAddDescriptionForLab.tr,
              ctaIcon: Icons.description_outlined,
              onTap: onEdit,
            ),
        ],
      ),
    );
  }
}

class _GallerySection extends StatelessWidget {
  final List<Galleries> galleries;
  final VoidCallback onEdit;

  const _GallerySection({required this.galleries, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final allImages = galleries
        .expand((p) => p.imageUrls ?? const <String>[])
        .toList(growable: false);
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: AppStrings.gallery.tr,
            subtitle: 'Photos of your lab',
            trailing: _ChipCta(
              label: AppStrings.edit.tr,
              icon: Icons.edit_outlined,
              iconAtStart: true,
              onTap: onEdit,
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          if (allImages.isEmpty)
            EmptySectionPlaceholder(
              imageAsset: 'assets/images/other_gallery.png',
              ctaLabel: AppStrings.gallery.tr,
              onTap: onEdit,
            )
          else
            _GalleryGrid(images: allImages),
        ],
      ),
    );
  }
}

class _GalleryGrid extends StatelessWidget {
  final List<String> images;

  const _GalleryGrid({required this.images});

  @override
  Widget build(BuildContext context) {
    final display = images.length > 4 ? images.sublist(0, 4) : images;
    final extra = images.length > 4 ? images.length - 4 : 0;
    const double gap = 4;

    void open(int i) => navigatePushTo(
          context,
          ImageViewScreen(
            subTitle: AppStrings.imageViewer,
            appBarTitle: AppStrings.imageViewer,
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
                CachedNetworkImage(
                  imageUrl: display[i],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
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

    if (display.length == 1) {
      return AspectRatio(aspectRatio: 1, child: tile(0));
    }
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
}

class _ContactCard extends StatelessWidget {
  final ContactInfo? contact;
  final Profile? profile;
  final VoidCallback onEdit;

  const _ContactCard({
    required this.contact,
    required this.profile,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: AppStrings.contactUs.tr,
            subtitle: 'How customers can reach you',
            trailing: _ChipCta(
              label: AppStrings.edit.tr,
              icon: Icons.edit_outlined,
              iconAtStart: true,
              onTap: onEdit,
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          if (contact == null)
            EmptySectionPlaceholder(
              imageAsset: 'assets/images/other_gallery.png',
              ctaLabel: AppStrings.labAddContactInfo.tr,
              ctaIcon: Icons.contact_phone_outlined,
              onTap: onEdit,
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                      image: (profile?.logoUrl?.isNotEmpty ?? false)
                          ? DecorationImage(
                              image: NetworkImage(profile!.logoUrl!),
                              fit: BoxFit.cover,
                            )
                          : DecorationImage(
                              image:
                                  AssetImage(AppIconAssets.place_holder_image),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomText(profile?.name ?? '',
                      fontSize: 18, fontWeight: FontWeight.bold),
                  const SizedBox(height: 5),
                  CustomText(
                    profile?.description ?? '',
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  const Divider(height: 30),
                  if ((contact?.websiteUrl ?? '').isNotEmpty)
                    _contactItem(AppIconAssets.website_click,
                        contact!.websiteUrl!, AppColors.primaryColor),
                  _contactItem(AppIconAssets.principal, AppStrings.reception.tr,
                      Colors.grey[700]!),
                  if ((contact?.email ?? '').isNotEmpty)
                    _contactItem(AppIconAssets.email, contact!.email!,
                        AppColors.secondaryTextColor),
                  if ((contact?.phoneNo ?? '').isNotEmpty)
                    _contactItem(AppIconAssets.phone_outline, contact!.phoneNo!,
                        AppColors.secondaryTextColor),
                  if ((contact?.location?.name ?? '').isNotEmpty)
                    _contactItem(AppIconAssets.location_new,
                        contact!.location!.name!, Colors.grey[700]!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _contactItem(String icon, String label, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          LocalAssets(imagePath: icon, imgColor: iconColor),
          const SizedBox(width: 12),
          Expanded(
              child: CustomText(label, fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
}

/// Testimonials carousel section — matches assets/img_2.png card design.
///
/// Fetches the owner's testimonials on first mount, renders them as a
/// PageView of quote cards with page indicators underneath. Section
/// header carries an Edit button that opens the full manager screen
/// ([LabTestimonialsScreen]); the per-card blue pill opens the add /
/// edit form sheet ([LabTestimonialFormSheet]) for that testimonial.
class _TestimonialsSection extends StatefulWidget {
  const _TestimonialsSection();

  @override
  State<_TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends State<_TestimonialsSection> {
  final LabTestimonialController _ctrl =
      getOrPut(() => LabTestimonialController());
  final PageController _pageController = PageController(viewportFraction: 0.94);
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (_ctrl.myTestimonials.isEmpty) {
      _ctrl.fetchMyTestimonials();
    }
    _pageController.addListener(() {
      final p = _pageController.page?.round() ?? 0;
      if (p != _page && mounted) setState(() => _page = p);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openManager() async {
    await Get.to(() => const LabTestimonialsScreen());
    // Refresh in case the manager screen added / edited / deleted anything.
    await _ctrl.fetchMyTestimonials();
  }

  Future<void> _openForm({LabTestimonial? existing}) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LabTestimonialFormSheet(existing: existing),
    );
    // The form-sheet controller refreshes on success so we don't need to.
  }

  @override
  Widget build(BuildContext context) {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Testimonials',
            subtitle: 'What customers say about you',
            trailing: _ChipCta(
              label: AppStrings.edit.tr,
              icon: Icons.edit_outlined,
              iconAtStart: true,
              onTap: _openManager,
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          Obx(() {
            final list = _ctrl.myTestimonials.toList();
            if (_ctrl.isLoading.value && list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (list.isEmpty) {
              return EmptySectionPlaceholder(
                imageAsset: 'assets/images/other_gallery.png',
                ctaLabel: 'Add Testimonial',
                ctaIcon: Icons.format_quote_rounded,
                onTap: () => _openForm(),
              );
            }
            return Column(
              children: [
                SizedBox(
                  height: 260,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: list.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _TestimonialQuoteCard(
                        testimonial: list[i],
                        onEdit: () => _openForm(existing: list[i]),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.size10),
                _dots(list.length),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _dots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _page ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == _page
                  ? AppColors.primaryColor
                  : AppColors.primaryColor.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

/// One quote card in the testimonials carousel — matches assets/img_2.png:
/// centered blue quote glyph on top, centered message body, author name +
/// designation bottom-left, blue "Edit" pill bottom-right.
class _TestimonialQuoteCard extends StatelessWidget {
  final LabTestimonial testimonial;
  final VoidCallback onEdit;

  const _TestimonialQuoteCard({
    required this.testimonial,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final name = (testimonial.authorName ?? '').trim();
    final designation = (testimonial.designation ?? '').trim();
    final message = (testimonial.message ?? '').trim();
    return Container(
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F001120), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Icon(
              Icons.format_quote_rounded,
              size: 36,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: SizeConfig.size6),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: CustomText(
                  message,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                  height: 1.45,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      name.isEmpty ? '' : '- $name',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (designation.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: CustomText(
                          designation,
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
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: CustomText(
                    'Edit',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryColor,
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

// ─── Shared header + chip primitives (mirrors lab_tests_tab_v2.dart) ────

/// Vertical brand bar + bold title + one-line helper + trailing chip.
/// Copied verbatim from `lab_tests_tab_v2.dart` so the Overview + Tests
/// tabs share the same section-header language without exposing a
/// widget through a shared file.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                title,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              CustomText(
                subtitle,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        trailing,
      ],
    );
  }
}

/// Brand-outlined chip with a solid circular icon badge — used for both
/// leading-icon CTAs ("+ Add …") and trailing-icon ones ("View All →").
class _ChipCta extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool iconAtStart;
  final VoidCallback onTap;

  const _ChipCta({
    required this.label,
    required this.icon,
    required this.iconAtStart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconBadge = Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
    final labelWidget = CustomText(
      label,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.primaryColor,
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: iconAtStart
            ? const EdgeInsets.fromLTRB(4, 4, 12, 4)
            : const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: iconAtStart
              ? [iconBadge, SizedBox(width: SizeConfig.size6), labelWidget]
              : [labelWidget, SizedBox(width: SizeConfig.size6), iconBadge],
        ),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, size: 14, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            CustomText(
              AppStrings.edit.tr,
              fontSize: 12,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}
