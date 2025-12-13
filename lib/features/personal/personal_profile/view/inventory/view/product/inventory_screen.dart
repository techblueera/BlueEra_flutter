import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/food/controller/food_upload_controller.dart';
import 'package:BlueEra/features/common/service/controller/service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product/inventory_business_cards_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product/product_screen.dart';
import 'package:BlueEra/features/common/service/view/view_service_list.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_search_bar.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/tab_bar_delegate.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/inventory_controller.dart';
import '../../../../../../common/food/view/food_and_grocery_screen.dart';

class InventoryScreen extends StatefulWidget {
  final bool fromBottomNavBar;
  const InventoryScreen({super.key, this.fromBottomNavBar = false});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();
  TabController? _tabController;

  String _businessType = BusinessType.Product.name;
  bool _isLoading = true;
  late List<Tab> _tabs;

  final inventoryController = getOrPut(() => InventoryController());
  final serviceController = getOrPut(() => ServiceController());
  final foodUploadController = getOrPut(() => FoodUploadController());

  @override
  void initState() {
    _initializeData();
    super.initState();
  }

  void _initializeData() {
    // final type = businessTypeGlobal;
    // // final type = await getBusinessType();
    final business = businessTypeGlobal.toLowerCase();

    _businessType = business;
    _tabs = [];

    if (isShowProduct.contains(business)) _tabs.add(Tab(text: AppStrings.myProducts.tr));
    if (isShowService.contains(business)) _tabs.add(Tab(text: AppStrings.myServices.tr));
    if (isShowFood.contains(business)) _tabs.add(Tab(text: AppStrings.foodAndGrocery.tr));
    _tabs.add(Tab(text: AppStrings.businessCards.tr));

    _tabController = TabController(length: _tabs.length, vsync: this);
    if (_tabs.isEmpty) {
      log("No tabs available for business type: $business");
      setState(() => _isLoading = false);
      return;
    }

    final firstTab = _tabs.first.text;
    if (firstTab == 'My Products') {
      inventoryController.callApi(forceRefresh: true);
    } else if (firstTab == 'My Services') {
      final queryParams = {
        ApiKeys.all: false,
        ApiKeys.type: AppConstants.service,
        ApiKeys.providerType: ProductServiceProviderType.business.title,
      };
      serviceController.getServices(queryParams);
    } else if (firstTab == 'Food & Grocery') {
      final queryParams = {
        ApiKeys.all: false,
        ApiKeys.type: AppConstants.food,
        ApiKeys.providerType: ProductServiceProviderType.business.title,
      };
      foodUploadController.getFoodService(queryParams);
    }
    setState(() => _isLoading = false);
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
    // Called when coming back to this screen
    print("Returned to InventoryScreen from: ${Get.previousRoute}");
  }

  @override
  void dispose() {
    // Get.delete<ProductController>();
    // Get.delete<InventoryController>();
    RouteHelper.routeObserver.unsubscribe(this);
    _tabController?.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    return Scaffold(
      // appBar: PreferredSize(
      //   preferredSize: Size.fromHeight(kToolbarHeight + 50),
      //   child: CommonBackAppBar(
      //     isLeading: !(widget.fromBottomNavBar),
      //     controller: searchController,
      //     searchHintText:
      //     AppStrings.searchHintText,
      //     // 'Search ${_tabController.index == 0 ? 'Product' : _tabController.index == 1 ? 'Service' : 'Food & Grocery'}...',
      //     onClearCallback: () => searchController.clear(),
      //     isSearch: true,
      //     isInventoryPopUpMenu: true,
      //     bottomWidget: TabBar(
      //       controller: _tabController,
      //       labelColor: AppColors.primaryColor,
      //       unselectedLabelColor: Colors.grey[600],
      //       indicatorColor: Colors.blue,
      //       indicatorWeight: 2,
      //       labelStyle: TextStyle(fontWeight: FontWeight.w600),
      //       tabs: [
      //         if (isShowProduct.contains(_businessType))
      //           Tab(text: AppStrings.myProducts.tr),
      //         if (isShowService.contains(_businessType))
      //           Tab(text: AppStrings.myServices.tr),
      //         if (isShowFood.contains(_businessType))
      //           Tab(text: AppStrings.foodAndGrocery.tr),
      //         Tab(text: AppStrings.businessCards.tr),
      //       ],
      //     ),
      //   ),
      // ),
      backgroundColor: AppColors.whiteF3,
      floatingActionButton: Builder(builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: widget.fromBottomNavBar
                  ? kBottomNavigationBarHeight + SizeConfig.size20
                  : 0.0
          ),
          child: FloatingActionButton(
            onPressed: () => showPopUpMenu(context, inventoryController),
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: AnimatedRotation(
              turns: inventoryController.isMenuOpen.value ? 0.25 : 0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: Obx(() => Icon(
                    inventoryController.isMenuOpen.value ? Icons.close : Icons.add,
                    key: ValueKey(inventoryController.isMenuOpen.value),
                    // important for AnimatedSwitcher
                    size: SizeConfig.size36,
                  )),
            ),
          ),
        );
      }),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                floating: true,   // appear on scroll up
                snap: true,       // instantly snap down
                pinned: false,    // don't keep the header fixed
                automaticallyImplyLeading: false,
                flexibleSpace: Padding(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size15),
                  child: _buildHeader(context), // your header row
                ),
                expandedHeight: SizeConfig.size70,
              ),

              SliverPersistentHeader(
                pinned: true,   // TabBar should always stay visible
                delegate: TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primaryColor,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Colors.blue,
                    indicatorWeight: 2,
                    labelStyle: TextStyle(fontWeight: FontWeight.w600),
                    tabs: [
                      if (isShowProduct.contains(_businessType))
                        Tab(text: AppStrings.myProducts.tr),
                      if (isShowService.contains(_businessType))
                        Tab(text: AppStrings.myServices.tr),
                      if (isShowFood.contains(_businessType))
                        Tab(text: AppStrings.foodAndGrocery.tr),
                      Tab(text: AppStrings.businessCards.tr),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              if ((isShowProduct.contains(_businessType)))
                ProductScreen(),
              if ((isShowService.contains(_businessType)))
                ViewServiceList(
                  providerType: ProductServiceProviderType.business,
                ),
              if ((isShowFood.contains(_businessType)))
                // FoodCategoryPage(),
                FoodAndGroceryScreen(
                  providerType: ProductServiceProviderType.business,
                ),
              InventoryBusinessCardsScreen(
                showBackAppBar: false,
              )
            ],
          ),
        ),
      ),
    );
  }

  void showPopUpMenu(
      BuildContext context, InventoryController controller) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // FAB position & size
    final Offset fabPosition =
        button.localToGlobal(Offset.zero, ancestor: overlay);
    final Size fabSize = button.size;

    // Menu height (approximate based on items * itemHeight)
    const double itemHeight = 36.0;
    const int itemCount = 3;
    const double menuHeight = itemHeight * (itemCount-1);

    final RelativeRect position = RelativeRect.fromLTRB(
      fabPosition.dx, // align with FAB left
      fabPosition.dy - menuHeight - 24, // just above FAB
      overlay.size.width - fabPosition.dx - fabSize.width,
      overlay.size.height - fabPosition.dy,
    );

    controller.isMenuOpen.value = true;
    final result = await showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      items: popupMenuInventoryItems(_businessType),
    );
    controller.isMenuOpen.value = false;

    if (result != null) {
      log('result--> $result');
      if (result == InventoryMenuItem.addProduct) {
        await Get.toNamed(
            RouteHelper.getAddProductScreenRoute(),
            arguments: {
              ApiKeys.id: businessId,
              ApiKeys.providerType: ProductServiceProviderType.business
            }
        );
        controller.callApi(forceRefresh: true);

        // bool isApiCall = await Get.toNamed(
        //   RouteHelper.getAddProductScreenRoute(),
        //   arguments: {
        //     ApiKeys.id: businessId,
        //     ApiKeys.providerType: ProductServiceProviderType.business,
        //   },
        // );
        //
        // log('need api calling--> $isApiCall');
        //
        // if (isApiCall) {
        //   controller.callApi(forceRefresh: true);
        // }

      } else if (result == InventoryMenuItem.addService) {
        Get.toNamed(
            RouteHelper.getAddServicesScreenRoute(),
            arguments: {
              ApiKeys.providerType: ProductServiceProviderType.business,
            }
        );
      } else if (result == InventoryMenuItem.addFood) {
        Get.toNamed(
          RouteHelper.getFoodUploadScreenRoute(),
          arguments: {
            ApiKeys.providerType: ProductServiceProviderType.business,
          },
        );
      }
    }
  }

  Widget? _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (!widget.fromBottomNavBar)
          IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                    Navigator.of(context).pop();
                  },
              icon: LocalAssets(
                imagePath: AppIconAssets.back_arrow,
                height: SizeConfig.paddingL,
                width: SizeConfig.paddingL,
                imgColor:  Colors.black,
              )),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                left:
                (!widget.fromBottomNavBar) ? 0.0 : SizeConfig.size15),
            child: CommonSearchBar(
                controller: searchController,
                onClearCallback: ()=> searchController.clear(),
                hintText: AppStrings.searchHintText),
          ),
        ),
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          offset: const Offset(-6, 36),
          color: AppColors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          icon: Icon(Icons.more_vert),
          itemBuilder: (context) => inventoryPopupMenuItems(),
        ),
      ],
    );
  }
}
