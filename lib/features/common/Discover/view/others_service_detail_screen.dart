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
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/common/service/view/service_details_view_screen.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/features/me/others/widget/business_enquiry_sheet.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
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
      body: RefreshIndicator(
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
