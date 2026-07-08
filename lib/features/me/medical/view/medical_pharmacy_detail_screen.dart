import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/medical/model/medical_home_response_model.dart';
import 'package:BlueEra/features/me/medical/repo/medical_repo.dart';
import 'package:BlueEra/features/me/medical/widget/healthcare_enquiry_sheet.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/features/me/medical/view/medical_inventory_category_screen.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/service/profile_click_tracker.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/visit_business_common_header.dart';
import 'package:BlueEra/widgets/visit_business_stats_card.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:BlueEra/widgets/social_gallery_grid.dart';
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
  MedicalHomeResponseModel? _data;
  bool _isLoading = true;

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
    if (_isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_data == null) {
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

    final profile = _data!.businessProfile;
    final inventory = _data!.inventorySummary;
    final popularProducts = inventory?.popularProducts ?? [];
    final categoriesWithProducts = inventory?.categoriesWithProducts ?? [];

    return Scaffold(
      appBar: CommonBackAppBar(title: profile?.businessName ?? AppStrings.pharmacy.tr),
      bottomNavigationBar: _buildEnquiryBottomBar(profile),
      body: RefreshIndicator(
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
                    .visitedBusinessProfileDetails
                    ?.data;
                return VisitBusinessCommonHeader(
                  details: details,
                  onRated: () =>
                      viewBusinessDetailsController.viewBusinessProfileById(
                    widget.businessId,
                    silent: true,
                  ),
                  onFollowChanged: () =>
                      viewBusinessDetailsController.viewBusinessProfileById(
                    widget.businessId,
                    silent: true,
                  ),
                );
              }),
              SizedBox(height: SizeConfig.size10),
              _buildUploadPrescriptionCard(),
              SizedBox(height: SizeConfig.size10),
              Obx(() {
                viewBusinessDetailsController.profileVersion.value;
                return VisitBusinessStatsCard(
                  details: viewBusinessDetailsController
                      .visitedBusinessProfileDetails
                      ?.data,
                );
              }),
              SizedBox(height: SizeConfig.size10),

              // Website preview
              if (profile?.websiteUrl != null &&
                  profile!.websiteUrl!.isNotEmpty) ...[
                _buildWebsitePreview(profile.websiteUrl!),
                SizedBox(height: SizeConfig.size10),
              ],

              if (popularProducts.isNotEmpty) ...[
                _buildPopularProducts(popularProducts),
                SizedBox(height: SizeConfig.size10),
              ],

              if (categoriesWithProducts.isNotEmpty) ...[
                _buildMedicalProductCategories(categoriesWithProducts),
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
                    .visitedBusinessProfileDetails
                    ?.data;
                return BusinessContactMapCard(
                  businessProfileDetails: details,
                  showEditButton: false,
                );
              }),
              SizedBox(height: kBottomNavigationBarHeight + 30),
            ],
          ),
        ),
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
                    onTap: () => Get.to(
                        () => CommonWebView(urlLink: url, urlTitle: AppStrings.websiteLabel.tr)),
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
  Widget _buildPopularProducts(List<PopularProduct> products) {
    final showViewMore = products.length > 5;
    final displayList = showViewMore ? products.sublist(0, 5) : products;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        padding: 10,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: ServiceHomeTitleWidget(
                        title: AppStrings.popularMedicalProducts.tr)),
                if (showViewMore)
                  CustomText(AppStrings.viewAllLabel,
                      fontSize: SizeConfig.small,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600),
              ],
            ),
            SizedBox(height: SizeConfig.size10),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: displayList.length,
                separatorBuilder: (_, __) =>
                    SizedBox(width: SizeConfig.size10),
                itemBuilder: (_, i) => _popularProductCard(displayList[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _popularProductCard(PopularProduct item) {
    final productName =
        item.product?.name ?? item.variant?.variantName ?? AppStrings.productParcel.tr;
    final imageUrl = item.product?.images?.firstOrNull?.url ??
        item.variant?.images?.firstOrNull?.url;
    final mrp =
        item.batches?.mrp ?? item.variant?.pricing?.firstOrNull?.mrp;
    final sellingPrice = item.batches?.sellingPrice ??
        item.variant?.pricing?.firstOrNull?.sellingPrice;
    final discount = (mrp != null && sellingPrice != null && mrp > 0)
        ? (((mrp - sellingPrice) / mrp) * 100).toInt()
        : 0;

    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 90,
            width: double.infinity,
            child: _networkImage(imageUrl, BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(productName,
                      fontSize: 11,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w600),
                  Spacer(),
                  Row(
                    children: [
                      if (sellingPrice != null || mrp != null)
                        CustomText('â‚¹${sellingPrice ?? mrp}',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mainTextColor),
                      if (discount > 0) ...[
                        SizedBox(width: 4),
                        CustomText('$discount% off',
                            fontSize: 9,
                            color: AppColors.green00,
                            fontWeight: FontWeight.w600),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // CATEGORIES â€” Only with products, View More if > 6
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const List<Map<String, String>> _staticCategories = [
    {'title': 'Ayurveda &\nNutrition', 'key': 'AYURVEDA___NUTRITION', 'image': 'assets/category/medical/AyurvedaNutrition.png'},
    {'title': 'Home &\nPatient Care', 'key': 'HOME___PATIENT_CARE', 'image': 'assets/category/medical/Home_Patient_Care.png'},
    {'title': 'Medical\nDevices', 'key': 'MEDICAL_DEVICES', 'image': 'assets/category/medical/Medical_Devices.png'},
    {'title': 'OTC\nMedicines', 'key': 'OTC_MEDICINES', 'image': 'assets/category/medical/OTC_Medicines.png'},
    {'title': 'Personal\n& Baby Care', 'key': 'PERSONAL___BABY_CARE', 'image': 'assets/category/medical/Personal_Baby_Care.png'},
    {'title': 'Wound Care\n& First Aid', 'key': 'WOUND_CARE___FIRST_AID', 'image': 'assets/category/medical/Wound_Care_First_Aid.png'},
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
          title: apiCat.name?.replaceAll('_', ' ') ?? AppStrings.parcelCategory.tr,
          image: '',
          category: apiCat,
        ));
      }
    }

    if (activeCats.isEmpty) return const SizedBox.shrink();

    final showViewMore = activeCats.length > 6;
    final displayList =
        showViewMore ? activeCats.sublist(0, 6) : activeCats;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        padding: 12,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child:
                        ServiceHomeTitleWidget(title: AppStrings.medicalProducts.tr)),
                if (showViewMore)
                  CustomText(AppStrings.viewAllLabel,
                      fontSize: SizeConfig.small,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600),
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: displayList.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: SizeConfig.size10,
                mainAxisSpacing: SizeConfig.size10,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final item = displayList[index];
                final productCount = item.category.getAllProducts().length;
                return _productCategoryCard(item, productCount);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCategoryCard(_CategoryDisplay item, int productCount) {
    return InkWell(
      onTap: () {
        if (item.category.children != null &&
            item.category.children!.isNotEmpty) {
          Get.to(() => MedicalInventoryCategoryScreen(
                title: item.title,
                children: item.category.children!,
              ));
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.whiteF3,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.image.isNotEmpty)
              Image.asset(item.image,
                  width: 44, height: 44, fit: BoxFit.contain)
            else
              Icon(Icons.medical_services_outlined,
                  size: 44, color: AppColors.primaryColor),
            SizedBox(height: 4),
            CustomText(item.title,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                color: Colors.blueGrey.shade700),
            SizedBox(height: 2),
            CustomText('$productCount ${AppStrings.productsCountLabel.tr}',
                fontSize: 9,
                color: AppColors.green00,
                fontWeight: FontWeight.w600),
          ],
        ),
      ),
    );
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
      final livePhotos = details?.livePhotos
          ?.where((p) => p.trim().isNotEmpty)
          .toList();
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
            SizedBox(height: 12),
            SocialGalleryGrid(imageUrls: galleryImages),
          ],
        ),
      ),
    );
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
        child: Icon(Icons.image_outlined,
            color: Colors.grey.shade400, size: 40),
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
