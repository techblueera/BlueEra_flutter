import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/common/Discover/controller/finance_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/finance_search_res_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class FinanceDetailScreen extends StatefulWidget {
  const FinanceDetailScreen({super.key});

  @override
  State<FinanceDetailScreen> createState() => _FinanceDetailScreenState();
}

class _FinanceDetailScreenState extends State<FinanceDetailScreen> {
  final controller = Get.find<FinanceDiscoverController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteE5,
      appBar: CommonBackAppBar(
        title: 'Finance Service',
      ),
      body: Obx(() {
        final data = controller.selectedDetail.value;
        if (data == null) {
          return const Center(child: CustomText("No Data Found"));
        }
        return CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader(data)),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // About / Description
                    if (data.description?.isNotEmpty ?? false)
                      _buildSection(
                        title: 'About',
                        child: CustomText(
                          data.description!,
                          fontSize: 13,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),

                    // Organisation
                    if (data.aboutOrganisation != null &&
                        data.aboutOrganisation!.isNotEmpty)
                      _buildSection(
                        title: 'Our Organisation',
                        child: _buildOrganisationList(data.aboutOrganisation!),
                      ),

                    // Staff
                    if (data.staff != null && data.staff!.isNotEmpty)
                      _buildSection(
                        title: 'Our Team',
                        child: _buildStaffList(data.staff!),
                      ),

                    // Blogs
                    if (data.blogs != null && data.blogs!.isNotEmpty)
                      _buildSection(
                        title: 'Blogs',
                        child: _buildBlogsList(data.blogs!),
                      ),

                    // Gallery
                    if (data.gallery != null && data.gallery!.isNotEmpty)
                      _buildSection(
                        title: 'Gallery',
                        child: _buildGallery(data.gallery!),
                      ),

                    // Contact Us
                    if (data.contactUs != null && data.contactUs!.isNotEmpty)
                      _buildSection(
                        title: 'Contact Us',
                        child: _buildContactUs(data.contactUs!),
                      ),

                    // Map
                    if (data.location?.coordinates != null &&
                        data.location!.coordinates!.length >= 2)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BusinessLocationWidget(
                          locationText: data.location?.name,
                          latitude: double.tryParse(
                                  data.location!.coordinates![0].toString()) ??
                              0.0,
                          longitude: double.tryParse(
                                  data.location!.coordinates![1].toString()) ??
                              0.0,
                          businessName: data.profileName ?? "",
                          padding: 10,
                          isTitleShow: true,
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(FinanceBusinessItem data) {
    return Stack(
      children: [
        // Cover Image
        Container(
          height: 180,
          width: double.infinity,
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          child: (data.coverUrl?.isNotEmpty ?? false)
              ? CachedNetworkImage(
                  imageUrl: data.coverUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    child: Icon(Icons.business,
                        size: 60, color: AppColors.primaryColor),
                  ),
                )
              : Center(
                  child: Icon(Icons.business,
                      size: 60, color: AppColors.primaryColor),
                ),
        ),
        // Profile info overlay
        Container(
          margin: const EdgeInsets.only(top: 130),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Logo
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 70,
                    height: 70,
                    color: AppColors.white,
                    child: (data.logoUrl?.isNotEmpty ?? false)
                        ? CachedNetworkImage(
                            imageUrl: data.logoUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => LocalAssets(
                                imagePath: AppIconAssets.place_holder_image),
                          )
                        : LocalAssets(
                            imagePath: AppIconAssets.place_holder_image),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      data.profileName ?? 'Unknown',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                    ),
                    if (data.category?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: CustomText(
                          (data.category ?? '')
                              .replaceAll('_', ' ')
                              .capitalize ??
                              '',
                          fontSize: 11,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (data.location?.name?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14, color: AppColors.secondaryTextColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: CustomText(
                              data.location!.name!,
                              fontSize: 12,
                              color: AppColors.secondaryTextColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonCardWidget(
          cardMargin: 0,
          padding: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ServiceHomeTitleWidget(title: title),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOrganisationList(List<FinanceAboutOrganisation> items) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 250,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl ?? "",
                    height: 180,
                    width: 250,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Container(height: 180, width: 250, color: Colors.grey[300]),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        item.title ?? "",
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      CustomText(
                        item.description ?? "",
                        color: AppColors.whiteE5,
                        fontSize: 12,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStaffList(List<FinanceStaff> staffList) {
    return SizedBox(
      height: 197,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: staffList.length,
        itemBuilder: (context, index) {
          final staff = staffList[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.whiteE5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        topLeft: Radius.circular(8)),
                    child: CachedNetworkImage(
                      imageUrl: staff.imageUrl ?? "",
                      height: 132,
                      width: 160,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          Container(height: 100, width: 120, color: Colors.grey[300]),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CustomText(
                  staff.name ?? "",
                  fontWeight: FontWeight.bold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  color: AppColors.mainTextColor,
                ),
                CustomText(
                  staff.position ?? "",
                  color: AppColors.secondaryTextColor,
                  fontSize: 12,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlogsList(List<FinanceBlog> blogs) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: blogs.length,
        itemBuilder: (context, index) {
          final blog = blogs[index];
          return Container(
            width: 250,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: blog.imageUrl ?? "",
                    height: 180,
                    width: 250,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Container(height: 180, width: 250, color: Colors.grey[300]),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(blog.title ?? "",
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                      CustomText(
                        blog.blog ?? "",
                        color: AppColors.whiteE5,
                        fontSize: 12,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGallery(List<FinanceGallery> galleryList) {
    final List<String> allImages = [];
    for (var g in galleryList) {
      if (g.imageUrls != null) allImages.addAll(g.imageUrls!);
    }
    if (allImages.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: allImages[index],
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Container(width: 120, height: 120, color: Colors.grey[300]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactUs(List<FinanceContactUs> contacts) {
    return Column(
      children: contacts.map((contact) {
        final branch = contact.branch;
        final firstDept = (contact.departments?.isNotEmpty ?? false)
            ? contact.departments!.first
            : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (branch?.name?.isNotEmpty ?? false)
                Row(
                  children: [
                    const Icon(Icons.business_outlined,
                        size: 16, color: AppColors.secondaryTextColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomText(
                        branch!.name!,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                  ],
                ),
              if (branch?.website?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => launchUrl(Uri.parse(branch.website ?? '')),
                  child: Row(
                    children: [
                      LocalAssets(
                        imagePath: AppIconAssets.website_click,
                        height: 20,
                        width: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          branch!.website!,
                          style: const TextStyle(
                            color: AppColors.primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (firstDept != null) ...[
                if (firstDept.phone?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      LocalAssets(
                        imagePath: AppIconAssets.phone_outline,
                        height: 20,
                        width: 20,
                        imgColor: AppColors.mainTextColor,
                      ),
                      const SizedBox(width: 8),
                      CustomText(firstDept.phone!,
                          color: AppColors.mainTextColor),
                    ],
                  ),
                ],
                if (firstDept.email?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      LocalAssets(
                        imagePath: AppIconAssets.email,
                        height: 20,
                        width: 20,
                        imgColor: AppColors.mainTextColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomText(firstDept.email!,
                            color: AppColors.mainTextColor),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
