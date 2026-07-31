import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/service/profile_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/controller/other_service_business_search_controller.dart';
import 'package:BlueEra/features/common/Discover/model/other_service_business_search_res_model.dart';
import 'package:BlueEra/features/common/Discover/view/finance/finance_job_listing_screen.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/common/service/view/service_details_view_screen.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/features/me/others/widget/business_enquiry_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:BlueEra/widgets/visit_business_hero.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../business/widgets/business_qrcode_widget.dart';

class OthersServiceDetailScreen extends StatefulWidget {
  final String visitUserId;

  const OthersServiceDetailScreen({
    super.key,
    required this.visitUserId,
  });

  @override
  State<OthersServiceDetailScreen> createState() =>
      _OthersServiceDetailScreenState();
}

class _OthersServiceDetailScreenState extends State<OthersServiceDetailScreen> {
  final ViewBusinessDetailsController viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();

  @override
  void initState() {
    super.initState();
    // Load the visiting business profile and track the store-detail view
    // (same pattern as the grocery visit screen).
    viewBusinessDetailsController
        .viewBusinessProfileByIdIfNeeded(widget.visitUserId);
    viewBusinessDetailsController.fetchServices(
      visitBusinessId: widget.visitUserId,
    );
    ProfileClickTracker.track(
      userId: widget.visitUserId,
      source: ChatClickSource.storeDetail,
    );
  }

  /// Open the "other" business enquiry sheet. [details] is the loaded
  /// [BusinessProfileDetails] snapshot; its `categoryOfBusiness` is
  /// passed straight to the server-driven catalog
  /// (`GET /predefined-enquiry/{category}`) — supports the 4 Finance,
  /// 8 Find Services and 3 Automotive categories listed in
  /// `lib/docs/predefined-enquiry-ui-integration.md` §1.
  ///
  /// `listingId` must be the BusinessProfile._id (`details.id`) per the
  /// doc — not the owner's user id.
  void _openEnquirySheet(BusinessProfileDetails details) {
    final listingId = (details.id ?? '').trim();
    final ownerId = (details.userId ?? widget.visitUserId).trim();
    if (listingId.isEmpty || ownerId.isEmpty) return;
    BusinessEnquirySheet.open(
      context,
      category: (details.categoryOfBusiness ?? '').trim(),
      listing: BusinessEnquiryListing(
        listingId: listingId,
        ownerId: ownerId,
        ownerName: (details.businessName ?? '').trim(),
        listingName: (details.businessName ?? '').trim(),
        listingImage: details.logo,
        location: details.address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: Obx(() {
        // Subscribe to profile refreshes so the bar appears as soon as
        // the details load.
        viewBusinessDetailsController.profileVersion.value;
        final details =
            viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
        // Hide until the profile is loaded; also hide for the owner
        // viewing their own listing (matches the finance-detail pattern).
        if (details == null || details.userId == userId) {
          return const SizedBox.shrink();
        }
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: SizeConfig.paddingS,
              right: SizeConfig.paddingS,
              bottom: 15,
              top: 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: PositiveCustomBtn(
                    onTap: () => _openEnquirySheet(details),
                    title: AppStrings.inquiry,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      body: _buildBody(),
    );
  }

  /// Look up the current listing in the shared search controller by
  /// matching `profile.userId`. Returns null when the controller isn't
  /// registered (deep-link entry) or the item isn't in the current page —
  /// callers then skip the management / gallery sections.
  OtherServiceBusinessItem? _searchItem() {
    if (!Get.isRegistered<OtherServiceBusinessSearchController>()) return null;
    final ctrl = Get.find<OtherServiceBusinessSearchController>();
    for (final p in ctrl.profiles) {
      if ((p.profile?.userId ?? '') == widget.visitUserId) return p;
    }
    return null;
  }

  List<String> _flattenGallery(List<OtherGalleryItem>? galleryList) {
    final all = <String>[];
    for (final g in galleryList ?? const <OtherGalleryItem>[]) {
      for (final url in g.imageUrls) {
        if (url.trim().isNotEmpty) all.add(url);
      }
    }
    return all;
  }

  // ─── MANAGEMENT ────────────────────────────────────────────────────
  Widget _buildManagementSection(List<OtherManagementItem> members) {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.managementLabel),
          SizedBox(height: SizeConfig.size12),
          ...members.asMap().entries.map((entry) {
            final isLast = entry.key == members.length - 1;
            final m = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: m.imageUrl ?? '',
                      height: 64,
                      width: 64,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        height: 64,
                        width: 64,
                        color: Colors.grey[200],
                        child: Icon(Icons.person,
                            color: AppColors.secondaryTextColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          m.name ?? '',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((m.position ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: CustomText(
                              m.position ?? '',
                              fontSize: 12,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── JOBS ──────────────────────────────────────────────────────────
  Widget _buildJobsSection() {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.jobVacancy.tr),
          SizedBox(height: SizeConfig.size12),
          InkWell(
            onTap: () => Get.to(() => const FinanceJobListingScreen()),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.work_outline,
                      size: 20, color: AppColors.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomText(
                      AppStrings.jobVacancy.tr,
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── GALLERY ───────────────────────────────────────────────────────
  Widget _buildGallerySection(List<String> images) {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.gallery),
          SizedBox(height: SizeConfig.size12),
          if (images.isEmpty)
            EmptyStateWidget(
              message: AppStrings.noPhotosAvailableMsg.tr,
              imageSize: 60,
            )
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: images[index],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[300],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
        onRefresh: () async {
          viewBusinessDetailsController
              .viewBusinessProfileById(widget.visitUserId);
          viewBusinessDetailsController.fetchServices(
            visitBusinessId: widget.visitUserId,
          );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // ─── 1. Hero (edge-to-edge, includes overlay app-bar) ───
              Obx(() {
                // Subscribe to silent profile refreshes — bumps on every
                // successful fetch so this Obx rebuilds even when the
                // loader is skipped.
                viewBusinessDetailsController.profileVersion.value;
                if (viewBusinessDetailsController.isProfileLoading.value) {
                  return buildBusinessHeaderSkeleton();
                }
                final details = viewBusinessDetailsController
                    .visitedBusinessProfileDetails?.data;
                return VisitBusinessHero(
                  details: details,
                  scheduleOverride: _otherTimingsToSchedule(
                    _searchItem()?.timings,
                  ),
                  onFollowChanged: () =>
                      viewBusinessDetailsController.viewBusinessProfileById(
                    widget.visitUserId,
                    silent: true,
                  ),
                  onRated: () =>
                      viewBusinessDetailsController.viewBusinessProfileById(
                    widget.visitUserId,
                    silent: true,
                  ),
                );
              }),

              // ─── Sections below the hero share the horizontal gutter. ───
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
                child: Column(
                  children: [
                    // const SizedBox(height: 10),

                    // ─── 2. Live Photos ───
                    Obx(() {
                      if (viewBusinessDetailsController
                          .isProfileLoading.value) {
                        return const SizedBox.shrink();
                      }
                      final details = viewBusinessDetailsController
                          .visitedBusinessProfileDetails?.data;
                      if (details?.livePhotos != null &&
                          details!.livePhotos!
                              .any((p) => p.trim().isNotEmpty)) {
                        return Padding(
                          padding: EdgeInsets.only(top: SizeConfig.paddingXSL),
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
                                  livePhotos: details.livePhotos!
                                      .where((p) => p.trim().isNotEmpty)
                                      .toList(),
                                  natureOfBusiness:
                                      details.subCategoryDetails?.name ??
                                          details.natureOfBusiness ??
                                          'OTHER',
                                  onViewFullScreen: ({
                                    required int index,
                                    required List<String> storeImage,
                                    required String natureOfBusiness,
                                  }) {
                                    navigatePushTo(
                                      context,
                                      ImageViewScreen(
                                        appBarTitle: details.businessName ?? '',
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
                      }
                      return const SizedBox.shrink();
                    }),

                    // ─── 4. Services (horizontal) ───
                    Obx(() {
                      final services =
                          viewBusinessDetailsController.services.toList();
                      if (services.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(top: SizeConfig.paddingXSL),
                        child: CustomFormCard(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                AppStrings.services.tr,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              const SizedBox(height: 10),
                              _ServicesHorizontalList(services: services),
                            ],
                          ),
                        ),
                      );
                    }),

                    // ─── Management ───
                    // Sourced from the search-list item (not the profile
                    // response). Read reactively from the shared search
                    // controller so it appears once the list has loaded.
                    Obx(() {
                      final item = _searchItem();
                      if (item == null || item.management.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: EdgeInsets.only(top: SizeConfig.paddingXSL),
                        child: _buildManagementSection(item.management),
                      );
                    }),

                    // ─── Jobs ───
                    Padding(
                      padding: EdgeInsets.only(top: SizeConfig.paddingXSL),
                      child: _buildJobsSection(),
                    ),

                    // ─── Gallery ───
                    Obx(() {
                      final item = _searchItem();
                      final images = _flattenGallery(item?.gallery);
                      if (images.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(top: SizeConfig.paddingXSL),
                        child: _buildGallerySection(images),
                      );
                    }),

                    // ─── 5. Contact & Map ───
                    Obx(() {
                      if (viewBusinessDetailsController
                          .isProfileLoading.value) {
                        return const SizedBox.shrink();
                      }
                      final details = viewBusinessDetailsController
                          .visitedBusinessProfileDetails?.data;
                      return BusinessContactMapCard(
                        businessProfileDetails: details,
                        showEditButton: false,
                      );
                    }),

                    // ─── 6. QR Code ───
                    Obx(() {
                      if (viewBusinessDetailsController
                          .isProfileLoading.value) {
                        return const SizedBox.shrink();
                      }
                      final details = viewBusinessDetailsController
                          .visitedBusinessProfileDetails?.data;
                      return BusinessQrCodeWidget(data: details);
                    }),

                    SizedBox(height: SizeConfig.size100),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _ServicesHorizontalList extends StatelessWidget {
  final List<GetServiceModel> services;

  const _ServicesHorizontalList({required this.services});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final s = services[i];
          final firstPhoto =
              (s.photos?.isNotEmpty ?? false) ? s.photos!.first : '';
          return InkWell(
            onTap: () => Get.to(() => ServiceDetailsScreen(service: s)),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(10)),
                    child: SizedBox(
                      height: 100,
                      width: 160,
                      child: firstPhoto.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: firstPhoto,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  Container(color: Colors.grey[300]),
                              placeholder: (_, __) =>
                                  Container(color: Colors.grey[200]),
                            )
                          : Container(color: Colors.grey[300]),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          s.title ?? AppStrings.na,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        CustomText(
                          '₹${s.priceRange?.min ?? 0} - ₹${s.priceRange?.max ?? 0}',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Convert the other-service `/full` (also present on `/search`) timings
/// block (weekday-keyed `{isOpen, openTime, closeTime}`) into the
/// `List<Schedule>` shape [BusinessAvailabilityWidget] renders. Mirrors
/// `_financeTimingsToSchedule` in `finance_detail_screen.dart` — kept
/// separate because [OtherTimings] and [FinanceTimings] are distinct
/// types even though the payload shape matches.
List<Schedule>? _otherTimingsToSchedule(OtherTimings? t) {
  if (t == null) return null;
  const days = [
    ('Monday', 1),
    ('Tuesday', 2),
    ('Wednesday', 3),
    ('Thursday', 4),
    ('Friday', 5),
    ('Saturday', 6),
    ('Sunday', 7),
  ];
  final out = <Schedule>[];
  for (final entry in days) {
    final d = t.forWeekday(entry.$2);
    if (d == null || !d.hasHours) continue;
    out.add(Schedule(
      day: entry.$1,
      isOpen: true,
      shopOpenTime: d.openTime,
      shopCloseTime: d.closeTime,
      timeSlots: [TimeSlots(startTime: d.openTime, endTime: d.closeTime)],
    ));
  }
  return out;
}
