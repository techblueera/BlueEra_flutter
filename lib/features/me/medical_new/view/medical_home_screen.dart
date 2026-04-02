import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_home_response_model.dart';
import 'package:BlueEra/features/me/medical_new/controller/medical_gallery_controller.dart';
import 'package:BlueEra/features/me/medical_new/repo/medical_repo.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_gallery/medical_gallery_list_screen.dart';
import 'package:BlueEra/features/me/medical_new/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_contact_edit_screen.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_nested_category_model.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_level2_category_screen.dart';
import 'package:BlueEra/features/me/medical_new/view/my_medical_listing/my_medical_super_category_screen.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';

/// Static 6 categories for "Update Your Medical Products"
const List<Map<String, String>> _staticCategories = [
  {'title': 'Ayurveda &\nNutrition', 'key': 'AYURVEDA___NUTRITION', 'image': 'assets/category/medical/AyurvedaNutrition.png'},
  {'title': 'Home &\nPatient Care', 'key': 'HOME___PATIENT_CARE', 'image': 'assets/category/medical/Home_Patient_Care.png'},
  {'title': 'Medical\nDevices', 'key': 'MEDICAL_DEVICES', 'image': 'assets/category/medical/Medical_Devices.png'},
  {'title': 'OTC\nMedicines', 'key': 'OTC_MEDICINES', 'image': 'assets/category/medical/OTC_Medicines.png'},
  {'title': 'Personal\n& Baby Care', 'key': 'PERSONAL___BABY_CARE', 'image': 'assets/category/medical/Personal_Baby_Care.png'},
  {'title': 'Wound Care\n& First Aid', 'key': 'WOUND_CARE___FIRST_AID', 'image': 'assets/category/medical/Wound_Care_First_Aid.png'},
];

class MedicalHomeScreen extends StatefulWidget {
  final String businessId;

  const MedicalHomeScreen({super.key, required this.businessId});

  @override
  State<MedicalHomeScreen> createState() => _MedicalHomeScreenState();
}

class _MedicalHomeScreenState extends State<MedicalHomeScreen> {
  MedicalHomeResponseModel? _data;
  bool _isLoading = true;
  late final MedicalGalleryController _galleryController;
  final _businessController = getOrPut(() => ViewBusinessDetailsController());
  late final MedicalController _medicalController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _galleryController = Get.put(MedicalGalleryController());
    _medicalController = getOrPut(() => MedicalController());
    _medicalController.fetchGroceryNestedCategory();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final res = await MedicalRepo().fetchMedicalProfileFd(businessId: widget.businessId);
      if (res.isSuccess && res.response?.data != null) {
        final data = res.response?.data['data'] ?? res.response?.data;
        if (data != null && data is Map<String, dynamic>) {
          setState(() => _data = MedicalHomeResponseModel.fromJson(data));
        }
      }
    } catch (e) {
      debugPrint("Error fetching medical profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_data == null) {
      return Scaffold(
        body: Center(child: CustomText('NA', color: AppColors.greyA5)),
      );
    }

    final profile = _data!.businessProfile;
    final inventory = _data!.inventorySummary;
    final popularProducts = inventory?.popularProducts ?? [];
    final categoriesWithProducts = inventory?.categoriesWithProducts ?? [];

    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(profile),
              SizedBox(height: SizeConfig.size10),
              _buildAddProductsSection(),
              SizedBox(height: SizeConfig.size10),
              _buildBulkUploadSection(),
              SizedBox(height: SizeConfig.size10),
              if (popularProducts.isNotEmpty) ...[
                SizedBox(height: SizeConfig.size10),
                _buildPopularProducts(popularProducts),
              ],
              SizedBox(height: SizeConfig.size10),
              _buildUpdateMedicalProducts(categoriesWithProducts),
              SizedBox(height: SizeConfig.size10),
              _buildGallerySection(),
              SizedBox(height: SizeConfig.size10),
              _buildContactSection(profile),
              SizedBox(height: kBottomNavigationBarHeight + 30),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER (ss6) — Editable logo & cover
  // ─────────────────────────────────────────────
  Widget _buildHeader(BusinessProfile? profile) {
    return CommonCardWidget(
      padding: 0,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: Obx(() {
                      final cover = _businessController.coverImage?.value ?? '';
                      final logo = _businessController.imagePath?.value ?? '';
                      final url = cover.isNotEmpty
                          ? cover
                          : logo.isNotEmpty
                              ? logo
                              : (profile?.logo ?? '');
                      return url.isNotEmpty
                          ? Image.network(url, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: Colors.blueGrey[100]))
                          : Container(color: Colors.blueGrey[100]);
                    }),
                  ),
                ),

                // Edit cover button (top-right)
                Positioned(
                  right: 10,
                  top: 8,
                  child: InkWell(
                    onTap: () => _onEditCover(profile),
                    child: CircleAvatar(
                      backgroundColor: AppColors.black.withValues(alpha: 0.3),
                      child: LocalAssets(imagePath: 'assets/images/camera.png'),
                    ),
                  ),
                ),

                // Share & Bookmark
                Positioned(
                  top: 10,
                  right: 55,
                  child: Row(
                    children: [
                      _circleIconButton(Icons.share_outlined),
                      SizedBox(width: 8),
                      _circleIconButton(Icons.bookmark_border),
                    ],
                  ),
                ),

                // Editable logo (circular)
                Positioned(
                  left: 20,
                  top: 90,
                  child: Obx(() {
                    return CommonProfileImage(
                      imagePath: _businessController.imagePath?.value ??
                          profile?.logo ??
                          '',
                      onImageUpdate: (imagePath) => _onEditLogo(imagePath),
                      dialogTitle: AppStrings.uploadBusinessLogo.tr,
                      showProfileBorder: true,
                    );
                  }),
                ),
              ],
            ),
          ),

          // Name + Rating + Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                CustomText(
                  profile?.businessName ?? '',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  maxLines: 2,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    CustomText(
                      '${profile?.avgRating ?? 0}',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    CustomText(
                      '(${profile?.totalRatings ?? '0'} reviews)',
                      fontSize: 12,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.location_on_outlined,
                        color: AppColors.secondaryTextColor, size: 14),
                    Flexible(
                      child: CustomText(
                        profile?.cityStatePincode ?? '',
                        fontSize: 12,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (profile?.businessDescription != null &&
                    profile!.businessDescription!.isNotEmpty) ...[
                  SizedBox(height: 8),
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
                SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Upload new logo via business profile API
  Future<void> _onEditLogo(String imagePath) async {
    try {
      _businessController.imagePath?.value = imagePath;
      dio.MultipartFile? imageByPart;
      if (imagePath.isNotEmpty) {
        final fileName = imagePath.split('/').last;
        imageByPart = await dio.MultipartFile.fromFile(imagePath, filename: fileName);
      }
      final reqData = {
        ApiKeys.businessId: businessId,
        ApiKeys.logo_image: imageByPart,
      };
      await _businessController.updateBusinessDetails(reqData);
    } catch (e) {
      commonSnackBar(message: AppStrings.updatePictureFailed);
    }
  }

  /// Upload new cover via business profile API
  Future<void> _onEditCover(BusinessProfile? profile) async {
    try {
      final newPath = await SelectProfilePictureDialog.showLogoDialog(
        context,
        AppStrings.editCoverPicture,
        cropAspectRatio: CropAspectRatio(width: 3, height: 1),
      );

      if (newPath == null || newPath.isEmpty) return;

      _businessController.coverImage?.value = newPath;

      final file = File(newPath);
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        "${file.path}_compressed.jpg",
        quality: 75,
      );

      final dataImage = await multiPartImage(
        imagePath: compressed?.path ?? newPath,
      );

      if (dataImage == null) {
        commonSnackBar(message: AppStrings.imageProcessingFailed);
        return;
      }

      final reqProfile = {
        ApiKeys.businessId: businessId,
        ApiKeys.business_name: profile?.businessName,
        "coverPicture": dataImage,
      };
      await _businessController.updateBusinessProfileDetails(reqProfile);
    } catch (e) {
      commonSnackBar(message: AppStrings.updatePictureFailed);
    }
  }

  Widget _circleIconButton(IconData icon) {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: AppColors.mainTextColor),
    );
  }

  // ─────────────────────────────────────────────
  // ADD PRODUCTS SECTION
  // ─────────────────────────────────────────────
  Widget _buildAddProductsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        padding: 12,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServiceHomeTitleWidget(title: 'Add Medical Products'),
            SizedBox(height: SizeConfig.size12),
            Row(
              children: [
                Expanded(
                  child: _addProductActionCard(
                    icon: Icons.add_circle_outline,
                    title: 'Add New\nProducts',
                    subtitle: 'Browse categories & add',
                    color: AppColors.primaryColor,
                    onTap: () => Get.toNamed(
                      RouteHelper.getMedicalCategoryScreenRoute(),
                    ),
                  ),
                ),
                SizedBox(width: SizeConfig.size10),
                Expanded(
                  child: _addProductActionCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'My\nProducts',
                    subtitle: 'View & manage listings',
                    color: AppColors.green00,
                    onTap: () => Get.to(
                        () => const MyMedicalSuperCategoryScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _addProductActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            SizedBox(height: 10),
            CustomText(
              title,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
              maxLines: 2,
            ),
            SizedBox(height: 4),
            CustomText(
              subtitle,
              fontSize: 11,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // UPLOAD PRESCRIPTION
  // ─────────────────────────────────────────────

  // ─────────────────────────────────────────────
  // POPULAR PRODUCTS (ss7)
  // ─────────────────────────────────────────────
  Widget _buildPopularProducts(List<PopularProduct> products) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        padding: 10,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServiceHomeTitleWidget(title: 'Our Popular Medical Products'),
            SizedBox(height: SizeConfig.size10),
            SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length.clamp(0, 10),
                separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size10),
                itemBuilder: (_, i) => _popularProductCard(products[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _popularProductCard(PopularProduct item) {
    final productName = item.product?.name ?? item.variant?.variantName ?? '';
    final description = item.product?.description ?? '';
    final imageUrl = item.product?.images?.firstOrNull?.url ??
        item.variant?.images?.firstOrNull?.url;
    final mrp = item.batches?.mrp ?? item.variant?.pricing?.firstOrNull?.mrp;
    final sellingPrice = item.batches?.sellingPrice ??
        item.variant?.pricing?.firstOrNull?.sellingPrice;
    final discount = (mrp != null && sellingPrice != null && mrp > 0)
        ? (((mrp - sellingPrice) / mrp) * 100).toInt()
        : 0;

    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          SizedBox(
            height: 100,
            width: double.infinity,
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey.shade100),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade100,
                      child: Icon(Icons.image_outlined, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade100,
                    child: Icon(Icons.image_outlined, color: Colors.grey),
                  ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    productName,
                    fontSize: 12,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 2),
                  if (description.isNotEmpty)
                    CustomText(
                      description,
                      fontSize: 10,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      color: AppColors.secondaryTextColor,
                    ),
                  Spacer(),
                  // Price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CustomText(
                        '₹${sellingPrice ?? mrp ?? ''}',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainTextColor,
                      ),
                      if (mrp != null && sellingPrice != null && mrp != sellingPrice) ...[
                        SizedBox(width: 4),
                        Text(
                          '₹$mrp',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        SizedBox(width: 4),
                        CustomText(
                          '$discount% Off',
                          fontSize: 10,
                          color: AppColors.green00,
                          fontWeight: FontWeight.w600,
                        ),
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

  // ─────────────────────────────────────────────
  // UPDATE YOUR MEDICAL PRODUCTS (ss8) - Static 6 categories
  // ─────────────────────────────────────────────
  Widget _buildUpdateMedicalProducts(List<CategoryWithProducts> apiCategories) {
    // Build a set of API category keys that have products
    final activeKeys = <String>{};
    for (final cat in apiCategories) {
      if (cat.key != null && cat.hasProducts) activeKeys.add(cat.key!);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        padding: 12,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServiceHomeTitleWidget(title: 'Update Your Medical Products'),
            SizedBox(height: SizeConfig.size12),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _staticCategories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: SizeConfig.size10,
                mainAxisSpacing: SizeConfig.size10,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final cat = _staticCategories[index];
                final hasProducts = activeKeys.contains(cat['key']);
                return _staticCategoryCard(cat, hasProducts, apiCategories);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _staticCategoryCard(
    Map<String, String> category,
    bool hasProducts,
    List<CategoryWithProducts> apiCategories,
  ) {
    return InkWell(
      onTap: () => _onCategoryTap(category),
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
            Image.asset(
              category['image']!,
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 6),
            CustomText(
              category['title'],
              fontSize: 11,
              fontWeight: FontWeight.w500,
              textAlign: TextAlign.center,
              maxLines: 2,
              color: Colors.blueGrey.shade700,
            ),
            if (hasProducts)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.check_circle, color: AppColors.green00, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BULK UPLOAD (from create screen)
  // ─────────────────────────────────────────────
  Future<void> _pickAndSnapSearch({required ImageSource source}) async {
    try {
      final List<XFile> images;
      if (source == ImageSource.gallery) {
        images = await _picker.pickMultiImage(limit: 5);
      } else {
        final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
        images = photo != null ? [photo] : [];
      }
      if (images.isEmpty) return;
      await _medicalController.snapSearch(
        imagePaths: images.map((e) => e.path).toList(),
      );
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  MedicalNestedCategoryModel? _findApiCategory(String staticKey) {
    for (final level0 in _medicalController.medicalNestedCategoryList) {
      if (_keysMatch(level0.key, staticKey)) return level0;
      for (final level1 in (level0.children ?? <MedicalNestedCategoryModel>[])) {
        if (_keysMatch(level1.key, staticKey)) return level1;
      }
    }
    return null;
  }

  bool _keysMatch(String? apiKey, String staticKey) {
    if (apiKey == null) return false;
    return apiKey.toUpperCase().replaceAll(' ', '_') ==
        staticKey.toUpperCase().replaceAll(' ', '_');
  }

  void _onCategoryTap(Map<String, String> category) {
    final apiCategory = _findApiCategory(category['key']!);
    if (apiCategory == null) {
      commonSnackBar(message: 'Category not available yet');
      return;
    }
    final level2Children = apiCategory.children ?? [];
    if (level2Children.isNotEmpty) {
      Get.to(() => MedicalLevel2CategoryScreen(
            title: category['title']!.replaceAll('\n', ' '),
            level2Categories: level2Children,
          ));
    }
  }

  Widget _buildBulkUploadSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              "Bulk Upload Shop Product Photos",
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: 10),
            Obx(() => _medicalController.isSnapSearchLoading.value
                ? SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Row(
                    children: [
                      _uploadMediaWidget(
                        imagePath: 'assets/category/medical/medical_upload_photo_med.png',
                        title: 'Upload Photo',
                        onTap: () => _pickAndSnapSearch(source: ImageSource.camera),
                      ),
                      SizedBox(width: 7),
                      _uploadMediaWidget(
                        imagePath: 'assets/category/medical/medical_upload_photo.png',
                        title: 'Upload List',
                        onTap: () => _pickAndSnapSearch(source: ImageSource.gallery),
                      ),
                    ],
                  )),
          ],
        ),
      ),
    );
  }

  Widget _uploadMediaWidget({
    required String imagePath,
    required String title,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: Get.width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(imagePath, fit: BoxFit.contain),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 5),
                child: CustomText(
                  title,
                  fontSize: SizeConfig.small,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // GALLERY (ss9) - Grid with Add More → full gallery screen
  // ─────────────────────────────────────────────
  Widget _buildGallerySection() {
    return Obx(() {
      final allImages = <String>[];
      for (final entry in _galleryController.galleryList) {
        allImages.addAll(entry.imageUrls ?? []);
      }

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: CommonCardWidget(
          padding: 10,
          cardMargin: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ServiceHomeTitleWidget(title: AppStrings.gallery),
                  InkWell(
                    onTap: () => Get.to(() => MedicalGalleryListScreen()),
                    child: CustomText(
                      'Add More',
                      fontSize: 13,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              if (allImages.isEmpty)
                GestureDetector(
                  onTap: () => Get.to(() => MedicalGalleryListScreen()),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            color: Colors.grey.shade400, size: 36),
                        SizedBox(height: 8),
                        Text('Add Photos',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else
                _buildGalleryGrid(allImages),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildGalleryGrid(List<String> images) {
    final display = images.length > 4 ? images.sublist(0, 4) : images;
    final extra = images.length > 4 ? images.length - 4 : 0;
    const double height = 220;
    const double gap = 4;

    void openViewer(int index) => navigatePushTo(
          context,
          ImageViewScreen(
            subTitle: AppStrings.imageViewer,
            appBarTitle: AppStrings.imageViewer,
            imageUrls: images,
            initialIndex: index,
          ),
        );

    Widget imgTile(int index, {bool showOverlay = false}) {
      return GestureDetector(
        onTap: () => openViewer(index),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                display[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                ),
              ),
              if (showOverlay && extra > 0)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  alignment: Alignment.center,
                  child: Text(
                    '+$extra',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // 1 image
    if (display.length == 1) {
      return SizedBox(height: height, width: double.infinity, child: imgTile(0));
    }

    // 2 images — side by side
    if (display.length == 2) {
      return SizedBox(
        height: height,
        child: Row(children: [
          Expanded(child: imgTile(0)),
          SizedBox(width: gap),
          Expanded(child: imgTile(1)),
        ]),
      );
    }

    // 3 images — 1 large left, 2 stacked right
    if (display.length == 3) {
      return SizedBox(
        height: height,
        child: Row(children: [
          Expanded(child: imgTile(0)),
          SizedBox(width: gap),
          Expanded(
            child: Column(children: [
              Expanded(child: imgTile(1)),
              SizedBox(height: gap),
              Expanded(child: imgTile(2)),
            ]),
          ),
        ]),
      );
    }

    // 4+ images — 2×2 grid, +N overlay on last cell
    return SizedBox(
      height: height,
      child: Column(children: [
        Expanded(
          child: Row(children: [
            Expanded(child: imgTile(0)),
            SizedBox(width: gap),
            Expanded(child: imgTile(1)),
          ]),
        ),
        SizedBox(height: gap),
        Expanded(
          child: Row(children: [
            Expanded(child: imgTile(2)),
            SizedBox(width: gap),
            Expanded(child: imgTile(3, showOverlay: extra > 0)),
          ]),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  // CONTACT US (ss10) + Google Map
  // ─────────────────────────────────────────────
  Widget _buildContactSection(BusinessProfile? profile) {
    if (profile == null) return const SizedBox.shrink();
    final loc = profile.businessLocation;
    final phone = profile.businessNumber?.formattedMobile;
    final owner = profile.ownerDetails?.firstOrNull;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Column(
        children: [
          CommonCardWidget(
            padding: 5,
            cardMargin: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 6, right: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ServiceHomeTitleWidget(title: AppStrings.contactUs),
                      IconButton(
                        onPressed: () => Get.to(() => MedicalContactEditScreen(
                              profile: profile,
                              businessController: _businessController,
                              businessId: widget.businessId,
                            )),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo + Name
                      if (profile.logo != null && profile.logo!.isNotEmpty)
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                            image: DecorationImage(
                              image: NetworkImage(profile.logo!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      SizedBox(height: 10),
                      CustomText(
                        profile.businessName,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      if (profile.businessDescription?.isNotEmpty ?? false) ...[
                        SizedBox(height: 5),
                        CustomText(
                          profile.businessDescription!,
                          color: AppColors.secondaryTextColor,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          fontSize: 13,
                        ),
                      ],
                      Divider(height: 20),
                      // Contact items
                      if (profile.websiteUrl?.isNotEmpty ?? false)
                        _contactItem(AppIconAssets.website_click, profile.websiteUrl!, AppColors.primaryColor),
                      if (owner?.name?.isNotEmpty ?? false)
                        _contactItem(AppIconAssets.principal, owner!.name!, Colors.grey[700]!),
                      if (owner?.email?.isNotEmpty ?? false)
                        _contactItem(AppIconAssets.email, owner!.email!, AppColors.secondaryTextColor),
                      if (phone != null)
                        _contactItem(AppIconAssets.phone_outline, phone, AppColors.secondaryTextColor),
                      if (profile.address?.isNotEmpty ?? false)
                        _contactItem(AppIconAssets.location_new, profile.address!, Colors.grey[700]!),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Google Map
          if (loc?.lat != null && loc?.lon != null) ...[
            SizedBox(height: SizeConfig.size16),
            BusinessLocationWidget(
              locationText: "",
              latitude: loc!.lat!,
              longitude: loc.lon!,
              businessName: profile.businessName ?? "",
              padding: 0,
              isTitleShow: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _contactItem(String icon, String label, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalAssets(imagePath: icon, imgColor: iconColor, height: 18, width: 18),
          SizedBox(width: 12),
          Expanded(
            child: CustomText(
              label,
              color: AppColors.mainTextColor,
              fontSize: 13,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
