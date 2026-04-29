import 'package:BlueEra/core/api/model/school_contact_us_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/features/common/service/controller/service_controller.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/common/service/view/service_details_view_screen.dart';
import 'package:BlueEra/features/common/service/view/service_upload_screen.dart';
import 'package:BlueEra/features/common/service/view/view_service_list.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_share_banner.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/me_menu_card_design.dart';
import 'package:BlueEra/features/me/others/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/me/others/controller/other_branch_contact_controller.dart';
import 'package:BlueEra/features/me/others/model/business_profile_full_model.dart' hide Location;
import 'package:BlueEra/features/me/others/view/about_us/about_us.dart';
import 'package:BlueEra/features/me/others/view/management/management_screen.dart';
import 'package:BlueEra/features/me/others/view/other_blog/other_blogs_screen.dart';
import 'package:BlueEra/features/me/others/view/other_career_jobs/other_job_listing_screen.dart';
import 'package:BlueEra/features/me/others/view/other_contact_us/other_branch_details_form_screen.dart';
import 'package:BlueEra/features/me/others/view/other_contact_us/other_branch_only_screen.dart';
import 'package:BlueEra/features/me/others/view/other_contact_us/other_contact_us.dart';
import 'package:BlueEra/features/me/others/view/other_service_gallery/other_service_photos_screen.dart';
import 'package:BlueEra/features/me/others/view/staff/staff_screen.dart';
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
  final serviceController = getOrPut(() => ServiceController());

  @override
  void initState() {
    super.initState();
    _loadProfileServices();
  }

  void _loadProfileServices() {
    serviceController.getServices({
      ApiKeys.all: false,
      ApiKeys.type: AppConstants.service,
      ApiKeys.providerType: ProviderType.business.title,
      ApiKeys.subType: 'homeService',
    });
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
            // SliverAppBar(
            //   expandedHeight:(controller.businessProfile.value?.profile?.description?.isNotEmpty??false)? Get.height * 0.35: Get.height * 0.30,
            //   flexibleSpace: FlexibleSpaceBar(
            //     background: OtherHeaderView(
            //       schoolAboutUsController: controller,
            //     ),
            //     collapseMode: CollapseMode.parallax,
            //   ),
            // ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0,vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
               /*     /// "Our Staffs"
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
                    const SizedBox(height: 10),*/
                    /// "Our Services"
                    CommonCardWidget(
                      cardMargin: 0,
                      padding: 10,
                      child: Obx(() {
                        final services =
                            serviceController.serviceDataList.toList();
                        final hasServices = services.isNotEmpty;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOurServicesHeader(hasServices: hasServices),
                            const SizedBox(height: 10),
                            if (hasServices)
                              _buildOurServicesHorizontalList(
                                  services.take(5).toList())
                            else
                              _buildServicesEmptyCard(),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    /// "Management"
                    CommonCardWidget(
                      cardMargin: 0,
                      padding: 10,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildManagementHeader(),
                          const SizedBox(height: 10),
                          if (data.management != null && data.management!.isNotEmpty)
                            _buildManagementList(data.management!)
                          else
                            _buildManagementEmptyCard(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                  /*  /// "Our Organisation"
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
                    const SizedBox(height: 10),*/

             /*       /// "Our Blogs"
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
                    const SizedBox(height: 10),*/

                    /// "Career / Jobs"
                    CommonCardWidget(
                      cardMargin: 0,
                      padding: 10,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCareerJobsHeader(),
                          const SizedBox(height: 10),
                          _buildCareerJobsEmptyCard(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),



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
                            _buildGalleryEmptyCard(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                /*    /// Website Section
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
*/
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
                    const SizedBox(height: 10),

                    /// Map Section
                    if ((data.contactUs?.firstOrNull?.branch?.location?.coordinates != null &&
                        data.contactUs!.firstOrNull!.branch!.location!.coordinates!.length >= 2 &&
                        (double.tryParse(data.contactUs!.firstOrNull!.branch!.location!.coordinates![0].toString()) ?? 0.0) != 0.0 &&
                        (double.tryParse(data.contactUs!.firstOrNull!.branch!.location!.coordinates![1].toString()) ?? 0.0) != 0.0))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BusinessLocationWidget(
                            locationText: data.contactUs?.firstOrNull?.branch?.location?.name,
                            latitude: double.parse(data.contactUs!.firstOrNull!.branch!.location!.coordinates![0].toString()),
                            longitude: double.parse(data.contactUs!.firstOrNull!.branch!.location!.coordinates![1].toString()),
                            businessName: data.profile?.profileName ?? "",
                            padding: 10,
                            isTitleShow: true),
                      ),

                    const SizedBox(height: 20),

                    /// Promo share banner — shop photo, name, subcategory
                    /// Reusable share banner — reads from
                    /// ViewBusinessDetailsController, so every business
                    /// home screen gets the same card by dropping
                    /// `const BusinessShareBanner()` at the end.
                    const BusinessShareBanner(),

                    const SizedBox(height: 4 * kBottomNavigationBarHeight),

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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business_center_outlined, size: 36, color: Colors.grey[350]),
          const SizedBox(height: 8),
          CustomText(
            AppStrings.otherNoOrganisationInfoAdded.tr,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),
          const SizedBox(height: 4),
          CustomText(
            AppStrings.otherShareOrgStory.tr,
            fontSize: 11,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
                    fontSize: 12,
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

  Widget _buildManagementHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ServiceHomeTitleWidget(title: AppStrings.otherManagementTitle.tr),
        InkWell(
          onTap: () => Get.to(() => const ManagementScreen()),
          child: CustomText(
            AppStrings.viewAll,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildManagementList(List<Management> managementList) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: managementList.length,
        itemBuilder: (context, index) {
          final member = managementList[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              border: Border.all(color: AppColors.whiteE5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: member.imageUrl ?? "",
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            member.name ?? "",
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((member.position ?? "").isNotEmpty)
                            CustomText(
                              member.position ?? "",
                              color: AppColors.whiteE5,
                              fontSize: 12,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildManagementEmptyCard() {
    return GestureDetector(
      onTap: () => Get.to(() => const ManagementScreen()),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/other_management.png',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined,
                        size: 40, color: Colors.white),
                    const SizedBox(height: 10),
                    CustomText(
                     "You Have Not Update Your Team Management",
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: CustomText(
                       "Add Now",
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareerJobsHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ServiceHomeTitleWidget(title: AppStrings.otherJobsTitle.tr),
        InkWell(
          onTap: () => Get.to(() => const OtherJobListingScreen()),
          child: CustomText(
            "View All",
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCareerJobsEmptyCard() {
    return GestureDetector(
      onTap: () => Get.to(() => const OtherJobListingScreen()),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/other_job.png',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined,
                        size: 40, color: Colors.white),
                    const SizedBox(height: 10),
                    CustomText(
                      "You Have Not Post Any Job",
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: CustomText(
                        "Post Now",
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOurServicesHeader({bool hasServices = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ServiceHomeTitleWidget(title: AppStrings.ourServices.tr),
        InkWell(
          onTap: () => Get.to(
            () => ViewServiceList(
              providerType: ProviderType.business,
              showScaffold: true,
            ),
          ),
          child: CustomText(
            hasServices ? "Manage" : AppStrings.viewAll.tr,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildOurServicesHorizontalList(List<GetServiceModel> services) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final service = services[index];
          final firstPhoto =
              (service.photos?.isNotEmpty ?? false) ? service.photos!.first : '';
          return InkWell(
            onTap: () => Get.to(() => ServiceDetailsScreen(service: service)),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10)),
                    child: SizedBox(
                      height: 100,
                      width: 160,
                      child: firstPhoto.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: firstPhoto,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  Container(color: Colors.grey[300]),
                              placeholder: (_, __) =>
                                  Container(color: Colors.grey[200]),
                            )
                          : Container(color: Colors.grey[300]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          service.title ?? AppStrings.na,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        CustomText(
                          "₹${service.priceRange?.min ?? 0} - ₹${service.priceRange?.max ?? 0}",
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServicesEmptyCard() {
    return GestureDetector(
      onTap: _onAddServiceTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/other_service_add.png',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined,
                        size: 40, color: Colors.white),
                    const SizedBox(height: 10),
                    CustomText(
                      "You Have Not Post\nAny Service",
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomText(
                        "Add Service",
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAddServiceTap() {
    if (accountTypeGlobal == AppConstants.individual) {
      if (userProfessionGlobal.trim().isEmpty ||
          userDesignationGlobal.toString().trim().isEmpty) {
        commonSnackBar(
            message: AppStrings.kindlyAddServicesProfession.tr);
        return;
      }
    } else {
      if (businessCategoryGlobal.trim().isEmpty ||
          businessSubCategoryGlobal.trim().isEmpty) {
        commonSnackBar(
            message: AppStrings.kindlyAddServicesCategory.tr);
        return;
      }
    }
    Get.to(() =>
        ServiceUploadScreen(providerType: ProviderType.business));
  }

  Widget _buildGalleryEmptyCard() {
    return GestureDetector(
      onTap: () => Get.to(OtherServicePhotosPhotoScreen()),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/other_gallery.png',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined,
                        size: 40, color: Colors.white),
                    const SizedBox(height: 10),
                    CustomText(
                      "You Have Not Post Photo In Your Gallery",
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: CustomText(
                        "Upload Photo",
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                          CustomText(AppStrings.edit, fontSize: 12, color: AppColors.primaryColor),
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
                CustomText(AppStrings.addMore, fontSize: 13, color: AppColors.primaryColor, fontWeight: FontWeight.w600),
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

