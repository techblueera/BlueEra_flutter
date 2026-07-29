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
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/service/profile_click_tracker.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/features/me/medical/controller/medical_cart_controller.dart';
import 'package:BlueEra/features/me/medical/model/medical_home_response_model.dart';
import 'package:BlueEra/features/me/medical/model/medical_product_card_adapter.dart';
import 'package:BlueEra/features/me/medical/repo/medical_repo.dart';
import 'package:BlueEra/features/me/medical/view/all_popular_medical_products_screen.dart';
import 'package:BlueEra/features/me/medical/view/medical_category_products_screen.dart';
import 'package:BlueEra/features/me/medical/widget/healthcare_enquiry_sheet.dart';
import 'package:BlueEra/features/me/medical/widget/medical_floating_cart.dart';
import 'package:BlueEra/features/me/medical/widget/medical_product_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:BlueEra/widgets/social_gallery_grid.dart';
import 'package:BlueEra/widgets/visit_business_common_header.dart';
import 'package:BlueEra/widgets/visit_business_stats_card.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MedicalPharmacyDetailScreen extends StatefulWidget {
  final String businessId;

  const MedicalPharmacyDetailScreen({super.key, required this.businessId});

  @override
  State<MedicalPharmacyDetailScreen> createState() =>
      _MedicalPharmacyDetailScreenState();
}

class _MedicalPharmacyDetailScreenState
    extends State<MedicalPharmacyDetailScreen> {
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();
  final storeController = getOrPut(() => StoreController());
  final medicalCart = getOrPut(() => MedicalCartController(), permanent: true);
  MedicalHomeResponseModel? _data;
  bool _isLoading = true;

  /// Cards shown in the popular rail before "View All" takes over. Matches
  /// grocery's `businessProductsPreviewLimit`.
  static const int _kPopularPreviewLimit = 5;

  /// Category nodes carry no image, so any category outside [_staticCategories]
  /// falls back to this.
  static const String _kCategoryFallbackIcon =
      'assets/category/medical/health_pharmacy.png';

  @override
  void initState() {
    super.initState();
    final id = widget.businessId;
    if (id.isNotEmpty) {
      viewBusinessDetailsController.viewBusinessProfileById(id);
      ProfileClickTracker.track(
        userId: id,
        source: ChatClickSource.storeDetail,
      );
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final res = await MedicalRepo()
          .fetchMedicalProfileFd(businessId: widget.businessId);
      if (res.isSuccess && res.response?.data != null) {
        final data = res.response?.data['data'] ?? res.response?.data;
        if (data != null && data is Map<String, dynamic>) {
          if (mounted) {
            setState(() => _data = MedicalHomeResponseModel.fromJson(data));
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching pharmacy profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Pull-to-refresh handler — re-hydrates both the shared business
  /// profile (VisitBusinessStatsCard reads from it) and the pharmacy
  /// inventory in parallel. Mirrors the grocery store screen's refresh.
  Future<void> _refresh() async {
    final id = widget.businessId;
    if (id.isEmpty) return;
    viewBusinessDetailsController.viewBusinessProfileById(id);
    await _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    // Only a *failed* fetch gets the full-page fallback. While loading, the page
    // renders immediately and each section shows its own shimmer — the same
    // pattern the grocery store screen uses, so the two behave identically
    // instead of pharmacy blocking on a full-screen spinner.
    if (!_isLoading && _data == null) {
      return Scaffold(
        appBar: CommonBackAppBar(title: AppStrings.pharmacy),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront_outlined,
                  size: 64, color: Colors.grey.shade300),
              SizedBox(height: 12),
              CustomText(AppStrings.pharmacyDetailsNotAvailable,
                  fontSize: SizeConfig.large,
                  color: AppColors.secondaryTextColor),
            ],
          ),
        ),
      );
    }

    // Null while the inventory fetch is in flight — the sections below show
    // skeletons until it lands.
    final profile = _data?.businessProfile;
    final inventory = _data?.inventorySummary;
    final popularProducts = inventory?.popularProducts ?? [];
    final categoriesWithProducts = inventory?.categoriesWithProducts ?? [];

    return Scaffold(
      appBar: CommonBackAppBar(
          title: profile?.businessName ?? AppStrings.pharmacy.tr),
      // The cart lives in this Stack rather than `bottomNavigationBar` so its
      // expandable panel can rise *over* the page content — a bottomNavigationBar
      // slot is sized to its child and would clip the panel / shove the page up.
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shared profile header — same one grocery uses. Handles
                  // banner, logo, name, rating, follow/share/rate actions.
                  // Wrapped in Obx so silent profile refreshes (rating, follow)
                  // rebuild without a full page reload.
                  Obx(() {
                    viewBusinessDetailsController.profileVersion.value;
                    if (viewBusinessDetailsController.isProfileLoading.value) {
                      return buildBusinessHeaderSkeleton();
                    }
                    final details = viewBusinessDetailsController
                        .visitedBusinessProfileDetails?.data;
                    return Padding(
                      padding: EdgeInsets.all(SizeConfig.size12),
                      child: VisitBusinessCommonHeader(
                        details: details,
                        onRated: () => viewBusinessDetailsController
                            .viewBusinessProfileById(
                          widget.businessId,
                          silent: true,
                        ),
                        onFollowChanged: () => viewBusinessDetailsController
                            .viewBusinessProfileById(
                          widget.businessId,
                          silent: true,
                        ),
                      ),
                    );
                  }),
                  // SizedBox(height: SizeConfig.size10),
                  _buildUploadPrescriptionCard(),
                  SizedBox(height: SizeConfig.size10),
                  Obx(() {
                    viewBusinessDetailsController.profileVersion.value;
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                      child: VisitBusinessStatsCard(
                        details: viewBusinessDetailsController
                            .visitedBusinessProfileDetails?.data,
                      ),
                    );
                  }),
                  SizedBox(height: SizeConfig.size10),

                  // Website preview
                  if (profile?.websiteUrl != null &&
                      profile!.websiteUrl!.isNotEmpty) ...[
                    _buildWebsitePreview(profile.websiteUrl!),
                    SizedBox(height: SizeConfig.size10),
                  ],

                  // Popular rail + category grid — same section language as the
                  // grocery store screen, each independently swapping its own
                  // shimmer for content. Both supply their own CustomFormCard,
                  // so only the page inset is applied here.
                  if (_isLoading) ...[
                    buildHorizontalListSkeleton(),
                    SizedBox(height: SizeConfig.size10),
                  ] else if (popularProducts.isNotEmpty) ...[
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                      child: _buildPopularProducts(popularProducts),
                    ),
                    SizedBox(height: SizeConfig.size10),
                  ],

                  if (_isLoading) ...[
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                      child: buildCategoryGridSkeleton(),
                    ),
                    SizedBox(height: SizeConfig.size10),
                  ] else if (categoriesWithProducts.isNotEmpty) ...[
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                      child: _buildMedicalProductCategories(
                          categoriesWithProducts),
                    ),
                    SizedBox(height: SizeConfig.size10),
                  ],

                  // Live Photos — mirrors the grocery store screen; sourced
                  // from the shared business profile so the section shows up
                  // as soon as the profile fetch completes.
                  _buildLivePhotosSection(),

                  _buildGallerySection(),

                  // Unified contact + map card — same widget grocery uses.
                  Obx(() {
                    if (viewBusinessDetailsController.isProfileLoading.value) {
                      return const SizedBox.shrink();
                    }
                    final details = viewBusinessDetailsController
                        .visitedBusinessProfileDetails?.data;
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                      child: BusinessContactMapCard(
                        businessProfileDetails: details,
                        showEditButton: false,
                      ),
                    );
                  }),
                  // Clears the floating cart / enquiry bar stacked over the page.
                  SizedBox(height: kBottomNavigationBarHeight + 30),
                ],
              ),
            ),
          ),
          // Floating cart when the cart has items, else the Send Enquiry CTA —
          // pinned to the bottom of the Stack, floating over the content.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(profile) ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // UPLOAD PRESCRIPTION
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildUploadPrescriptionCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        padding: 12,
        cardMargin: 0,
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.description_outlined,
                  color: AppColors.primaryColor, size: 28),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(AppStrings.uploadPrescription,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor),
                  SizedBox(height: 2),
                  CustomText(AppStrings.scheduleYourVisitEasily,
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor),
                ],
              ),
            ),
            InkWell(
              onTap: () async {
                final path =
                    await CommonImageUploadTile.pickImage(context: context);
                if (path != null && path.isNotEmpty) {
                  commonSnackBar(
                      message: AppStrings.prescriptionUploadedSuccessfully.tr);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.greyE5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt_outlined,
                        size: 16, color: AppColors.mainTextColor),
                    SizedBox(width: 6),
                    CustomText(AppStrings.uploadLabel,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mainTextColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // WEBSITE PREVIEW
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildWebsitePreview(String url) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        padding: 0,
        cardMargin: 0,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 12, right: 12, top: 10),
              child: Row(
                children: [
                  Icon(Icons.language, size: 16, color: AppColors.primaryColor),
                  SizedBox(width: 6),
                  Expanded(
                    child: CustomText(url,
                        fontSize: SizeConfig.small,
                        color: AppColors.primaryColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  InkWell(
                    onTap: () => Get.to(() => CommonWebView(
                        urlLink: url, urlTitle: AppStrings.websiteLabel.tr)),
                    child: CustomText(AppStrings.visitLabel,
                        fontSize: SizeConfig.small,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: AbsorbPointer(
                child:
                    CommonWebView(urlLink: url, urlTitle: '', hideAppBar: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // POPULAR PRODUCTS â€” View More if > 5
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Popular rail — mirrors grocery's `_topSellingProduct()`: same CustomFormCard,
  /// same title + working View All, same 265-high rail of 150-wide bordered
  /// cards.
  Widget _buildPopularProducts(List<PopularProduct> products) {
    final previewList = products.length > _kPopularPreviewLimit
        ? products.sublist(0, _kPopularPreviewLimit)
        : products;
    final ctx = _businessCtxFor(_data?.businessProfile);

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      color: AppColors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(AppStrings.popularMedicalProducts.tr,
                    fontSize: SizeConfig.large,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(width: SizeConfig.size8),
              if (ctx != null)
                InkWell(
                  onTap: () => Get.to(() => AllPopularMedicalProductsScreen(
                        products: products,
                        businessCtx: ctx,
                      )),
                  child: CustomText(AppStrings.groceryViewViewAll.tr,
                      fontSize: SizeConfig.medium,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600),
                ),
            ],
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          SizedBox(
            height: 265,
            child: ListView.builder(
              itemCount: previewList.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 8),
                // topCenter so the min-height card doesn't stretch to fill the
                // rail's 265 and leave a gap under the ADD button.
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: SizeConfig.size150,
                    // Outer border so the white card reads against the
                    // section's white background.
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.greyE5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _popularProductCard(previewList[index]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Business context passed to every product card so cart lines carry
  /// enough info for the cart screen (name, logo, address, coords) without
  /// a re-fetch. Always buildable — `widget.businessId` is guaranteed
  /// non-empty on this screen, so we never return null just because the
  /// business profile hasn't populated yet. Profile fields fill in only
  /// when available.
  MedicalCartBusiness? _businessCtxFor(BusinessProfile? profile) {
    final id = (profile?.id ?? widget.businessId).trim();
    if (id.isEmpty) return null;
    return MedicalCartBusiness(
      businessId: id,
      businessName: profile?.businessName ?? AppStrings.pharmacy.tr,
      logo: profile?.logo,
      address: profile?.address ?? profile?.cityStatePincode,
      lat: profile?.businessLocation?.lat,
      lng: profile?.businessLocation?.lon,
      category: profile?.typeOfBusiness,
    );
  }

  Widget _popularProductCard(PopularProduct item) {
    //
    // final productName = item.product?.name ?? item.variant?.variantName ?? AppStrings.productParcel.tr;
    // final imageUrl = item.product?.images?.firstOrNull?.url ?? item.variant?.images?.firstOrNull?.url;
    // final mrp = item.batches?.mrp ?? item.variant?.pricing?.firstOrNull?.mrp;
    // final sellingPrice = item.batches?.sellingPrice ?? item.variant?.pricing?.firstOrNull?.sellingPrice;
    // final discount =
    // (mrp != null && sellingPrice != null && mrp > 0) ? (((mrp - sellingPrice) / mrp) * 100).toInt() : 0;
    //
    // return Container(
    //     width: 140,
    //     decoration: BoxDecoration(
    //       color: Colors.white,
    //       borderRadius: BorderRadius.circular(10),
    //       border: Border.all(color: Colors.grey.shade200),
    //     ),
    //     clipBehavior: Clip.hardEdge,
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //       SizedBox(
    //       height: 90,
    //       width: double.infinity,
    //       child: _networkImage(imageUrl, BoxFit.cover),
    //     ),
    //     Expanded(
    //         child: Padding(
    //           padding: const EdgeInsets.all(8),
    //           child: Column(
    //             crossAxisAlignment: CrossAxisAlignment.start,
    //             children: [
    //               CustomText(productName,
    //                   fontSize: 11,
    //                   maxLines: 2,
    //                   overflow: TextOverflow.ellipsis,
    //                   fontWeight: FontWeight.w600),
    //               Spacer(),
    //               Row(
    //                 children: [
    //                   if (sellingPrice != null || mrp != null)
    //                     CustomText('₹${sellingPrice ?? mrp}',
    //                         fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.mainTextColor),
    //                   if (discount > 0) ...[
    //                     SizedBox(width: 4),
    //                     CustomText('$discount% off',
    //                         fontSize: 9, color: AppColors.green00, fontWeight: FontWeight.w600),
    //                   ],
    //                 ],
    //               ),
    //             ],
    //           ),
    //         ),
    final ctx = _businessCtxFor(_data?.businessProfile);
    final card = item.toCardProduct();
    if (ctx == null || card == null) {
      debugPrint(
          '[MedicalPharmacy] static tile fallback for "${item.product?.name}" — '
          'ctx=${ctx == null ? 'null' : 'ok'} card=${card == null ? 'null' : 'ok'}');
      return _staticProductTile(item);
    }
    return MedicalProductCard(product: card, businessCtx: ctx);
  }

  Widget _staticProductTile(PopularProduct item) {
    final productName = item.product?.name ??
        item.variant?.variantName ??
        AppStrings.productParcel.tr;
    final imageUrl = item.product?.images?.firstOrNull?.url ??
        item.variant?.images?.firstOrNull?.url;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.hardEdge,
      // mainAxisSize.min so the tile hugs its content — otherwise the parent
      // rail's tight height stretches this Column and leaves blank space.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              height: 140,
              width: double.infinity,
              child: _networkImage(imageUrl, BoxFit.contain)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: CustomText(productName,
                fontSize: SizeConfig.small,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // CATEGORIES â€” Only with products, View More if > 6
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const List<Map<String, String>> _staticCategories = [
    {
      'title': 'Ayurveda &\nNutrition',
      'key': 'AYURVEDA___NUTRITION',
      'image': 'assets/category/medical/AyurvedaNutrition.png'
    },
    {
      'title': 'Home &\nPatient Care',
      'key': 'HOME___PATIENT_CARE',
      'image': 'assets/category/medical/Home_Patient_Care.png'
    },
    {
      'title': 'Medical\nDevices',
      'key': 'MEDICAL_DEVICES',
      'image': 'assets/category/medical/Medical_Devices.png'
    },
    {
      'title': 'OTC\nMedicines',
      'key': 'OTC_MEDICINES',
      'image': 'assets/category/medical/OTC_Medicines.png'
    },
    {
      'title': 'Personal\n& Baby Care',
      'key': 'PERSONAL___BABY_CARE',
      'image': 'assets/category/medical/Personal_Baby_Care.png'
    },
    {
      'title': 'Wound Care\n& First Aid',
      'key': 'WOUND_CARE___FIRST_AID',
      'image': 'assets/category/medical/Wound_Care_First_Aid.png'
    },
  ];

  static String _normalizeKey(String key) =>
      key.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  Widget _buildMedicalProductCategories(
      List<CategoryWithProducts> apiCategories) {
    final activeCats = <_CategoryDisplay>[];
    for (final sc in _staticCategories) {
      final staticNorm = _normalizeKey(sc['key']!);
      final match = apiCategories.cast<CategoryWithProducts?>().firstWhere(
            (c) => c?.key != null && _normalizeKey(c!.key!) == staticNorm,
            orElse: () => null,
          );
      if (match != null && match.hasProducts) {
        activeCats.add(_CategoryDisplay(
          title: sc['title']!.replaceAll('\n', ' '),
          image: sc['image']!,
          category: match,
        ));
      }
    }
    for (final apiCat in apiCategories) {
      if (!apiCat.hasProducts || apiCat.key == null) continue;
      final apiNorm = _normalizeKey(apiCat.key!);
      final alreadyAdded =
          activeCats.any((a) => _normalizeKey(a.category.key ?? '') == apiNorm);
      if (!alreadyAdded) {
        activeCats.add(_CategoryDisplay(
          title:
              apiCat.name?.replaceAll('_', ' ') ?? AppStrings.parcelCategory.tr,
          image: '',
          category: apiCat,
        ));
      }
    }

    // Mirrors grocery's `_categoryWithInventoryWidget()`: same CustomFormCard,
    // title, and 3-up masonry of CommonServiceCard. No "View All" and no 6-cap
    // — grocery shows every category, and the masonry grows to fit.
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(AppStrings.medicalProducts.tr,
              fontSize: SizeConfig.large,
              color: AppColors.mainTextColor,
              fontWeight: FontWeight.w600),
          SizedBox(height: SizeConfig.paddingXSL),
          activeCats.isNotEmpty
              ? MasonryGridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  padding: EdgeInsets.zero,
                  // Required — this sits inside the page's SingleChildScrollView.
                  primary: false,
                  shrinkWrap: true,
                  itemCount: activeCats.length,
                  itemBuilder: (context, index) {
                    final item = activeCats[index];
                    return CommonServiceCard<_CategoryDisplay>(
                      service: item,
                      getName: (c) => c.title,
                      // Local asset for the six known categories; anything the
                      // backend adds falls back to the pharmacy placeholder,
                      // since category nodes carry no image.
                      getIcon: (c) =>
                          c.image.isNotEmpty ? c.image : _kCategoryFallbackIcon,
                      iconHeight: SizeConfig.size60,
                      onTap: (c) => _openCategory(c),
                    );
                  },
                )
              : EmptyStateWidget(
                  message: AppStrings.groceryViewNoProductsYet.trParams({
                    'name': _data?.businessProfile?.businessName ?? '',
                  }),
                ),
        ],
      ),
    );
  }

  /// Category tap → the grocery-style browser (left sub-category rail, tabs,
  /// 2-col product grid). A category with products but no children would be a
  /// dead tap there, so it's wrapped in a synthetic single-row rail.
  void _openCategory(_CategoryDisplay item) {
    final ctx = _businessCtxFor(_data?.businessProfile);
    if (ctx == null) return;
    final children = item.category.children ?? const <CategoryWithProducts>[];
    Get.to(() => MedicalCategoryProductsScreen(
          title: item.title,
          children: children.isNotEmpty ? children : [item.category],
          businessCtx: ctx,
        ));
  }

  // ─────────────────────────────────────────────────────────────────────
  // LIVE PHOTOS — recent activity photos published on the business
  // profile. Ported from `visit_grocery_store_screen.dart` so pharmacy
  // detail carries the same section language across services.
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildLivePhotosSection() {
    return Obx(() {
      if (viewBusinessDetailsController.isProfileLoading.value) {
        return const SizedBox.shrink();
      }
      final details =
          viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
      final livePhotos =
          details?.livePhotos?.where((p) => p.trim().isNotEmpty).toList();
      if (livePhotos == null || livePhotos.isEmpty) {
        return const SizedBox.shrink();
      }
      final natureOfBusiness = details?.subCategoryDetails?.name ??
          details?.natureOfBusiness ??
          'OTHER';
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: CommonCardWidget(
          padding: 10,
          cardMargin: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                AppStrings.groceryViewLivePhotos.tr,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 10),
              StoreLivePhotoWidget(
                livePhotos: livePhotos,
                natureOfBusiness: natureOfBusiness,
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
    });
  }

  // ─────────────────────────────────────────────────────────────────────
  // GALLERY — Social style (SocialGalleryGrid)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildGallerySection() {
    final galleryImages = <String>[];
    if (_data?.gallery != null) {
      for (final item in _data!.gallery!) {
        if (item is Map<String, dynamic>) {
          final urls = item['imageUrls'] as List?;
          if (urls != null) {
            for (final u in urls) {
              if (u is String && u.isNotEmpty) galleryImages.add(u);
            }
          }
        } else if (item is String && item.isNotEmpty) {
          galleryImages.add(item);
        }
      }
    }

    if (galleryImages.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        padding: 10,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServiceHomeTitleWidget(title: AppStrings.gallery),
            SizedBox(height: SizeConfig.size12),
            SocialGalleryGrid(imageUrls: galleryImages),
          ],
        ),
      ),
    );
  }

  /// Reactive bottom bar: shows the floating cart summary when items are
  /// present, otherwise falls back to the Send Enquiry CTA. Both are hidden
  /// on the owner's own listing (the enquiry endpoint would reject a
  /// self-enquiry with 400, and the cart won't have a valid checkout target).
  Widget? _buildBottomBar(BusinessProfile? profile) {
    final enquiryBar = _buildEnquiryBottomBar(profile);
    // Owner's own listing → hide both (enquiryBar returns SizedBox.shrink()).
    if (enquiryBar is SizedBox) return enquiryBar;
    return Obx(() {
      // ignore: unused_local_variable
      final _ = medicalCart.cartQuantities.length;
      if (medicalCart.isNotEmpty) {
        return MedicalFloatingCart(controller: medicalCart);
      }
      return enquiryBar ?? const SizedBox.shrink();
    });
  }

  /// Sticky bottom CTA — opens the unified healthcare-enquiry sheet for
  /// this pharmacy listing. Hidden when viewing your own listing (the
  /// server would reject an enquiry against yourself with 400 anyway).
  /// Routes through the non-hospital business endpoint with category
  /// PHARMACY — see lib/docs/healthcare-enquiry-ui-integration.md.
  Widget? _buildEnquiryBottomBar(BusinessProfile? profile) {
    final ownerId = (profile?.userId ?? '').trim();
    if (ownerId.isEmpty) return null;
    // Hide the CTA on the owner's own listing.
    if (ownerId == userId) return const SizedBox.shrink();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size10,
        ),
        child: PositiveCustomBtn(
          onTap: () => _openPharmacyEnquirySheet(profile),
          title: AppStrings.sendEnquiryLabel.tr,
        ),
      ),
    );
  }

  void _openPharmacyEnquirySheet(BusinessProfile? profile) {
    final ownerId = (profile?.userId ?? '').trim();
    final listingId = widget.businessId.trim();
    if (ownerId.isEmpty || listingId.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    HealthcareEnquirySheet.open(
      context,
      category: 'PHARMACY',
      listing: HealthcareEnquiryListing(
        listingId: listingId,
        ownerId: ownerId,
        ownerName: (profile?.businessName ?? AppStrings.pharmacy.tr).trim(),
        listingName: (profile?.businessName ?? AppStrings.pharmacy.tr).trim(),
        listingImage: profile?.logo,
        location: profile?.cityStatePincode,
      ),
    );
  }

  Widget _networkImage(String? url, BoxFit fit) {
    if (url == null || url.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child:
            Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 40),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) => Container(color: Colors.grey.shade200),
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.broken_image_outlined,
            color: Colors.grey.shade400, size: 40),
      ),
    );
  }
}

class _CategoryDisplay {
  final String title;
  final String image;
  final CategoryWithProducts category;

  _CategoryDisplay({
    required this.title,
    required this.image,
    required this.category,
  });
}
