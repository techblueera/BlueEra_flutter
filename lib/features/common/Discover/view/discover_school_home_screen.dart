import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_school_quick_info_card.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/category/career_jobs/school_job_listing_screen.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_director_card_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_management_view.dart';
import 'package:BlueEra/features/me/school/widget/education_enquiry_sheet.dart';
import 'package:BlueEra/features/me/school/widget/school_course_list_item_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart'
    as avail;
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:BlueEra/widgets/social_gallery_grid.dart';
import 'package:BlueEra/widgets/visit_business_hero.dart';
import 'package:BlueEra/widgets/website_preview_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../business/widgets/business_qrcode_widget.dart';

class DiscoverSchoolHomeScreen extends StatefulWidget {
  const DiscoverSchoolHomeScreen({super.key});

  @override
  State<DiscoverSchoolHomeScreen> createState() =>
      _DiscoverSchoolHomeScreenState();
}

class _DiscoverSchoolHomeScreenState extends State<DiscoverSchoolHomeScreen> {
  final schoolAboutUsController = getOrPut(() => SchoolAboutUsController());
  // Shared business-profile controller. `permanent: true` matches how every
  // other Discover detail screen (finance / lab / hospital) binds it — the
  // header keys off the same instance so nav doesn't refetch.
  final viewBusinessDetailsController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);
  Worker? _profileHydrateWorker;

  @override
  void initState() {
    super.initState();
    // Load the full record from `education-service/schools/{id}` on open so the
    // screen shows the live API data, not just the lighter list item a caller
    // seeded into the controller. Uses the seeded school id (falling back to
    // ownerId); the controller tries the school-id lookup first, then owner-id,
    // so it resolves regardless of which the id actually is. If neither is
    // present (e.g. deep-link path that seeds an empty school and fetches
    // itself), we skip and let that caller's own fetch run.
    final data = schoolAboutUsController.schoolDetailsData?.value;
    final id = (data?.id ?? '').trim();
    final ownerId = (data?.ownerId ?? '').trim();
    if (id.isNotEmpty || ownerId.isNotEmpty) {
      // Discover renders quick-info from the main /schools/:id
      // response via DiscoverSchoolQuickInfoCard, so we skip the
      // extra GET /schools/:id/quick-info round-trip.
      schoolAboutUsController.getSchoolByIdController(
        schoolID: id.isNotEmpty ? id : ownerId,
        ownerID: ownerId.isNotEmpty ? ownerId : id,
        skipQuickInfoFetch: true,
      );
    }

    // Hydrate the shared business-profile controller from the school
    // owner id so [VisitBusinessCommonHeader] has data on first paint,
    // and re-hydrate whenever the school controller swaps in a fresh
    // record post-fetch.
    void hydrateProfile(String? ownerIdVal) {
      final uid = (ownerIdVal ?? '').trim();
      if (uid.isEmpty) return;
      // ignore: unawaited_futures
      viewBusinessDetailsController.viewBusinessProfileById(uid);
    }

    hydrateProfile(ownerId);
    final rx = schoolAboutUsController.schoolDetailsData;
    if (rx != null) {
      _profileHydrateWorker = ever<SchoolDetailsData>(
        rx,
        (d) => hydrateProfile(d.ownerId),
      );
    }
  }

  @override
  void dispose() {
    _profileHydrateWorker?.dispose();
    super.dispose();
  }

  /// Vertical spacer between adjacent cards. Sized off `SizeConfig.size10`
  /// so tablet layouts scale in step with `CommonCardWidget`'s inner rhythm.
  Widget _gap() => SizedBox(height: SizeConfig.size10);

  /// Horizontal inset applied around every card whose child widget uses
  /// `cardMargin: 0`. Kept on `paddingXSL` (10px phone / 14px tablet) to
  /// match the inset the shared card widgets use everywhere else on
  /// Discover, so this screen doesn't drift from siblings like Finance /
  /// Hospital / Lab detail pages.
  Widget _pad(Widget child) => Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = schoolAboutUsController.schoolDetailsData?.value;
      // A real school always carries an id. When there's no id yet and a fetch
      // is in flight (e.g. opened from a deep link / QR with only an id), show a
      // loader instead of a page full of empty "no data" sections.
      final hasData = (data?.id ?? '').isNotEmpty;
      final isLoading = schoolAboutUsController.isDetailLoading.value;

      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        bottomNavigationBar: hasData ? _buildBottomBar(context) : null,
        body: (!hasData && isLoading)
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Header (edge-to-edge hero includes overlay app-bar) ───
                    Obx(() {
                      // Subscribe to silent profile refreshes — bumps on every
                      // successful fetch so this Obx rebuilds even when the
                      // loader is skipped.
                      viewBusinessDetailsController.profileVersion.value;
                      if (viewBusinessDetailsController
                          .isProfileLoading.value) {
                        return buildBusinessHeaderSkeleton();
                      }
                      final details = viewBusinessDetailsController
                          .visitedBusinessProfileDetails?.data;
                      return VisitBusinessHero(
                        details: details,
                        scheduleOverride:
                            _schoolTimingsToSchedule(data?.availability),
                        onRated: () => viewBusinessDetailsController
                            .viewBusinessProfileById(
                          data?.ownerId ?? '',
                          silent: true,
                        ),
                        onFollowChanged: () => viewBusinessDetailsController
                            .viewBusinessProfileById(
                          data?.ownerId ?? '',
                          silent: true,
                        ),
                      );
                    }),

                    // ─── Section rhythm ──────────────────────────────────────
                    // Every card below hero renders `cardMargin: 0` and is
                    // wrapped by `_pad(...)` for horizontal inset, with a
                    // single `_gap()` between neighbours. That keeps gaps
                    // identical whether a card renders its populated body,
                    // its empty-state variant, or (for Obx-driven blocks)
                    // collapses to `SizedBox.shrink()`. Two exceptions:
                    //   • DirectorCard already applies its own 10px all-
                    //     around margin via `Card`, so it acts as both card
                    //     and gap — no external `_gap()` around it.
                    //   • DiscoverSchoolQuickInfoCard handles its own
                    //     horizontal inset (12px) so we skip `_pad` for it.

                    /// DIRECTOR / PRINCIPAL MESSAGE — self-margined
                    DirectorCard(
                      schoolAboutUsController: schoolAboutUsController,
                    ),

                    /// HIGHLIGHTS (category-driven quick info)
                    DiscoverSchoolQuickInfoCard(data: data),

                    /// MANAGEMENT
                    _gap(),
                    _pad(_ManagementSection(data: data)),

                    /// COURSES
                    _gap(),
                    _pad(_CoursesSection(data: data)),

                    /// LIVE PHOTOS — Obx that owns its own leading gap so
                    /// hiding the section removes both the card and the
                    /// spacer, leaving no orphan gap in the scroll view.
                    Obx(() {
                      if (viewBusinessDetailsController
                          .isProfileLoading.value) {
                        return const SizedBox.shrink();
                      }
                      final details = viewBusinessDetailsController
                          .visitedBusinessProfileDetails?.data;
                      final photos = (details?.livePhotos ?? const <String>[])
                          .where((p) => p.trim().isNotEmpty)
                          .toList();
                      if (photos.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(
                          top: SizeConfig.size10,
                          left: SizeConfig.paddingXSL,
                          right: SizeConfig.paddingXSL,
                        ),
                        child: CustomFormCard(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CustomText(
                                'Live Photos',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              const SizedBox(height: 10),
                              StoreLivePhotoWidget(
                                livePhotos: photos,
                                natureOfBusiness:
                                    details?.subCategoryDetails?.name ??
                                        details?.natureOfBusiness ??
                                        'OTHER',
                                onViewFullScreen: ({
                                  required int index,
                                  required List<String> storeImage,
                                  required String natureOfBusiness,
                                }) {
                                  navigatePushTo(
                                    context,
                                    ImageViewScreen(
                                      appBarTitle: details?.businessName ?? '',
                                      subTitle: natureOfBusiness,
                                      imageUrls: storeImage,
                                      initialIndex: index,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    /// CAMPUS GALLERY (social-style grid)
                    _gap(),
                    _pad(_GallerySection(data: data)),

                    /// QUICK LINKS — Job Vacancy only (Academics /
                    /// Student Corner / Notices removed per product ask).
                    _gap(),
                    _pad(_JobVacancyLink()),

                    /// CONTACT MAP — Obx owns leading gap so it collapses
                    /// cleanly during profile loading.
                    Obx(() {
                      if (viewBusinessDetailsController
                          .isProfileLoading.value) {
                        return const SizedBox.shrink();
                      }
                      final details = viewBusinessDetailsController
                          .visitedBusinessProfileDetails?.data;
                      return Padding(
                        padding: EdgeInsets.only(
                          // top: SizeConfig.size10,
                          left: SizeConfig.paddingXSL,
                          right: SizeConfig.paddingXSL,
                        ),
                        child: BusinessContactMapCard(
                          businessProfileDetails: details,
                          showEditButton: false,
                        ),
                      );
                    }),

                    /// WEBSITE PREVIEW — Obx owns leading gap, hides when
                    /// there is no website URL to preview.
                    Obx(() {
                      // `visitedBusinessProfileDetails` is a plain field —
                      // reading it doesn't subscribe Obx to anything. Bind
                      // to the reactive loading flag + refresh version bump
                      // so this Obx rebuilds when the profile fetch lands
                      // (matches the hero / contact-map / QR pattern above).
                      viewBusinessDetailsController.profileVersion.value;
                      if (viewBusinessDetailsController
                          .isProfileLoading.value) {
                        return const SizedBox.shrink();
                      }
                      final url = viewBusinessDetailsController
                              .visitedBusinessProfileDetails
                              ?.data
                              ?.websiteUrl ??
                          '';
                      // Preserve prior gating: original code showed the
                      // card when the URL was empty (`?.isEmpty ?? false`).
                      // That branch renders nothing useful, so folding to
                      // "hide when empty" keeps the visible surface the
                      // same while making the intent obvious.
                      if (url.trim().isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(
                          // top: SizeConfig.size10,
                          left: SizeConfig.paddingXSL,
                          right: SizeConfig.paddingXSL,
                        ),
                        child: WebsitePreviewCard(url: url),
                      );
                    }),

                    /// QR CODE — Obx owns leading gap.
                    Obx(() {
                      if (viewBusinessDetailsController
                          .isProfileLoading.value) {
                        return const SizedBox.shrink();
                      }
                      final details = viewBusinessDetailsController
                          .visitedBusinessProfileDetails?.data;
                      return Padding(
                        padding: EdgeInsets.only(
                          // top: SizeConfig.size10,
                          left: SizeConfig.paddingXSL,
                          right: SizeConfig.paddingXSL,
                        ),
                        child: BusinessQrCodeWidget(data: details),
                      );
                    }),

                    SizedBox(
                        height: kBottomNavigationBarHeight + SizeConfig.size50),
                  ],
                ),
              ),
      );
    });
  }

  Widget? _buildBottomBar(BuildContext context) {
    if (schoolAboutUsController.schoolDetailsData?.value.ownerId == userId) {
      return null;
    }
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: SizeConfig.paddingS,
          right: SizeConfig.paddingS,
          bottom: SizeConfig.paddingM,
          top: SizeConfig.paddingXSL,
        ),
        child: Row(
          children: [
            // Expanded(
            //   child: PositiveCustomBtn(
            //     onTap: () {
            //       final chatViewController = Get.find<ChatViewController>();
            //       chatViewController.checkChatConnectionAndOpenChat(
            //         userId: schoolAboutUsController
            //                 .schoolDetailsData?.value.ownerId ??
            //             '',
            //         route: AppConstants.route_discover,
            //       );
            //     },
            //     title: AppStrings.chat,
            //   ),
            // ),
            // SizedBox(width: SizeConfig.paddingS),
            Expanded(
              child: PositiveCustomBtn(
                onTap: () => _openSchoolEnquirySheet(context),
                title: AppStrings.inquiry,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the education-enquiry sheet for the currently-viewed school.
  /// Pulls the listing id / owner id / name / banner / first-contact
  /// location from the loaded SchoolDetailsData so the sheet header and
  /// the eventual in-chat card render without an extra fetch.
  void _openSchoolEnquirySheet(BuildContext context) {
    final data = schoolAboutUsController.schoolDetailsData?.value;
    final listingId = (data?.id ?? '').trim();
    final ownerId = (data?.ownerId ?? '').trim();
    if (listingId.isEmpty || ownerId.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    EducationEnquirySheet.open(
      context,
      listing: EducationEnquiryListing(
        listingId: listingId,
        ownerId: ownerId,
        ownerName: (data?.name ?? '').trim(),
        listingName: (data?.name ?? '').trim(),
        listingImage: data?.bannerUrl ?? data?.logo,
        location: data?.contacts?.firstOrNull?.branch?.location?.name,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MANAGEMENT SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _ManagementSection extends StatelessWidget {
  final SchoolDetailsData? data;
  const _ManagementSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final management = data?.aboutId?.management ?? [];
    if (management.isEmpty) {
      return _emptySection(
        Icons.people_outline,
        AppStrings.managementTrust.tr,
        AppStrings.noManagementDetailsAvailable.tr,
      );
    }
    // cardMargin: 0 → the shared parent (`_pad`) owns the horizontal
    // inset and the surrounding `_gap()` owns the vertical space, so
    // populated / empty states produce the same gap to neighbours.
    return SchoolManagementSection(
      managementData: management,
      cardMargin: 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COURSES SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _CoursesSection extends StatelessWidget {
  final SchoolDetailsData? data;
  const _CoursesSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final courses = data?.courses ?? [];
    if (courses.isEmpty) {
      return _emptySection(
        Icons.menu_book_outlined,
        AppStrings.coursesLabel.tr,
        AppStrings.noCoursesAvailable.tr,
      );
    }
    // Reuse the same card the owner Academics tab uses, in read-only
    // mode (no edit/delete callbacks → the overflow menu is hidden).
    // Horizontal rail — matches assets/img.png. Each card is fixed at
    // 340px so the right column stays ~155px wide.
    //
    // Horizontal inset and vertical gap are owned by the parent — see
    // `_pad` / `_gap` in `_DiscoverSchoolHomeScreenState.build`.
    return CommonCardWidget(
      padding: 0,
      cardMargin: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.paddingS,
                  vertical: SizeConfig.paddingXS),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: CustomText(
                      AppStrings.coursesLabel.tr,
                      fontSize: SizeConfig.size18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black22,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (courses.length > 1)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openAllCoursesSheet(context, courses),
                      child: CustomText(
                        AppStrings.viewAll.tr,
                        fontSize: SizeConfig.size14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                ],
              ),
            ),
            // 240px covers the tallest natural card height: 165px image +
            // 16px card padding + slack for a card whose right column runs
            // longer than the image (title + fee + 2-line description +
            // chips + divider + admission pill). Bumped from 210 after a
            // 4px overflow on cards with the admission pill visible.
            // Align each card to top so shorter cards don't stretch.
            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: courses.length,
                separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size10),
                itemBuilder: (_, i) => SizedBox(
                  width: 340,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SchoolCourseListItemCard(
                      course: courses[i],
                      showBorder: true,
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

  /// Full-screen list of every course on the school, stacked vertically.
  /// Shown when the user taps "View All" on the horizontal rail. Same
  /// [SchoolCourseListItemCard] as the rail — only the layout changes.
  void _openAllCoursesSheet(BuildContext context, List<Courses> courses) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.paddingS,
                vertical: SizeConfig.paddingXS,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(
                      AppStrings.coursesLabel.tr,
                      fontSize: SizeConfig.size18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black22,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: EdgeInsets.all(SizeConfig.paddingS),
                itemCount: courses.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: SizeConfig.size10),
                itemBuilder: (_, i) => SchoolCourseListItemCard(
                  course: courses[i],
                  showBorder: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GALLERY SECTION (social-style grid using SocialGalleryGrid)
// ─────────────────────────────────────────────────────────────────────────────
class _GallerySection extends StatelessWidget {
  final SchoolDetailsData? data;
  const _GallerySection({required this.data});

  @override
  Widget build(BuildContext context) {
    final campusLife = data?.campusLife ?? [];
    final List<String> allImages = [];
    for (var item in campusLife) {
      for (var img in item.images ?? []) {
        if (img.url != null) allImages.add(img.url!);
      }
    }

    if (allImages.isEmpty) {
      return _emptySection(
        Icons.photo_library_outlined,
        AppStrings.gallery.tr,
        AppStrings.noPhotosAvailableMsg.tr,
      );
    }

    return CommonCardWidget(
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.photo_library_outlined, AppStrings.gallery.tr),
          SizedBox(height: SizeConfig.paddingXS),
          SocialGalleryGrid(imageUrls: allImages),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JOB VACANCY LINK — the only quick-link kept for the public detail view.
// Academics / Student Corner / Notices were dropped per product ask.
// ─────────────────────────────────────────────────────────────────────────────
class _JobVacancyLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CommonCardWidget(
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.work_outline, AppStrings.jobVacancy.tr),
          SizedBox(height: SizeConfig.paddingXS),
          InkWell(
            onTap: () => Get.to(() => SchoolJobListingScreen(isEdit: false)),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: SizeConfig.paddingS),
              child: Row(
                children: [
                  Icon(Icons.work_outline,
                      size: SizeConfig.size20, color: AppColors.primaryColor),
                  SizedBox(width: SizeConfig.paddingXS),
                  Expanded(
                    child: CustomText(
                      AppStrings.jobVacancy.tr,
                      fontSize: SizeConfig.size14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: SizeConfig.size16,
                      color: AppColors.secondaryTextColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

Widget _sectionHeader(IconData icon, String title) {
  return Row(
    children: [
      Icon(icon, color: AppColors.primaryColor, size: SizeConfig.size20),
      SizedBox(width: SizeConfig.paddingXS),
      ServiceHomeTitleWidget(title: title),
    ],
  );
}

/// Empty-state card. Horizontal padding is applied by the parent
/// (`_pad` in `_DiscoverSchoolHomeScreenState.build`) so the empty and
/// populated variants of every section land at the exact same inset —
/// otherwise gaps between cards jump when data drops out.
Widget _emptySection(IconData icon, String title, String message) {
  return CommonCardWidget(
    cardMargin: 0,
    child: Column(
      children: [
        _sectionHeader(icon, title),
        SizedBox(height: SizeConfig.paddingM),
        EmptyStateWidget(
          message: message,
          imageSize: SizeConfig.size60,
        ),
        SizedBox(height: SizeConfig.paddingS),
      ],
    ),
  );
}

/// Convert `education-service/schools/{id}` (and `.../timings`) rows
/// (`{day, isOpen, openTime, closeTime}`) into the `List<Schedule>` shape
/// `BusinessAvailabilityWidget` renders inside `VisitBusinessHero`.
/// School rows use `openTime`/`closeTime`; the widget reads
/// `timeSlots[0].startTime/endTime`, so we mint a single-slot entry per
/// open day. Returns null when the school hasn't published timings, so
/// the hero falls back to the user-service availability document.
List<avail.Schedule>? _schoolTimingsToSchedule(List<Availability>? timings) {
  if (timings == null || timings.isEmpty) return null;
  final out = <avail.Schedule>[];
  for (final t in timings) {
    if (t.isOpen != true) continue;
    final open = t.openTime;
    final close = t.closeTime;
    if ((open == null || open.isEmpty) && (close == null || close.isEmpty)) {
      continue;
    }
    out.add(avail.Schedule(
      day: t.day,
      isOpen: true,
      shopOpenTime: open,
      shopCloseTime: close,
      timeSlots: [avail.TimeSlots(startTime: open, endTime: close)],
    ));
  }
  return out;
}
