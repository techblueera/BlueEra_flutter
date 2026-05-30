import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/school_academics_page.dart';
import 'package:BlueEra/features/me/school/view/category/career_jobs/school_job_listing_screen.dart';
import 'package:BlueEra/features/me/school/view/category/notice_news/notice_news_screen.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_course_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_director_card_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_management_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_student_corner.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:BlueEra/widgets/social_gallery_grid.dart';
import 'package:BlueEra/widgets/website_preview_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class DiscoverSchoolHomeScreen extends StatelessWidget {
  DiscoverSchoolHomeScreen({super.key});

  final schoolAboutUsController = Get.find<SchoolAboutUsController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = schoolAboutUsController.schoolDetailsData?.value;

      return Scaffold(
        backgroundColor: AppColors.appBackgroundColor,
        appBar: CommonBackAppBar(
          title: AppStrings.school,
        ),
        bottomNavigationBar: _buildBottomBar(),
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER with rating, type, establishment
              _SchoolHeader(controller: schoolAboutUsController),

              SizedBox(height: SizeConfig.paddingXS),

              /// DIRECTOR / PRINCIPAL MESSAGE
              DirectorCard(
                schoolAboutUsController: schoolAboutUsController,
              ),

              SizedBox(height: SizeConfig.paddingXS),

              /// MANAGEMENT
              _ManagementSection(data: data),

              SizedBox(height: SizeConfig.paddingXS),

              /// COURSES
              _CoursesSection(data: data),

              SizedBox(height: SizeConfig.paddingXS),

              /// CAMPUS GALLERY (social-style grid)
              _GallerySection(data: data),

              SizedBox(height: SizeConfig.paddingXS),

              /// QUICK LINKS (Job Vacancy, Academics, Student Corner, Notices)
              _QuickLinksSection(),

              SizedBox(height: SizeConfig.paddingXS),

              /// REVIEWS (placeholder)
              _ReviewsSection(),

              SizedBox(height: SizeConfig.paddingXS),

              /// CONTACT US (clickable phone, email, website)
              _ContactUsSection(data: data),

              SizedBox(height: SizeConfig.paddingXS),

              /// WEBSITE PREVIEW
              WebsitePreviewCard(
                url: data?.contacts?.firstOrNull?.branch?.website ?? '',
              ),

              SizedBox(height: SizeConfig.paddingXS),

              /// LOCATION MAP
              _LocationSection(data: data),

              SizedBox(height: kBottomNavigationBarHeight + SizeConfig.size50),
            ],
          ),
        ),
      );
    });
  }

  Widget? _buildBottomBar() {
    if (schoolAboutUsController.schoolDetailsData?.value.ownerId == userId) {
      return null;
    }
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: SizeConfig.paddingS,
          right: SizeConfig.paddingS,
          bottom: SizeConfig.paddingM,
          top: SizeConfig.paddingXSL,
        ),
        child: Row(
          children: [
            Expanded(
              child: PositiveCustomBtn(
                onTap: () {
                  final chatViewController = Get.find<ChatViewController>();
                  chatViewController.checkChatConnectionAndOpenChat(
                    userId: schoolAboutUsController
                            .schoolDetailsData?.value.ownerId ??
                        '',
                    route: AppConstants.route_discover,
                  );
                },
                title: AppStrings.chat,
              ),
            ),
            SizedBox(width: SizeConfig.paddingS),
            Expanded(
              child: PositiveCustomBtn(
                onTap: () =>
                    commonSnackBar(message: AppStrings.comingSoonLabel.tr),
                title: AppStrings.bookInquiry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER SECTION — banner, logo, name, stats (rating, type, est. year)
// ─────────────────────────────────────────────────────────────────────────────
class _SchoolHeader extends StatelessWidget {
  final SchoolAboutUsController controller;
  const _SchoolHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final data = controller.schoolDetailsData?.value;
    final bannerUrl = data?.bannerUrl ?? '';
    final logoUrl = data?.logo ?? '';
    final name = data?.name ?? '';
    final description = data?.aboutId?.visionAndMission ?? '';
    final type = data?.type ?? '';
    final estYear = data?.establishmentYear;

    return CommonCardWidget(
      cardMargin: 0,
      padding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner + Logo
          SizedBox(
            height: 180,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[100],
                    ),
                    child: bannerUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: bannerUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const SizedBox.shrink(),
                          )
                        : null,
                  ),
                ),
                // Logo
                Positioned(
                  left: 20,
                  top: 90,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8)
                      ],
                    ),
                    child: ClipOval(
                      child: logoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: logoUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Icon(
                                Icons.school,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            )
                          : Icon(
                              Icons.school,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Name
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  name,
                  fontSize: SizeConfig.size18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  SizedBox(height: SizeConfig.size4),
                  CustomText(
                    description,
                    fontSize: SizeConfig.size12,
                    color: AppColors.secondaryTextColor,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: SizeConfig.paddingS),

          // Stats row: Rating, Type, Est. Year
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
            child: Row(
              children: [
                _statChip(
                  icon: Icons.star_rounded,
                  iconColor: Colors.amber,
                  label: AppStrings.newLabel.tr,
                ),
                SizedBox(width: SizeConfig.paddingS),
                if (type.isNotEmpty)
                  _statChip(
                    icon: Icons.school_outlined,
                    iconColor: AppColors.primaryColor,
                    label: type,
                  ),
                if (type.isNotEmpty) SizedBox(width: SizeConfig.paddingS),
                if (estYear != null)
                  _statChip(
                    icon: Icons.calendar_today_outlined,
                    iconColor: AppColors.primaryColor,
                    label: "${AppStrings.estPrefix.tr} $estYear",
                  ),
              ],
            ),
          ),

          SizedBox(height: SizeConfig.paddingS),
        ],
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: SizeConfig.size16, color: iconColor),
        SizedBox(width: SizeConfig.size4),
        CustomText(
          label,
          fontSize: SizeConfig.size12,
          color: AppColors.secondaryTextColor,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MANAGEMENT SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _ManagementSection extends StatelessWidget {
  final SchoolDetailsData? data;
  const _ManagementSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final management = data?.aboutId?.management ?? [];
    if (management.isEmpty) {
      return _emptySection(
        Icons.people_outline,
        AppStrings.managementTrust.tr,
        AppStrings.noManagementDetailsAvailable.tr,
      );
    }
    return SchoolManagementSection(
      managementData: management,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COURSES SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _CoursesSection extends StatelessWidget {
  final SchoolDetailsData? data;
  const _CoursesSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final courses = data?.courses ?? [];
    if (courses.isEmpty) {
      return _emptySection(
        Icons.menu_book_outlined,
        AppStrings.coursesLabel.tr,
        AppStrings.noCoursesAvailable.tr,
      );
    }
    return SchoolCourseSection(courses: courses, isEdit: false);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GALLERY SECTION (social-style grid using SocialGalleryGrid)
// ─────────────────────────────────────────────────────────────────────────────
class _GallerySection extends StatelessWidget {
  final SchoolDetailsData? data;
  const _GallerySection({required this.data});

  @override
  Widget build(BuildContext context) {
    final campusLife = data?.campusLife ?? [];
    final List<String> allImages = [];
    for (var item in campusLife) {
      for (var img in item.images ?? []) {
        if (img.url != null) allImages.add(img.url!);
      }
    }

    if (allImages.isEmpty) {
      return _emptySection(
        Icons.photo_library_outlined,
        AppStrings.gallery.tr,
        AppStrings.noPhotosAvailableMsg.tr,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.photo_library_outlined, AppStrings.gallery.tr),
            SizedBox(height: SizeConfig.paddingXS),
            SocialGalleryGrid(imageUrls: allImages),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK LINKS SECTION (Job, Academics, Student Corner, Notices)
// ─────────────────────────────────────────────────────────────────────────────
class _QuickLinksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.link_outlined, AppStrings.quickLinksLabel.tr),
            SizedBox(height: SizeConfig.paddingXS),
            _quickLinkTile(
              icon: Icons.work_outline,
              title: AppStrings.jobVacancy.tr,
              onTap: () => Get.to(SchoolJobListingScreen(isEdit: false)),
            ),
            Divider(color: Colors.grey.shade200, height: 1),
            _quickLinkTile(
              icon: Icons.school_outlined,
              title: AppStrings.academics.tr,
              onTap: () => Get.to(SchoolAcademicsPage(isEdit: false)),
            ),
            Divider(color: Colors.grey.shade200, height: 1),
            _quickLinkTile(
              icon: Icons.groups_outlined,
              title: AppStrings.studentCorner.tr,
              onTap: () => Get.to(SchoolStudentCorner(isEdit: false)),
            ),
            Divider(color: Colors.grey.shade200, height: 1),
            _quickLinkTile(
              icon: Icons.campaign_outlined,
              title: AppStrings.noticesNews.tr,
              onTap: () => Get.to(NoticeNewsScreen(isEdit: false)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickLinkTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.paddingS),
        child: Row(
          children: [
            Icon(icon, size: SizeConfig.size20, color: AppColors.primaryColor),
            SizedBox(width: SizeConfig.paddingXS),
            Expanded(
              child: CustomText(
                title,
                fontSize: SizeConfig.size14,
                fontWeight: FontWeight.w500,
                color: AppColors.mainTextColor,
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: SizeConfig.size16, color: AppColors.secondaryTextColor),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REVIEWS SECTION (placeholder)
// ─────────────────────────────────────────────────────────────────────────────
class _ReviewsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _emptySection(
      Icons.rate_review_outlined,
      AppStrings.reviewsTitle.tr,
      AppStrings.noReviewsYet.tr,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTACT US SECTION (clickable phone, email, website like hospital)
// ─────────────────────────────────────────────────────────────────────────────
class _ContactUsSection extends StatelessWidget {
  final SchoolDetailsData? data;
  const _ContactUsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final contacts = data?.contacts ?? [];

    if (contacts.isEmpty) {
      return _emptySection(
        Icons.phone_outlined,
        AppStrings.contactUs.tr,
        AppStrings.noContactDetailsMsg.tr,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.phone_outlined, AppStrings.contactUs.tr),
            SizedBox(height: SizeConfig.paddingXS),
            ...contacts.map((contact) => _buildBranchCard(contact)),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchCard(Contacts contact) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.paddingS),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        title: CustomText(
          contact.branch?.name ?? AppStrings.branchLabel.tr,
          fontWeight: FontWeight.w600,
          fontSize: SizeConfig.size14,
        ),
        childrenPadding: EdgeInsets.symmetric(
            horizontal: SizeConfig.paddingS, vertical: SizeConfig.paddingXS),
        children: [
          // Website
          if ((contact.branch?.website ?? '').isNotEmpty)
            _contactRow(
              AppIconAssets.website_click,
              contact.branch!.website!,
              isLink: true,
              onTap: () => _launchUrl(contact.branch!.website!),
            ),
          // Departments
          ...(contact.departments ?? []).map((dept) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((dept.department ?? '').isNotEmpty)
                  _contactRow(AppIconAssets.phone_outline, dept.department!),
                if ((dept.email ?? '').isNotEmpty)
                  _contactRow(
                    AppIconAssets.email,
                    dept.email!,
                    isLink: true,
                    onTap: () => _launchEmail(dept.email!),
                  ),
                if ((dept.phone ?? '').isNotEmpty)
                  _contactRow(
                    AppIconAssets.phone_outline,
                    dept.phone!,
                    isLink: true,
                    onTap: () => _launchPhone(dept.phone!),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.paddingXS),
                  child: Divider(
                      height: 1, thickness: 0.5, color: Colors.grey.shade300),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _contactRow(String icon, String text,
      {bool isLink = false, VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            LocalAssets(
              imagePath: icon,
              imgColor:
                  isLink ? AppColors.primaryColor : AppColors.mainTextColor,
              height: 20,
              width: 20,
            ),
            SizedBox(width: SizeConfig.paddingXS),
            Expanded(
              child: CustomText(
                text,
                fontSize: SizeConfig.size13,
                color: isLink
                    ? AppColors.primaryColor
                    : AppColors.secondaryTextColor,
                decoration:
                    isLink ? TextDecoration.underline : TextDecoration.none,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    launchUrl(Uri(scheme: 'tel', path: clean));
  }

  void _launchEmail(String email) {
    launchUrl(Uri(scheme: 'mailto', path: email));
  }

  void _launchUrl(String url) {
    final uri = url.startsWith('http') ? url : 'https://$url';
    launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCATION SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _LocationSection extends StatelessWidget {
  final SchoolDetailsData? data;
  const _LocationSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final coords = data?.location?.coordinates;
    if (coords == null ||
        coords.length < 2 ||
        coords[0] == 0.0 ||
        coords[1] == 0.0) {
      return const SizedBox.shrink();
    }

    return BusinessLocationWidget(
      locationText: data?.name,
      latitude: double.tryParse(coords[0].toString()) ?? 0.0,
      longitude: double.tryParse(coords[1].toString()) ?? 0.0,
      businessName: data?.name ?? '',
      padding: SizeConfig.paddingXSL,
      isTitleShow: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

Widget _sectionHeader(IconData icon, String title) {
  return Row(
    children: [
      Icon(icon, color: AppColors.primaryColor, size: SizeConfig.size20),
      SizedBox(width: SizeConfig.paddingXS),
      ServiceHomeTitleWidget(title: title),
    ],
  );
}

Widget _emptySection(IconData icon, String title, String message) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
    child: CommonCardWidget(
      cardMargin: 0,
      child: Column(
        children: [
          _sectionHeader(icon, title),
          SizedBox(height: SizeConfig.paddingM),
          EmptyStateWidget(
            message: message,
            imageSize: SizeConfig.size60,
          ),
          SizedBox(height: SizeConfig.paddingS),
        ],
      ),
    ),
  );
}
