import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/food/controller/grocery_controller.dart';
import 'package:BlueEra/widgets/collapsible_grid_section.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_text_cm.dart';
import 'grocery_subcategory_screen.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> with SingleTickerProviderStateMixin {
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
                        Get.to(()=> GrocerySubCategoryScreen(
                            arrGroceries: groceryController.biscuitFoods,
                            selectedGroceryData: groceryCategoryModel
                        ));
                      }
                  ),

                  CollapsibleGridSection(
                    title: "Fruits & Vegetables",
                    categories: groceryController.fruitsVeg,
                    onTap:(groceryCategoryModel){
                        Get.to(()=> GrocerySubCategoryScreen(
                            arrGroceries: groceryController.fruitsVeg,
                            selectedGroceryData: groceryCategoryModel
                        ));
                    }
                  ),

                  CollapsibleGridSection(
                    title: "Cooking Essentials",
                    categories: groceryController.cookingEssentials,
                      onTap:(groceryCategoryModel){
                        Get.to(()=> GrocerySubCategoryScreen(
                            arrGroceries: groceryController.cookingEssentials,
                            selectedGroceryData: groceryCategoryModel
                        ));
                      }
                  ),

                  CollapsibleGridSection(
                    title: "Dairy & Bakery",
                    categories: groceryController.dairyBakery,
                    onTap:(groceryCategoryModel){
                        Get.to(()=> GrocerySubCategoryScreen(
                            arrGroceries: groceryController.dairyBakery,
                            selectedGroceryData: groceryCategoryModel
                        ));
                    }
                  ),

                  CollapsibleGridSection(
                    title: "Mom & Baby Care",
                    categories: groceryController.momBabyCare,
                    onTap:(groceryCategoryModel){
                        Get.to(()=> GrocerySubCategoryScreen(
                            arrGroceries: groceryController.momBabyCare,
                            selectedGroceryData: groceryCategoryModel
                        ));
                    }
                  ),

                  CollapsibleGridSection(
                    title: "Kitchenware",
                    categories: groceryController.kitchenware,
                      onTap:(groceryCategoryModel){
                        Get.to(()=> GrocerySubCategoryScreen(
                            arrGroceries: groceryController.cookingEssentials,
                            selectedGroceryData: groceryCategoryModel
                        ));
                      }
                  ),

                  CollapsibleGridSection(
                    title: "Tableware",
                    categories: groceryController.tableware,
                    onTap:(groceryCategoryModel){
                        Get.to(()=> GrocerySubCategoryScreen(
                            arrGroceries: groceryController.tableware,
                            selectedGroceryData: groceryCategoryModel
                        ));
                    }

                  ),

                  CollapsibleGridSection(
                    title: "Gifts & Hampers",
                    categories: groceryController.giftsHampers,
                      onTap:(groceryCategoryModel){
                        Get.to(()=> GrocerySubCategoryScreen(
                            arrGroceries: groceryController.giftsHampers,
                            selectedGroceryData: groceryCategoryModel
                        ));
                      }
                  ),

                  CollapsibleGridSection(
                    title: "Home",
                    categories: groceryController.homeCategory,
                    onTap:(groceryCategoryModel){
                        Get.to(()=> GrocerySubCategoryScreen(
                            arrGroceries: groceryController.homeCategory,
                            selectedGroceryData: groceryCategoryModel
                        ));
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
