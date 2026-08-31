import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/features/me/school/binding/school_branch_contact_binding.dart';
import 'package:BlueEra/features/me/school/binding/campus_life_binding.dart';
import 'package:BlueEra/core/api/model/school_quick_info_field.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_joined_profile_card.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/profile_share_banner.dart';
import 'package:BlueEra/features/business/widgets/website_overview_card.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/empty_section_placeholder.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/availability_form_screen.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/managment_trust_form_screen.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/principal_message_screen.dart';
import 'package:BlueEra/features/me/school/view/category/campus_life/campus_life_listing_screen.dart';
import 'package:BlueEra/features/me/school/view/category/school_contact_us/school_contact_us.dart'
    as contact_us;
import 'package:BlueEra/features/me/school/view/category/school_home/school_availability_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_campus_photo_gallery_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_contact_us_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_director_card_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_management_view.dart';
import 'package:BlueEra/widgets/business_live_photo_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_business_live_photo.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_icon_assets.dart';
import '../../../../../../widgets/local_assets.dart';
import '../../category/acadamics/school_quick_info_form_screen.dart';
import '../../category/acadamics/widgets/school_quick_info_view.dart';

/// Overview tab for the redesigned school "me" profile.
///
/// Layout mirrors the product/inventory v2 overview: shared joined-date +
/// identity + cover card, live photos, business description, then the
/// school-specific sections (director, management, campus life,
/// availability, contact us, location), followed by website, QR, and share
/// banner.
///
/// Every top-level child sits inside [_hPad] so the outer edges of every
/// card align at [_hInset] from both screen edges. `BusinessJoinedProfileCard`
/// is the sole exception — it self-pads internally at the same inset, so
/// wrapping it again would double the gutter.
class SchoolOverviewTabV2 extends StatefulWidget {
  final SchoolAboutUsController controller;

  const SchoolOverviewTabV2({super.key, required this.controller});

  @override
  State<SchoolOverviewTabV2> createState() => _SchoolOverviewTabV2State();
}

class _SchoolOverviewTabV2State extends State<SchoolOverviewTabV2> {
  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  // Single source of truth for horizontal gutter used across every card in
  // this tab. Change here and every section stays aligned.
  double get _hInset => SizeConfig.size12;

  Widget _hPad({required Widget child}) => Padding(
        padding: EdgeInsets.only(left: _hInset, right: _hInset
            // bottom: kBottomNavigationBarHeight + 30,
            // top: SizeConfig.size10,
            ),
        child: child,
      );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Get.isRegistered<BottomBarController>() &&
          Get.find<BottomBarController>().currentIndex.value != 0) {
        return;
      }
      showBusinessLivePhotoBottomSheetIfNeeded(
        context: context,
        controller: _businessController,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = widget.controller.schoolDetailsData?.value;
      final coordinates = data?.location?.coordinates;
      final hasCoords = (coordinates?.isNotEmpty ?? false) &&
          coordinates!.length >= 2 &&
          coordinates[0] != 0.0 &&
          coordinates[1] != 0.0;

      final principal = data?.aboutId?.principalMessage;
      final hasDirector = (principal?.name?.isNotEmpty ?? false) ||
          (principal?.message?.isNotEmpty ?? false);

      final management = data?.aboutId?.management ?? const [];
      final campusLife = data?.campusLife ?? const [];
      final contacts = data?.contacts ?? const [];

      // Gate: when the listing's category is one of the six Siksha
      // education categories and *every* required Quick Info field for
      // that category is empty, hide every section below the header and
      // surface a single banner that pushes into the Quick Info form.
      // Required-field set per category comes from
      // [kQuickInfoFieldsByCategory] so School Education, Coaching,
      // College/University, Sports & Hobby, Professional Learn and
      // Skill Training each gate on their own field list.
      final quickInfoValues = widget.controller.quickInfoValues;
      final resolvedCategory = resolveQuickInfoCategoryKey(
          widget.controller.quickInfoCategory.value);
      final requiredKeys = resolvedCategory != null
          ? kQuickInfoFieldsByCategory[resolvedCategory]
          : null;
      final gateBehindQuickInfo = requiredKeys != null &&
          requiredKeys.isNotEmpty &&
          requiredKeys.every((k) => _isQuickInfoValueEmpty(quickInfoValues[k]));

      if (gateBehindQuickInfo) {
        // Pull user-friendly labels from the loaded descriptors when
        // available; fall back to a prettified key so the banner still
        // reads correctly if descriptors haven't arrived yet.
        final descriptorByKey = {
          for (final f in widget.controller.quickInfoFields) f.key: f
        };
        final fieldLabels = requiredKeys
            .map((k) => descriptorByKey[k]?.label ?? _prettifyFieldKey(k))
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Joined date + identity + cover (self-pads at _hInset) ──
            BusinessJoinedProfileCard(businessController: _businessController),
            SizedBox(height: SizeConfig.size10),
            _QuickInfoRequiredBanner(
              category: resolvedCategory,
              fieldLabels: fieldLabels,
              onTap: () => Get.to(() => const SchoolQuickInfoFormScreen())
                  ?.then((_) => widget.controller.getSchoolByIdController()),
            ),
            SizedBox(height: SizeConfig.size16),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Joined date + identity + cover (self-pads at _hInset) ──
          BusinessJoinedProfileCard(businessController: _businessController),

          // DirectorCard uses `Card(margin: EdgeInsets.all(10))`, which adds
          // 10px above and below itself; the empty _SplitEmptyCard has no
          // such margin. Skip the outer spacers when data is present so
          // both states show the same 10px gap on either side.
          if (!hasDirector) SizedBox(height: SizeConfig.size10),

          // ── Director / Principal Message ──
          // _hPad(
          //   child:
          hasDirector
              ? DirectorCard(
                  schoolAboutUsController: widget.controller,
                  isEdit: true,
                )
              : _SplitEmptyCard(
                  message: 'You Have Not Add Any Principal / Director Message',
                  icon: Icons.person_outline,
                  onTap: () => Get.to(() => PrincipalMessageScreen())?.then(
                      (_) => widget.controller.getSchoolByIdController()),
                ),
          // ),

          if (!hasDirector) SizedBox(height: SizeConfig.size10),

          // ── School Quick Info (Class range / Ratio / Medium) ──
          // _hPad(
          //   child:
          SchoolQuickInfoCard(
            controller: widget.controller,
            onEditTap: () => Get.to(() => const SchoolQuickInfoFormScreen())
                ?.then((_) => widget.controller.getSchoolByIdController()),
          ),
          // ),

          // SchoolManagementSection wraps in `CommonCardWidget(padding: 0)`
          // without overriding cardMargin, so it inherits the default 10px
          // margin on top and bottom. The empty _SplitEmptyCard has no
          // such margin, so its outer spacer alone drives the visible gap.
          // Skip this outer spacer above Management when data is present
          // (the top card-margin fills in) so both states show 10px.
          if (management.isEmpty) SizedBox(height: SizeConfig.size10),

          // ── Management ──
          // _hPad(
          //   child:
          management.isNotEmpty
              ? SchoolManagementSection(
                  managementData: management,
                  isEdit: true,
                )
              : _SplitEmptyCard(
                  message: 'You Have Not Add Any Management / Trust Info',
                  icon: Icons.groups_outlined,
                  showIconPanel: false,
                  onTap: () =>
                      Get.to(() => ManagementTrustFormScreen(isEdit: false))
                          ?.then((_) =>
                              widget.controller.getSchoolByIdController()),
                ),
          // ),

          // Same rationale below the card: the CommonCardWidget's default
          // bottom margin covers the 10px gap in the data state, so we
          // only emit the outer spacer for the empty state.
          if (management.isEmpty) SizedBox(height: SizeConfig.size10),

          // ── Availability ──
          // _hPad(
          //   child:
          SchoolAvailabilityCard(
            controller: widget.controller,
            onEditTap: () => Get.to(() => const AvailabilityFormScreen())
                ?.then((_) => widget.controller.getSchoolByIdController()),
          ),
          // ),

          // SizedBox(height: SizeConfig.size10),

          // ── Live photos ──
          _hPad(
            child: CommonBusinessLivePhoto(controller: _businessController),
          ),

          SizedBox(height: SizeConfig.size10),

          // ── Campus Life Gallery ──
          _hPad(
            child: campusLife.isNotEmpty
                ? CampusPhotoGallery(
                    campusLife: campusLife,
                    isEdit: true,
                  )
                : _SectionEmptyCard(
                    title: AppStrings.campusLife.tr,
                    ctaLabel: AppStrings.campusLife.tr,
                    onTap: () => Get.to(() => CampusLifeListingScreen(),
                            binding: CampusLifeBinding())
                        ?.then(
                            (_) => widget.controller.getSchoolByIdController()),
                  ),
          ),

          // ContactUsSection wraps its content in
          // `CustomFormCard(margin: EdgeInsets.only(top: 10))`, so it adds
          // 10px above itself; the empty _SectionEmptyCard has no such
          // margin. Skip the outer spacer when data is present so both
          // states show the same 10px gap above Contact Us.
          if (contacts.isEmpty) SizedBox(height: SizeConfig.size10),

          // ── Contact Us ──
          _hPad(
            child: contacts.isNotEmpty
                ? ContactUsSection(
                    isEdit: true,
                    contacts: contacts,
                  )
                : _SectionEmptyCard(
                    title: AppStrings.contactUs.tr,
                    ctaLabel: AppStrings.contactUs.tr,
                    ctaIcon: Icons.contact_phone_outlined,
                    onTap: () => Get.to(() => contact_us.SchoolContactUs(),
                            binding: SchoolBranchContactBinding())
                        ?.then(
                            (_) => widget.controller.getSchoolByIdController()),
                  ),
          ),

          // SizedBox(height: SizeConfig.size10),

          // ── Website (shared, business data) ──
          _hPad(
            child: Obx(() {
              final details =
                  _businessController.businessProfileDetails.value?.data;
              return WebsiteOverviewCard(
                websiteUrl: details?.websiteUrl,
                onSave: (url) => _businessController
                    .updateBusinessProfileDetails({ApiKeys.websiteUrl: url}),
              );
            }),
          ),

          // ── Location (school data) ──
          if (hasCoords) SizedBox(height: SizeConfig.size10),
          if (hasCoords)
            _hPad(
              child: CommonCardWidget(
                padding: 5,
                cardMargin: 0,
                child: BusinessLocationWidget(
                  locationText: data?.name,
                  latitude: double.parse(coordinates[0].toString()),
                  longitude: double.parse(coordinates[1].toString()),
                  businessName: data?.name ?? '',
                  padding: 0,
                  isTitleShow: true,
                ),
              ),
            ),

          // SizedBox(height: SizeConfig.size10),

          // ── QR Code (shared) ──
          _hPad(child: _buildQrCodeSection()),

          // SizedBox(height: SizeConfig.size10),

          // ── Share banner (shared) ──
          _hPad(child: const ProfileShareBanner()),

          SizedBox(height: SizeConfig.size16),
        ],
      );
    });
  }

  Widget _buildQrCodeSection() {
    return Obx(() {
      final details = _businessController.businessProfileDetails.value?.data;
      if (details == null) return const SizedBox.shrink();
      return NewBusinessQrCodeWidget(data: details);
    });
  }

  // A Quick Info value counts as "missing" when the backend returned null,
  // an empty string, or an empty list — matching the shapes documented in
  // school_quick_info_field.dart.
  static bool _isQuickInfoValueEmpty(dynamic v) {
    if (v == null) return true;
    if (v is String) return v.trim().isEmpty;
    if (v is List) return v.isEmpty;
    return false;
  }

  // Fallback used only when the field descriptors haven't been loaded yet
  // — converts a whitelist key ("mediumOfInstruction") into a readable
  // label ("Medium Of Instruction") so the banner never renders a raw
  // camelCase key.
  static String _prettifyFieldKey(String key) {
    if (key.isEmpty) return key;
    final spaced = key.replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

/// Titled card used for any school section that has no data yet — shows
/// the section heading + edit pill, then the shared greyscale
/// placeholder image with a tap-to-add CTA underneath. No horizontal
/// padding here — the parent tab applies the shared gutter via `_hPad`.
class _SectionEmptyCard extends StatelessWidget {
  final String title;
  final String ctaLabel;
  final IconData ctaIcon;
  final VoidCallback onTap;

  const _SectionEmptyCard({
    required this.title,
    required this.ctaLabel,
    required this.onTap,
    this.ctaIcon = Icons.add_photo_alternate_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(title, fontWeight: FontWeight.w700),
              _EditPill(onTap: onTap),
            ],
          ),
          SizedBox(height: SizeConfig.size8),
          EmptySectionPlaceholder(
            imageAsset: 'assets/images/other_gallery.png',
            ctaLabel: ctaLabel,
            ctaIcon: ctaIcon,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// Compact empty-state card for the principal-message and management
/// sections. Left panel is a light-grey square with a section icon; right
/// panel shows the "not yet added" line plus a primary "Add Now" pill.
class _SplitEmptyCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback onTap;

  // When false, the left grey icon panel is omitted and the right content
  // (illustration + message + CTA) fills the whole card. Used by the
  // management empty state, which doesn't want the greyscale sidebar.
  final bool showIconPanel;

  const _SplitEmptyCard({
    required this.message,
    required this.icon,
    required this.onTap,
    this.showIconPanel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showIconPanel)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                        topRight: Radius.circular(8)),
                  ),
                  child: Center(
                    child: Icon(icon, size: 32, color: Colors.grey.shade400),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size12,
                    vertical: SizeConfig.size16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      LocalAssets(
                        imagePath: AppIconAssets.emptyIcon,
                        height: 50,
                        width: 50,
                      ),
                      SizedBox(height: SizeConfig.size16),
                      CustomText(
                        message,
                        fontSize: 13,
                        color: AppColors.secondaryTextColor,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                      SizedBox(height: SizeConfig.size16),
                      InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size14,
                            vertical: SizeConfig.size8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              CustomText(
                                'Add Now',
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner shown in place of the entire profile body when the listing's
/// category is one of the six Siksha education categories and every
/// required Quick Info field for that category is empty. Tapping it
/// opens [SchoolQuickInfoFormScreen]; the parent refetches the listing
/// when the form returns so the gate flips off as soon as any required
/// field is saved.
class _QuickInfoRequiredBanner extends StatelessWidget {
  final String? category;
  final List<String> fieldLabels;
  final VoidCallback onTap;

  const _QuickInfoRequiredBanner({
    required this.category,
    required this.fieldLabels,
    required this.onTap,
  });

  String get _heading {
    final c = category?.trim();
    if (c == null || c.isEmpty) return 'Complete your Quick Info';
    return 'Complete your $c Quick Info';
  }

  String get _message {
    if (fieldLabels.isEmpty) {
      return 'Please fill all required Quick Info fields — the rest of your profile can only be displayed once these basics are saved.';
    }
    return 'Please fill ${_joinWithAnd(fieldLabels)} — all fields are required before the rest of your profile can be displayed.';
  }

  static String _joinWithAnd(List<String> items) {
    if (items.length == 1) return items.first;
    if (items.length == 2) return '${items[0]} and ${items[1]}';
    return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LocalAssets(
              imagePath: AppIconAssets.emptyIcon,
              height: 60,
              width: 60,
            ),
            SizedBox(height: SizeConfig.size16),
            CustomText(
              _heading,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size8),
            CustomText(
              _message,
              fontSize: 13,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
              maxLines: 5,
            ),
            SizedBox(height: SizeConfig.size16),
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16,
                  vertical: SizeConfig.size10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_outlined,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    CustomText(
                      'Fill Quick Info',
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
}

class _EditPill extends StatelessWidget {
  final VoidCallback onTap;
  const _EditPill({required this.onTap});

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
            Icon(Icons.add, size: 14, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            CustomText(
              AppStrings.add.tr,
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
