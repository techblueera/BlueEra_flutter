import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_profile_header_view.dart';
import 'package:BlueEra/features/business/widgets/business_stats.dart';
import 'package:BlueEra/features/me/me_tab_registry.dart';
import 'package:BlueEra/features/me/product/controller/product_business_profile_full_controller.dart';
import 'package:BlueEra/features/subscription/view/subscription_status_view.dart';
import 'package:BlueEra/features/me/product/view/product_home_screen.dart';
import 'package:BlueEra/features/business/widgets/empty_website_tab.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/inventory_controller.dart';

class InventoryScreen extends StatefulWidget {
  final bool fromBottomNavBar;
  // final String? isShowScreen;

  const InventoryScreen(
      {
        super.key,
        this.fromBottomNavBar = false,
        // this.isShowScreen
      });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin
    // , RouteAware
{
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();
  TabController? _tabController;

  // String _businessType = BusinessType.Product.name;
  bool _isLoading = true;
  late List<Tab> _tabs;

  final inventoryController = getOrPut(() => InventoryController());
  final controller = getOrPut(() => ProductBusinessProfileFullController());
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();
  late List<Widget> _tabViews;

  @override
  void initState() {
    // logs("widget.isShowScreen=== ${widget.isShowScreen}");
    // if (widget.isShowScreen?.isNotEmpty ?? false) {
    //   _businessType = widget.isShowScreen ?? "";
    // }
    // apiCalling();
    _initializeData();
    super.initState();
  }

  // apiCalling() async {
  //   try {
  //     log('id -- $productBusinessProfileIDGlobal');
  //     if (productBusinessProfileIDGlobal.isEmpty) {
  //       ResponseModel response = await InventoryRepo().getBusinessProfileRepo();
  //       if (response.isSuccess) {
  //         productBusinessProfileIDGlobal = response.response?.data['data']['_id'];
  //         if (productBusinessProfileIDGlobal.isNotEmpty) {
  //           await setProductBusinessProfileID(productBusinessProfileIDGlobal);
  //         } else {
  //           await setProductBusinessProfileID("");
  //         }
  //       }
  //     }
  //     await getProductBusinessProfileID();
  //     setState(() {
  //       controller.hasProfile.value = productBusinessProfileIDGlobal.isNotEmpty;
  //     });
  //   } on Exception {
  //     // TODO
  //   }
  // }
  //

  void _initializeData() {
    _tabs = [
      Tab(text: AppStrings.home.tr),
      Tab(text: AppStrings.website.tr),
      Tab(text: AppStrings.statistics.tr),
    ];

    _tabViews = [
      ProductHomeScreen(),
      const WebsiteTab(),
      const SubscriptionStatusView(),
    ];

    _tabController = TabController(length: _tabs.length, vsync: this);
    MeTabRegistry.register(_tabController!);
    setState(() => _isLoading = false);
  }

  // void _initializeData() {
  //   // final business =  _businessType.toLowerCase();
  //   final business = businessTypeGlobal.toLowerCase();
  //   log('business -- $business');
  //   log('business 1111 -- ${(isShowProduct.contains(business))}');
  //   log('business 2222 -- ${(isShowService.contains(business))}');
  //   // log('business 3333 -- ${(isShowFood.contains(business))}');
  //
  //   _businessType = business;
  //   _tabs = [];
  //
  //   if (isShowProduct.contains(business))
  //     _tabs.add(Tab(text: AppStrings.myProducts.tr));
  //   if (isShowService.contains(business))
  //     _tabs.add(Tab(text: AppStrings.myServices.tr));
  //   if (isShowFood.contains(business))
  //     _tabs.add(Tab(text: AppStrings.foodAndGrocery.tr));
  //   _tabs.add(Tab(text: AppStrings.statistics.tr));
  //
  //   _tabController = TabController(length: _tabs.length, vsync: this);
  //   if (_tabs.isEmpty) {
  //     log("No tabs available for business type: $business");
  //     setState(() => _isLoading = false);
  //     return;
  //   }
  //
  //   final firstTab = _tabs.first.text;
  //   if (firstTab == AppStrings.myProducts.tr) {
  //     inventoryController.callApi(forceRefresh: true);
  //   } else if (firstTab == AppStrings.myServices.tr) {
  //     final queryParams = {
  //       ApiKeys.all: false,
  //       ApiKeys.type: AppConstants.service,
  //       ApiKeys.providerType: ProviderType.business.title,
  //     };
  //     serviceController.getServices(queryParams);
  //   }
  //   else if (firstTab == AppStrings.foodAndGrocery.tr) {
  //     final queryParams = {
  //       ApiKeys.all: false,
  //       ApiKeys.type: AppConstants.food,
  //       ApiKeys.providerType: ProviderType.business.title,
  //     };
  //     foodUploadController.getFoodService(queryParams);
  //   }
  //   setState(() => _isLoading = false);
  // }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   final route = ModalRoute.of(context);
  //   if (route is PageRoute) {
  //     RouteHelper.routeObserver.subscribe(this, route);
  //   }
  // }
  //
  // @override
  // void didPopNext() {
  //   // Called when coming back to this screen
  //   print("Returned to InventoryScreen from: ${Get.previousRoute}");
  // }

  @override
  void dispose() {
    // deleteIfRegistered<ProductController>();
    // deleteIfRegistered<InventoryController>();
    // RouteHelper.routeObserver.unsubscribe(this);
    if (_tabController != null) MeTabRegistry.unregister(_tabController!);
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
      backgroundColor: AppColors.white,
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

      // floatingActionButton: Padding(
      //   padding: EdgeInsets.only(
      //       bottom: widget.fromBottomNavBar
      //           ? kBottomNavigationBarHeight + SizeConfig.size20
      //           : 0.0),
      //   child: FloatingActionButton(
      //     onPressed: () async {
      //       await Get.toNamed(RouteHelper.getAddProductScreenRoute(), arguments: {
      //         ApiKeys.id: businessId,
      //         ApiKeys.providerType: ProviderType.business
      //       });
      //       inventoryController.callApi(forceRefresh: true);
      //     },
      //     backgroundColor: AppColors.primaryColor,
      //     foregroundColor: Colors.white,
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(10),
      //     ),
      //     child: Icon(
      //       Icons.add,
      //       size: SizeConfig.size36,
      //     ),
      //   ),
      // ),
      body: SafeArea(
        child: BottomNavHideOnScroll(
          child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
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
                  buildCustomActionWidget: () => _AddActionPill(
                    label: AppStrings.addProduct.tr,
                    onTap: () async {
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
                    },
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Obx(() {
                final details = viewBusinessDetailsController
                    .businessProfileDetails.value?.data;
                return BusinessProfileHeaderView(
                  details: details,
                  controller: viewBusinessDetailsController,
                );
              }),
            ),
            SliverToBoxAdapter(
              child: Obx(() {
                final details = viewBusinessDetailsController
                    .businessProfileDetails.value?.data;
                return BusinessStats(details: details);
              }),
            ),
            SliverAppBar(
              pinned: true,
              floating: false,
              primary: false,
              automaticallyImplyLeading: false,
              toolbarHeight: 0,
              collapsedHeight: 0,
              expandedHeight: 0,
              backgroundColor: AppColors.white,
              surfaceTintColor: AppColors.white,
              bottom: TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryColor,
                unselectedLabelColor: AppColors.secondaryTextColor,
                indicatorColor: AppColors.primaryColor,
                indicatorWeight: 2,
                tabAlignment: TabAlignment.fill,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.w400),
                tabs: _tabs,
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: _tabViews,
          ),
        ),
        ),
      ),
    );
  }

  // void showPopUpMenu(
  //     BuildContext context, InventoryController controller) async {
  //   final RenderBox button = context.findRenderObject() as RenderBox;
  //   final RenderBox overlay =
  //       Overlay.of(context).context.findRenderObject() as RenderBox;
  //
  //   // FAB position & size
  //   final Offset fabPosition =
  //       button.localToGlobal(Offset.zero, ancestor: overlay);
  //   final Size fabSize = button.size;
  //
  //   // Menu height (approximate based on items * itemHeight)
  //   const double itemHeight = 36.0;
  //   const int itemCount = 3;
  //   const double menuHeight = itemHeight * (itemCount - 1);
  //
  //   final RelativeRect position = RelativeRect.fromLTRB(
  //     fabPosition.dx, // align with FAB left
  //     fabPosition.dy - menuHeight + 10, // just above FAB
  //     overlay.size.width - fabPosition.dx - fabSize.width,
  //     overlay.size.height - fabPosition.dy,
  //   );
  //
  //   controller.isMenuOpen.value = true;
  //   final result = await showMenu(
  //     context: context,
  //     position: position,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     items: popupMenuInventoryItems(_businessType),
  //   );
  //   controller.isMenuOpen.value = false;
  //
  //   if (result != null) {
  //     log('result--> $result');
  //     if (result == InventoryMenuItem.addProduct) {
  //       await Get.toNamed(RouteHelper.getAddProductScreenRoute(), arguments: {
  //         ApiKeys.id: businessId,
  //         ApiKeys.providerType: ProviderType.business
  //       });
  //       controller.callApi(forceRefresh: true);
  //
  //       // bool isApiCall = await Get.toNamed(
  //       //   RouteHelper.getAddProductScreenRoute(),
  //       //   arguments: {
  //       //     ApiKeys.id: businessId,
  //       //     ApiKeys.providerType: ProductServiceProviderType.business,
  //       //   },
  //       // );
  //       //
  //       // log('need api calling--> $isApiCall');
  //       //
  //       // if (isApiCall) {
  //       //   controller.callApi(forceRefresh: true);
  //       // }
  //     } else if (result == InventoryMenuItem.addService) {
  //       Get.toNamed(RouteHelper.getAddServicesScreenRoute(), arguments: {
  //         ApiKeys.providerType: ProviderType.business,
  //       });
  //     } else if (result == InventoryMenuItem.addFood) {
  //       Get.toNamed(
  //         RouteHelper.getFoodUploadScreenRoute(),
  //         arguments: {
  //           ApiKeys.providerType: ProviderType.business,
  //         },
  //       );
  //     }
  //
  //   }
  // }

}

class _AddActionPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddActionPill({required this.label, required this.onTap});

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                Icon(
                  Icons.add,
                  size: 16,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
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
