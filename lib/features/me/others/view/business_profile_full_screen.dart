import 'dart:math';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/me/others/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/me/others/model/business_profile_full_model.dart';
import 'package:BlueEra/features/me/others/view/about_us/about_organization.dart';
import 'package:BlueEra/features/me/others/view/other_blog/other_blogs_screen.dart';
import 'package:BlueEra/features/me/others/view/other_header_view.dart';
import 'package:BlueEra/features/me/others/view/staff/staff_screen.dart';
import 'package:BlueEra/features/me/others/widget/other_product_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product/inventory_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:readmore/readmore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_enum.dart';

class BusinessProfileFullScreen extends StatefulWidget {
  BusinessProfileFullScreen({super.key});

  @override
  State<BusinessProfileFullScreen> createState() =>
      _BusinessProfileFullScreenState();
}

class _BusinessProfileFullScreenState extends State<BusinessProfileFullScreen> {
  final controller = Get.find<BusinessProfileFullController>();

  @override
  void initState() {
    // TODO: implement initState
    controller.getBusinessProfileFull();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.appBackgroundColor,
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = controller.businessProfile.value;
        if (data == null) {
          return const Center(child: Text("No Profile Data Found"));
        }

        return CustomScrollView(
          slivers: [
            // 1. Header Image
            SliverAppBar(
              expandedHeight: Get.height * 0.35,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: AppColors.appBackgroundColor,
                  child: OtherHeaderView(
                    schoolAboutUsController: controller,
                  ),
                ),
                collapseMode: CollapseMode.parallax,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ///"Our Staffs"
                    if (data.staff != null && data.staff!.isNotEmpty) ...[
                      CommonCardWidget(
                        cardMargin: 0,
                        padding: 10,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("Our Staffs", onSeeAll: () {
                              Get.to(StaffScreen());
                            }),
                            const SizedBox(height: 10),
                            _buildStaffList(data.staff!),
                            // const SizedBox(height: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    ///PRODUCT....

                    CommonCardWidget(
                        cardMargin: 0,
                        padding: 10,
                        bgColor: Color(0xff0085FE).withValues(alpha: 0.10),
                        child: Column(
                          children: [
                            _buildSectionTitle("Product", onSeeAll: () {
                              Get.to(InventoryScreen(
                                fromBottomNavBar: false,
                                isShowScreen: BusinessType.Product.name,
                              ));
                            }),
                            OtherProductWidget(),
                          ],
                        )),
                    const SizedBox(height: 20),

                    ///"Our Organisation"
                    if (data.aboutOrganisation != null &&
                        data.aboutOrganisation!.isNotEmpty) ...[
                      CommonCardWidget(
                        cardMargin: 0,
                        padding: 10,
                        child: Column(
                          children: [
                            _buildSectionTitle("Our Organisation",
                                onSeeAll: () {
                              Get.to(AboutOrganization());
                            }),
                            const SizedBox(height: 10),
                            _buildServicesList(data.aboutOrganisation!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (data.blogs != null && data.blogs!.isNotEmpty) ...[
                      CommonCardWidget(
                        cardMargin: 0,
                        padding: 10,
                        child: Column(
                          children: [
                            _buildSectionTitle("Our Blogs", onSeeAll: () {
                              Get.to(OtherBlogsScreen());
                            }),
                            // Using Blogs/News as Products for now
                            const SizedBox(height: 10),
                            _buildBlogsServicesList(data.blogs ?? []),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    /// Gallery
                    if (data.gallery != null && data.gallery!.isNotEmpty) ...[
                      CommonCardWidget(
                        cardMargin: 0,
                        padding: 10,
                        child: Column(
                          children: [
                            _buildSectionTitle("Gallery"),
                            const SizedBox(height: 10),
                            _buildGallery(data.gallery ?? [], context),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // // Testimonials (Management messages?)
                    // if (data.management != null &&
                    //     data.management!.isNotEmpty) ...[
                    //   _buildSectionTitle("Testimonials"),
                    //   const SizedBox(height: 10),
                    //   _buildTestimonials(data.management!),
                    //   const SizedBox(height: 20),
                    // ],
                    // Contact Us
                    CommonCardWidget(
                      cardMargin: 0,
                      padding: 10,
                      child: Column(
                        children: [
                          _buildSectionTitle("Contact Us"),
                          const SizedBox(height: 10),
                          _buildContactUs(
                              data.contactUs, data.timings, data.profile),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Map Placeholder
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BusinessLocationWidget(
                          locationText: data.profile?.location?.address,
                          latitude: double.parse(data
                                  .profile?.location?.coordinates?[0]
                                  .toString() ??
                              "0.0"),
                          longitude: double.parse(data
                                  .profile?.location?.coordinates?[1]
                                  .toString() ??
                              "0.0"),
                          businessName: data.profile?.profileName ?? "",
                          padding: 10,
                          isTitleShow: true),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeaderImage(Profile? profile) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (profile?.coverUrl != null)
          CachedNetworkImage(
            imageUrl: profile!.coverUrl!,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Container(color: Colors.grey),
          )
        else
          Container(color: Colors.blueGrey),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(Profile? profile) {
    if (profile == null) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                image: profile.logoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(profile.logoUrl!),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: profile.logoUrl == null
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.profileName ?? "Business Name",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const Text(" 4.5 (88 reviews)",
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.grey),
                      Expanded(
                        child: Text(
                          " ${profile.location?.address ?? 'Location'}",
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (profile.description != null)
          ReadMoreText(
            profile.description!,
            trimLines: 3,
            colorClickableText: Colors.blue,
            trimMode: TrimMode.Line,
            trimCollapsedText: '...Read More',
            trimExpandedText: ' Show Less',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildActionButton("Home", Colors.blue, true),
          _buildActionButton("Product", Colors.white, false),
          _buildActionButton("Services", Colors.white, false),
          _buildActionButton("Career / Job", Colors.white, false),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        backgroundColor: color,
        side: isSelected
            ? BorderSide.none
            : const BorderSide(color: Colors.grey, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          title,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            child: const CustomText(
              "View All",
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildStaffList(List<Staff> staffList) {
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
                border: Border.all(
                  color: AppColors.whiteE5,
                ),
                borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        topLeft: Radius.circular(8)),
                    child: CachedNetworkImage(
                      imageUrl: staff.imageUrl ?? "",
                      height: 132,
                      width: 160,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                          height: 100, width: 120, color: Colors.grey[300]),
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

  Widget _buildServicesList(List<AboutOrganisation> services) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
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
                    imageUrl: service.imageUrl ?? "",
                    height: 180,
                    width: 250,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                        height: 180, width: 250, color: Colors.grey[300]),
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
                        Colors.black.withOpacity(0.8)
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
                      Text(
                        service.title ?? "",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      Text(
                        service.description ?? "",
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
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

  Widget _buildBlogsServicesList(List<Blogs> services) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
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
                    imageUrl: service.imageUrl ?? "",
                    height: 180,
                    width: 250,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                        height: 180, width: 250, color: Colors.grey[300]),
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
                        Colors.black.withOpacity(0.8)
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
                      CustomText(service.title ?? "",
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                      CustomText(
                        service.blog ?? "",
                        color: Colors.white70,
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

  Widget _buildProductsList(List<Blogs> products) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl ?? "",
                    height: 120,
                    width: 160,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                        height: 120, width: 160, color: Colors.grey[300]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title ?? "",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.blog ?? "",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 1,
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

  Widget _buildGallery(List<Gallery> galleryList, BuildContext context) {
    // Flatten all images
    List<String> allImages = [];
    for (var g in galleryList) {
      if (g.imageUrls != null) {
        allImages.addAll(g.imageUrls!);
      }
    }

    if (allImages.isEmpty) return const SizedBox();

    // Randomize and pick 6
    allImages.shuffle(Random());
    List<String> displayImages =
        allImages.length > 6 ? allImages.sublist(0, 6) : allImages;

    return StaggeredGrid.count(
      // shrinkWrap: true,
      // physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children:
          List.generate(allImages.length > 10 ? 10 : allImages.length, (index) {
        // Logic to replicate the pattern in your image:
        // Large Vertical (index 0), Two small (index 1,2), Large Horizontal (index 3)...
        int crossAxisCellCount = 2;
        num mainAxisCellCount = 2;

        if (index % 6 == 0 || index % 6 == 5) {
          // Large Vertical Tiles
          crossAxisCellCount = 2;
          mainAxisCellCount = 3;
        } else if (index % 6 == 3) {
          // Large Full-Width Horizontal Tile
          crossAxisCellCount = 4;
          mainAxisCellCount = 2;
        } else {
          // Standard Small Squares
          crossAxisCellCount = 2;
          mainAxisCellCount = 1.5;
        }

        return StaggeredGridTile.count(
          crossAxisCellCount: crossAxisCellCount,
          mainAxisCellCount: mainAxisCellCount,
          child: InkWell(
            onTap: () {
              navigatePushTo(
                context,
                ImageViewScreen(
                  subTitle: AppStrings.imageViewer,
                  appBarTitle: AppStrings.imageViewer,
                  imageUrls: allImages,
                  initialIndex: index,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                allImages[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image)),
              ),
            ),
          ),
        );
      }),

      // itemCount: displayImages.length,
      // itemBuilder: (context, index) {
      //   return ClipRRect(
      //     borderRadius: BorderRadius.circular(8),
      //     child: CachedNetworkImage(
      //       imageUrl: displayImages[index],
      //       fit: BoxFit.cover,
      //       errorWidget: (context, url, error) =>
      //           Container(color: Colors.grey[300]),
      //     ),
      //   );
      // },
    );
  }

  Widget _buildLatestPost(News post) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.business, color: Colors.grey),
            ),
            title: const Text("Business Name",
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(post.createdAt?.substring(0, 10) ?? "Just now"),
            trailing: const Icon(Icons.more_vert),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(post.news ?? ""),
          ),
          const SizedBox(height: 8),
          if (post.imageUrl != null)
            CachedNetworkImage(
              imageUrl: post.imageUrl!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const SizedBox(),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInteractionIcon(Icons.thumb_up_alt_outlined, "Like"),
                _buildInteractionIcon(Icons.comment_outlined, "Comment"),
                _buildInteractionIcon(Icons.share_outlined, "Share"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionIcon(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildTestimonials(List<Management> testimonials) {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        itemCount: testimonials.length,
        itemBuilder: (context, index) {
          final item = testimonials[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.format_quote, color: Colors.blue, size: 30),
                Text(
                  item.message ?? "",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  item.name ?? "",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  item.position ?? "",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactUs(
      List<ContactUs>? contacts, Timings? timings, Profile? profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile?.profileName != null)
            Text(
              profile!.profileName!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          const SizedBox(height: 8),
          if (contacts != null && contacts.isNotEmpty) ...[
            if (contacts.first.websiteUrl != null)
              _buildContactRow(AppIconAssets.website_click,
                  contacts.first.websiteUrl!, AppColors.primaryColor,
                  isLink: true),
            if (contacts.first.contactNumber != null)
              _buildContactRow(AppIconAssets.phone_outline,
                  contacts.first.contactNumber!, AppColors.mainTextColor),
            if (contacts.first.email != null)
              _buildContactRow(AppIconAssets.email, contacts.first.email!,
                  AppColors.mainTextColor),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(String icon, String text, Color textColor,
      {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: isLink == false ? AppColors.mainTextColor : null,
            height: 20,
            width: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: isLink ? () => launchUrl(Uri.parse(text)) : null,
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  decoration: isLink ? TextDecoration.underline : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
