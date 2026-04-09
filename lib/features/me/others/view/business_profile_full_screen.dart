import 'package:BlueEra/core/api/model/school_contact_us_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/me_menu_card_design.dart';
import 'package:BlueEra/features/me/others/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/me/others/controller/other_branch_contact_controller.dart';
import 'package:BlueEra/features/me/others/model/business_profile_full_model.dart' hide Location;
import 'package:BlueEra/features/me/others/view/about_us/about_us.dart';
import 'package:BlueEra/features/me/others/view/other_blog/other_blogs_screen.dart';
import 'package:BlueEra/features/me/others/view/other_contact_us/other_branch_details_form_screen.dart';
import 'package:BlueEra/features/me/others/view/other_contact_us/other_branch_only_screen.dart';
import 'package:BlueEra/features/me/others/view/other_contact_us/other_contact_us.dart';
import 'package:BlueEra/features/me/others/view/other_header_view.dart';
import 'package:BlueEra/features/me/others/view/other_service_gallery/other_service_photos_screen.dart';
import 'package:BlueEra/features/me/others/view/staff/staff_screen.dart';
import 'package:BlueEra/features/me/others/widget/other_product_widget.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessProfileFullScreen extends StatefulWidget {
  BusinessProfileFullScreen({super.key});

  @override
  State<BusinessProfileFullScreen> createState() =>
      _BusinessProfileFullScreenState();
}

class _BusinessProfileFullScreenState extends State<BusinessProfileFullScreen> {
  final controller = getOrPut(() => BusinessProfileFullController());
  final contactController = getOrPut(() => OtherBranchContactController());

  @override
  void initState() {
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
          return Center(child: CustomText(AppStrings.noDataFound.tr));
        }

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight:(controller.businessProfile.value?.profile?.description?.isNotEmpty??false)? Get.height * 0.35: Get.height * 0.30,
              flexibleSpace: FlexibleSpaceBar(
                background: OtherHeaderView(
                  schoolAboutUsController: controller,
                ),
                collapseMode: CollapseMode.parallax,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0,vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// "Our Staffs"
                    CommonCardWidget(
                      cardMargin: 0,
                      padding: 10,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(AppStrings.otherOurStaffs.tr, onSeeAll: () {
                            Get.to(StaffScreen());
                          }),
                          const SizedBox(height: 10),
                          if (data.staff != null && data.staff!.isNotEmpty)
                            _buildStaffList(data.staff!)
                          else
                            _buildEmptySectionCard(
                              title: AppStrings.otherAddStaffMembers.tr,
                              icon: AppIconAssets.about_us,
                              onTap: () => Get.to(StaffScreen()),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// PRODUCT
                    CommonCardWidget(
                        cardMargin: 0,
                        padding: 10,
                        bgColor: Color(0xff0085FE).withValues(alpha: 0.10),
                        child: Column(
                          children: [
                            _buildSectionTitle(AppStrings.otherProduct.tr, onSeeAll: () {
                              Get.toNamed(RouteHelper.getInventoryScreenRoute());
                            }),
                            OtherProductWidget(),
                          ],
                        )),
                    const SizedBox(height: 20),

                    /// "Our Organisation"
                    CommonCardWidget(
                      cardMargin: 0,
                      padding: 10,
                      child: Column(
                        children: [
                          _buildSectionTitle(AppStrings.otherOurOrganisation.tr, onSeeAll: () {
                            Get.to(OthersAboutUs());
                          }),
                          const SizedBox(height: 10),
                          if (data.aboutOrganisation != null && data.aboutOrganisation!.isNotEmpty)
                            _buildServicesList(data.aboutOrganisation!)
                          else
                            _buildOrgEmptyCard(onTap: () => Get.to(OthersAboutUs())),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// "Our Blogs"
                    CommonCardWidget(
                      cardMargin: 0,
                      padding: 10,
                      child: Column(
                        children: [
                          _buildSectionTitle(AppStrings.otherOurBlogs.tr, onSeeAll: () {
                            Get.to(OtherBlogsScreen());
                          }),
                          const SizedBox(height: 10),
                          if (data.blogs != null && data.blogs!.isNotEmpty)
                            _buildBlogsServicesList(data.blogs!)
                          else
                            _buildEmptySectionCard(
                              title: AppStrings.otherAddBlogPosts.tr,
                              icon: AppIconAssets.other_announcements,
                              onTap: () => Get.to(OtherBlogsScreen()),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// Gallery
                    CommonCardWidget(
                      cardMargin: 0,
                      padding: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ServiceHomeTitleWidget(title: AppStrings.gallery.tr),
                              GestureDetector(
                                onTap: () => Get.to(OtherServicePhotosPhotoScreen()),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.add_photo_alternate_outlined, size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      CustomText(AppStrings.otherAddEdit.tr, fontSize: 12, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (data.gallery != null && data.gallery!.isNotEmpty)
                            _buildGallery(data.gallery!, context)
                          else
                            _buildEmptySectionCard(
                              title: AppStrings.otherAddGalleryPhotos.tr,
                              icon: AppIconAssets.other_gallery,
                              onTap: () => Get.to(OtherServicePhotosPhotoScreen()),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// Website Section
                    Obx(() {
                      final website = contactController.website.isNotEmpty 
                          ? contactController.website 
                          : controller.website;
                      if (website.isEmpty) return const SizedBox.shrink();
                      return Column(
                        children: [
                          CommonCardWidget(
                            cardMargin: 0,
                            padding: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(AppStrings.website.tr),
                                const SizedBox(height: 10),
                                _buildContactRow(
                                  AppIconAssets.website_click,
                                  website,
                                  AppColors.primaryColor,
                                  isLink: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }),

                    /// Contact Us
                    CommonCardWidget(
                      cardMargin: 0,
                      padding: 10,
                      child: Column(
                        children: [
                          _buildSectionTitle(AppStrings.contactUs.tr, onSeeAll: () {
                            Get.to(OtherContactUs());
                          }),
                          const SizedBox(height: 10),
                          _buildContactUs(data.contactUs?.firstOrNull ?? ContactUsOtherProfile()),
                        ],
                      ),
                    ),

                    /// Map Section
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BusinessLocationWidget(
                          locationText: data.contactUs?.firstOrNull?.branch?.location?.name,
                          latitude: double.parse(data.contactUs?.firstOrNull?.branch?.location?.coordinates?[0].toString() ?? "0.0"),
                          longitude: double.parse(data.contactUs?.firstOrNull?.branch?.location?.coordinates?[1].toString() ?? "0.0"),
                          businessName: data.profile?.profileName ?? "",
                          padding: 10,
                          isTitleShow: true),
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

  Widget _buildOrgEmptyCard({required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business_center_outlined, size: 48, color: Colors.grey[350]),
          const SizedBox(height: 12),
          CustomText(
            AppStrings.otherNoOrganisationInfoAdded.tr,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),
          const SizedBox(height: 6),
          CustomText(
            AppStrings.otherShareOrgStory.tr,
            fontSize: 12,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  CustomText(
                    AppStrings.otherAddOrganisation.tr,
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySectionCard({
    required String title,
    required String icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: MeMenuCardDesign(title: title, icon: icon),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ServiceHomeTitleWidget(title: title),
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            child: CustomText(
              AppStrings.otherAddEdit.tr,
              color: AppColors.primaryColor,
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
                    borderRadius: const BorderRadius.only(
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
                        Colors.black.withValues(alpha: 0.8)
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
                        service.title ?? "",
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      CustomText(
                        service.description ?? "",
                            color: AppColors.whiteE5, fontSize: 12,
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
                        Colors.black.withValues(alpha: 0.8)
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

  Widget _buildGallery(List<Gallery> galleryList, BuildContext context) {
    final List<String> allImages = [];
    for (var g in galleryList) {
      if (g.imageUrls != null) allImages.addAll(g.imageUrls!);
    }
    if (allImages.isEmpty) return const SizedBox.shrink();
    return _buildGalleryLayout(context, allImages);
  }

  Widget _buildGalleryLayout(BuildContext context, List<String> images) {
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
              CachedNetworkImage(
                imageUrl: display[index],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[200]),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[200],
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

    if (display.length == 1) {
      return SizedBox(height: height, width: double.infinity, child: imgTile(0));
    }

    if (display.length == 2) {
      return SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(child: imgTile(0)),
            const SizedBox(width: gap),
            Expanded(child: imgTile(1)),
          ],
        ),
      );
    }

    if (display.length == 3) {
      return SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(child: imgTile(0)),
            const SizedBox(width: gap),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: imgTile(1)),
                  const SizedBox(height: gap),
                  Expanded(child: imgTile(2)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: imgTile(0)),
                const SizedBox(width: gap),
                Expanded(child: imgTile(1)),
              ],
            ),
          ),
          const SizedBox(height: gap),
          Expanded(
            child: Row(
              children: [
                Expanded(child: imgTile(2)),
                const SizedBox(width: gap),
                Expanded(child: imgTile(3, showOverlay: extra > 0)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactUs(ContactUsOtherProfile contacts) {
    final branch = contacts.branch;
    final firstDept = contacts.departments?.isNotEmpty == true ? contacts.departments!.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
              Row(
                children: [
                  const Icon(Icons.business_outlined, size: 16, color: AppColors.secondaryTextColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: CustomText(
                      branch?.name ?? "",
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.to(OtherBranchOnlyScreen(schoolContactUsData: SchoolContactUsData(id: contacts.id,branch: Branch(name: contacts.branch?.name,location:SchoolLocation(name: contacts.branch!.location?.name ,coordinates:  contacts.branch!.location?.coordinates??[]),website: contacts.branch?.website),departments: contacts.departments??[] ,schoolId: contacts.id,v:contacts.v ))),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.edit_outlined, size: 14, color: AppColors.primaryColor),
                          SizedBox(width: 4),
                          CustomText('Edit', fontSize: 12, color: AppColors.primaryColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (branch?.website != null && branch!.website!.isNotEmpty)
                _buildContactRow(AppIconAssets.website_click,
                    branch.website!, AppColors.primaryColor, isLink: true),
              if (firstDept != null) ...[
                if (firstDept.phone != null && firstDept.phone!.isNotEmpty)
                  _buildContactRow(AppIconAssets.phone_outline,
                      firstDept.phone!, AppColors.mainTextColor),
                if (firstDept.email != null && firstDept.email!.isNotEmpty)
                  _buildContactRow(AppIconAssets.email,
                      firstDept.email!, AppColors.mainTextColor),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => Get.to(OtherBranchDetailsFormScreen()),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add, size: 16, color: AppColors.primaryColor),
                SizedBox(width: 6),
                CustomText('Add More', fontSize: 13, color: AppColors.primaryColor, fontWeight: FontWeight.w600),
              ],
            ),
          ),
        ),
      ],
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
