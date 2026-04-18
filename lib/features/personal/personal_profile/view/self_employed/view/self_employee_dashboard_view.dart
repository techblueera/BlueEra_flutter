import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/features/business/widgets/business_card_ui.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/common/visiting_card/view/all_personal_visiting_cards.dart';
import 'package:BlueEra/features/me/me_tab_registry.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/choose_earn_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_dashboard_view.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_profile_selector.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/self_work_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_employee_orders.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_profession_details_screen.dart';
import 'package:BlueEra/features/subscription/view/subscription_status_view.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/user_profile_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class SelfEmployeeDashboardView extends StatefulWidget {
  final bool fromBottomNavBar;

  const SelfEmployeeDashboardView({
    super.key,
    required this.fromBottomNavBar,
  });

  @override
  State<SelfEmployeeDashboardView> createState() =>
      _SelfEmployeeDashboardViewState();
}

class _SelfEmployeeDashboardViewState extends State<SelfEmployeeDashboardView>
    with SingleTickerProviderStateMixin {
  final _viewCtrl = Get.find<ViewPersonalDetailsController>();
  final _personalCtrl = getOrPut(() => PersonalCreateProfileController());
  final controller = getOrPut(() => SelfWorkServiceController());
  final earnServiceController = getOrPut(() => EarnServiceController());

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    MeTabRegistry.register(_tabController);
    _viewCtrl.UserFollowersAndPostsCount(userId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncShopStatus());
  }

  @override
  void dispose() {
    MeTabRegistry.unregister(_tabController);
    _tabController.dispose();
    super.dispose();
  }

  void _syncShopStatus() {
    _viewCtrl.shopStatusOpenClose.value =
        serviceProviderStatusGlobal.toUpperCase() ==
            AppConstants.OPEN.toUpperCase();
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _formatCount(int count) {
    if (count >= 1000000) return "${(count / 1000000).toStringAsFixed(1)}M";
    if (count >= 1000) return "${(count / 1000).toStringAsFixed(1)}k";
    return "$count";
  }

  String _extractCityState(String address) {
    if (address.isEmpty) return '';
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 3) {
      final statePart =
          parts[parts.length - 2].replaceAll(RegExp(r'\d{5,6}'), '').trim();
      final city = parts[parts.length - 3].trim();
      if (city.isNotEmpty && statePart.isNotEmpty) return "$city, $statePart";
      return city.isNotEmpty ? city : statePart;
    }
    return address;
  }

  String _formatJoinedDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isEarnSelected = controller.selectedProfileIndex.value == 1 &&
          _viewCtrl.earnProfileType.value != null;

      if (isEarnSelected) {
        return EarnServiceDashboardView(
          fromBottomNavBar: widget.fromBottomNavBar,
        );
      }

      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(child: _buildCoverSection(context)),
              SliverToBoxAdapter(child: _buildProfileInfoSection()),
              SliverToBoxAdapter(child: _buildStatsRow()),
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
                  controller: _tabController,
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
                    Tab(text: AppStrings.myOrder.tr),
                    Tab(text: AppStrings.home.tr),
                    Tab(text: AppStrings.statistics.tr),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                SelfEmployeeOrders(),
                SelfProfessionDetailsScreen(),
                const SubscriptionStatusView(),
              ],
            ),
          ),
        ),
      );
    });
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
          // Top bar: back + camera + actions
          Positioned(
            top: 4,
            left: 8,
            right: 8,
            child: Row(
              children: [
                if (!widget.fromBottomNavBar)
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 18),
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _onCoverImageEdit(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_outlined,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
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
                        dynamic dataImage =
                            await multiPartImage(imagePath: image);
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

  // ============================================================
  // PROFILE INFO SECTION
  // ============================================================

  Widget _buildProfileInfoSection() {
    final user = _viewCtrl.personalProfileDetails.value.user;
    final name = _capitalizeFirst(user?.name ?? '');
    final username = user?.username ?? '';
    final designation = user?.designation ?? '';
    final location = _extractCityState(user?.address ?? '');
    final email = user?.email ?? '';
    final createdAt = user?.createdAt ?? '';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  CustomText(
                    name,
                    fontSize: SizeConfig.extraLarge22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                if (designation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
                      border: Border.all(
                        color: AppColors.primaryColor.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: CustomText(
                      designation,
                      fontSize: SizeConfig.small,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (location.isNotEmpty || email.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  if (location.isNotEmpty) ...[
                    _infoRow(Icons.location_on_outlined, location),
                    const SizedBox(height: 6),
                  ],
                  if (email.isNotEmpty)
                    _infoRow(Icons.email_outlined, email),
                ],
                // Profile switcher + actions
                const SizedBox(height: 10),
                _buildActionRow(),
              ],
            ),
          ),
          // Go Live on right
          const SizedBox(width: 12),
          _buildGoLiveChip(),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Obx(() {
      final userImage = _viewCtrl
              .personalProfileDetails.value.user?.profileImage ??
          '';
      final earnType = _viewCtrl.earnProfileType.value;
      final hasEarnProfile = earnType != null && earnType.isNotEmpty;

      return Row(
        children: [
          // Profile switcher or avatar
          if (hasEarnProfile)
            EarnServiceProfileSelector(
              profileImages: [userImage, userImage],
              profileNames: [
                'Skill Work',
                earnServiceController.earnProfileLabel(earnType)
              ],
              selectedIndex: controller.selectedProfileIndex.value,
              onProfileSelected: (index) => controller.switchProfile(index),
            )
          else
            CommonProfileAvatar(),
          const Spacer(),
          // Availability clock
          GestureDetector(
            onTap: () async => await Get.toNamed(
              RouteHelper.getAvailabilityScreenRoute(),
              arguments: {ApiKeys.argId: userId},
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.greyE5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: LocalAssets(
                imagePath: AppIconAssets.clockIcon,
                width: 18,
                height: 18,
              ),
            ),
          ),
          // Add service button (only if no earn profile)
          if (_viewCtrl.earnProfileType.value == null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Get.to(() => const chooseEarnServiceScreen()),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildGoLiveChip() {
    return Container(
      height: SizeConfig.size36,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: SizeConfig.size8),
          CustomText(
            AppStrings.goLive,
            fontSize: SizeConfig.small,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
          buildToggleSwitchChip(
            value: _viewCtrl.shopStatusOpenClose,
            onChanged: _viewCtrl.toggleShopStatus,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryTextColor),
        const SizedBox(width: 5),
        Flexible(
          child: CustomText(
            text,
            fontSize: SizeConfig.medium15,
            color: AppColors.secondaryTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATS ROW
  // ============================================================

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
        CustomText(value,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.bold,
            color: AppColors.mainTextColor),
        const SizedBox(height: 4),
        CustomText(label,
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w400),
      ],
    );
  }

  Widget _statDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.shade200);
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
