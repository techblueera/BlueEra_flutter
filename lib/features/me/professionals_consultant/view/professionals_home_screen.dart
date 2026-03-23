import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/professional_profile_res_model.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/basic_profile_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/portfolio_project_card_widget.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/portfolio_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/pricing_engagement_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professional_contact_us_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professional_profile_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professional_service_offered.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professionals_certificates_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professionals_timing_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfessionalsHomeScreen extends StatelessWidget {
  ProfessionalsHomeScreen({super.key});

  final viewProfileController =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);

  final controller = Get.find<AiProfessionalsController>();
  final personalCreateProfileController =
      getOrPut(() => PersonalCreateProfileController());

  // Dummy placeholder colors
  static const _dummyBg = Color(0xFFF5F5F5);
  static const _dummyCardBg = Color(0xFFEEEEEE);
  static const _dummyTextColor = Color(0xFFBDBDBD);
  static const _dummyDarkText = Color(0xFF9E9E9E);
  static const _dummyBorderColor = Color(0xFFE0E0E0);

  bool _statsFetched = false;

  void _navigateToEdit(Widget screen) async {
    await Get.to(() => screen);
    controller.professionalsFullDetailsController();
  }

  void _fetchStatsOnce() {
    if (!_statsFetched && userId.isNotEmpty) {
      _statsFetched = true;
      viewProfileController.UserFollowersAndPostsCount(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.appBackgroundColor,
      child: Obx(() {
        final data = controller.getProfessionalServiceRes?.value.data;
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        _fetchStatsOnce();

        return Padding(
          padding: EdgeInsets.all(SizeConfig.paddingXS),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                CommonCardWidget(
                  cardMargin: 0,
                  padding: 0,
                  child: _buildHeaderSection(context),
                ),
                SizedBox(height: SizeConfig.size14),

                // Stats (Followers, Following, etc.)
                _buildStatsSection(data),
                SizedBox(height: SizeConfig.size14),

                // Expertise
                _buildExpertiseSection(data),
                SizedBox(height: SizeConfig.size14),

                // Our Services
                _buildServicesSection(data),
                SizedBox(height: SizeConfig.size14),

                // Portfolio / Case Studies
                _buildPortfolioSection(data),
                SizedBox(height: SizeConfig.size14),

                // Certificate & Awards
                _buildCertificatesSection(data),
                SizedBox(height: SizeConfig.size14),

                // Gallery
                _buildGallerySection(data, context),
                SizedBox(height: SizeConfig.size14),

                // // Testimonials
                // _buildTestimonialsSection(),
                // SizedBox(height: SizeConfig.size14),

                // Contact Us
                _buildContactSection(data),
                SizedBox(height: SizeConfig.size12),

                // Map
                BusinessLocationWidget(
                  locationText: data.basicDetails?.fullName,
                  latitude: double.parse(
                      data.contact?.location?.coordinates?[0].toString() ??
                          "0.0"),
                  longitude: double.parse(
                      data.contact?.location?.coordinates?[1].toString() ??
                          "0.0"),
                  businessName: "",
                  padding: 10,
                  isTitleShow: true,
                ),
                SizedBox(height: SizeConfig.size14),

                // Working Hours
                _buildTimingsSection(data),
                SizedBox(height: SizeConfig.size100),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ============================================================
  // SECTION HEADER WITH EDIT
  // ============================================================

  Widget _sectionHeader(String title, {VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: ServiceHomeTitleWidget(title: title)),
          if (onEdit != null)
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // DUMMY OVERLAY
  // ============================================================

  Widget _dummyOverlay({required Widget child}) {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 0.45, 0,
          ]),
          child: child,
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'No Data Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dummyTextLine({required double width, double height = 12}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: _dummyDarkText.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeaderSection(BuildContext context) {
    String capitalizeFirstLetter(String text) {
      if (text.isEmpty) return '';
      return text[0].toUpperCase() + text.substring(1).toLowerCase();
    }

    return CustomFormCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A1A1A), Color(0xFF2B2B2B)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Obx(() {
                      final banner = personalCreateProfileController
                              .coverImagePath?.value ??
                          '';
                      return banner.isNotEmpty
                          ? Image.network(banner, fit: BoxFit.cover)
                          : CachedNetworkImage(
                              imageUrl: personalCreateProfileController
                                      .imagePath?.value ??
                                  '',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                              ),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.person,
                                      size: SizeConfig.size32 / 2),
                            );
                    }),
                  ),
                ),
                Positioned(
                  left: 20,
                  top: 90,
                  child: Obx(() {
                    return CommonProfileImage(
                      imagePath:
                          personalCreateProfileController.imagePath?.value ??
                              "",
                      onImageUpdate: (image) async {
                        personalCreateProfileController.imagePath?.value =
                            image;
                        dynamic dataImage =
                            await multiPartImage(imagePath: image);
                        var reqProfile = {ApiKeys.profile_image: dataImage};
                        await personalCreateProfileController
                            .updateUserProfileDetails(
                                params: reqProfile,
                                isFromProfileOnly: true);
                      },
                      dialogTitle: AppStrings.uploadProfilePicture,
                      showProfileBorder: true,
                    );
                  }),
                ),
                Positioned(
                  right: 10,
                  top: 8,
                  child: InkWell(
                    onTap: () async {
                      final String? newPath =
                          await SelectProfilePictureDialog.showLogoDialog(
                        context,
                        AppStrings.editCoverPicture,
                        cropAspectRatio:
                            CropAspectRatio(width: 3, height: 1),
                      );
                      if (newPath == null || newPath.isEmpty) return;
                      dynamic dataImage =
                          await multiPartImage(imagePath: newPath);
                      var reqProfile = {ApiKeys.coverpicture: dataImage};
                      await personalCreateProfileController
                          .updateUserProfileDetails(
                              params: reqProfile,
                              isFromProfileOnly: true);
                    },
                    child: CircleAvatar(
                      backgroundColor:
                          AppColors.black.withValues(alpha: 0.3),
                      child: LocalAssets(
                          imagePath: 'assets/images/image.png'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: SizeConfig.size15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  capitalizeFirstLetter(
                    viewProfileController.personalProfileDetails.value
                            .user?.name ??
                        '',
                  ),
                  fontSize: SizeConfig.size24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
              ],
            ),
          ),
          if (viewProfileController.personalProfileDetails.value.user?.bio
                  ?.isNotEmpty ??
              false)
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size15),
              child: ExpandableText(
                text: viewProfileController
                        .personalProfileDetails.value.user?.bio ??
                    "",
                trimLines: 3,
                style: TextStyle(
                  color: AppColors.mainTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
                expandMode: ExpandMode.dialog,
                dialogTitle: AppStrings.bio,
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ============================================================
  // STATS SECTION (Followers, Following, Posts, Joined)
  // ============================================================

  Widget _buildStatsSection(ProfessionalProfileData data) {
    String formatJoinedDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return '-';
      try {
        final date = DateTime.parse(dateStr);
        return "${date.day}/${date.month}/${date.year}";
      } catch (_) {
        return '-';
      }
    }

    return CommonCardWidget(
      cardMargin: 0,
      padding: 0,
      child: Obx(() {
        final followers = viewProfileController.followersCount.value;
        final following = viewProfileController.followingCount.value;
        final posts = viewProfileController.postsCount.value;
        final joinedDate = formatJoinedDate(data.createdAt);

        return Container(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size14, vertical: SizeConfig.size12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              _statItem("Posts", "$posts"),
              _statDivider(),
              _statItem("Followers", _formatCount(followers)),
              _statDivider(),
              _statItem("Following", _formatCount(following)),
              _statDivider(),
              _statItem("Joined", joinedDate),
            ],
          ),
        );
      }),
    );
  }

  Widget _statItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          CustomText(
            label,
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w400,
          ),
          const SizedBox(height: 4),
          CustomText(
            value,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.bold,
            color: AppColors.mainTextColor,
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade200,
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return "${(count / 1000000).toStringAsFixed(1)}M";
    if (count >= 1000) return "${(count / 1000).toStringAsFixed(1)}k";
    return "$count";
  }

  // ============================================================
  // EXPERTISE
  // ============================================================

  Widget _buildExpertiseSection(ProfessionalProfileData data) {
    final expertise = data.about?.expertise ?? [];
    final hasData = expertise.isNotEmpty;

    return CommonCardWidget(
      cardMargin: 0,
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Expertise",
              onEdit: () =>
                  _navigateToEdit(ProfessionalProfileScreen())),
          if (hasData)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: expertise
                  .expand((item) => item.split(','))
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.3)),
                        ),
                        child: CustomText(tag,
                            fontSize: SizeConfig.small,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500),
                      ))
                  .toList(),
            )
          else
            _dummyOverlay(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  4,
                  (_) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _dummyCardBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _dummyTextLine(width: 70, height: 10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // OUR SERVICES
  // ============================================================

  Widget _buildServicesSection(ProfessionalProfileData data) {
    final services = data.servicesOffered ?? [];
    final hasData = services.isNotEmpty;

    return CommonCardWidget(
      cardMargin: 0,
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Our Services",
              onEdit: () =>
                  _navigateToEdit(ProfessionalServiceOffered())),
          if (hasData)
            ...services.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 18, color: AppColors.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomText(s,
                            fontSize: SizeConfig.medium,
                            color: AppColors.mainTextColor),
                      ),
                    ],
                  ),
                ))
          else
            _dummyOverlay(
              child: Column(
                children: List.generate(
                  3,
                  (_) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 18, color: _dummyTextColor),
                        const SizedBox(width: 8),
                        _dummyTextLine(width: 150),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // PORTFOLIO / CASE STUDIES
  // ============================================================

  Widget _buildPortfolioSection(ProfessionalProfileData data) {
    final portfolio = data.portfolio ?? [];
    final hasData = portfolio.isNotEmpty;

    return CommonCardWidget(
      cardMargin: 0,
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Portfolio / Case Studies",
              onEdit: () => _navigateToEdit(PortfolioScreen())),
          if (hasData)
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: portfolio.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: Get.width * 0.85,
                    padding: EdgeInsets.zero,
                    child: PortfolioProjectCardWidget(
                      isShowMore: false,
                      project: portfolio[index],
                    ),
                  );
                },
              ),
            )
          else
            _dummyOverlay(
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _dummyCardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.work_outline,
                      size: 40, color: _dummyTextColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CERTIFICATES & AWARDS
  // ============================================================

  Widget _buildCertificatesSection(ProfessionalProfileData data) {
    final certs = data.certificates ?? [];
    final hasData = certs.isNotEmpty;

    return CommonCardWidget(
      cardMargin: 0,
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Certificate & Awards",
              onEdit: () =>
                  _navigateToEdit(ProfessionalsCertificatesScreen())),
          if (hasData)
            SizedBox(
              height: 260,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: certs.length,
                itemBuilder: (context, index) {
                  final cert = certs[index];
                  return Container(
                    width: 240,
                    margin: EdgeInsets.only(right: SizeConfig.size12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CachedNetworkImage(
                              imageUrl: cert.fileKey ?? "",
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  Container(color: Colors.grey[300]),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                    child: Icon(Icons.emoji_events,
                                        size: 40, color: Colors.grey)),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.1),
                                    Colors.black.withValues(alpha: 0.8),
                                  ],
                                  stops: const [0.5, 0.7, 1.0],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding:
                                  EdgeInsets.all(SizeConfig.size12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomText(
                                    cert.title ?? "Certificate",
                                    color: Colors.white,
                                    fontSize: SizeConfig.medium,
                                    fontWeight: FontWeight.bold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (cert.description != null &&
                                      cert.description!
                                          .isNotEmpty) ...[
                                    SizedBox(
                                        height: SizeConfig.size4),
                                    CustomText(
                                      cert.description!,
                                      color: Colors.white,
                                      fontSize: SizeConfig.small,
                                      maxLines: 2,
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                  ],
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
            )
          else
            _dummyOverlay(
              child: SizedBox(
                height: 160,
                child: Row(
                  children: List.generate(
                    2,
                    (_) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _dummyCardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(Icons.emoji_events,
                              size: 36, color: _dummyTextColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // GALLERY
  // ============================================================

  Widget _buildGallerySection(
      ProfessionalProfileData data, BuildContext context) {
    final urls = data.gallery?.signedUrls ?? [];
    final hasData = urls.isNotEmpty;

    return CommonCardWidget(
      cardMargin: 0,
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Gallery",
              onEdit: () =>
                  _navigateToEdit(ProfessionalsCertificatesScreen())),
          if (hasData)
            _buildGalleryGrid(urls, context)
          else
            _dummyOverlay(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemBuilder: (_, __) => Container(
                  decoration: BoxDecoration(
                    color: _dummyCardBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(Icons.image,
                        size: 28, color: _dummyTextColor),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid(
      List<String> signedUrls, BuildContext context) {
    final count = signedUrls.length;
    final hasMore = count > 4;

    Widget imageTile(int index, {double? height}) {
      return InkWell(
        onTap: () => navigatePushTo(
          context,
          ImageViewScreen(
            subTitle: AppStrings.imageViewer,
            appBarTitle: AppStrings.imageViewer,
            imageUrls: signedUrls,
            initialIndex: index,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: signedUrls[index],
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: Colors.grey[200]),
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
      );
    }

    Widget viewMoreOverlay(int index) {
      return InkWell(
        onTap: () => _openFullGallery(context, signedUrls),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: signedUrls[index],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[200]),
                errorWidget: (_, __, ___) =>
                    Container(color: Colors.grey[200]),
              ),
              Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: Center(
                  child: CustomText(
                    "+${count - 3}",
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 1 image: full width
    if (count == 1) {
      return imageTile(0, height: 200);
    }

    // 2 images: side by side
    if (count == 2) {
      return SizedBox(
        height: 160,
        child: Row(
          children: [
            Expanded(child: imageTile(0, height: 160)),
            const SizedBox(width: 6),
            Expanded(child: imageTile(1, height: 160)),
          ],
        ),
      );
    }

    // 3 images: 1 left + 2 right stacked
    if (count == 3) {
      return SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(flex: 1, child: imageTile(0, height: 200)),
            const SizedBox(width: 6),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(child: imageTile(1)),
                  const SizedBox(height: 6),
                  Expanded(child: imageTile(2)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4 images: 2x2 grid
    // 4+ images: 2x2 grid with "+N" overlay on last tile
    return SizedBox(
      height: 260,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: imageTile(0)),
                const SizedBox(width: 6),
                Expanded(child: imageTile(1)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                Expanded(child: imageTile(2)),
                const SizedBox(width: 6),
                Expanded(
                    child: hasMore ? viewMoreOverlay(3) : imageTile(3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFullGallery(BuildContext context, List<String> urls) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullGalleryScreen(imageUrls: urls),
      ),
    );
  }

  // ============================================================
  // TESTIMONIALS
  // ============================================================

  Widget _buildTestimonialsSection() {
    return CommonCardWidget(
      cardMargin: 0,
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Testimonials"),
          _dummyOverlay(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _dummyBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _dummyBorderColor),
              ),
              child: Column(
                children: [
                  Icon(Icons.format_quote,
                      size: 36, color: _dummyTextColor),
                  const SizedBox(height: 12),
                  _dummyTextLine(width: double.infinity, height: 8),
                  const SizedBox(height: 6),
                  _dummyTextLine(width: double.infinity, height: 8),
                  const SizedBox(height: 6),
                  _dummyTextLine(width: 200, height: 8),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: _dummyCardBg,
                        child: Icon(Icons.person,
                            size: 14, color: _dummyTextColor),
                      ),
                      const SizedBox(width: 8),
                      _dummyTextLine(width: 80),
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

  // ============================================================
  // CONTACT US
  // ============================================================

  Widget _buildContactSection(ProfessionalProfileData data) {
    final contact = data.contact;
    final hasData = contact != null &&
        ((contact.website ?? '').isNotEmpty ||
            (contact.phone ?? '').isNotEmpty ||
            (contact.email ?? '').isNotEmpty);

    return CommonCardWidget(
      cardMargin: 0,
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Contact Us",
              onEdit: () =>
                  _navigateToEdit(ProfessionalContactUsScreen())),
          if (hasData)
            Container(
              padding: EdgeInsets.all(SizeConfig.size12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((contact?.website ?? "").isNotEmpty)
                    _contactRow(AppIconAssets.website_click,
                        contact!.website!,
                        isLink: true),
                  if ((contact?.phone ?? "").isNotEmpty)
                    _contactRow(
                        AppIconAssets.phone_outline, contact!.phone!),
                  if ((contact?.email ?? "").isNotEmpty)
                    _contactRow(
                        AppIconAssets.email, contact!.email!),
                  if ((contact?.address ?? "").isNotEmpty)
                    _contactRow(AppIconAssets.location_new,
                        contact!.address!,
                        color: AppColors.secondaryTextColor),
                ],
              ),
            )
          else
            _dummyOverlay(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: _dummyBorderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _dummyContactItem(Icons.language),
                    _dummyContactItem(Icons.phone),
                    _dummyContactItem(Icons.email_outlined),
                    _dummyContactItem(Icons.location_on_outlined),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _contactRow(String icon, String text,
      {bool isLink = false, Color? color}) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
      child: Row(
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: isLink ? null : AppColors.mainTextColor,
            height: 20,
            width: 20,
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: InkWell(
              onTap: isLink ? () => launchUrl(Uri.parse(text)) : null,
              child: CustomText(
                text,
                color: color ?? AppColors.black,
                decoration: isLink
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dummyContactItem(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _dummyTextColor),
          const SizedBox(width: 12),
          _dummyTextLine(width: 160, height: 10),
        ],
      ),
    );
  }

  // ============================================================
  // WORKING HOURS
  // ============================================================

  Widget _buildTimingsSection(ProfessionalProfileData data) {
    final timings = data.timings;
    final hasData = timings?.schedule != null;

    return CommonCardWidget(
      cardMargin: 0,
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Working Hours",
              onEdit: () =>
                  _navigateToEdit(ProfessionalsTimingScreen())),
          if (hasData)
            _buildTimingsGrid(timings!)
          else
            _dummyOverlay(
              child: Column(
                children: [
                  "Monday",
                  "Tuesday",
                  "Wednesday",
                  "Thursday",
                  "Friday",
                  "Saturday",
                  "Sunday"
                ]
                    .map((day) => Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              _dummyTextLine(width: 80),
                              _dummyTextLine(width: 100, height: 10),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimingsGrid(Timings timings) {
    final schedule = timings.schedule;
    Widget item(
        String day, bool? open, String? openTime, String? closeTime) {
      final isOpen = open == true;
      final text = isOpen ? "$openTime - $closeTime" : "Closed";
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(day, fontWeight: FontWeight.w500),
            CustomText(
              text,
              color: isOpen ? Colors.green : Colors.red,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        item("Monday", schedule?.monday?.isOpen,
            schedule?.monday?.openTime, schedule?.monday?.closeTime),
        item("Tuesday", schedule?.tuesday?.isOpen,
            schedule?.tuesday?.openTime, schedule?.tuesday?.closeTime),
        item(
            "Wednesday",
            schedule?.wednesday?.isOpen,
            schedule?.wednesday?.openTime,
            schedule?.wednesday?.closeTime),
        item(
            "Thursday",
            schedule?.thursday?.isOpen,
            schedule?.thursday?.openTime,
            schedule?.thursday?.closeTime),
        item("Friday", schedule?.friday?.isOpen,
            schedule?.friday?.openTime, schedule?.friday?.closeTime),
        item(
            "Saturday",
            schedule?.saturday?.isOpen,
            schedule?.saturday?.openTime,
            schedule?.saturday?.closeTime),
        item("Sunday", schedule?.sunday?.isOpen,
            schedule?.sunday?.openTime, schedule?.sunday?.closeTime),
      ],
    );
  }
}

// ============================================================
// FULL GALLERY SCREEN
// ============================================================

class _FullGalleryScreen extends StatelessWidget {
  final List<String> imageUrls;

  const _FullGalleryScreen({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          "${AppStrings.gallery} (${imageUrls.length})",
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
        backgroundColor: AppColors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.mainTextColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: imageUrls.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => navigatePushTo(
              context,
              ImageViewScreen(
                subTitle: AppStrings.imageViewer,
                appBarTitle: AppStrings.imageViewer,
                imageUrls: imageUrls,
                initialIndex: index,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrls[index],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[200]),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
