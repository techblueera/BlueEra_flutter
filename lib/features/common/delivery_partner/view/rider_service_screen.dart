import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
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
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/address_location_riding_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/delivery_partner_orders/delivery_partner_orders.dart';
import 'package:BlueEra/features/common/delivery_partner/view/personal_information_riding_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_profile_status_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/vehicle_information_riding_screen.dart';
import 'package:BlueEra/features/common/Discover/view/go_live_permission_screen.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/common/visiting_card/view/all_personal_visiting_cards.dart';
import 'package:BlueEra/features/me/me_tab_registry.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/subscription/view/subscription_status_view.dart';
import 'package:BlueEra/permissionCentralize/go_live_permission_service.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'rider_add_store_screen.dart';
import 'rider_my_store_tab.dart';

class RiderServiceScreen extends StatefulWidget {
  final bool fromBottomNavBar;

  const RiderServiceScreen({super.key, this.fromBottomNavBar = false});

  @override
  State<RiderServiceScreen> createState() => _RiderServiceScreenState();
}

class _RiderServiceScreenState extends State<RiderServiceScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  int _currentTabIndex = 0;

  final controller = getOrPut(() => DeliveryPartnerController());
  final _viewCtrl =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);
  final _personalCtrl = getOrPut(() => PersonalCreateProfileController());
  bool allCompleted = false;
  bool allStepsCompleted = false;

  @override
  void initState() {
    _checkRiderStatus();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    MeTabRegistry.register(_tabController);
    _viewCtrl.UserFollowersAndPostsCount(userId);
    super.initState();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_currentTabIndex != _tabController.index) {
      setState(() => _currentTabIndex = _tabController.index);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      RouteHelper.routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _checkRiderStatus();
  }

  @override
  void dispose() {
    deleteIfRegistered<DeliveryPartnerController>();
    _tabController.removeListener(_onTabChanged);
    MeTabRegistry.unregister(_tabController);
    _tabController.dispose();
    RouteHelper.routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _checkRiderStatus() {
    controller.ridersOnboardingStatusRepoApi();
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

  String _formatJoinedDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return '';
    }
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

  Future<void> _handleGoLiveToggle() async {
    if (_viewCtrl.shopStatusOpenClose.value) {
      _viewCtrl.toggleShopStatus();
      return;
    }
    if (await GoLivePermissionService.areAllGranted()) {
      _viewCtrl.toggleShopStatus();
      return;
    }
    if (!mounted) return;
    final granted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const GoLivePermissionScreen()),
    );
    if (granted == true) {
      _viewCtrl.toggleShopStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.ridersOnboardingStatusResponse.value.status ==
          Status.COMPLETE) {
        final stepStatus = controller.stepStatus;
        allCompleted = controller
                .riderOnboardingStatusData.value?.verificationStatus ==
            "approved";
        allStepsCompleted =
            stepStatus.values.every((status) => status == true);
        return _buildRiderEnabled(context);
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildRiderEnabled(BuildContext context) {
    final stepStatus = controller.stepStatus;
    final firstIncompleteEntry = stepStatus.entries
        .where((entry) => entry.value == false)
        .cast<MapEntry<RiderProfileStep, bool>>()
        .toList()
        .firstOrNull;

    return Scaffold(
      body: SafeArea(
        // Keep bottom safe-area padding so the tab content doesn't get
        // clipped by the device's system gesture/nav area.
        bottom: true,
        child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Cover section
          SliverToBoxAdapter(child: _buildCoverSection(context)),
          // Profile info
          SliverToBoxAdapter(child: _buildProfileInfoSection()),
          // Stats
          SliverToBoxAdapter(child: _buildStatsRow()),
          // Pinned tabs
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
                Tab(
                    text: allCompleted
                        ? AppStrings.myOrder.tr
                        : AppStrings.document.tr),
                // Tab(text: AppStrings.myStore.tr),
                Tab(text: AppStrings.statistics.tr),
              ],
            ),
          ),
        ],
        body: Padding(
          // Extra breathing room so UI at the very bottom of each tab
          // (action buttons, list tails) isn't clipped by the system
          // gesture area / bottom nav bar on smaller devices.
          padding: const EdgeInsets.only(bottom: 80),
          child: TabBarView(
            controller: _tabController,
            children: [
              (firstIncompleteEntry?.key == RiderProfileStep.personalInfo)
                  ? PersonalInformationRidingScreen(
                      screeName: 'from_tab_view')
                  : (firstIncompleteEntry?.key ==
                          RiderProfileStep.addressInfo)
                      ? AddressLocationRidingScreen(
                          screeName: 'from_tab_view')
                      : (firstIncompleteEntry?.key ==
                              RiderProfileStep.vehicleInfo)
                          ? VehicleInformationRidingScreen(
                              screeName: 'from_tab_view')
                          : controller.riderOnboardingStatusData.value
                                      ?.verificationStatus ==
                                  "approved"
                              ? DeliveryPartnerOrders()
                              : RiderProfileStatusScreen(
                                  screeName: 'from_tab_view'),
              // const RiderMyStoreTab(),
              const SubscriptionStatusView(),
            ],
          ),
        ),
      )),
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
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
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
                        _viewCtrl.personalProfileDetails.value.user?.name ??
                            '';
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
                      border:
                          Border.all(color: AppColors.greyE5, width: 1.5),
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
                      color:
                          AppColors.primaryColor.withValues(alpha: 0.08),
                      border: Border.all(
                        color:
                            AppColors.primaryColor.withValues(alpha: 0.3),
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
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildGoLiveWidget(),
        ],
      ),
    );
  }

  Widget _buildGoLiveWidget() {
    if (_currentTabIndex == 1) return _buildNewStoreButton();
    if (!Platform.isAndroid) return const SizedBox.shrink();

    return Builder(builder: (_) {
      final statusData = serviceProviderStatusGlobal.toUpperCase();
      final isOpen = statusData == AppConstants.OPEN.toUpperCase();
      if (_viewCtrl.shopStatusOpenClose.value != isOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _viewCtrl.shopStatusOpenClose.value = isOpen;
        });
      }
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
              onChanged: () => _handleGoLiveToggle(),
            ),
          ],
        ),
      );
    });
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

  Widget _buildNewStoreButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RiderAddStoreScreen()),
        ).then((_) => controller.getAssociatedShops(filter: 'all'));
      },
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size10, vertical: SizeConfig.size6),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: AppColors.white, size: 18),
            SizedBox(width: SizeConfig.size4),
            CustomText(
              'New Store',
              fontSize: SizeConfig.medium,
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
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
