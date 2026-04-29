import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/choose_earn_service_screen.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/features/business/widgets/business_card_ui.dart';
import 'package:BlueEra/features/common/auth/controller/ai_suggestion_controller.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/common/visiting_card/view/all_personal_visiting_cards.dart';
import 'package:BlueEra/features/me/school/view/coming_soon.dart';
import 'package:BlueEra/features/me/social/controller/social_home_controller.dart';
import 'package:BlueEra/features/me/social/view/social_home_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/edit_profile_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/profile_designation_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

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
    _tabController = TabController(
      length: _lastHasWebsite ? 3 : 2,
      vsync: this,
    );
    _viewCtrl.UserFollowersAndPostsCount(userId);
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
      final newLength = current ? 3 : 2;
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
        child: Obx(() {
        _ctrl.profile.value;
        _rebuildTabsIfNeeded();
        final tabCtrl = _tabController;
        if (tabCtrl == null) return const SizedBox.shrink();

        return BottomNavHideOnScroll(
          child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Custom AppBar — placed in the sliver header so it scrolls
              // away with the cover/profile/stats content. The TabBar
              // below stays pinned.
              SliverToBoxAdapter(
                child: SizedBox(
                  height: kToolbarHeight,
                  child: CommonBackAppBar(
                    showElevation: 0,
                    isDrawerMenu: true,
                    isLeading: false,
                    isProfile: false,
                    isNotification: !isGuestUser(),
                    bellIconNotEmpty: true,
                    isGuestLogout: isGuestUser(),
                    onNotificationTap: () {
                      Navigator.pushNamed(
                        context,
                        RouteHelper.getNotificationScreenRoute(),
                      );
                    },
                    buildCustomActionWidget: () => _EarnActionPill(
                      onTap: () =>
                          Get.to(() => const chooseEarnServiceScreen()),
                    ),
                  ),
                ),
              ),
              // Cover + Profile info + Stats — all scroll away
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
                    Tab(text: AppStrings.home.tr),
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
              SocialHomeScreen(),
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
    return Container(
      color: AppColors.white,
      height: 230,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover image
          Obx(() {
            final banner = _personalCtrl.coverImagePath?.value ?? '';
            return SizedBox(
              height: 190,
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

          // Top bar: camera
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            right: 8,
            child: _circleButton(
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
                    final link = profileDeepLink(
                      userId: userId,
                      accountType: AppConstants.individual,
                    );
                    final userName =
                        _viewCtrl.personalProfileDetails.value.user?.name ?? '';
                    await SharePlus.instance.share(
                      ShareParams(
                        text: "See my profile on BlueEra:\n$link\n",
                        subject: userName,
                      ),
                    );
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

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
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
                      "\u2022",
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
  // BIO EDIT BOTTOM SHEET
  // ============================================================

  void _showBioEditSheet(BuildContext context, String currentBio) {
    final bioController = TextEditingController(text: currentBio);
    final locationController = TextEditingController(
        text: _viewCtrl.personalProfileDetails.value.user?.address ?? '');
    final aiController = Get.put(AiSuggestionController());
    final user = _viewCtrl.personalProfileDetails.value.user;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return GestureDetector(
              onTap: () => FocusScope.of(ctx).unfocus(),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            "Update Bio",
                            fontSize: SizeConfig.large18,
                            fontWeight: FontWeight.w600,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Obx(() => aiController.isLoading.value
                                  ? const SizedBox(
                                      height: 25,
                                      width: 25,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : InkWell(
                                      onTap: () async {
                                        await aiController.fetchSuggestions(
                                          bodyRequest: {
                                            ApiKeys.profession:
                                                user?.profession ?? '',
                                            ApiKeys.designation:
                                                user?.designation ?? '',
                                            ApiKeys.date_of_birth_Obj: {
                                              ApiKeys.year:
                                                  user?.dateOfBirth?.year,
                                              ApiKeys.month:
                                                  user?.dateOfBirth?.month,
                                              ApiKeys.date:
                                                  user?.dateOfBirth?.date,
                                            },
                                            ApiKeys.gender: user?.gender,
                                          },
                                          apiType: "bio",
                                          targetController: bioController,
                                          onSaved: () =>
                                              setSheetState(() {}),
                                        );
                                      },
                                      child: LocalAssets(
                                        height: 25,
                                        width: 25,
                                        imagePath:
                                            AppIconAssets.ai_generative,
                                        imgColor: AppColors.primaryColor,
                                      ),
                                    )),
                              const SizedBox(width: 4),
                              const CloseButton(),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CommonTextField(
                        textEditController: bioController,
                        title: "",
                        hintText: "Write something about yourself...",
                        maxLine: 5,
                        maxLength: 900,
                        isValidate: false,
                        isCounterVisible: true,
                        keyBoardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                      ),
                      const SizedBox(height: 14),
                      CustomText(
                        AppStrings.location.tr,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                      ),
                      const SizedBox(height: 6),
                      CommonLocationSearchField(
                        controller: locationController,
                        hintText: "E.g. Ranchi, Jharkhand...",
                        isShowLeading: false,
                        title: "",
                        onSelected: (placeId, lat, lng, address) {
                          locationController.text = address;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomBtn(
                        radius: 10,
                        bgColor: AppColors.primaryColor,
                        title: AppStrings.save.tr,
                        onTap: () async {
                          final newBio = bioController.text.trim();
                          final newAddress = locationController.text.trim();
                          final currentAddress = user?.address ?? '';

                          if (newBio == currentBio &&
                              newAddress == currentAddress) {
                            Navigator.pop(ctx);
                            return;
                          }

                          final params = <String, dynamic>{};
                          if (newBio != currentBio) {
                            params[ApiKeys.bio] = newBio;
                          }
                          if (newAddress != currentAddress) {
                            params[ApiKeys.address] = newAddress;
                          }

                          if (params.isNotEmpty) {
                            await _personalCtrl.updateUserProfileDetails(
                              params: params,
                              isFromProfileOnly: true,
                            );
                            _ctrl.fetchProfile();
                            _viewCtrl.viewPersonalProfile();
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                      SizedBox(height: MediaQuery.of(ctx).padding.bottom),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // COVER IMAGE EDIT
  // ============================================================

  Future<void> _onCoverImageEdit(BuildContext context) async {
    final String? newPath = await SelectProfilePictureDialog.showLogoDialog(
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
    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LocalAssets(
                  imagePath: AppIconAssets.earnWithBEIcon,
                  imgColor: AppColors.primaryColor,
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Earn',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



