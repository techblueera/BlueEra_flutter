import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/food/controller/grocery_controller.dart';
import 'package:BlueEra/features/common/food/model/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/collapsible_grid_section.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/common_back_app_bar.dart';

class GroceryCategoryScreen extends StatefulWidget {
  final Map<String, List<CollapsibleGridModel>> arrGroceryCat;
  final String pageHeading;
  final bool isMyGrocery;

  const GroceryCategoryScreen({
    super.key,
    required this.arrGroceryCat,
    required this.pageHeading,
    required this.isMyGrocery
  });

  @override
  State<GroceryCategoryScreen> createState() => _GroceryCategoryScreenState();
}

class _GroceryCategoryScreenState extends State<GroceryCategoryScreen> with SingleTickerProviderStateMixin {
  // TabController? _tabController;
  final TextEditingController searchController = TextEditingController();
  // final List<Tab> _tabs = [
  //   Tab(text: 'Grocery & Veg'),
  //   Tab(text: 'Home Essential'),
  //   Tab(text: 'Others')
  // ];
  final groceryController = getOrPut(() => GroceryController());
  late bool isMyGrocery;
  late String _pageHeading;
  late Map<String, List<CollapsibleGridModel>> _argArrGroceryCat;

  @override
  void initState() {
    isMyGrocery = widget.isMyGrocery;
    _pageHeading = widget.pageHeading;
    _argArrGroceryCat = widget.arrGroceryCat;
    // _tabController = TabController(length: _tabs.length, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(
        title: _pageHeading,
      ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ..._argArrGroceryCat.entries.map((entry) {
                  final title = entry.key;
                  final categories = entry.value;

                  if (categories.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return CollapsibleGridSection(
                    title: title,
                    categories: categories,
                    onTap: (groceryCategoryModel) {
                      final route = isMyGrocery
                          ? RouteHelper.getGrocerySubCategoryScreenRoute()
                          : RouteHelper.getGroceryListingScreenRoute();

                      Get.toNamed(
                        route,
                        arguments: {
                          ApiKeys.argGroceries: categories,
                          ApiKeys.argSelectedGroceryData: groceryCategoryModel,
                        },
                      );
                    },
                  );
                }).toList(),

                SizedBox(height: SizeConfig.size40),
              ],
            ),
          ),
        )

      // appBar: PreferredSize(
      //   preferredSize: Size.fromHeight(kToolbarHeight + 50),
      //   child: CommonBackAppBar(
      //     bottomWidget: TabBar(
      //       controller: _tabController,
      //       labelColor: AppColors.primaryColor,
      //       unselectedLabelColor: Colors.grey[600],
      //       indicatorColor: Colors.blue,
      //       indicatorWeight: 2,
      //       labelStyle: TextStyle(fontWeight: FontWeight.w600),
      //       tabs: _tabs,
      //     ),
      //   ),
      // ),
      // body: SafeArea(
      //   child: TabBarView(
      //     controller: _tabController,
      //     children: [
      //
      //       SingleChildScrollView(
      //         child: Column(
      //           children: [
      //
      //             CollapsibleGridSection(
      //               title: "Biscuits, Drinks & Packaged Foods",
      //               categories: groceryController.biscuitFoods,
      //                 onTap:(groceryCategoryModel){
      //                   final route = isOwnGrocery
      //                       ? RouteHelper.getGrocerySubCategoryScreenRoute()
      //                       : RouteHelper.getGroceryListingScreenRoute();
      //
      //                   Get.toNamed(
      //                     route,
      //                     arguments: {
      //                       ApiKeys.argGroceries: groceryController.biscuitFoods,
      //                       ApiKeys.argSelectedGroceryData: groceryCategoryModel,
      //                     },
      //                   );
      //                 }
      //             ),
      //
      //             CollapsibleGridSection(
      //               title: "Fruits & Vegetables",
      //               categories: groceryController.fruitsVeg,
      //               onTap:(groceryCategoryModel){
      //                 final route = isOwnGrocery
      //                     ? RouteHelper.getGrocerySubCategoryScreenRoute()
      //                     : RouteHelper.getGroceryListingScreenRoute();
      //
      //                 Get.toNamed(
      //                   route,
      //                   arguments: {
      //                     ApiKeys.argGroceries: groceryController.fruitsVeg,
      //                     ApiKeys.argSelectedGroceryData: groceryCategoryModel,
      //                   },
      //                 );
      //
      //               }
      //             ),
      //
      //             CollapsibleGridSection(
      //               title: "Cooking Essentials",
      //               categories: groceryController.cookingEssentials,
      //                 onTap:(groceryCategoryModel){
      //                   final route = isOwnGrocery
      //                       ? RouteHelper.getGrocerySubCategoryScreenRoute()
      //                       : RouteHelper.getGroceryListingScreenRoute();
      //
      //                   Get.toNamed(
      //                     route,
      //                     arguments: {
      //                       ApiKeys.argGroceries: groceryController.cookingEssentials,
      //                       ApiKeys.argSelectedGroceryData: groceryCategoryModel,
      //                     },
      //                   );
      //
      //                 }
      //             ),
      //
      //             CollapsibleGridSection(
      //               title: "Dairy & Bakery",
      //               categories: groceryController.dairyBakery,
      //               onTap:(groceryCategoryModel){
      //                 final route = isOwnGrocery
      //                     ? RouteHelper.getGrocerySubCategoryScreenRoute()
      //                     : RouteHelper.getGroceryListingScreenRoute();
      //
      //                 Get.toNamed(
      //                   route,
      //                   arguments: {
      //                     ApiKeys.argGroceries: groceryController.dairyBakery,
      //                     ApiKeys.argSelectedGroceryData: groceryCategoryModel,
      //                   },
      //                 );
      //
      //               }
      //             ),
      //
      //             CollapsibleGridSection(
      //               title: "Mom & Baby Care",
      //               categories: groceryController.momBabyCare,
      //               onTap:(groceryCategoryModel){
      //                 final route = isOwnGrocery
      //                     ? RouteHelper.getGrocerySubCategoryScreenRoute()
      //                     : RouteHelper.getGroceryListingScreenRoute();
      //
      //                 Get.toNamed(
      //                   route,
      //                   arguments: {
      //                     ApiKeys.argGroceries: groceryController.momBabyCare,
      //                     ApiKeys.argSelectedGroceryData: groceryCategoryModel,
      //                   },
      //                 );
      //
      //               }
      //             ),
      //
      //             CollapsibleGridSection(
      //               title: "Kitchenware",
      //               categories: groceryController.kitchenware,
      //                 onTap:(groceryCategoryModel){
      //                   final route = isOwnGrocery
      //                       ? RouteHelper.getGrocerySubCategoryScreenRoute()
      //                       : RouteHelper.getGroceryListingScreenRoute();
      //
      //                   Get.toNamed(
      //                     route,
      //                     arguments: {
      //                       ApiKeys.argGroceries: groceryController.cookingEssentials,
      //                       ApiKeys.argSelectedGroceryData: groceryCategoryModel,
      //                     },
      //                   );
      //
      //                 }
      //             ),
      //
      //             CollapsibleGridSection(
      //               title: "Tableware",
      //               categories: groceryController.tableware,
      //               onTap:(groceryCategoryModel){
      //                 final route = isOwnGrocery
      //                     ? RouteHelper.getGrocerySubCategoryScreenRoute()
      //                     : RouteHelper.getGroceryListingScreenRoute();
      //
      //                 Get.toNamed(
      //                   route,
      //                   arguments: {
      //                     ApiKeys.argGroceries: groceryController.tableware,
      //                     ApiKeys.argSelectedGroceryData: groceryCategoryModel,
      //                   },
      //                 );
      //
      //               }
      //
      //             ),
      //
      //             CollapsibleGridSection(
      //               title: "Gifts & Hampers",
      //               categories: groceryController.giftsHampers,
      //                 onTap:(groceryCategoryModel){
      //                   final route = isOwnGrocery
      //                       ? RouteHelper.getGrocerySubCategoryScreenRoute()
      //                       : RouteHelper.getGroceryListingScreenRoute();
      //
      //                   Get.toNamed(
      //                     route,
      //                     arguments: {
      //                       ApiKeys.argGroceries: groceryController.giftsHampers,
      //                       ApiKeys.argSelectedGroceryData: groceryCategoryModel,
      //                     },
      //                   );
      //
      //                 }
      //             ),
      //
      //             CollapsibleGridSection(
      //               title: "Home",
      //               categories: groceryController.homeCategory,
      //               onTap:(groceryCategoryModel){
      //                 final route = isOwnGrocery
      //                     ? RouteHelper.getGrocerySubCategoryScreenRoute()
      //                     : RouteHelper.getGroceryListingScreenRoute();
      //
      //                 Get.toNamed(
      //                   route,
      //                   arguments: {
      //                     ApiKeys.argGroceries: groceryController.homeCategory,
      //                     ApiKeys.argSelectedGroceryData: groceryCategoryModel,
      //                   },
      //                 );
      //
      //                 }
      //             ),
      //
      //             const SizedBox(height: 40),
      //           ],
      //         ),
      //       ),
      //
      //       Center(child: CustomText(AppStrings.comingSoon)),
      //
      //       Center(child: CustomText(AppStrings.comingSoon))
      //
      //     ],
      //   ),
      // ),

    );
  }

}
