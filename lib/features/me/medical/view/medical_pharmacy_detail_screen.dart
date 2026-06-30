import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
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
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/service/profile_click_tracker.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/widgets/visit_business_stats_card.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:BlueEra/widgets/social_gallery_grid.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(profile),
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

            _buildGallerySection(),

            _buildContactSection(profile),
            SizedBox(height: kBottomNavigationBarHeight + 30),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // HEADER â€” Cover, Logo, Rating, Reviews, Distance
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildHeader(BusinessProfile? profile) {
    final loc = profile?.businessLocation;
    String? distanceText;
    if (loc?.lat != null && loc?.lon != null) {
      final km = calculateDistance(loc!.lat!, loc.lon!);
      if (km != null) distanceText = '${km.toStringAsFixed(1)} KM';
    }

    return CommonCardWidget(
      padding: 0,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover + Logo
          SizedBox(
            height: 170,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: _networkImage(profile?.logo, BoxFit.cover),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 80,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8)
                      ],
                      color: Colors.grey[200],
                    ),
                    child: ClipOval(
                      child: (profile?.logo != null &&
                              profile!.logo!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: profile.logo!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Icon(
                                  Icons.local_pharmacy,
                                  color: Colors.grey,
                                  size: 36),
                            )
                          : Icon(Icons.local_pharmacy,
                              color: Colors.grey, size: 36),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Name + Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 6),
                CustomText(
                  (profile?.businessName != null &&
                          profile!.businessName!.isNotEmpty)
                      ? profile.businessName!
                      : AppStrings.pharmacy.tr,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  maxLines: 2,
                ),
                SizedBox(height: 6),

                // Rating â€¢ Reviews â€¢ Distance
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            size: 16, color: AppColors.yellow00),
                        SizedBox(width: 2),
                        CustomText(
                          (profile?.avgRating != null &&
                                  profile!.avgRating! > 0)
                              ? '${profile.avgRating}'
                              : 'N/A',
                          fontSize: SizeConfig.small,
                          color: AppColors.yellow00,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                    _statDot(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.rate_review_outlined,
                            size: 14,
                            color: AppColors.secondaryTextColor),
                        SizedBox(width: 3),
                        CustomText(
                          '${profile?.totalRatings ?? '0'} ${AppStrings.reviewsLabel.tr}',
                          fontSize: SizeConfig.small,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                    if (distanceText != null) ...[
                      _statDot(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14, color: AppColors.primaryColor),
                          SizedBox(width: 2),
                          CustomText(distanceText,
                              fontSize: SizeConfig.small,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600),
                        ],
                      ),
                    ],
                  ],
                ),

                if (profile?.cityStatePincode != null &&
                    profile!.cityStatePincode!.isNotEmpty) ...[
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.place_outlined,
                          size: 14, color: AppColors.secondaryTextColor),
                      SizedBox(width: 4),
                      Flexible(
                        child: CustomText(
                          profile.cityStatePincode!,
                          fontSize: SizeConfig.small,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // GALLERY â€” Social style (SocialGalleryGrid)
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // CONTACT US â€” Clickable (phone, email, website)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildContactSection(BusinessProfile? profile) {
    if (profile == null) return const SizedBox.shrink();

    final loc = profile.businessLocation;
    final phone = profile.businessNumber?.formattedMobile;
    final owner = profile.ownerDetails?.firstOrNull;

    final hasAnyContact = (profile.websiteUrl?.isNotEmpty ?? false) ||
        (owner?.name?.isNotEmpty ?? false) ||
        (owner?.email?.isNotEmpty ?? false) ||
        phone != null ||
        (profile.address?.isNotEmpty ?? false);

    if (!hasAnyContact && loc?.lat == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Column(
        children: [
          if (hasAnyContact)
            CommonCardWidget(
              padding: 12,
              cardMargin: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ServiceHomeTitleWidget(title: AppStrings.contactUs),
                  SizedBox(height: 12),

                  // About
                  if (profile.businessDescription != null &&
                      profile.businessDescription!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16,
                                  color: AppColors.primaryColor),
                              SizedBox(width: 6),
                              CustomText(AppStrings.aboutUsLabel,
                                  fontSize: SizeConfig.medium,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor),
                            ],
                          ),
                          SizedBox(height: 6),
                          ExpandableText(
                            text: profile.businessDescription!,
                            trimLines: 3,
                            isReadMoreNewLine: false,
                            expandMode: ExpandMode.dialog,
                            style: TextStyle(
                              color: AppColors.secondaryTextColor,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              fontFamily: AppConstants.OpenSans,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                  ],

                  // Contact items
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        if (profile.websiteUrl?.isNotEmpty ?? false)
                          _contactItem(
                            Icons.language_outlined,
                            profile.websiteUrl!,
                            isLink: true,
                            onTap: () => _launchUrl(profile.websiteUrl),
                          ),
                        if (owner?.name?.isNotEmpty ?? false)
                          _contactItem(
                              Icons.person_outline, owner!.name!),
                        if (owner?.email?.isNotEmpty ?? false)
                          _contactItem(
                            Icons.email_outlined,
                            owner!.email!,
                            isLink: true,
                            onTap: () => _launchEmail(owner.email),
                          ),
                        if (phone != null)
                          _contactItem(
                            Icons.phone_outlined,
                            phone,
                            isLink: true,
                            onTap: () => _launchPhone(phone),
                          ),
                        if (profile.address?.isNotEmpty ?? false)
                          _contactItem(
                              Icons.location_on_outlined, profile.address!),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Google Map
          if (loc?.lat != null && loc?.lon != null) ...[
            SizedBox(height: SizeConfig.size12),
            BusinessLocationWidget(
              locationText: '',
              latitude: loc!.lat!,
              longitude: loc.lon!,
              businessName: profile.businessName ?? '',
              padding: 0,
              isTitleShow: true,
            ),
          ],
          SizedBox(height: SizeConfig.size10),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // HELPERS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _contactItem(IconData icon, String text,
      {bool isLink = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: (isLink && onTap != null) ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: isLink
                    ? AppColors.primaryColor
                    : AppColors.secondaryTextColor),
            SizedBox(width: 12),
            Expanded(
              child: CustomText(
                text,
                fontSize: SizeConfig.medium,
                color: isLink
                    ? AppColors.primaryColor
                    : AppColors.mainTextColor,
                decoration: isLink
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: isLink ? AppColors.primaryColor : null,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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

  Widget _statDot() => Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.secondaryTextColor,
          shape: BoxShape.circle,
        ),
      );

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

  void _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    String finalUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      finalUrl = 'https://$url';
    }
    try {
      await launchUrl(
          Uri.parse(finalUrl), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _launchEmail(String? email) async {
    if (email == null || email.isEmpty) return;
    try {
      await launchUrl(Uri(scheme: 'mailto', path: email));
    } catch (_) {}
  }

  void _launchPhone(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    try {
      await launchUrl(Uri(scheme: 'tel', path: clean));
    } catch (_) {}
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
