import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/food/controller/grocery_controller.dart';
import 'package:BlueEra/widgets/collapsible_grid_section.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_text_cm.dart';

class GroceryCategoryScreen extends StatefulWidget {
  const GroceryCategoryScreen({super.key});

  @override
  State<GroceryCategoryScreen> createState() => _GroceryCategoryScreenState();
}

class _GroceryCategoryScreenState extends State<GroceryCategoryScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController searchController = TextEditingController();
  final List<Tab> _tabs = [
    Tab(text: 'Grocery & Veg'),
    Tab(text: 'Home Essential'),
    Tab(text: 'Others')
  ];
  final groceryController = getOrPut(() => GroceryController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 50),
        child: CommonBackAppBar(
          bottomWidget: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue,
            indicatorWeight: 2,
            labelStyle: TextStyle(fontWeight: FontWeight.w600),
            tabs: _tabs,
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [

            SingleChildScrollView(
              child: Column(
                children: [

                  CollapsibleGridSection(
                    title: "Biscuits, Drinks & Packaged Foods",
                    categories: groceryController.biscuitFoods,
                      onTap:(groceryCategoryModel){
                        Get.toNamed(RouteHelper.getGrocerySubCategoryScreenRoute(),
                            arguments: {
                              ApiKeys.argGroceries: groceryController.biscuitFoods,
                              ApiKeys.argSelectedGroceryData: groceryCategoryModel
                            },
                        );
                      }
                  ),

                  CollapsibleGridSection(
                    title: "Fruits & Vegetables",
                    categories: groceryController.fruitsVeg,
                    onTap:(groceryCategoryModel){
                      Get.toNamed(RouteHelper.getGrocerySubCategoryScreenRoute(),
                        arguments: {
                          ApiKeys.argGroceries: groceryController.fruitsVeg,
                          ApiKeys.argSelectedGroceryData: groceryCategoryModel
                        },
                      );
                    }
                  ),

                  CollapsibleGridSection(
                    title: "Cooking Essentials",
                    categories: groceryController.cookingEssentials,
                      onTap:(groceryCategoryModel){
                        Get.toNamed(RouteHelper.getGrocerySubCategoryScreenRoute(),
                          arguments: {
                            ApiKeys.argGroceries: groceryController.cookingEssentials,
                            ApiKeys.argSelectedGroceryData: groceryCategoryModel
                          },
                        );
                      }
                  ),

                  CollapsibleGridSection(
                    title: "Dairy & Bakery",
                    categories: groceryController.dairyBakery,
                    onTap:(groceryCategoryModel){
                      Get.toNamed(RouteHelper.getGrocerySubCategoryScreenRoute(),
                        arguments: {
                          ApiKeys.argGroceries: groceryController.dairyBakery,
                          ApiKeys.argSelectedGroceryData: groceryCategoryModel
                        },
                      );

                    }
                  ),

                  CollapsibleGridSection(
                    title: "Mom & Baby Care",
                    categories: groceryController.momBabyCare,
                    onTap:(groceryCategoryModel){
                      Get.toNamed(RouteHelper.getGrocerySubCategoryScreenRoute(),
                        arguments: {
                          ApiKeys.argGroceries: groceryController.momBabyCare,
                          ApiKeys.argSelectedGroceryData: groceryCategoryModel
                        },
                      );
                    }
                  ),

                  CollapsibleGridSection(
                    title: "Kitchenware",
                    categories: groceryController.kitchenware,
                      onTap:(groceryCategoryModel){
                        Get.toNamed(RouteHelper.getGrocerySubCategoryScreenRoute(),
                          arguments: {
                            ApiKeys.argGroceries: groceryController.cookingEssentials,
                            ApiKeys.argSelectedGroceryData: groceryCategoryModel
                          },
                        );
                      }
                  ),

                  CollapsibleGridSection(
                    title: "Tableware",
                    categories: groceryController.tableware,
                    onTap:(groceryCategoryModel){
                      Get.toNamed(RouteHelper.getGrocerySubCategoryScreenRoute(),
                        arguments: {
                          ApiKeys.argGroceries: groceryController.tableware,
                          ApiKeys.argSelectedGroceryData: groceryCategoryModel
                        },
                      );
                    }

                  ),

                  CollapsibleGridSection(
                    title: "Gifts & Hampers",
                    categories: groceryController.giftsHampers,
                      onTap:(groceryCategoryModel){
                        Get.toNamed(RouteHelper.getGrocerySubCategoryScreenRoute(),
                          arguments: {
                            ApiKeys.argGroceries: groceryController.giftsHampers,
                            ApiKeys.argSelectedGroceryData: groceryCategoryModel
                          },
                        );
                      }
                  ),

                  CollapsibleGridSection(
                    title: "Home",
                    categories: groceryController.homeCategory,
                    onTap:(groceryCategoryModel){
                      Get.toNamed(RouteHelper.getGrocerySubCategoryScreenRoute(),
                        arguments: {
                          ApiKeys.argGroceries: groceryController.homeCategory,
                          ApiKeys.argSelectedGroceryData: groceryCategoryModel
                        },
                      );
                      }
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),

            Center(child: CustomText(AppStrings.comingSoon)),

            Center(child: CustomText(AppStrings.comingSoon))

          ],
        ),
      ),
    );
  }

}
