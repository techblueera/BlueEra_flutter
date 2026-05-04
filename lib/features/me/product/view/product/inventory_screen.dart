import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_verify_now_button.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_statistics_screen.dart';
import 'package:BlueEra/features/me/me_tab_registry.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/controller/product_business_profile_full_controller.dart';
import 'package:BlueEra/features/me/product/view/product_home_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Inventory home (v2) — pattern background, blue gradient top bar,
/// white profile row, and a rounded-pill tab card. Pill order:
/// Orders, Overview, Post, Add Product, Statistics. "Add Product" is
/// action-only — it fires the existing add-product flow without
/// switching the body.
class InventoryScreen extends StatefulWidget {
  final bool fromBottomNavBar;

  const InventoryScreen({
    super.key,
    this.fromBottomNavBar = false,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _selectedBody = _bodyOverview;
  bool _isLoading = true;

  late final List<_PillTab> _tabs;
  late final List<Widget> _tabViews;

  // Body indices (kept in sync with _tabViews order).
  static const int _bodyOrders = 0;
  static const int _bodyOverview = 1;
  static const int _bodyPost = 2;
  static const int _bodyStatistics = 3;

  final inventoryController = getOrPut(() => InventoryController());
  final controller = getOrPut(() => ProductBusinessProfileFullController());
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _tabs = [
      _PillTab(label: AppStrings.orders.tr, action: _PillAction.body, bodyIndex: _bodyOrders),
      _PillTab(label: AppStrings.overview.tr, action: _PillAction.body, bodyIndex: _bodyOverview),
      _PillTab(label: AppStrings.post.tr, action: _PillAction.body, bodyIndex: _bodyPost),
      _PillTab(label: AppStrings.addProduct.tr, action: _PillAction.addProduct),
      _PillTab(label: AppStrings.statistics.tr, action: _PillAction.body, bodyIndex: _bodyStatistics),
    ];

    _tabViews = [
      _OrdersTabBody(),
      const ProductHomeScreen(),
      _PostTabBody(),
      MedicalStatisticsScreen(businessId: userId),
    ];

    _tabController = TabController(
      length: _tabViews.length,
      initialIndex: _selectedBody,
      vsync: this,
    )..addListener(_onTabChanged);
    MeTabRegistry.register(_tabController!);
    setState(() => _isLoading = false);
  }

  void _onTabChanged() {
    final c = _tabController;
    if (c == null || c.indexIsChanging) return;
    if (_selectedBody != c.index) {
      setState(() => _selectedBody = c.index);
    }
  }

  @override
  void dispose() {
    if (_tabController != null) {
      MeTabRegistry.unregister(_tabController!);
      _tabController!.removeListener(_onTabChanged);
    }
    _tabController?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading || _tabController == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFEAF2FB),
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FB),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            _buildPatternBackground(),
            Column(
              children: [
                _buildTopBar(),
                _buildProfileRow(),
                SizedBox(height: SizeConfig.size10),
                _buildTabsCard(),
                SizedBox(height: SizeConfig.size10),
                Expanded(
                  child: IndexedStack(
                    index: _selectedBody,
                    children: _tabViews,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BACKGROUND
  // ─────────────────────────────────────────────
  Widget _buildPatternBackground() {
    return Positioned.fill(
      child: Image.asset(
        AppImageAssets.chatDefaultBg,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEAF2FB)),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────
  Widget _buildTopBar() {
    final topInset = MediaQuery.of(context).padding.top;
    final isGuest = isGuestUser();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        topInset + SizeConfig.size8,
        SizeConfig.size12,
        SizeConfig.size10,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E88FF), Color(0xFF0040A0)],
        ),
      ),
      child: Row(
        children: [
          _circleIconButton(icon: Icons.menu, onTap: _openDrawer),
          const Spacer(),
          if (!isGuest)
            _circleIconButton(
              icon: Icons.notifications_none,
              onTap: _openNotifications,
            ),
        ],
      ),
    );
  }

  void _openDrawer() {
    showDialog(
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      useSafeArea: false,
      context: context,
      builder: (_) => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          height: double.infinity,
          child: Drawer(backgroundColor: Colors.transparent, elevation: 0, child: ProfileMenuDrawer()),
        ),
      ),
    );
  }

  void _openNotifications() {
    Navigator.pushNamed(context, RouteHelper.getNotificationScreenRoute());
  }

  /// Same flow that was previously triggered by the top-bar "Add Product"
  /// pill — now reused by the "Add Product" tab pill.
  Future<void> _onAddProduct() async {
    if (businessId.isEmpty) return;
    await Get.toNamed(
      RouteHelper.getProductSuperCategoryScreenRoute(),
      arguments: {
        ApiKeys.id: businessId,
        ApiKeys.providerType: ProviderType.business,
      },
    );
    if (inventoryController.productDataNeedsRefresh) {
      inventoryController.productDataNeedsRefresh = false;
      inventoryController.fetchAllProductData();
    }
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        height: SizeConfig.size36,
        width: SizeConfig.size36,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.mainTextColor),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PROFILE ROW
  // ─────────────────────────────────────────────
  Widget _buildProfileRow() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size12,
      ),
      child: Obx(() {
        final details =
            viewBusinessDetailsController.businessProfileDetails.value?.data;
        final logoFromCtrl =
            viewBusinessDetailsController.imagePath?.value ?? '';
        final logo =
            logoFromCtrl.isNotEmpty ? logoFromCtrl : (details?.logo ?? '');
        final name = details?.businessName ?? '';
        final type = details?.typeOfBusiness ?? '';

        return Row(
          children: [
            Container(
              height: SizeConfig.size40,
              width: SizeConfig.size40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              clipBehavior: Clip.hardEdge,
              child: logo.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: logo,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _logoFallback(),
                    )
                  : _logoFallback(),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    name.isNotEmpty ? name : AppStrings.businessName.tr,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (type.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    CustomText(
                      type,
                      fontSize: 12,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            BusinessVerifyNowButton(details: details),
          ],
        );
      }),
    );
  }

  Widget _logoFallback() => Container(
        color: Colors.grey.shade200,
        child: Icon(
          Icons.storefront,
          size: 20,
          color: AppColors.secondaryTextColor,
        ),
      );

  // ─────────────────────────────────────────────
  // TABS CARD (rounded white pills)
  // ─────────────────────────────────────────────
  Widget _buildTabsCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
          vertical: SizeConfig.size8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final selected = tab.action == _PillAction.body &&
                  tab.bodyIndex == _selectedBody;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onPillTapped(tab),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size16,
                      vertical: SizeConfig.size6,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryColor
                            : Colors.grey.shade300,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tab.action == _PillAction.addProduct) ...[
                          Icon(
                            Icons.add,
                            size: 14,
                            color: selected
                                ? Colors.white
                                : AppColors.primaryColor,
                          ),
                          SizedBox(width: SizeConfig.size4),
                        ],
                        CustomText(
                          tab.label,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppColors.mainTextColor,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _onPillTapped(_PillTab tab) {
    if (tab.action == _PillAction.addProduct) {
      _onAddProduct();
      return;
    }
    final c = _tabController;
    if (c == null) return;
    final body = tab.bodyIndex;
    if (body == null || body < 0 || body >= c.length) return;
    if (body == c.index) return;
    c.animateTo(body);
    setState(() => _selectedBody = body);
  }
}

enum _PillAction { addProduct, body }

class _PillTab {
  final String label;
  final _PillAction action;
  final int? bodyIndex;
  const _PillTab({
    required this.label,
    required this.action,
    this.bodyIndex,
  });
}

// ─────────────────────────────────────────────
// POST TAB — embeds FeedScreen filtered to the current user's posts.
// ─────────────────────────────────────────────
class _PostTabBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FeedController>()) {
      Get.put(FeedController());
    }
    return FeedScreen(
      key: const ValueKey('inventory_v2_my_posts'),
      postFilterType: PostType.myPosts,
      id: userId,
      horizontalPaddingChannel: SizeConfig.size12,
    );
  }
}

// ─────────────────────────────────────────────
// ORDERS TAB — placeholder until product orders ships.
// ─────────────────────────────────────────────
class _OrdersTabBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size40,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(height: SizeConfig.size10),
            CustomText(
              AppStrings.orders.tr,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size4),
            CustomText(
              AppStrings.comingSoon.tr,
              fontSize: 12,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
