import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_home_response_model.dart';
import 'package:BlueEra/features/me/medical_new/repo/medical_repo.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_inventory_category_screen.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

/// View-only pharmacy detail screen — same UI as MedicalHomeScreen
/// but without edit capabilities (no logo/cover edit, no inventory management).
/// Used when a user taps a pharmacy card from NearestPharmaciesListScreen.
class MedicalPharmacyDetailScreen extends StatefulWidget {
  final String businessId;

  const MedicalPharmacyDetailScreen({super.key, required this.businessId});

  @visibleForTesting
  static Future<MedicalHomeResponseModel?> fetchProfile(String businessId) async {
    final res = await MedicalRepo().fetchMedicalProfileFd(businessId: businessId);
    if (res.isSuccess && res.response?.data != null) {
      final data = res.response?.data['data'] ?? res.response?.data;
      if (data != null && data is Map<String, dynamic>) {
        return MedicalHomeResponseModel.fromJson(data);
      }
    }
    return null;
  }

  @override
  State<MedicalPharmacyDetailScreen> createState() =>
      _MedicalPharmacyDetailScreenState();
}

class _MedicalPharmacyDetailScreenState
    extends State<MedicalPharmacyDetailScreen> {
  MedicalHomeResponseModel? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final result =
          await MedicalPharmacyDetailScreen.fetchProfile(widget.businessId);
      if (mounted) setState(() => _data = result);
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
        body: Center(
            child: CustomText('No data found', color: AppColors.greyA5)),
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
              if (popularProducts.isNotEmpty) ...[
                SizedBox(height: SizeConfig.size10),
                _buildPopularProducts(popularProducts),
              ],
              if (categoriesWithProducts.isNotEmpty) ...[
                SizedBox(height: SizeConfig.size10),
                _buildMedicalProductCategories(categoriesWithProducts),
              ],
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
  // HEADER — View only (no edit buttons)
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
                    child: Builder(builder: (_) {
                      final url = profile?.logo ?? '';
                      return url.isNotEmpty
                          ? Image.network(url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: Colors.blueGrey[100]))
                          : Container(color: Colors.blueGrey[100]);
                    }),
                  ),
                ),

                // Back button
                Positioned(
                  left: 10,
                  top: 8,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: CircleAvatar(
                      backgroundColor:
                          AppColors.black.withValues(alpha: 0.3),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),

                // Logo (circular, view only)
                Positioned(
                  left: 20,
                  top: 90,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12, blurRadius: 8)
                      ],
                      image: (profile?.logo != null &&
                              profile!.logo!.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(profile.logo!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.grey[200],
                    ),
                    child: (profile?.logo == null ||
                            profile!.logo!.isEmpty)
                        ? Icon(Icons.local_pharmacy,
                            color: Colors.grey, size: 36)
                        : null,
                  ),
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

  // ─────────────────────────────────────────────
  // POPULAR PRODUCTS
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
            ServiceHomeTitleWidget(title: 'Popular Medical Products'),
            SizedBox(height: SizeConfig.size10),
            SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length.clamp(0, 10),
                separatorBuilder: (_, __) =>
                    SizedBox(width: SizeConfig.size10),
                itemBuilder: (_, i) =>
                    _popularProductCard(products[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _popularProductCard(PopularProduct item) {
    final productName =
        item.product?.name ?? item.variant?.variantName ?? '';
    final description = item.product?.description ?? '';
    final imageUrl = item.product?.images?.firstOrNull?.url ??
        item.variant?.images?.firstOrNull?.url;
    final mrp =
        item.batches?.mrp ?? item.variant?.pricing?.firstOrNull?.mrp;
    final sellingPrice = item.batches?.sellingPrice ??
        item.variant?.pricing?.firstOrNull?.sellingPrice;
    final discount =
        (mrp != null && sellingPrice != null && mrp > 0)
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
                    placeholder: (_, __) =>
                        Container(color: Colors.grey.shade100),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade100,
                      child: Icon(Icons.image_outlined,
                          color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade100,
                    child: Icon(Icons.image_outlined,
                        color: Colors.grey),
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
                      if (mrp != null &&
                          sellingPrice != null &&
                          mrp != sellingPrice) ...[
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
  // MEDICAL PRODUCT CATEGORIES (Grid — same as MedicalHomeScreen)
  // ─────────────────────────────────────────────
  static const List<Map<String, String>> _staticCategories = [
    {'title': 'Ayurveda &\nNutrition', 'key': 'AYURVEDA___NUTRITION', 'image': 'assets/category/medical/AyurvedaNutrition.png'},
    {'title': 'Home &\nPatient Care', 'key': 'HOME___PATIENT_CARE', 'image': 'assets/category/medical/Home_Patient_Care.png'},
    {'title': 'Medical\nDevices', 'key': 'MEDICAL_DEVICES', 'image': 'assets/category/medical/Medical_Devices.png'},
    {'title': 'OTC\nMedicines', 'key': 'OTC_MEDICINES', 'image': 'assets/category/medical/OTC_Medicines.png'},
    {'title': 'Personal\n& Baby Care', 'key': 'PERSONAL___BABY_CARE', 'image': 'assets/category/medical/Personal_Baby_Care.png'},
    {'title': 'Wound Care\n& First Aid', 'key': 'WOUND_CARE___FIRST_AID', 'image': 'assets/category/medical/Wound_Care_First_Aid.png'},
  ];

  Widget _buildMedicalProductCategories(List<CategoryWithProducts> apiCategories) {
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
            ServiceHomeTitleWidget(title: 'Medical Products'),
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
      onTap: () {
        final apiCat = apiCategories.cast<CategoryWithProducts?>().firstWhere(
              (c) => c?.key == category['key'],
              orElse: () => null,
            );

        if (apiCat == null || apiCat.children == null || apiCat.children!.isEmpty) {
          commonSnackBar(message: 'No data found');
          return;
        }

        Get.to(() => MedicalInventoryCategoryScreen(
              title: apiCat.name ?? category['title'] ?? '',
              children: apiCat.children!,
            ));
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
  // GALLERY (View Only)
  // ─────────────────────────────────────────────
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
          final url = item['url'];
          if (url is String && url.isNotEmpty) galleryImages.add(url);
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
            StaggeredGrid.count(
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: List.generate(
                galleryImages.length > 9 ? 9 : galleryImages.length,
                (index) => StaggeredGridTile.count(
                  crossAxisCellCount: index == 0 ? 2 : 1,
                  mainAxisCellCount: index == 0 ? 2 : 1,
                  child: InkWell(
                    onTap: () => navigatePushTo(
                      context,
                      ImageViewScreen(
                        subTitle: AppStrings.imageViewer,
                        appBarTitle: AppStrings.imageViewer,
                        imageUrls: galleryImages,
                        initialIndex: index,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        galleryImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.broken_image,
                              color: Colors.grey),
                        ),
                      ),
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

  // ─────────────────────────────────────────────
  // CONTACT US + Map (View Only)
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
                  padding: const EdgeInsets.only(top: 8, left: 6),
                  child:
                      ServiceHomeTitleWidget(title: AppStrings.contactUs),
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
                      if (profile.logo != null &&
                          profile.logo!.isNotEmpty)
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8)
                            ],
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
                      if (profile.businessDescription?.isNotEmpty ??
                          false) ...[
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
                        _contactItem(
                            AppIconAssets.website_click,
                            profile.websiteUrl!,
                            AppColors.primaryColor),
                      if (owner?.name?.isNotEmpty ?? false)
                        _contactItem(AppIconAssets.principal,
                            owner!.name!, Colors.grey[700]!),
                      if (owner?.email?.isNotEmpty ?? false)
                        _contactItem(
                            AppIconAssets.email,
                            owner!.email!,
                            AppColors.secondaryTextColor),
                      if (phone != null)
                        _contactItem(AppIconAssets.phone_outline,
                            phone, AppColors.secondaryTextColor),
                      if (profile.address?.isNotEmpty ?? false)
                        _contactItem(
                            AppIconAssets.location_new,
                            profile.address!,
                            Colors.grey[700]!),
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
          LocalAssets(
              imagePath: icon,
              imgColor: iconColor,
              height: 18,
              width: 18),
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
