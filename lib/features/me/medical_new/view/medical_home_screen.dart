import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_profile_fd_model.dart';
import 'package:BlueEra/features/me/medical_new/repo/medical_repo.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class MedicalHomeScreen extends StatefulWidget {
  final String businessId;

  const MedicalHomeScreen({super.key, required this.businessId});

  @override
  State<MedicalHomeScreen> createState() => _MedicalHomeScreenState();
}

class _MedicalHomeScreenState extends State<MedicalHomeScreen> {
  MedicalProfileFdModel? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final res = await MedicalRepo().fetchMedicalProfileFd(businessId: widget.businessId);
      if (res.isSuccess) {
        final data = res.response?.data['data'];
        if (data != null) {
          setState(() => _data = MedicalProfileFdModel.fromJson(data));
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
        body: Center(child: CustomText('No data found', color: AppColors.greyA5)),
      );
    }
    final profile = _data!.profile;
    final contact = _data!.contactInfo;
    final galleries = _data!.galleries ?? [];
    final products = _data!.popularProducts ?? [];

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(profile),
            SizedBox(height: SizeConfig.size12),
            _buildUploadPrescription(),
            if (products.isNotEmpty) ...[
              SizedBox(height: SizeConfig.size12),
              _buildPopularProducts(products),
            ],
            SizedBox(height: SizeConfig.size12),
            _buildGallery(galleries),
            SizedBox(height: SizeConfig.size12),
            _buildContact(contact, profile),
            SizedBox(height: kBottomNavigationBarHeight + 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MedicalProfile? profile) {
    final size = MediaQuery.of(context).size;
    return CommonCardWidget(
      padding: 0,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: size.height * 0.21,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (profile?.coverUrl?.isNotEmpty ?? false)
                  Container(
                    width: double.infinity,
                    height: size.height * 0.17,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                      image: DecorationImage(
                        image: NetworkImage(profile!.coverUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      image: (profile?.logoUrl?.isNotEmpty ?? false)
                          ? DecorationImage(
                              image: NetworkImage(profile!.logoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                CustomText(
                  profile?.name,
                  fontSize: 18,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.bold,
                ),
                if (profile?.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  ExpandableText(
                    text: profile!.description!,
                    trimLines: 4,
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
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadPrescription() {
    return CommonCardWidget(
      cardMargin: 0,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload_file, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  CustomText(
                    'Upload Prescription',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.phone, color: AppColors.primaryColor, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularProducts(List<MedicalPopularProduct> products) {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: 'Our Popular Medical Products'),
          SizedBox(height: SizeConfig.size8),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length.clamp(0, 10),
              separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size10),
              itemBuilder: (_, i) => _productCard(products[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(MedicalPopularProduct product) {
    final imageUrl = product.images?.firstOrNull?.url;
    final variant = product.variants?.firstOrNull;
    final pricing = variant?.pricing;

    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 90,
            width: double.infinity,
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey.shade100),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image_outlined, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.image_outlined, color: Colors.grey),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    product.name ?? '',
                    fontSize: 12,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 4),
                  if (variant != null)
                    CustomText(
                      '${variant.weight?.toInt() ?? ''} ${variant.unit ?? ''}',
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  const Spacer(),
                  if (pricing != null)
                    Row(
                      children: [
                        CustomText(
                          '₹${pricing.sellingPrice ?? pricing.mrp ?? ''}',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                        if (pricing.mrp != null && pricing.sellingPrice != null && pricing.mrp != pricing.sellingPrice) ...[
                          const SizedBox(width: 4),
                          CustomText(
                            '₹${pricing.mrp}',
                            fontSize: 10,
                            color: Colors.grey,
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

  Widget _buildGallery(List<MedicalGallery> galleries) {
    final List<String> allImages = galleries
        .expand((g) => g.imageUrls ?? <String>[])
        .toList();
    if (allImages.isEmpty) return const SizedBox.shrink();

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.gallery),
          const SizedBox(height: 12),
          StaggeredGrid.count(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: List.generate(
              allImages.length > 10 ? 10 : allImages.length,
              (index) {
                int crossAxisCellCount = 2;
                num mainAxisCellCount = 2;

                if (index % 6 == 0 || index % 6 == 5) {
                  crossAxisCellCount = 2;
                  mainAxisCellCount = 3;
                } else if (index % 6 == 3) {
                  crossAxisCellCount = 4;
                  mainAxisCellCount = 2;
                } else {
                  crossAxisCellCount = 2;
                  mainAxisCellCount = 1.5;
                }

                return StaggeredGridTile.count(
                  crossAxisCellCount: crossAxisCellCount,
                  mainAxisCellCount: mainAxisCellCount,
                  child: InkWell(
                    onTap: () => navigatePushTo(
                      context,
                      ImageViewScreen(
                        subTitle: AppStrings.imageViewer,
                        appBarTitle: AppStrings.imageViewer,
                        imageUrls: allImages,
                        initialIndex: index,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        allImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image),
                        ),
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

  Widget _buildContact(MedicalContactInfo? contact, MedicalProfile? profile) {
    if (contact == null) return const SizedBox.shrink();
    final loc = contact.location;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonCardWidget(
          padding: 5,
          cardMargin: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 6),
                child: ServiceHomeTitleWidget(title: AppStrings.contactUs),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (profile?.logoUrl?.isNotEmpty ?? false)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                          image: DecorationImage(
                            image: NetworkImage(profile!.logoUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    CustomText(profile?.name, fontSize: 16, fontWeight: FontWeight.bold),
                    if (profile?.description?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 5),
                      CustomText(
                        profile!.description!,
                        color: AppColors.secondaryTextColor,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Divider(height: 20),
                    if (contact.websiteUrl?.isNotEmpty ?? false)
                      _contactItem(AppIconAssets.website_click, contact.websiteUrl!, AppColors.primaryColor),
                    if (contact.name?.isNotEmpty ?? false)
                      _contactItem(AppIconAssets.principal, contact.name!, Colors.grey[700]!),
                    if (contact.email?.isNotEmpty ?? false)
                      _contactItem(AppIconAssets.email, contact.email!, AppColors.secondaryTextColor),
                    if (contact.phoneNo?.isNotEmpty ?? false)
                      _contactItem(AppIconAssets.phone_outline, contact.phoneNo!, AppColors.secondaryTextColor),
                    if (loc?.name?.isNotEmpty ?? false)
                      _contactItem(AppIconAssets.location_new, loc!.name!, Colors.grey[700]!),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (loc?.coordinates != null && loc!.coordinates!.length >= 2) ...[
          SizedBox(height: SizeConfig.size16),
          BusinessLocationWidget(
            locationText: "",
            latitude: loc.coordinates![1],
            longitude: loc.coordinates![0],
            businessName: loc.name ?? "",
            padding: 0,
            isTitleShow: true,
          ),
        ],
      ],
    );
  }

  Widget _contactItem(String icon, String label, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          LocalAssets(imagePath: icon, imgColor: iconColor, height: 20, width: 20),
          const SizedBox(width: 12),
          Expanded(child: CustomText(label, color: AppColors.mainTextColor)),
        ],
      ),
    );
  }
}
