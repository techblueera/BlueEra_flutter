import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
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
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  @override
  void initState() {
    ctrl.fetchProfile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading.value && ctrl.profile.value == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final data = ctrl.profile.value?.data;
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _identityCard(data?.identity),
            const SizedBox(height: 10),
            _activitiesCard(data?.activities ?? []),
            const SizedBox(height: 10),
            _missionVisionCard(data?.missionVision),
            const SizedBox(height: 10),
            _eventsCard(data?.events ?? []),
            const SizedBox(height: 10),
            _achievementsCard(data?.achievements ?? []),
            const SizedBox(height: 10),
            _socialActivitiesCard(data?.socialActivities ?? []),
            const SizedBox(height: 10),
            _latestPostSection(data?.activities ?? []),
            const SizedBox(height: 10),
            _gallerySection(data),
            const SizedBox(height: 10),
            _testimonialSection(data),
            const SizedBox(height: 10),
            _buildContactCard(data),
            const SizedBox(height: 10),
            _buildMapCard(data),
            const SizedBox(height: 10),
            _quickLinksSection(data),
            SizedBox(height: kBottomNavigationBarHeight + 30),
          ],
        ),
      );
    });
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _navigateToEdit(Widget screen) async {
    await Get.to(() => screen);
    ctrl.fetchProfile();
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

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  // ============================================================
  // CARD WRAPPER
  // ============================================================

  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _sectionHeader(String title, {VoidCallback? onEdit, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: AppColors.primaryColor),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: CustomText(
              title,
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
          ),
          if (onEdit != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined,
                          size: 14, color: AppColors.primaryColor),
                      const SizedBox(width: 4),
                      CustomText(
                        "Edit",
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE PLACEHOLDER
  // ============================================================

  Widget _emptyState({
    required IconData icon,
    required String message,
    VoidCallback? onAdd,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF2F7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: const Color(0xFFA0AEC0)),
          ),
          const SizedBox(height: 12),
          CustomText(
            message,
            fontSize: SizeConfig.medium,
            color: const Color(0xFF718096),
            textAlign: TextAlign.center,
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomText(
                  "Add Now",
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // IDENTITY / BIO CARD
  // ============================================================

  Widget _identityCard(identity) {
    final bool hasData = identity != null &&
        ((identity.bio ?? '').isNotEmpty ||
            (identity.journey ?? '').isNotEmpty ||
            (identity.familyBackground ?? '').isNotEmpty);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.shortBio,
              icon: Icons.person_outline,
              onEdit: () => _navigateToEdit(SocialProfileIdentityScreen())),
          if (hasData) ...[
            _infoBlock("Bio", identity?.bio ?? "-"),
            const SizedBox(height: 14),
            _infoBlock(AppStrings.journey, identity?.journey ?? "-"),
            const SizedBox(height: 14),
            _infoBlock(
                AppStrings.familyBackground, identity?.familyBackground ?? "-"),
          ] else
            _emptyState(
              icon: Icons.person_outline,
              message: "Share your story - add your bio, journey & background",
              onAdd: () => _navigateToEdit(SocialProfileIdentityScreen()),
            ),
        ],
      ),
    );
  }

  Widget _infoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor,
          letterSpacing: 0.3,
        ),
        const SizedBox(height: 6),
        CustomText(
          value,
          fontSize: SizeConfig.medium,
          color: AppColors.secondaryTextColor,
          height: 1.5,
        ),
      ],
    );
  }

  // ============================================================
  // ACTIVITIES GRID
  // ============================================================

  Widget _activitiesCard(List activities) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.activities,
              icon: Icons.grid_view_rounded,
              onEdit: () => _navigateToEdit(SocialFeedScreen())),
          if (activities.isEmpty)
            _emptyState(
              icon: Icons.photo_library_outlined,
              message: "Showcase your activities and feed posts",
              onAdd: () => _navigateToEdit(SocialFeedScreen()),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length > 4 ? 4 : activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final a = activities[index];
                return _activityTile(a);
              },
            ),
        ],
      ),
    );
  }

  Widget _activityTile(dynamic a) {
    final imageUrl =
        (a?.mediaUrls ?? []).isNotEmpty ? a?.mediaUrls?.first ?? "" : "";
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDF2F7)),
      ),
      child: Row(
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 90,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(width: 90, height: 80, color: Colors.grey[100]),
                errorWidget: (_, __, ___) =>
                    Container(width: 90, height: 80, color: Colors.grey[100]),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    a?.title ?? "-",
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.medium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (a?.description != null &&
                      (a.description as String).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    CustomText(
                      a.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.small,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MISSION & VISION
  // ============================================================

  Widget _missionVisionCard(mv) {
    final bool hasData = mv != null &&
        ((mv.description ?? '').isNotEmpty || (mv.mediaUrl ?? '').isNotEmpty);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.visionMission,
              icon: Icons.visibility_outlined,
              onEdit: () => _navigateToEdit(SocialVisionMissionScreen())),
          if (!hasData)
            _emptyState(
              icon: Icons.visibility_outlined,
              message: "Define your vision & mission to inspire others",
              onAdd: () => _navigateToEdit(SocialVisionMissionScreen()),
            )
          else ...[
            if (mv?.mediaUrl != null && (mv?.mediaUrl as String).isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: mv?.mediaUrl ?? "",
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                      height: 170,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      )),
                  errorWidget: (_, __, ___) => Container(
                      height: 170,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      )),
                ),
              ),
            if (mv?.mediaUrl != null && (mv?.mediaUrl as String).isNotEmpty)
              const SizedBox(height: 12),
            CustomText(
              mv?.description ?? "-",
              fontSize: SizeConfig.medium,
              color: AppColors.secondaryTextColor,
              height: 1.5,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // EVENTS
  // ============================================================

  Widget _eventsCard(List events) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.events,
              icon: Icons.event_outlined,
              onEdit: () => _navigateToEdit(EventScheduleScreen())),
          if (events.isEmpty)
            _emptyState(
              icon: Icons.event_outlined,
              message: "Schedule and share your upcoming events",
              onAdd: () => _navigateToEdit(EventScheduleScreen()),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _eventCard(events[index]),
            ),
        ],
      ),
    );
  }

  Widget _eventCard(dynamic e) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF2F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                CustomText(
                  e?.title ?? "-",
                  fontSize: SizeConfig.large18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (e?.eventType != null &&
                    (e.eventType as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomText(
                      e.eventType ?? "",
                      fontSize: SizeConfig.small,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Event details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Organizer
                Row(
                  children: [
                    Obx(() => CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(
                            personalCreateProfileController.imagePath?.value ??
                                "",
                          ),
                          backgroundColor: Colors.grey[200],
                        )),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomText(
                        viewProfileController
                                .personalProfileDetails.value.user?.name ??
                            '',
                        fontWeight: FontWeight.w600,
                        fontSize: SizeConfig.medium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Location & date chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (e?.venue?.name != null)
                      _infoChip(Icons.location_on_outlined,
                          e?.venue?.name ?? e?.venue?.location?.name ?? "-"),
                    _infoChip(
                        Icons.calendar_today_outlined, _formatDate(e?.startDate)),
                    if (e?.timing?.from != null)
                      _infoChip(Icons.access_time,
                          "${e?.timing?.from ?? ''} - ${e?.timing?.to ?? ''}"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.secondaryTextColor),
          const SizedBox(width: 5),
          Flexible(
            child: CustomText(
              text,
              color: AppColors.secondaryTextColor,
              fontSize: SizeConfig.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.achievements,
              icon: Icons.emoji_events_outlined,
              onEdit: () => _navigateToEdit(SocialCertificatesScreen())),
          if (achievements.isEmpty)
            _emptyState(
              icon: Icons.emoji_events_outlined,
              message: "Highlight your certificates & achievements",
              onAdd: () => _navigateToEdit(SocialCertificatesScreen()),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: achievements.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (_, index) => _achievementTile(achievements[index]),
            ),
        ],
      ),
    );
  }

  Widget _achievementTile(dynamic c) {
    final fileUrl = c?.fileUrl ?? "";
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDF2F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: fileUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: fileUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey[100]),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[100],
                        child: const Center(
                            child: Icon(Icons.image_not_supported,
                                color: Colors.grey)),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFF7FAFC),
                      child: Center(
                        child: Icon(Icons.emoji_events,
                            size: 36, color: Colors.amber[300]),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  c?.title ?? "-",
                  fontWeight: FontWeight.w600,
                  fontSize: SizeConfig.medium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (c?.description != null &&
                    (c.description as String).isNotEmpty) ...[
                  const SizedBox(height: 3),
                  CustomText(
                    c.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    color: AppColors.secondaryTextColor,
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
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.socialActivity,
              icon: Icons.volunteer_activism_outlined,
              onEdit: () => _navigateToEdit(SocialActivityListScreen())),
          if (socialActivities.isEmpty)
            _emptyState(
              icon: Icons.volunteer_activism_outlined,
              message: "Share your social contributions & initiatives",
              onAdd: () => _navigateToEdit(SocialActivityListScreen()),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: socialActivities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _socialActivityTile(socialActivities[index]),
            ),
        ],
      ),
    );
  }

  Widget _socialActivityTile(dynamic s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDF2F7)),
        color: const Color(0xFFFCFCFD),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.volunteer_activism,
                color: AppColors.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(s?.title ?? "-",
                    fontWeight: FontWeight.w600, fontSize: SizeConfig.medium),
                if (s?.date != null) ...[
                  const SizedBox(height: 4),
                  CustomText(
                    s.date ?? "",
                    color: AppColors.secondaryTextColor,
                    fontSize: SizeConfig.small,
                  ),
                ],
                if (s?.description != null &&
                    (s.description as String).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  CustomText(
                    s.description,
                    color: AppColors.secondaryTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    fontSize: SizeConfig.small,
                    height: 1.4,
                  ),
                ],
                if (s?.location?.name != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.secondaryTextColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: CustomText(
                          s.location.name ?? "-",
                          color: AppColors.secondaryTextColor,
                          fontSize: SizeConfig.small,
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
    );
  }

  // ============================================================
  // LATEST POST
  // ============================================================

  Widget _latestPostSection(List activities) {
    final postActivities =
        activities.where((a) => (a?.mediaUrls ?? []).isNotEmpty).toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Latest Post",
              icon: Icons.dynamic_feed_outlined,
              onEdit: () => _navigateToEdit(SocialFeedScreen())),
          if (postActivities.isEmpty)
            _emptyState(
              icon: Icons.dynamic_feed_outlined,
              message: "Create your first post to engage with your audience",
              onAdd: () => _navigateToEdit(SocialFeedScreen()),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount:
                  postActivities.length > 3 ? 3 : postActivities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _latestPostCard(postActivities[index]),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF2F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Obx(() => CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(
                        personalCreateProfileController.imagePath?.value ?? "",
                      ),
                      backgroundColor: Colors.grey[200],
                    )),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        viewProfileController
                                .personalProfileDetails.value.user?.name ??
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
          if (a?.description != null && (a.description as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: CustomText(
                a.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                color: AppColors.secondaryTextColor,
                fontSize: SizeConfig.medium,
                height: 1.4,
              ),
            ),
          if (a?.description != null && (a.description as String).isNotEmpty)
            const SizedBox(height: 10),
          // Image
          if (imageUrl.isNotEmpty)
            ClipRRect(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(height: 200, color: Colors.grey[100]),
                errorWidget: (_, __, ___) =>
                    Container(height: 200, color: Colors.grey[100]),
              ),
            ),
          // Action row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _postAction(Icons.thumb_up_outlined, "Like"),
                const SizedBox(width: 24),
                _postAction(Icons.comment_outlined, "Comment"),
                const SizedBox(width: 24),
                _postAction(Icons.share_outlined, "Share"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _postAction(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondaryTextColor),
        const SizedBox(width: 5),
        CustomText(
          label,
          fontSize: SizeConfig.small,
          color: AppColors.secondaryTextColor,
        ),
      ],
    );
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

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.gallery,
              icon: Icons.photo_library_outlined,
              onEdit: () => _navigateToEdit(SocialFeedScreen())),
          if (galleryImages.isEmpty)
            _emptyState(
              icon: Icons.photo_library_outlined,
              message: "Your gallery is empty - add photos to showcase",
              onAdd: () => _navigateToEdit(SocialFeedScreen()),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: galleryImages.length > 9 ? 9 : galleryImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final isLast = index == 8 && galleryImages.length > 9;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: galleryImages[index],
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey[100]),
                        errorWidget: (_, __, ___) =>
                            Container(color: Colors.grey[100]),
                      ),
                      if (isLast)
                        Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          child: Center(
                            child: CustomText(
                              "+${galleryImages.length - 9}",
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
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
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.testimonials,
              icon: Icons.format_quote_outlined),
          _emptyState(
            icon: Icons.format_quote_outlined,
            message: "Testimonials from people who know your work",
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTACT
  // ============================================================

  Widget _buildContactCard(SocialProfileData? profile) {
    final bool hasContact = profile?.contact != null;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.contactUs,
              icon: Icons.contact_mail_outlined,
              onEdit: () => _navigateToEdit(SocialContactUsScreen())),
          if (!hasContact)
            _emptyState(
              icon: Icons.contact_mail_outlined,
              message: "Add your contact details so people can reach you",
              onAdd: () => _navigateToEdit(SocialContactUsScreen()),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFEDF2F7)),
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFFCFCFD),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    viewProfileController
                        .personalProfileDetails.value.user?.name,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 14),
                  _contactItem(AppIconAssets.website_click,
                      profile?.contact?.websiteUrl ?? "", AppColors.primaryColor),
                  _contactItem(AppIconAssets.principal, AppStrings.reception,
                      AppColors.secondaryTextColor),
                  _contactItem(AppIconAssets.email,
                      profile?.contact?.email ?? "", AppColors.secondaryTextColor),
                  _contactItem(AppIconAssets.phone_outline,
                      profile?.contact?.phoneNo ?? "", AppColors.secondaryTextColor),
                  _contactItem(
                      AppIconAssets.location_new,
                      profile?.contact?.location?.name ?? "",
                      AppColors.secondaryTextColor),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: LocalAssets(
              imagePath: icon,
              imgColor: iconColor,
              width: 18,
              height: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomText(label,
                fontSize: SizeConfig.medium, color: AppColors.mainTextColor),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAP
  // ============================================================

  Widget _buildMapCard(SocialProfileData? data) {
    return _card(
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BusinessLocationWidget(
          locationText: "",
          latitude: double.parse(
              data?.contact?.location?.coordinates?[0].toString() ?? "0.0"),
          longitude: double.parse(
              data?.contact?.location?.coordinates?[1].toString() ?? "0.0"),
          businessName: "",
          padding: 0,
          isTitleShow: true,
        ),
      ),
    );
  }

  // ============================================================
  // QUICK LINKS
  // ============================================================

  Widget _quickLinksSection(SocialProfileData? data) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Quick Links", icon: Icons.link_outlined),
          _emptyState(
            icon: Icons.link_outlined,
            message: "Add quick links to your important resources",
          ),
        ],
      ),
    );
  }
}
