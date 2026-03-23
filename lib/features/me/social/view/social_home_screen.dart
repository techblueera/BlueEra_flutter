import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/me/social/controller/social_home_controller.dart';
import 'package:BlueEra/features/me/social/model/social_profile_res_model.dart';
import 'package:BlueEra/features/me/social/view/event_schedule_screen.dart';
import 'package:BlueEra/features/me/social/view/social_achievements/social_certificates_screen.dart';
import 'package:BlueEra/features/me/social/view/social_activity_list_screen.dart';
import 'package:BlueEra/features/me/social/view/social_contact_us/social_contact_us_screen.dart';
import 'package:BlueEra/features/me/social/view/social_feed/social_feed_screen.dart';
import 'package:BlueEra/features/me/social/view/social_profile_identity_screen.dart';
import 'package:BlueEra/features/me/social/view/social_vision_mission_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_header_title_widget.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class SocialHomeScreen extends StatefulWidget {
  SocialHomeScreen({super.key});

  @override
  State<SocialHomeScreen> createState() => _SocialHomeScreenState();
}

class _SocialHomeScreenState extends State<SocialHomeScreen> {
  final ctrl = Get.put(SocialHomeController());

  final personalCreateProfileController =
      getOrPut(() => PersonalCreateProfileController());

  final viewProfileController =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);

  // Dummy placeholder colors (grayscale)
  static const _dummyBg = Color(0xFFF5F5F5);
  static const _dummyCardBg = Color(0xFFEEEEEE);
  static const _dummyTextColor = Color(0xFFBDBDBD);
  static const _dummyDarkText = Color(0xFF9E9E9E);
  static const _dummyBorderColor = Color(0xFFE0E0E0);

  @override
  void initState() {
    ctrl.fetchProfile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (ctrl.isLoading.value && ctrl.profile.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = ctrl.profile.value?.data;
        return SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size8),
          child: Column(
            children: [
              _buildHeaderSection(context),
              _identityCard(data?.identity),
              _activityVideosSection(data?.activities ?? []),
              _activitiesCard(data?.activities ?? []),
              _missionVisionCard(data?.missionVision),
              _eventsCard(data?.events ?? []),
              _achievementsCard(data?.achievements ?? []),
              _socialActivitiesCard(data?.socialActivities ?? []),
              _latestPostSection(data?.activities ?? []),
              _gallerySection(data),
              _testimonialSection(data),
              _buildContactCard(data),
              BusinessLocationWidget(
                locationText: "",
                latitude: double.parse(
                    data?.contact?.location?.coordinates?[0].toString() ??
                        "0.0"),
                longitude: double.parse(
                    data?.contact?.location?.coordinates?[1].toString() ??
                        "0.0"),
                businessName: "",
                padding: 0,
                isTitleShow: true,
              ),
              _quickLinksSection(data),
              SizedBox(height: kBottomNavigationBarHeight + 30),
            ],
          ),
        );
      }),
    );
  }

  // ============================================================
  // DUMMY PLACEHOLDER BUILDERS (Grayscale guide for empty state)
  // ============================================================

  /// Wraps content in a grayscale overlay with "No Data Found" badge
  Widget _dummyOverlay({required Widget child}) {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0, // R
            0.2126, 0.7152, 0.0722, 0, 0, // G
            0.2126, 0.7152, 0.0722, 0, 0, // B
            0, 0, 0, 0.45, 0, // A (reduced opacity)
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

  // --- Dummy Video Thumbnails ---
  Widget _dummyVideoThumbnails() {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size8),
        itemBuilder: (_, index) {
          return Container(
            width: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SizeConfig.size8),
              color: _dummyCardBg,
            ),
            child: Stack(
              children: [
                // Placeholder image area
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(SizeConfig.size8),
                    color: _dummyCardBg,
                  ),
                  child: Center(
                    child: Icon(Icons.image, size: 40, color: _dummyTextColor),
                  ),
                ),
                // Play button
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _dummyDarkText.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.play_arrow,
                        color: Colors.white.withValues(alpha: 0.7), size: 24),
                  ),
                ),
                // Title placeholder
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      color: _dummyDarkText.withValues(alpha: 0.3),
                    ),
                    child: Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Dummy Activity Grid ---
  Widget _dummyActivityGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        mainAxisSpacing: SizeConfig.size8,
        crossAxisSpacing: SizeConfig.size8,
        childAspectRatio: 3 / 2,
      ),
      itemBuilder: (_, index) {
        return Container(
          decoration: BoxDecoration(
            color: _dummyBg,
            borderRadius: BorderRadius.circular(SizeConfig.size8),
            border: Border.all(color: _dummyBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _dummyCardBg,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(SizeConfig.size8),
                      topRight: Radius.circular(SizeConfig.size8),
                    ),
                  ),
                  child: Center(
                    child:
                        Icon(Icons.image, size: 40, color: _dummyTextColor),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(SizeConfig.size8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dummyTextLine(width: 120),
                    const SizedBox(height: 6),
                    _dummyTextLine(width: 180, height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Dummy Event Card ---
  Widget _dummyEventCard() {
    return Container(
      decoration: BoxDecoration(
        color: _dummyBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _dummyBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event banner placeholder
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              color: _dummyCardBg,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event, size: 32, color: _dummyTextColor),
                const SizedBox(height: 8),
                _dummyTextLine(width: 140, color: _dummyTextColor),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _dummyCardBg,
                      child: Icon(Icons.person, size: 18, color: _dummyTextColor),
                    ),
                    const SizedBox(width: 8),
                    _dummyTextLine(width: 100),
                  ],
                ),
                SizedBox(height: SizeConfig.size8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: _dummyTextColor),
                    const SizedBox(width: 4),
                    _dummyTextLine(width: 120, height: 8),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 14, color: _dummyTextColor),
                    const SizedBox(width: 4),
                    _dummyTextLine(width: 80, height: 8),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time, size: 14, color: _dummyTextColor),
                    const SizedBox(width: 4),
                    _dummyTextLine(width: 60, height: 8),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Dummy Achievement Grid ---
  Widget _dummyAchievementGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: SizeConfig.size8,
        crossAxisSpacing: SizeConfig.size8,
        childAspectRatio: 3 / 2,
      ),
      itemBuilder: (_, index) {
        return Container(
          decoration: BoxDecoration(
            color: _dummyBg,
            borderRadius: BorderRadius.circular(SizeConfig.size8),
            border: Border.all(color: _dummyBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _dummyCardBg,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(SizeConfig.size8),
                      topRight: Radius.circular(SizeConfig.size8),
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.emoji_events,
                        size: 32, color: _dummyTextColor),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(SizeConfig.size6),
                child: _dummyTextLine(width: 80),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Dummy Social Activity Tile ---
  Widget _dummySocialActivityTile() {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: _dummyBg,
        borderRadius: BorderRadius.circular(SizeConfig.size8),
        border: Border.all(color: _dummyBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _dummyCardBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.volunteer_activism,
                color: _dummyTextColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dummyTextLine(width: 140),
                const SizedBox(height: 6),
                _dummyTextLine(width: 80, height: 8),
                const SizedBox(height: 6),
                _dummyTextLine(width: double.infinity, height: 8),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: _dummyTextColor),
                    const SizedBox(width: 4),
                    _dummyTextLine(width: 100, height: 8),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Dummy Latest Post ---
  Widget _dummyLatestPost() {
    return Container(
      decoration: BoxDecoration(
        color: _dummyBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _dummyBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _dummyCardBg,
                  child: Icon(Icons.person, size: 20, color: _dummyTextColor),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dummyTextLine(width: 100),
                    const SizedBox(height: 4),
                    _dummyTextLine(width: 60, height: 8),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dummyTextLine(width: double.infinity, height: 8),
                const SizedBox(height: 4),
                _dummyTextLine(width: 200, height: 8),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 180,
            width: double.infinity,
            color: _dummyCardBg,
            child: Center(
              child: Icon(Icons.image, size: 48, color: _dummyTextColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.thumb_up_outlined,
                    size: 18, color: _dummyTextColor),
                const SizedBox(width: 16),
                Icon(Icons.comment_outlined,
                    size: 18, color: _dummyTextColor),
                const SizedBox(width: 16),
                Icon(Icons.share_outlined,
                    size: 18, color: _dummyTextColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Dummy Gallery Grid ---
  Widget _dummyGalleryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, index) {
        return Container(
          decoration: BoxDecoration(
            color: _dummyCardBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(Icons.image, size: 28, color: _dummyTextColor),
          ),
        );
      },
    );
  }

  // --- Dummy Testimonial ---
  Widget _dummyTestimonial() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _dummyBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _dummyBorderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.format_quote, size: 36, color: _dummyTextColor),
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
                child: Icon(Icons.person, size: 14, color: _dummyTextColor),
              ),
              const SizedBox(width: 8),
              _dummyTextLine(width: 80),
            ],
          ),
        ],
      ),
    );
  }

  // --- Dummy Contact Card ---
  Widget _dummyContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: _dummyBorderColor),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dummyTextLine(width: 140, height: 14),
          const SizedBox(height: 12),
          _dummyContactItem(Icons.language),
          _dummyContactItem(Icons.phone),
          _dummyContactItem(Icons.email_outlined),
          _dummyContactItem(Icons.location_on_outlined),
        ],
      ),
    );
  }

  Widget _dummyContactItem(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _dummyTextColor),
          const SizedBox(width: 12),
          _dummyTextLine(width: 160, height: 10),
        ],
      ),
    );
  }

  // --- Dummy Quick Links ---
  Widget _dummyQuickLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dummyTextLine(width: 100, height: 12),
        const SizedBox(height: 10),
        ...List.generate(3, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _dummyTextLine(width: 140, height: 8),
        )),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: _dummyCardBg,
                child: Icon(Icons.link, size: 14, color: _dummyTextColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Dummy Text Line Placeholder ---
  Widget _dummyTextLine({
    required double width,
    double height = 12,
    Color? color,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color ?? _dummyDarkText.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }

  // --- Dummy Identity Card ---
  Widget _dummyIdentityCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dummyTextLine(width: 80, height: 14),
        const SizedBox(height: 8),
        _dummyTextLine(width: double.infinity, height: 8),
        const SizedBox(height: 4),
        _dummyTextLine(width: 250, height: 8),
        const SizedBox(height: 12),
        Divider(color: _dummyBorderColor, thickness: 0.5),
        const SizedBox(height: 12),
        _dummyTextLine(width: 70, height: 14),
        const SizedBox(height: 8),
        _dummyTextLine(width: double.infinity, height: 8),
        const SizedBox(height: 4),
        _dummyTextLine(width: 200, height: 8),
        const SizedBox(height: 12),
        Divider(color: _dummyBorderColor, thickness: 0.5),
        const SizedBox(height: 12),
        _dummyTextLine(width: 130, height: 14),
        const SizedBox(height: 8),
        _dummyTextLine(width: double.infinity, height: 8),
        const SizedBox(height: 4),
        _dummyTextLine(width: 180, height: 8),
      ],
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  /// Navigate to edit screen and refresh profile on return
  void _navigateToEdit(Widget screen) async {
    await Get.to(() => screen);
    ctrl.fetchProfile();
  }

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
  // HEADER SECTION
  // ============================================================

  Widget _buildHeaderSection(BuildContext context) {
    String capitalizeFirstLetter(String text) {
      if (text.isEmpty) return '';
      return text[0].toUpperCase() + text.substring(1).toLowerCase();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
      child: CustomFormCard(
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
                                  width: SizeConfig.size32,
                                  height: SizeConfig.size32,
                                  color: Colors.grey[300],
                                ),
                                errorWidget: (context, url, error) => Icon(
                                    Icons.person,
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
                                  params: reqProfile, isFromProfileOnly: true);
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
                                params: reqProfile, isFromProfileOnly: true);
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
            ServiceHomeHeaderTitleWidget(
              title: capitalizeFirstLetter(
                viewProfileController
                        .personalProfileDetails.value.user?.name ??
                    '',
              ),
              description:
                  "",
            ),
            SizedBox(height: 10,),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // IDENTITY CARD
  // ============================================================

  Widget _identityCard(identity) {
    final bool hasData = identity != null &&
        ((identity.bio ?? '').isNotEmpty ||
            (identity.journey ?? '').isNotEmpty ||
            (identity.familyBackground ?? '').isNotEmpty);

    return CommonCardWidget(
      child: SizedBox(
        width: Get.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(AppStrings.shortBio,
                onEdit: () =>
                    _navigateToEdit(SocialProfileIdentityScreen())),
            if (hasData) ...[
              CustomText(identity?.bio ?? "-", color: AppColors.black28),
              SizedBox(height: SizeConfig.size5),
              Divider(color: AppColors.whiteE5, thickness: 0.5),
              SizedBox(height: SizeConfig.size5),
              ServiceHomeTitleWidget(title: AppStrings.journey),
              SizedBox(height: SizeConfig.size5),
              CustomText(
                  identity?.journey ?? "-", color: AppColors.black28),
              SizedBox(height: SizeConfig.size5),
              Divider(color: AppColors.whiteE5, thickness: 0.5),
              SizedBox(height: SizeConfig.size5),
              ServiceHomeTitleWidget(title: AppStrings.familyBackground),
              SizedBox(height: SizeConfig.size8),
              CustomText(identity?.familyBackground ?? "-",
                  color: AppColors.black28),
            ] else
              _dummyOverlay(child: _dummyIdentityCard()),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTIVITY VIDEOS (Horizontal Scroll)
  // ============================================================

  Widget _activityVideosSection(List activities) {
    final videoActivities = activities
        .where((a) =>
            a?.mediaType == 'video' && (a?.mediaUrls ?? []).isNotEmpty)
        .toList();

    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.activities,
              onEdit: () => _navigateToEdit(SocialFeedScreen())),
          if (videoActivities.isEmpty)
            _dummyOverlay(child: _dummyVideoThumbnails())
          else
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: videoActivities.length,
                separatorBuilder: (_, __) =>
                    SizedBox(width: SizeConfig.size8),
                itemBuilder: (context, index) {
                  final a = videoActivities[index];
                  final url = (a?.mediaUrls ?? []).isNotEmpty
                      ? a?.mediaUrls?.first ?? ""
                      : "";
                  return _videoThumbnailTile(url, a?.title ?? "");
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _videoThumbnailTile(String thumbnailUrl, String title) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SizeConfig.size8),
        color: Colors.grey[200],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(SizeConfig.size8),
            child: thumbnailUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    width: 160,
                    height: 140,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.grey[300]),
                    errorWidget: (_, __, ___) =>
                        Container(color: Colors.grey[300]),
                  )
                : Container(color: Colors.grey[300]),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow,
                  color: Colors.white, size: 24),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: CustomText(
                title,
                color: Colors.white,
                fontSize: SizeConfig.small,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVITIES GRID
  // ============================================================

  Widget _activitiesCard(List activities) {
    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.activities,
              onEdit: () => _navigateToEdit(SocialFeedScreen())),
          if (activities.isEmpty)
            _dummyOverlay(child: _dummyActivityGrid())
          else
            _responsiveGrid(
              itemCount: activities.length,
              builder: (context, index) {
                final a = activities[index];
                return _mediaTile(
                  a?.title ?? "-",
                  (a?.mediaUrls ?? []).isNotEmpty
                      ? a?.mediaUrls?.first ?? ""
                      : "",
                  a?.description ?? "",
                );
              },
            ),
        ],
      ),
    );
  }

  // ============================================================
  // MISSION VISION
  // ============================================================

  Widget _missionVisionCard(mv) {
    final bool hasData = mv != null &&
        ((mv.description ?? '').isNotEmpty ||
            (mv.mediaUrl ?? '').isNotEmpty);

    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.visionMission,
              onEdit: () => _navigateToEdit(SocialVisionMissionScreen())),
          if (!hasData)
            _dummyOverlay(
              child: Column(
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _dummyCardBg,
                      borderRadius: BorderRadius.circular(SizeConfig.size8),
                    ),
                    child: Center(
                      child: Icon(Icons.image, size: 40, color: _dummyTextColor),
                    ),
                  ),
                  SizedBox(height: SizeConfig.size10),
                  _dummyTextLine(width: double.infinity, height: 8),
                  const SizedBox(height: 4),
                  _dummyTextLine(width: 250, height: 8),
                  const SizedBox(height: 4),
                  _dummyTextLine(width: 200, height: 8),
                ],
              ),
            )
          else ...[
            if (mv?.mediaUrl != null &&
                (mv?.mediaUrl as String).isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(SizeConfig.size8),
                child: CachedNetworkImage(
                  imageUrl: mv?.mediaUrl ?? "",
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(height: 160, color: Colors.grey[200]),
                  errorWidget: (_, __, ___) =>
                      Container(height: 160, color: Colors.grey[200]),
                ),
              ),
            SizedBox(height: SizeConfig.size10),
            CustomText(mv?.description ?? "-"),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // EVENTS
  // ============================================================

  Widget _eventsCard(List events) {
    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.events,
              onEdit: () => _navigateToEdit(EventScheduleScreen())),
          if (events.isEmpty)
            _dummyOverlay(child: _dummyEventCard())
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (_, __) =>
                  SizedBox(height: SizeConfig.size8),
              itemBuilder: (context, index) {
                final e = events[index];
                return _eventCard(e);
              },
            ),
        ],
      ),
    );
  }

  Widget _eventCard(dynamic e) {
    String formatDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return '';
      try {
        final date = DateTime.parse(dateStr);
        return DateFormat('MMM dd, yyyy').format(date);
      } catch (_) {
        return dateStr;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withValues(alpha: 0.8),
                  AppColors.primaryColor.withValues(alpha: 0.4),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: CustomText(
                      e?.title ?? "-",
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (e?.eventType != null &&
                      (e.eventType as String).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomText(
                        e.eventType ?? "",
                        fontSize: SizeConfig.small,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Obx(() => CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(
                            personalCreateProfileController
                                    .imagePath?.value ??
                                "",
                          ),
                          backgroundColor: Colors.grey[300],
                        )),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomText(
                        viewProfileController.personalProfileDetails
                                .value.user?.name ??
                            '',
                        fontWeight: FontWeight.w600,
                        fontSize: SizeConfig.medium,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size8),
                if (e?.venue?.name != null) ...[
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: CustomText(
                          e?.venue?.name ??
                              e?.venue?.location?.name ??
                              "-",
                          color: AppColors.secondaryTextColor,
                          fontSize: SizeConfig.small,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    CustomText(
                      formatDate(e?.startDate),
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.small,
                    ),
                    if (e?.timing?.from != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      CustomText(
                        "${e?.timing?.from ?? ''} - ${e?.timing?.to ?? ''}",
                        color: AppColors.secondaryTextColor,
                        fontSize: SizeConfig.small,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACHIEVEMENTS
  // ============================================================

  Widget _achievementsCard(List achievements) {
    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.achievements,
              onEdit: () => _navigateToEdit(SocialCertificatesScreen())),
          if (achievements.isEmpty)
            _dummyOverlay(child: _dummyAchievementGrid())
          else
            _responsiveGrid(
              itemCount: achievements.length,
              builder: (context, index) {
                final c = achievements[index];
                return _achievementTile(c);
              },
            ),
        ],
      ),
    );
  }

  Widget _achievementTile(dynamic c) {
    final fileUrl = c?.fileUrl ?? "";
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(SizeConfig.size8),
                topRight: Radius.circular(SizeConfig.size8),
              ),
              child: fileUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: fileUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey[200]),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                            child: Icon(Icons.image_not_supported,
                                color: Colors.grey)),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(
                          child: Icon(Icons.emoji_events,
                              size: 40, color: Colors.grey)),
                    ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  c?.title ?? "-",
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (c?.description != null &&
                    (c.description as String).isNotEmpty) ...[
                  SizedBox(height: SizeConfig.size4),
                  CustomText(
                    c.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    color: AppColors.black28,
                    fontSize: SizeConfig.small,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SOCIAL ACTIVITIES
  // ============================================================

  Widget _socialActivitiesCard(List socialActivities) {
    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.socialActivity,
              onEdit: () => _navigateToEdit(SocialActivityListScreen())),
          if (socialActivities.isEmpty)
            _dummyOverlay(
              child: Column(
                children: [
                  _dummySocialActivityTile(),
                  SizedBox(height: SizeConfig.size6),
                  _dummySocialActivityTile(),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: socialActivities.length,
              separatorBuilder: (_, __) =>
                  SizedBox(height: SizeConfig.size6),
              itemBuilder: (context, index) {
                final s = socialActivities[index];
                return _socialActivityTile(s);
              },
            ),
        ],
      ),
    );
  }

  Widget _socialActivityTile(dynamic s) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.volunteer_activism,
                color: AppColors.primaryColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(s?.title ?? "-", fontWeight: FontWeight.w600),
                if (s?.date != null) ...[
                  SizedBox(height: SizeConfig.size4),
                  CustomText(
                    s.date ?? "",
                    color: AppColors.secondaryTextColor,
                    fontSize: SizeConfig.small,
                  ),
                ],
                SizedBox(height: SizeConfig.size4),
                CustomText(
                  s?.description ?? "",
                  color: AppColors.black28,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: CustomText(
                        s?.location?.name ?? "-",
                        color: AppColors.secondaryTextColor,
                        fontSize: SizeConfig.small,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LATEST POST
  // ============================================================

  Widget _latestPostSection(List activities) {
    // Use activities with images as latest posts
    final postActivities = activities
        .where((a) => (a?.mediaUrls ?? []).isNotEmpty)
        .toList();

    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Latest Post",
              onEdit: () => _navigateToEdit(SocialFeedScreen())),
          if (postActivities.isEmpty)
            _dummyOverlay(child: _dummyLatestPost())
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: postActivities.length > 3
                  ? 3
                  : postActivities.length,
              separatorBuilder: (_, __) =>
                  SizedBox(height: SizeConfig.size8),
              itemBuilder: (context, index) {
                final a = postActivities[index];
                return _latestPostCard(a);
              },
            ),
        ],
      ),
    );
  }

  Widget _latestPostCard(dynamic a) {
    final imageUrl =
        (a?.mediaUrls ?? []).isNotEmpty ? a?.mediaUrls?.first ?? "" : "";
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Obx(() => CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(
                        personalCreateProfileController.imagePath?.value ??
                            "",
                      ),
                      backgroundColor: Colors.grey[300],
                    )),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        viewProfileController.personalProfileDetails
                                .value.user?.name ??
                            '',
                        fontWeight: FontWeight.w600,
                        fontSize: SizeConfig.medium,
                      ),
                      if (a?.createdAt != null)
                        CustomText(
                          _formatRelativeDate(a.createdAt),
                          color: AppColors.secondaryTextColor,
                          fontSize: SizeConfig.small,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Description
          if (a?.description != null &&
              (a.description as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CustomText(
                a.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                color: AppColors.black28,
              ),
            ),
          const SizedBox(height: 8),
          // Image
          if (imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(height: 200, color: Colors.grey[200]),
              errorWidget: (_, __, ___) =>
                  Container(height: 200, color: Colors.grey[200]),
            ),
          // Action row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.thumb_up_outlined,
                    size: 18, color: Colors.grey[600]),
                const SizedBox(width: 16),
                Icon(Icons.comment_outlined,
                    size: 18, color: Colors.grey[600]),
                const SizedBox(width: 16),
                Icon(Icons.share_outlined,
                    size: 18, color: Colors.grey[600]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 30) return DateFormat('MMM dd, yyyy').format(date);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return '${diff.inMinutes}m ago';
    } catch (_) {
      return dateStr;
    }
  }

  // ============================================================
  // GALLERY
  // ============================================================

  Widget _gallerySection(SocialProfileData? data) {
    final List<String> galleryImages = [];
    for (final a in (data?.activities ?? [])) {
      for (final url in (a?.mediaUrls ?? [])) {
        if (url != null && url.isNotEmpty) galleryImages.add(url);
      }
    }
    for (final c in (data?.achievements ?? [])) {
      if (c?.fileUrl != null && c!.fileUrl!.isNotEmpty) {
        galleryImages.add(c.fileUrl!);
      }
    }
    if (data?.missionVision?.mediaUrl != null &&
        data!.missionVision!.mediaUrl!.isNotEmpty) {
      galleryImages.add(data.missionVision!.mediaUrl!);
    }

    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.gallery,
              onEdit: () => _navigateToEdit(SocialFeedScreen())),
          if (galleryImages.isEmpty)
            _dummyOverlay(child: _dummyGalleryGrid())
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount =
                    constraints.maxWidth > 600 ? 4 : 3;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: galleryImages.length > 9
                      ? 9
                      : galleryImages.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final isLast =
                        index == 8 && galleryImages.length > 9;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: galleryImages[index],
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: Colors.grey[200]),
                            errorWidget: (_, __, ___) =>
                                Container(color: Colors.grey[200]),
                          ),
                          if (isLast)
                            Container(
                              color:
                                  Colors.black.withValues(alpha: 0.5),
                              child: Center(
                                child: CustomText(
                                  "+${galleryImages.length - 9}",
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  // ============================================================
  // TESTIMONIALS
  // ============================================================

  Widget _testimonialSection(SocialProfileData? data) {
    // Currently no testimonial data in model - show dummy guide
    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.testimonials),
          _dummyOverlay(child: _dummyTestimonial()),
        ],
      ),
    );
  }

  // ============================================================
  // CONTACT
  // ============================================================

  Widget _buildContactCard(SocialProfileData? profile) {
    final bool hasContact = profile?.contact != null;

    return CommonCardWidget(
      padding: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 6),
            child: _sectionHeader(AppStrings.contactUs,
                onEdit: () =>
                    _navigateToEdit(SocialContactUsScreen())),
          ),
          const SizedBox(height: 10),
          if (!hasContact)
            _dummyOverlay(child: _dummyContactCard())
          else
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    viewProfileController
                        .personalProfileDetails.value.user?.name,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 5),
                  _contactItem(AppIconAssets.website_click,
                      profile?.contact?.websiteUrl ?? "", AppColors.primaryColor),
                  _contactItem(AppIconAssets.principal, AppStrings.reception,
                      Colors.grey[700]!),
                  _contactItem(AppIconAssets.email,
                      profile?.contact?.email ?? "", AppColors.secondaryTextColor),
                  _contactItem(AppIconAssets.phone_outline,
                      profile?.contact?.phoneNo ?? "", AppColors.secondaryTextColor),
                  _contactItem(AppIconAssets.location_new,
                      profile?.contact?.location?.name ?? "", Colors.grey[700]!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _contactItem(String icon, String label, Color iconColor) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: iconColor,
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomText(label,
                fontSize: 15, color: AppColors.mainTextColor),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK LINKS (Footer)
  // ============================================================

  Widget _quickLinksSection(SocialProfileData? data) {
    // No quick links data in model - show dummy guide
    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Quick Links"),
          _dummyOverlay(child: _dummyQuickLinks()),
        ],
      ),
    );
  }

  // ============================================================
  // SHARED WIDGETS
  // ============================================================

  Widget _responsiveGrid({
    required int itemCount,
    required Widget Function(BuildContext, int) builder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 1;
        if (width > 1000) {
          crossAxisCount = 3;
        } else if (width > 600) {
          crossAxisCount = 2;
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: SizeConfig.size8,
            crossAxisSpacing: SizeConfig.size8,
            childAspectRatio: 3 / 2,
          ),
          itemBuilder: builder,
        );
      },
    );
  }

  Widget _mediaTile(String title, String url, String description) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(SizeConfig.size8),
                topRight: Radius.circular(SizeConfig.size8),
              ),
              child: url.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: url,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey[200]),
                      errorWidget: (_, __, ___) =>
                          Container(color: Colors.grey[200]),
                    )
                  : Container(color: AppColors.white),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(title, fontWeight: FontWeight.w600),
                SizedBox(height: SizeConfig.size6),
                CustomText(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  color: AppColors.black28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
