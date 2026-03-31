import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/popup_menu_builders.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/product_business_profile_full_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product/product_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product_home_screen.dart';
import 'package:BlueEra/widgets/common_search_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/tab_bar_delegate.dart';
import 'package:BlueEra/widgets/user_profile_widget.dart';
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
  // final serviceController = getOrPut(() => ServiceController());
  // final foodUploadController = getOrPut(() => FoodUploadController());
  final controller = getOrPut(() => ProductBusinessProfileFullController());

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
    // _businessType = businessTypeGlobal.toLowerCase();
    // log('business -- $_businessType');

    _tabs = [
      Tab(text: AppStrings.home.tr),
      Tab(text: AppStrings.myProducts.tr),
      Tab(text: AppStrings.statistics.tr),
    ];
    _tabController = TabController(length: _tabs.length, vsync: this);
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
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                floating: true,
                snap: true,
                pinned: false,
                automaticallyImplyLeading: false,
                flexibleSpace: Padding(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size15),
                  child: _buildHeader(context), // your header row
                ),
                expandedHeight: SizeConfig.size70,
              ),
              SliverPersistentHeader(
                pinned: true, // TabBar should always stay visible
                delegate: TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primaryColor,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: AppColors.primaryColor,
                    indicatorWeight: 2,
                    labelStyle: TextStyle(fontWeight: FontWeight.w600),
                    tabs: _tabs,
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            // children: [
            //   if ((isShowProduct.contains(_businessType))) ProductScreen(),
            //   if ((isShowService.contains(_businessType)))
            //     ViewServiceList(
            //       providerType: ProviderType.business,
            //     ),
            //   // if ((isShowFood.contains(_businessType)))
            //   //   GroceryCategoryMenuScreen(),
            //
            //   // FoodCategoryPage(),
            //   // FoodAndGroceryScreen(
            //   //   providerType: ProductServiceProviderType.business,
            //   // ),
            //   CustomText(
            //     'Coming soon...',
            //   )
            // ],
            children: [
              ProductHomeScreen(),
              // ProductBusinessProfileFullScreen(),
              ProductScreen(),
              Center(
                child: CustomText(
                  'Coming soon...',
                ),
              )
            ],
          ),
        )
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
                imgColor: Colors.black,
              )),
        // SizedBox(width: !(widget.fromBottomNavBar) ? 0.0 : SizeConfig.size15),
        CommonProfileAvatar(),
        SizedBox(width: SizeConfig.size15),
        Expanded(
          child: CommonSearchBar(
            controller: searchController,
            onClearCallback: () => searchController.clear(),
          ),
        ),
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          offset: const Offset(-6, 36),
          color: AppColors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          icon: Icon(Icons.more_vert),
          itemBuilder: (context) => PopupMenuBuilders.inventoryPopupMenuItems(),
          onSelected: (String value) async {
            switch (value) {
              case "ADD_PRODUCT":
                await Get.toNamed(RouteHelper.getAddProductScreenRoute(), arguments: {
                  ApiKeys.id: businessId,
                  ApiKeys.providerType: ProviderType.business
                });
                inventoryController.callApi(forceRefresh: true);                break;

              case "BUSINESS_CARDS":
                Get.toNamed(RouteHelper.getInventoryBusinessCardsScreenRoute());
                break;
            }
          },
        ),
      ],
    );
  }
}
