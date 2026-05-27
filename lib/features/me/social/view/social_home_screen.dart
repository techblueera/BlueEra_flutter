import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
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
import 'package:BlueEra/features/me/social/view/social_vision_mission_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_property_card_v2.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// SOCIAL HOME — "Numbered Field Notes" treatment.
///
/// Each section is a numbered chapter (`01`, `02`, ...) with a
/// tracked uppercase title, a primary-color hairline, and a live
/// count chip that tweens between values when the underlying list
/// changes. A single `AnimationController` drives a one-shot
/// staggered fade+slide reveal across all chapters on first paint.
/// Every interactive tile wears a `_PressableCard` so taps feel
/// acknowledged. Pull-to-refresh re-runs `SocialHomeController.fetchProfile()`.
///
/// All existing data, navigation targets, and empty-state UX are
/// preserved — only the interaction quality and visual treatment
/// changed.
class SocialHomeScreen extends StatefulWidget {
  SocialHomeScreen({super.key});

  @override
  State<SocialHomeScreen> createState() => _SocialHomeScreenState();
}

class _SocialHomeScreenState extends State<SocialHomeScreen>
    with SingleTickerProviderStateMixin {
  final ctrl = Get.put(SocialHomeController());

  final personalCreateProfileController =
      getOrPut(() => PersonalCreateProfileController());

  final viewProfileController =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);

  // Drives the first-paint staggered reveal of all chapters.
  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    ctrl.fetchProfile();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // Pull-to-refresh handler. fetchProfile() returns a Future; we
  // also enforce a small minimum spinner time so the indicator
  // doesn't flicker on a fast network.
  Future<void> _onRefresh() async {
    try {
      await ctrl.fetchProfile();
    } catch (_) {/* swallow — UI keeps whatever data is cached */}
    await Future.delayed(const Duration(milliseconds: 450));
  }

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

  Widget _reveal(int index, Widget child) =>
      _RevealOnce(controller: _entryCtrl, index: index, child: child);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primaryColor,
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      child: Obx(() {
        if (ctrl.isLoading.value && ctrl.profile.value == null) {
          return _loadingScrollable();
        }
        final data = ctrl.profile.value?.data;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              const SizedBox(height: 14),
              _reveal(0, _buildActivitiesCard(data?.activities ?? [])),
              const SizedBox(height: 14),
              _reveal(1, const RentalPropertyCardV2(
                margin: EdgeInsets.zero,
              )),
              const SizedBox(height: 14),
              _reveal(2, _buildMissionVisionCard(data?.missionVision)),
              const SizedBox(height: 14),
              _reveal(3, _buildEventsCard(data?.events ?? [])),
              const SizedBox(height: 14),
              _reveal(4, _buildAchievementsCard(data?.achievements ?? [])),
              const SizedBox(height: 14),
              _reveal(
                  5, _buildSocialActivitiesCard(data?.socialActivities ?? [])),
              const SizedBox(height: 14),
              _reveal(6, _buildLatestPostSection(data?.activities ?? [])),
              const SizedBox(height: 14),
              _reveal(7, _buildGallerySection(data)),
              const SizedBox(height: 14),
              _reveal(8, _buildTestimonialSection()),
              const SizedBox(height: 14),
              _reveal(9, _buildContactCard(data)),
              const SizedBox(height: 14),
              _reveal(10, _buildMapCard(data)),
              const SizedBox(height: 14),
              _reveal(11, _buildQuickLinksSection()),
              SizedBox(height: kBottomNavigationBarHeight + 30),
            ],
          ),
        );
      }),
    );
  }

  // Initial-fetch placeholder. Wrapped in a scrollable so the
  // RefreshIndicator gesture still works while the first profile
  // request is in flight.
  Widget _loadingScrollable() => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
                strokeWidth: 2.4,
              ),
            ),
          ),
        ],
      );

  // ============================================================
  // 01 — ACTIVITIES
  // ============================================================
  Widget _buildActivitiesCard(List activities) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            index: 1,
            title: AppStrings.activities,
            count: activities.length,
            onEdit: () => _navigateToEdit(SocialFeedScreen()),
          ),
          if (activities.isEmpty)
            _EmptyState(
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
                return _PressableCard(child: _activityTile(activities[index]));
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
  // 02 — VISION & MISSION
  // ============================================================
  Widget _buildMissionVisionCard(dynamic mv) {
    final bool hasData = mv != null &&
        ((mv.description ?? '').isNotEmpty || (mv.mediaUrl ?? '').isNotEmpty);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            index: 2,
            title: AppStrings.visionMission,
            onEdit: () => _navigateToEdit(SocialVisionMissionScreen()),
          ),
          if (!hasData)
            _EmptyState(
              icon: Icons.visibility_outlined,
              message: "Define your vision & mission to inspire others",
              onAdd: () => _navigateToEdit(SocialVisionMissionScreen()),
            )
          else ...[
            if (mv?.mediaUrl != null && (mv?.mediaUrl as String).isNotEmpty)
              _PressableCard(
                child: ClipRRect(
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
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 170,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
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
  // 03 — EVENTS
  // ============================================================
  Widget _buildEventsCard(List events) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            index: 3,
            title: AppStrings.events,
            count: events.length,
            onEdit: () => _navigateToEdit(EventScheduleScreen()),
          ),
          if (events.isEmpty)
            _EmptyState(
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
              itemBuilder: (context, index) =>
                  _PressableCard(child: _eventCard(events[index])),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
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
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (e?.venue?.name != null)
                      _infoChip(Icons.location_on_outlined,
                          e?.venue?.name ?? e?.venue?.location?.name ?? "-"),
                    _infoChip(
                      Icons.calendar_today_outlined,
                      _formatDate(e?.startDate),
                    ),
                    if (e?.timing?.from != null)
                      _infoChip(
                        Icons.access_time,
                        "${e?.timing?.from ?? ''} - ${e?.timing?.to ?? ''}",
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
  // 04 — ACHIEVEMENTS
  // ============================================================
  Widget _buildAchievementsCard(List achievements) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            index: 4,
            title: AppStrings.achievements,
            count: achievements.length,
            onEdit: () => _navigateToEdit(SocialCertificatesScreen()),
          ),
          if (achievements.isEmpty)
            _EmptyState(
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
              itemBuilder: (_, index) =>
                  _PressableCard(child: _achievementTile(achievements[index])),
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
                              color: Colors.grey),
                        ),
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
  // 05 — SOCIAL ACTIVITIES
  // ============================================================
  Widget _buildSocialActivitiesCard(List socialActivities) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            index: 5,
            title: AppStrings.socialActivity,
            count: socialActivities.length,
            onEdit: () => _navigateToEdit(SocialActivityListScreen()),
          ),
          if (socialActivities.isEmpty)
            _EmptyState(
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
              itemBuilder: (context, index) => _PressableCard(
                child: _socialActivityTile(socialActivities[index]),
              ),
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
  // 06 — LATEST POST
  // ============================================================
  Widget _buildLatestPostSection(List activities) {
    final postActivities =
        activities.where((a) => (a?.mediaUrls ?? []).isNotEmpty).toList();

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            index: 6,
            title: "Latest Post",
            count: postActivities.length,
            onEdit: () => _navigateToEdit(SocialFeedScreen()),
          ),
          if (postActivities.isEmpty)
            _EmptyState(
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
              itemBuilder: (context, index) => _PressableCard(
                child: _latestPostCard(postActivities[index]),
              ),
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
  // 07 — GALLERY
  // ============================================================
  Widget _buildGallerySection(SocialProfileData? data) {
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

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            index: 7,
            title: AppStrings.gallery,
            count: galleryImages.length,
            onEdit: () => _navigateToEdit(SocialFeedScreen()),
          ),
          if (galleryImages.isEmpty)
            _EmptyState(
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
                return _PressableCard(
                  child: ClipRRect(
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
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ============================================================
  // 08 — TESTIMONIALS
  // ============================================================
  Widget _buildTestimonialSection() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(index: 8, title: AppStrings.testimonials),
          _EmptyState(
            icon: Icons.format_quote_outlined,
            message: "Testimonials from people who know your work",
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 09 — CONTACT
  // ============================================================
  Widget _buildContactCard(SocialProfileData? profile) {
    final bool hasContact = profile?.contact != null;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            index: 9,
            title: AppStrings.contactUs,
            onEdit: () => _navigateToEdit(SocialContactUsScreen()),
          ),
          if (!hasContact)
            _EmptyState(
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
                  _PressableContactItem(
                    icon: AppIconAssets.website_click,
                    label: profile?.contact?.websiteUrl ?? "",
                    iconColor: AppColors.primaryColor,
                  ),
                  _PressableContactItem(
                    icon: AppIconAssets.principal,
                    label: AppStrings.reception,
                    iconColor: AppColors.secondaryTextColor,
                  ),
                  _PressableContactItem(
                    icon: AppIconAssets.email,
                    label: profile?.contact?.email ?? "",
                    iconColor: AppColors.secondaryTextColor,
                  ),
                  _PressableContactItem(
                    icon: AppIconAssets.phone_outline,
                    label: profile?.contact?.phoneNo ?? "",
                    iconColor: AppColors.secondaryTextColor,
                  ),
                  _PressableContactItem(
                    icon: AppIconAssets.location_new,
                    label: profile?.contact?.location?.name ?? "",
                    iconColor: AppColors.secondaryTextColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // 10 — MAP (no header — visual continuation of contact)
  // ============================================================
  Widget _buildMapCard(SocialProfileData? data) {
    return _SectionCard(
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
  // 11 — QUICK LINKS
  // ============================================================
  Widget _buildQuickLinksSection() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(index: 10, title: "Quick Links"),
          _EmptyState(
            icon: Icons.link_outlined,
            message: "Add quick links to your important resources",
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// REUSABLE BUILDING BLOCKS
// ════════════════════════════════════════════════════════════════

/// One-shot fade + slide reveal driven by a parent
/// AnimationController. Each section's window opens at
/// `index * 0.06` and closes 0.40 later, producing a graceful
/// staggered cascade across the entire screen on first paint.
class _RevealOnce extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const _RevealOnce({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.06).clamp(0.0, 0.65);
    final end = (start + 0.40).clamp(0.05, 1.0);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, ch) {
        final t = ((controller.value - start) / (end - start)).clamp(0.0, 1.0);
        // easeOutCubic by hand — saves an extra CurvedAnimation.
        final eased = 1 - ((1 - t) * (1 - t) * (1 - t));
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 18),
            child: ch,
          ),
        );
      },
      child: child,
    );
  }
}

/// Tactile press feedback on any interactive tile. 96 % scale
/// over 140 ms `easeOut`. Optional [onTap] — passing null still
/// gives press feedback (useful for tiles that are visually
/// interactive even when they don't navigate).
class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressableCard({required this.child, this.onTap});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Live count chip — appended after a section title as " · 4" and
/// rolls smoothly between numbers when the source list changes.
/// Hidden when `count <= 0` so empty sections stay quiet.
class _CountChip extends StatefulWidget {
  final int count;
  const _CountChip({required this.count});

  @override
  State<_CountChip> createState() => _CountChipState();
}

class _CountChipState extends State<_CountChip> {
  // Tracked so the next tween starts from the previously displayed
  // value rather than snapping back to zero on every rebuild.
  double _from = 0;

  @override
  void didUpdateWidget(covariant _CountChip old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count) _from = old.count.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return const SizedBox.shrink();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _from, end: widget.count.toDouble()),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(
            '· ${v.round()}',
            style: TextStyle(
              fontFamily: AppConstants.OpenSans,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryColor,
              letterSpacing: 0.4,
              height: 1.0,
            ),
          ),
        );
      },
    );
  }
}

/// Section header — numbered chapter chip, primary hairline,
/// tracked uppercase title, optional live count chip, optional
/// Edit pill pinned to the right end of the row via `Spacer`.
/// The numeral chip scales in once on first paint via
/// `Curves.easeOutBack`.
class _SectionHeader extends StatelessWidget {
  final int index;
  final String title;
  final int? count;
  final VoidCallback? onEdit;

  const _SectionHeader({
    required this.index,
    required this.title,
    this.count,
    this.onEdit,
  });

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1.0),
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutBack,
            builder: (context, t, child) =>
                Transform.scale(scale: t, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.22),
                  width: 0.6,
                ),
              ),
              child: Text(
                _two(index),
                style: TextStyle(
                  fontFamily: AppConstants.OpenSans,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryColor,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 18,
            height: 1.4,
            color: AppColors.primaryColor.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppConstants.OpenSans,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                      letterSpacing: 1.2,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (count != null && count! > 0) _CountChip(count: count!),
              ],
            ),
          ),
          if (onEdit != null) _SectionEditPill(onTap: onEdit!),
        ],
      ),
    );
  }
}

/// Card chrome — same shape used by every numbered chapter. Soft
/// primary-tinted shadow + 1 px hairline border for that paper-on-
/// paper feel.
class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _SectionCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F001120),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// The Edit affordance — lives at the right end of the section
/// header row via `Spacer`. Reuses `_PressableCard` so the same
/// 96 % tap-scale applies as on every other interactive tile.
class _SectionEditPill extends StatelessWidget {
  final VoidCallback onTap;
  const _SectionEditPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PressableCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined,
                size: 13, color: AppColors.primaryColor),
            const SizedBox(width: 5),
            Text(
              'Edit',
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state — illustrated icon + message + optional primary CTA.
/// Same UX as before, refreshed with primary-tinted illustration
/// and a pressable CTA that picks up the global tap feedback.
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onAdd;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: AppColors.primaryColor),
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
            _PressableCard(
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
}

/// Contact row with a built-in pressable. Renders nothing when the
/// label is empty, matching the original collapse-on-empty behavior.
class _PressableContactItem extends StatelessWidget {
  final String icon;
  final String label;
  final Color iconColor;

  const _PressableContactItem({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return _PressableCard(
      child: Padding(
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
              child: CustomText(
                label,
                fontSize: SizeConfig.medium,
                color: AppColors.mainTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
