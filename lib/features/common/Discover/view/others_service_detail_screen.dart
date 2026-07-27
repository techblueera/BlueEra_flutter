import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/service/profile_click_tracker.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/features/me/others/widget/business_enquiry_sheet.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/visit_business_common_header.dart';
import 'package:BlueEra/widgets/visit_business_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constant.dart';
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
      appBar: CommonBackAppBar(),
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
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8,
            vertical: SizeConfig.size15,
          ),
          child: Column(
            children: [
              // ─── 1. Header + Business Stats ───
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
                return Column(
                  children: [
                    VisitBusinessCommonHeader(
                      details: details,
                      onRated: () =>
                          viewBusinessDetailsController.viewBusinessProfileById(
                        widget.visitUserId,
                        silent: true,
                      ),
                      onFollowChanged: () =>
                          viewBusinessDetailsController.viewBusinessProfileById(
                        widget.visitUserId,
                        silent: true,
                      ),
                      shareLink: serviceDeepLinkBusiness(
                        id: details?.userId,
                      ),
                    ),
                    const SizedBox(height: 10),
                    VisitBusinessStatsCard(details: details),
                  ],
                );
              }),

              // ─── 2. Live Photos ───
              Obx(() {
                if (viewBusinessDetailsController.isProfileLoading.value) {
                  return const SizedBox.shrink();
                }
                final details = viewBusinessDetailsController
                    .visitedBusinessProfileDetails?.data;
                if (details?.livePhotos != null &&
                    details!.livePhotos!.any((p) => p.trim().isNotEmpty)) {
                  return Padding(
                    padding: EdgeInsets.only(top: SizeConfig.paddingM),
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

              // ─── 3. Contact & Map ───
              Obx(() {
                if (viewBusinessDetailsController.isProfileLoading.value) {
                  return const SizedBox.shrink();
                }
                final details = viewBusinessDetailsController
                    .visitedBusinessProfileDetails?.data;
                return BusinessContactMapCard(
                  businessProfileDetails: details,
                  showEditButton: false,
                );
              }),

              // ─── 4. QR Code ───
              Obx(() {
                if (viewBusinessDetailsController.isProfileLoading.value) {
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
      ),
    );
  }
}
