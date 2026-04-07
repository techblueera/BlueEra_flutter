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
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_orders.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_selection_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/food_menu_management_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/tiffin_menu_management_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/self_profession_details_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/view/rental_service_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/tab_bar_delegate.dart';
import 'package:BlueEra/widgets/user_profile_widget.dart';
import 'package:BlueEra/features/me/product/widget/own_product_card.dart';

class EarnServiceDashboardView extends StatefulWidget {
  final bool fromBottomNavBar;
  final int initialTabIndex;
  final int initialProductSubTab;

  const EarnServiceDashboardView({
    super.key,
    required this.fromBottomNavBar,
    this.initialTabIndex = 0,
    this.initialProductSubTab = 0,
  });

  @override
  State<EarnServiceDashboardView> createState() =>
      _EarnServiceDashboardViewState();
}

class _EarnServiceDashboardViewState extends State<EarnServiceDashboardView>
    with SingleTickerProviderStateMixin {
  final controller = getOrPut(() => EarnServiceController());
  final viewPersonalDetailsController =
      Get.find<ViewPersonalDetailsController>();

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
      initialIndex: widget.initialTabIndex,
    );
    if (widget.initialProductSubTab != 0) {
      controller.selectedProductsServicesTabIndex.value =
          widget.initialProductSubTab;
    }
    controller.fetchOwnProducts();
    _nestedScrollController.addListener(_onScroll);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _syncShopStatus());
  }

  @override
  void dispose() {
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

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _buildFAB(),
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
              EarnServiceOrders(),
              _buildMyProductsTab(),
              RentalServiceScreen(),
            ],
          ),
        ),
      ),
    );
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
            Expanded(
              child: Row(
                children: [
                  CommonProfileAvatar(),
                  SizedBox(width: SizeConfig.size15),
                  InkWell(
                    onTap: () => Get.to(() => ProfessionDetailsScreen()),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: SizeConfig.paddingXSL),
                      child: CustomText(
                        userDesignationGlobal,
                        fontSize: SizeConfig.large,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildGoLiveChip(),
            IconButton(
              onPressed: () async => await Get.toNamed(
                RouteHelper.getAvailabilityScreenRoute(),
                arguments: {ApiKeys.argId: userId},
              ),
              icon: LocalAssets(imagePath: AppIconAssets.clockIcon),
            ),
            SizedBox(width: SizeConfig.paddingXSL),
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
            Tab(text: AppStrings.myProducts.tr),
            Tab(text: AppStrings.rentalServices.tr),
          ],
        ),
      ),
    );
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
                onTap: () => Get.to(() => const EarnServiceSelectionScreen()),
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

  // ─── My Products Tab ───────────────────────────────────────────

  Widget _buildMyProductsTab() {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: SizeConfig.size8,
                right: SizeConfig.size8,
                top: SizeConfig.size15,
              ),
              child: HorizontalTabSelector(
                tabs: controller.productsServicesTab,
                selectedIndex:
                    controller.selectedProductsServicesTabIndex.value,
                horizontalMargin: 0.0,
                labelBuilder: (label) => label,
                unSelectedBackgroundColor: AppColors.white,
                onTabSelected: (index, _) => _onProductSubTabChanged(index),
              ),
            ),
            Expanded(child: _buildProductSubTabContent()),
          ],
        ));
  }

  void _onProductSubTabChanged(int index) async {
    controller.selectedProductsServicesTabIndex.value = index;
    if (index == 2) await controller.fetchOwnProducts();
  }

  Widget _buildProductSubTabContent() {
    return Obx(() {
      switch (controller.selectedProductsServicesTabIndex.value) {
        case 0:
          return TiffinMenuManagementScreen();
        case 1:
          return const FoodMenuManagementScreen();
        case 2:
          return _buildOwnProductsGrid();
        default:
          return const SizedBox.shrink();
      }
    });
  }

  Widget _buildOwnProductsGrid() {
    if (controller.isOwnProductDataFirstLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    final productList = controller.ownProductDataList;
    if (productList.isEmpty) {
      return EmptyStateWidget(message: AppStrings.noProductFound);
    }

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 2;
              const spacing = 10.0;
              final itemWidth =
                  (constraints.maxWidth - spacing) / crossAxisCount;
              final childAspectRatio = itemWidth / SizeConfig.size240;

              return GridView.builder(
                itemCount: productList.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
                padding: EdgeInsets.only(
                  bottom: kBottomNavigationBarHeight + 40,
                  left: SizeConfig.size8,
                  right: SizeConfig.size8,
                  top: SizeConfig.size8,
                ),
                itemBuilder: (context, index) {
                  return OwnProductCard(
                    deleteProductApi: () {},
                    width: itemWidth,
                    product: productList[index],
                    isGridShow: true,
                  );
                },
              );
            },
          ),
        ),
        if (controller.isOwnProductDataLoadingMore.value)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
