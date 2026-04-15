import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/me/me_tab_registry.dart';
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/self_work_service_controller.dart';
import 'package:BlueEra/features/subscription/view/subscription_status_view.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_employee_orders.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/choose_earn_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_profession_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/tab_bar_delegate.dart';
import 'package:BlueEra/widgets/user_profile_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_dashboard_view.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_profile_selector.dart';

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
  final viewPersonalDetailsController = Get.find<ViewPersonalDetailsController>();
  final controller = getOrPut(() => SelfWorkServiceController());
  final earnServiceController = getOrPut(() => EarnServiceController());

  late TabController _tabController;
  final ScrollController _nestedScrollController = ScrollController();
  final RxBool _isFabVisible = true.obs;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
    );
    MeTabRegistry.register(_tabController);
    // controller.fetchOwnProducts();
    _nestedScrollController.addListener(_onScroll);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _syncShopStatus());
  }

  @override
  void dispose() {
    MeTabRegistry.unregister(_tabController);
    _tabController.dispose();
    _nestedScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _nestedScrollController.offset;
    if (offset > _lastScrollOffset && offset > 60) {
      if (_isFabVisible.value) _isFabVisible.value = false;
    } else if (offset < _lastScrollOffset) {
      if (!_isFabVisible.value) _isFabVisible.value = true;
    }
    _lastScrollOffset = offset;
  }

  void _syncShopStatus() {
    viewPersonalDetailsController.shopStatusOpenClose.value =
        serviceProviderStatusGlobal.toUpperCase() ==
            AppConstants.OPEN.toUpperCase();
  }


  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isEarnSelected = controller.selectedProfileIndex.value == 1 &&
          viewPersonalDetailsController.earnProfileType.value != null;

      if (isEarnSelected) {
        return EarnServiceDashboardView(
          fromBottomNavBar: widget.fromBottomNavBar,
        );
      }

      return Scaffold(
        body: SafeArea(
          child: NestedScrollView(
            controller: _nestedScrollController,
            headerSliverBuilder: (_, __) => [
              _buildSliverHeader(),
              _buildSliverTabBar(),
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

  // ─── Sliver Header ─────────────────────────────────────────────

  Widget _buildSliverHeader() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      automaticallyImplyLeading: false,
      expandedHeight: SizeConfig.size70,
      flexibleSpace: Padding(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size15),
        child: Row(
          children: [
            if (!widget.fromBottomNavBar)
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                icon: LocalAssets(
                  imagePath: AppIconAssets.back_arrow,
                  height: SizeConfig.paddingL,
                  width: SizeConfig.paddingL,
                  imgColor: Colors.black,
                ),
              ),
            Padding(
              padding: EdgeInsets.only(left: SizeConfig.size15),
              child: _buildProfileSelector(),
            ),
            Spacer(),
            _buildGoLiveChip(),
            IconButton(
              onPressed: () async => await Get.toNamed(
                RouteHelper.getAvailabilityScreenRoute(),
                arguments: {ApiKeys.argId: userId},
              ),
              icon: LocalAssets(imagePath: AppIconAssets.clockIcon),
            ),
            // Show add button only if no earn profile exists
            if (viewPersonalDetailsController.earnProfileType.value == null)
              Padding(
                padding: EdgeInsets.only(
                    right: SizeConfig.paddingL
                ),
                child: InkWell(
                  onTap: ()=> Get.to(() => const chooseEarnServiceScreen()),
                  child: Container(
                    height: SizeConfig.size40,
                    width: SizeConfig.size40,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(SizeConfig.size8),
                        color: AppColors.primaryColor
                    ),
                    alignment: Alignment.center,
                    padding: EdgeInsets.all(6.0),
                    child: LocalAssets(imagePath: AppIconAssets.add),
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoLiveChip() {
    return Container(
      margin: EdgeInsets.only(left: SizeConfig.size10),
      height: SizeConfig.size40,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(width: SizeConfig.paddingXSL),
          CustomText(
            AppStrings.goLive,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
          buildToggleSwitchChip(
            value: viewPersonalDetailsController.shopStatusOpenClose,
            onChanged: viewPersonalDetailsController.toggleShopStatus,
          ),
        ],
      ),
    );
  }

  // ─── Sliver Tab Bar ────────────────────────────────────────────

  Widget _buildSliverTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: TabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.blue,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: AppStrings.myOrder.tr),
            Tab(text: AppStrings.home.tr),
            Tab(text: AppStrings.statistics.tr),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSelector() {
    return Obx(() {
      final userImage = viewPersonalDetailsController
          .personalProfileDetails.value.user?.profileImage ?? '';
      final earnType = viewPersonalDetailsController.earnProfileType.value;
      final hasEarnProfile = earnType != null && earnType.isNotEmpty;

      debugPrint('=== hasEarnProfile: $hasEarnProfile');

      if (!hasEarnProfile) {
        return CommonProfileAvatar();
      }

      return EarnServiceProfileSelector(
        profileImages: [userImage, userImage],
        profileNames: ['Skill Work', earnServiceController.earnProfileLabel(earnType)],
        selectedIndex: controller.selectedProfileIndex.value,
        onProfileSelected: (index) => controller.switchProfile(index),
        onAddTap: () => Get.to(() => const chooseEarnServiceScreen()),
      );
    });
  }



  // ─── FAB ───────────────────────────────────────────────────────

  Widget _buildFAB() {
    return Obx(() => AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          offset:
              _isFabVisible.value ? Offset.zero : const Offset(0, 2.5),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isFabVisible.value ? 1.0 : 0.0,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: widget.fromBottomNavBar
                    ? kBottomNavigationBarHeight + SizeConfig.size20
                    : 0,
              ),
              child: GestureDetector(
                onTap: () => Get.to(() => const chooseEarnServiceScreen()),
                child: Container(
                  height: SizeConfig.size50,
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size20,
                    vertical: SizeConfig.size12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColor.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 18),
                      ),
                      SizedBox(width: SizeConfig.size8),
                      const CustomText(
                        'Add Service',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }

}
