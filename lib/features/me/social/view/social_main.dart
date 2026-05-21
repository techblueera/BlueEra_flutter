import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/choose_earn_service_screen.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
import 'package:BlueEra/features/business/widgets/business_card_ui.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/common/visiting_card/view/all_personal_visiting_cards.dart';
import 'package:BlueEra/features/me/school/view/coming_soon.dart';
import 'package:BlueEra/features/me/social/controller/social_home_controller.dart';
import 'package:BlueEra/features/me/social/view/social_home_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/widget/rental_tab_body.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/edit_profile_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/profile_designation_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class SocialMainScreen extends StatefulWidget {
  const SocialMainScreen({super.key});

  @override
  State<SocialMainScreen> createState() => _SocialMainScreenState();
}

class _SocialMainScreenState extends State<SocialMainScreen>
    with TickerProviderStateMixin {
  final _ctrl = Get.put(SocialHomeController());
  final _personalCtrl = getOrPut(() => PersonalCreateProfileController());
  final _viewCtrl =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);

  TabController? _tabController;
  bool _lastHasWebsite = false;

  @override
  void initState() {
    super.initState();
    _lastHasWebsite = _hasWebsite;
    // Tabs: Post · Profile · Rental · [Website?] · Statistics
    // Rental sits after Profile so the identity-then-content
    // rhythm matches the other dashboards (self-employee /
    // professionals / rider / cab) that surface RentalTabBody.
    _tabController = TabController(
      length: _lastHasWebsite ? 5 : 4,
      vsync: this,
    );
    _viewCtrl.UserFollowersAndPostsCount(userId);
    if (!Get.isRegistered<FeedController>()) {
      Get.put(FeedController());
    }
  }

  bool get _hasWebsite =>
      (_ctrl.profile.value?.data?.contact?.websiteUrl ?? '').isNotEmpty;

  String get _websiteUrl =>
      _ctrl.profile.value?.data?.contact?.websiteUrl ?? '';

  void _rebuildTabsIfNeeded() {
    final current = _hasWebsite;
    if (current != _lastHasWebsite) {
      _lastHasWebsite = current;
      final oldIndex = _tabController?.index ?? 0;
      _tabController?.dispose();
      final newLength = current ? 5 : 4;
      _tabController = TabController(
        length: newLength,
        vsync: this,
        initialIndex: oldIndex.clamp(0, newLength - 1),
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
        _ctrl.profile.value;
        _rebuildTabsIfNeeded();
        final tabCtrl = _tabController;
        if (tabCtrl == null) return const SizedBox.shrink();

        return BottomNavHideOnScroll(
          child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(child: _buildCoverSection(context)),
              SliverToBoxAdapter(child: _buildProfileInfoSection()),
              SliverToBoxAdapter(child: _buildStatsRow()),
              // Tab bar — pinned
              SliverAppBar(
                pinned: true,
                floating: false,
                primary: false,
                automaticallyImplyLeading: false,
                toolbarHeight: 0,
                collapsedHeight: 0,
                expandedHeight: 0,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                bottom: TabBar(
                  controller: tabCtrl,
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: AppColors.secondaryTextColor,
                  indicatorColor: AppColors.primaryColor,
                  indicatorWeight: 2,
                  indicatorPadding: EdgeInsets.zero,
                  labelPadding: EdgeInsets.zero,
                  tabAlignment: TabAlignment.fill,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w400, fontSize: 14),
                  tabs: [
                    const Tab(text: 'Post'),
                    const Tab(text: 'Profile'),
                    const Tab(text: 'Rental'),
                    if (_lastHasWebsite)
                      Tab(text: AppStrings.website.tr),
                    Tab(text: AppStrings.statistics.tr),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: tabCtrl,
            children: [
              FeedScreen(
                key: const ValueKey('social_main_my_posts'),
                postFilterType: PostType.myPosts,
                id: userId,
              ),
              SocialHomeScreen(),
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(top: SizeConfig.size12),
                child: const RentalTabBody(),
              ),
              if (_lastHasWebsite)
                CommonWebView(
                  urlLink: _websiteUrl,
                  urlTitle: '',
                  hideAppBar: true,
                ),
              ComingSoon(),
            ],
          ),
        ),
        );
      })),
    );
  }

  // ============================================================
  // STATS ROW
  // ============================================================

  String _formatCount(int count) {
    if (count >= 1000000) return "${(count / 1000000).toStringAsFixed(1)}M";
    if (count >= 1000) return "${(count / 1000).toStringAsFixed(1)}k";
    return "$count";
  }

  Widget _buildStatsRow() {
    return CommonCardWidget(
      cardMargin: 0,
      padding: 0,
      child: Obx(() {
        final followers = _viewCtrl.followersCount.value;
        final following = _viewCtrl.followingCount.value;
        final posts = _viewCtrl.postsCount.value;

        return Container(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size14, vertical: SizeConfig.size8),
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(child: _statItem("Posts", "$posts")),
              _statDivider(),
              Expanded(
                child: GestureDetector(
                  onTap: () => Get.to(() => FollowersFollowingPage(
                      tabIndex: 1, userID: userId)),
                  child: _statItem("Followers", _formatCount(followers)),
                ),
              ),
              _statDivider(),
              Expanded(
                child: GestureDetector(
                  onTap: () => Get.to(() => FollowersFollowingPage(
                      tabIndex: 0, userID: userId)),
                  child: _statItem("Following", _formatCount(following)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          value,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.bold,
          color: AppColors.mainTextColor,
        ),
        const SizedBox(height: 4),
        CustomText(
          label,
          fontSize: SizeConfig.small,
          color: AppColors.secondaryTextColor,
          fontWeight: FontWeight.w400,
        ),
      ],
    );
  }

  Widget _statDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade200,
    );
  }

  // ============================================================
  // COVER SECTION
  // ============================================================

  Widget _buildCoverSection(BuildContext context) {
    const bannerHeight = 260.0;
    return Container(
      color: AppColors.white,
      height: bannerHeight + 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover image
          Obx(() {
            final banner = _personalCtrl.coverImagePath?.value ?? '';
            return SizedBox(
              height: bannerHeight,
              width: double.infinity,
              child: banner.isNotEmpty
                  ? Image.network(banner, fit: BoxFit.cover)
                  : CachedNetworkImage(
                      imageUrl: _personalCtrl.imagePath?.value ?? '',
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
            );
          }),

          // Single glassmorphic header row sitting on the banner.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildGlassHeaderRow(context),
          ),

          // Banner-edit camera — bottom-right of the banner image.
          Positioned(
            right: 8,
            top: bannerHeight - 44,
            child: _coverIconButton(
              icon: Icons.camera_alt_outlined,
              onTap: () => _onCoverImageEdit(context),
            ),
          ),

          // Profile image + share + card
          Positioned(
            left: 16,
            bottom: 0,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Obx(() {
                return CommonProfileImage(
                  imagePath: _personalCtrl.imagePath?.value ?? "",
                  onImageUpdate: (image) async {
                    _personalCtrl.imagePath?.value = image;
                    dynamic dataImage = await multiPartImage(imagePath: image);
                    var reqProfile = {ApiKeys.profile_image: dataImage};
                    await _personalCtrl.updateUserProfileDetails(
                        params: reqProfile, isFromProfileOnly: true);
                  },
                  dialogTitle: AppStrings.uploadProfilePicture,
                  showProfileBorder: false,
                );
              }),
            ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    // ShareService owns the link + message + share-sheet
                    // handoff. Same single entry point as every other
                    // dashboard's share button.
                    final userName = _viewCtrl
                            .personalProfileDetails.value.user?.name ??
                        '';
                    await ShareService.instance.shareProfile(
                        userId: userId,
                        subject: userName);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.greyE5, width: 1.5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                          color: AppColors.black.withValues(alpha: 0.08),
                        ),
                      ],
                    ),
                    child: LocalAssets(
                      imagePath: AppIconAssets.profile_share,
                      width: 16,
                      height: 16,
                      imgColor: AppColors.secondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                BusinessCardUi(
                  onTap: () => Get.to(() => AllPersonalVisitingCards(
                        personalDetails:
                            _viewCtrl.personalProfileDetails.value,
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassHeaderRow(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _GlassPill(
                onTap: () => _openDrawer(context),
                padding: const EdgeInsets.all(8),
                shape: BoxShape.circle,
                dark: true,
                child: LocalAssets(
                  imagePath: AppIconAssets.drawer_more,
                  width: 18,
                  height: 18,
                  imgColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              _EarnActionPill(
                onTap: () => Get.toNamed(RouteHelper.getChooseEarnServiceScreenRoute()),
              ),
              const Spacer(),
              if (!isGuestUser())
                _GlassPill(
                  onTap: () => Navigator.pushNamed(
                    context,
                    RouteHelper.getNotificationScreenRoute(),
                  ),
                  padding: const EdgeInsets.all(8),
                  shape: BoxShape.circle,
                  dark: true,
                  child: LocalAssets(
                    imagePath: AppIconAssets.notificationOutlineIcon,
                    width: 18,
                    height: 18,
                    imgColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _openDrawer(BuildContext context) {
    showDialog(
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      useSafeArea: false,
      context: context,
      builder: (BuildContext context) {
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            height: double.infinity,
            child: Drawer(backgroundColor: Colors.transparent, elevation: 0, child: ProfileMenuDrawer()),
          ),
        );
      },
    );
  }

  Widget _coverIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _GlassPill(
      onTap: onTap,
      padding: const EdgeInsets.all(8),
      shape: BoxShape.circle,
      dark: true,
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  // ============================================================
  // PROFILE INFO SECTION
  // ============================================================

  Widget _buildProfileInfoSection() {
    final user = _viewCtrl.personalProfileDetails.value.user;
    final name = _capitalizeFirst(user?.name ?? '');
    final username = user?.username ?? '';
    final designation = user?.designation ?? '';
    final bio = user?.bio ?? _ctrl.profile.value?.data?.identity?.bio ?? '';
    final userAddress = user?.address ?? '';
    final socialLocation =
        _ctrl.profile.value?.data?.contact?.location?.name ?? '';
    final fullAddress = userAddress.isNotEmpty ? userAddress : socialLocation;
    final location = _extractCityState(fullAddress);
    final dob = user?.dateOfBirth;
    final websiteUrl =
        _ctrl.profile.value?.data?.contact?.websiteUrl ?? '';
    final email = user?.email ?? '';
    final createdAt = user?.createdAt ?? '';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          if (name.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: CustomText(
                    name,
                    fontSize: SizeConfig.extraLarge22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                _buildEditProfileChip(),
              ],
            ),

          // Username + Joined date
          if (username.isNotEmpty || createdAt.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                if (username.isNotEmpty)
                  CustomText(
                    "@$username",
                    fontSize: SizeConfig.medium,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                  ),
                if (username.isNotEmpty && createdAt.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: CustomText(
                      "•",
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                if (createdAt.isNotEmpty)
                  CustomText(
                    "Joined ${_formatJoinedDate(createdAt)}",
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                  ),
              ],
            ),
          ],

          // Designation chip — tap to open the category bottom sheet.
          const SizedBox(height: 8),
          _buildDesignationChip(designation),

          // Bio
          const SizedBox(height: 10),
          if (bio.isNotEmpty)
            ExpandableText(
              text: bio,
              trimLines: 2,
              expandMode: ExpandMode.expandable,
              dialogTitle: AppStrings.bio.tr,
              style: TextStyle(
                fontSize: SizeConfig.medium,
                color: AppColors.mainTextColor,
                height: 1.5,
              ),
            ),

          // Info rows: location, born, email
          if (location.isNotEmpty ||
              (dob != null && dob.date != null && dob.month != null) ||
              email.isNotEmpty ||
              websiteUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            if (location.isNotEmpty) ...[
              _infoRow(Icons.location_on_outlined, location),
              const SizedBox(height: 6),
            ],
            if (websiteUrl.isNotEmpty) ...[
              _infoRow(Icons.link, websiteUrl, color: AppColors.primaryColor),
              const SizedBox(height: 6),
            ],
            if (dob != null && dob.date != null && dob.month != null) ...[
              _infoRow(Icons.cake_outlined, "Born ${_formatDob(dob)}"),
              const SizedBox(height: 6),
            ],
            if (email.isNotEmpty)
              _infoRow(Icons.email_outlined, email),
          ],

          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.secondaryTextColor),
        const SizedBox(width: 5),
        Flexible(
          child: CustomText(
            text,
            fontSize: SizeConfig.medium15,
            color: color ?? AppColors.secondaryTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _extractCityState(String address) {
    if (address.isEmpty) return '';
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 3) {
      // Typical format: "street, area, city, state pincode, country"
      // Remove pincode from state if present
      final statePart = parts[parts.length - 2]
          .replaceAll(RegExp(r'\d{5,6}'), '')
          .trim();
      final city = parts[parts.length - 3].trim();
      if (city.isNotEmpty && statePart.isNotEmpty) {
        return "$city, $statePart";
      }
      return city.isNotEmpty ? city : statePart;
    }
    return address;
  }

  Widget _buildEditProfileChip() {
    return InkWell(
      onTap: _openEditProfile,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            width: 0.6,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined,
                size: 14, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            CustomText(
              'Edit',
              fontSize: SizeConfig.extraSmall,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }

  void _openEditProfile() {
    EditProfileBottomSheet.show(Get.context!);
  }

  Widget _buildDesignationChip(String designation) {
    final hasDesignation = designation.trim().isNotEmpty;
    return InkWell(
      onTap: () => showProfileDesignationSheet(Get.context!),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: CustomText(
                hasDesignation ? designation : 'Add designation',
                color: AppColors.primaryColor,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: SizeConfig.size10),
            LocalAssets(
              imagePath: AppIconAssets.editIcon,
              height: SizeConfig.size12,
              width: SizeConfig.size12,
              imgColor: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDob(DateOfBirth dob) {
    final months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final month = (dob.month != null && dob.month! >= 1 && dob.month! <= 12)
        ? months[dob.month!]
        : '';
    final day = dob.date?.toString() ?? '';
    if (month.isEmpty && day.isEmpty) return '';
    return "$day $month".trim();
  }

  String _formatJoinedDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return '';
    }
  }


  // ============================================================
  // COVER IMAGE EDIT
  // ============================================================

  Future<void> _onCoverImageEdit(BuildContext context) async {
    final String? newPath = await PhotoPickerService.pickSinglePhoto(
      context,
      AppStrings.editCoverPicture,
      cropAspectRatio: CropAspectRatio(width: 3, height: 1),
    );
    if (newPath == null || newPath.isEmpty) return;
    dynamic dataImage = await multiPartImage(imagePath: newPath);
    var reqProfile = {ApiKeys.coverpicture: dataImage};
    await _personalCtrl.updateUserProfileDetails(
        params: reqProfile, isFromProfileOnly: true);
  }
}

class _EarnActionPill extends StatelessWidget {
  final VoidCallback onTap;

  const _EarnActionPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _GlassPill(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      dark: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(
            imagePath: AppIconAssets.earnWithBEIcon,
            imgColor: Colors.white,
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 4),
          const Text(
            'Earn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsets padding;
  final BoxShape shape;
  final bool dark;

  const _GlassPill({
    required this.child,
    required this.onTap,
    required this.padding,
    this.shape = BoxShape.rectangle,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius =
        shape == BoxShape.circle ? null : BorderRadius.circular(100);
    final fill = dark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.35);
    final border = dark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.5);
    return GestureDetector(
      onTap: onTap,
      child: ClipPath(
        clipper: _GlassClipper(shape: shape, borderRadius: borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: borderRadius,
              shape: shape,
              border: Border.all(color: border, width: 0.6),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GlassClipper extends CustomClipper<Path> {
  final BoxShape shape;
  final BorderRadius? borderRadius;

  _GlassClipper({required this.shape, this.borderRadius});

  @override
  Path getClip(Size size) {
    final rect = Offset.zero & size;
    if (shape == BoxShape.circle) {
      return Path()..addOval(rect);
    }
    return Path()
      ..addRRect((borderRadius ?? BorderRadius.circular(100)).toRRect(rect));
  }

  @override
  bool shouldReclip(covariant _GlassClipper oldClipper) =>
      oldClipper.shape != shape || oldClipper.borderRadius != borderRadius;
}

// ════════════════════════════════════════════════════════════════
// (removed) Wrapper-era _ProfileTab / _ProfileHero / _AnimatedStat
// classes — interactivity now lives inside SocialHomeScreen itself.
// ════════════════════════════════════════════════════════════════
