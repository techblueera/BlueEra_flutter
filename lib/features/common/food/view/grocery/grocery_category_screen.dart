import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/food/controller/grocery_controller.dart';
import 'package:BlueEra/features/common/food/model/grocery_category_model.dart';
import 'package:BlueEra/features/common/store/widget/icon_grid_item.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/controller/earn_with_blueera_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_text_cm.dart';
import 'baby_care.dart';
import 'grocery_subcategory_screen.dart';
import 'diary.dart';
import 'fruits_veg.dart';

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

                  _sectionWidget(
                    "Biscuits, Drinks & Packaged Foods",
                    arrCategory: groceryController.biscuitFoods,
                    context: context,
                      onTap:(groceryCategoryModel){
                        Get.to(()=> GrocerySubCategoryScreen(
                            arrGroceries: groceryController.biscuitFoods,
                            selectedGroceryData: groceryCategoryModel
                        ));
                      }
                  ),

                  _sectionWidget(
                    "Fruits & Vegetables",
                    arrCategory: groceryController.fruitsVeg,
                    context: context,
                    onTap:(groceryCategoryModel){
                        Get.to(()=> GrocerySubCategoryScreen(
                            arrGroceries: groceryController.fruitsVeg,
                            selectedGroceryData: groceryCategoryModel
                        ));
                    }
                  ),

                  _sectionWidget(
                    "Cooking Essentials",
                    arrCategory: groceryController.cookingEssentials,
                    context: context,
                      onTap:(groceryCategoryModel){
                        Get.to(()=> GrocerySubCategoryScreen(
                            arrGroceries: groceryController.cookingEssentials,
                            selectedGroceryData: groceryCategoryModel
                        ));
                      }
                  ),

                  _sectionWidget(
                    "Dairy & Bakery",
                    arrCategory: groceryController.dairyBakery,
                    context: context,
                    onTap:(groceryCategoryModel){
                        Get.to(()=> GrocerySubCategoryScreen(
                            arrGroceries: groceryController.dairyBakery,
                            selectedGroceryData: groceryCategoryModel
                        ));
                    }
                  ),

                  _sectionWidget(
                    "Mom & Baby Care",
                    arrCategory: groceryController.momBabyCare,
                    context: context,
                    onTap:(groceryCategoryModel){
                        Get.to(()=> GrocerySubCategoryScreen(
                            arrGroceries: groceryController.momBabyCare,
                            selectedGroceryData: groceryCategoryModel
                        ));
                    }
                  ),

                  _sectionWidget(
                    "Kitchenware",
                    arrCategory: groceryController.kitchenware,
                    context: context,
                      onTap:(groceryCategoryModel){
                        Get.to(()=> GrocerySubCategoryScreen(
                            arrGroceries: groceryController.cookingEssentials,
                            selectedGroceryData: groceryCategoryModel
                        ));
                      }
                  ),

                  _sectionWidget(
                    "Tableware",
                    arrCategory: groceryController.tableware,
                    context: context,
                    onTap:(groceryCategoryModel){
                        Get.to(()=> GrocerySubCategoryScreen(
                            arrGroceries: groceryController.tableware,
                            selectedGroceryData: groceryCategoryModel
                        ));
                    }

                  ),

                  _sectionWidget(
                    "Gifts & Hampers",
                    arrCategory: groceryController.giftsHampers,
                    context: context,
                      onTap:(groceryCategoryModel){
                        Get.to(()=> GrocerySubCategoryScreen(
                            arrGroceries: groceryController.giftsHampers,
                            selectedGroceryData: groceryCategoryModel
                        ));
                      }
                  ),

                  _sectionWidget(
                    "Home",
                    arrCategory: groceryController.homeCategory,
                    context: context,
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

  Widget _sectionWidget(
      String title, {
        required List<GroceryCategoryModel> arrCategory,
        required BuildContext context,
        void Function(GroceryCategoryModel item)? onTap,
      }) {
    const int crossAxisCount = 4;
    const double mainAxisSpacing = 16.0;

    final firstEight = arrCategory.take(8).toList();
    final remaining = arrCategory.skip(8).toList();
    final bool hasMore = remaining.isNotEmpty;

    final isExpanded = false.obs;

    // list → rows-of-4
    List<Widget> _buildRows(List<GroceryCategoryModel> source) {
      final rows = <List<GroceryCategoryModel>>[];
      for (int i = 0; i < source.length; i += crossAxisCount) {
        rows.add(
          source.sublist(i, (i + crossAxisCount).clamp(0, source.length)),
        );
      }

      return rows.map((rowItems) {
        return Padding(
          padding: const EdgeInsets.only(bottom: mainAxisSpacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(crossAxisCount * 2 - 1, (i) {
              if (i.isEven) {
                final index = i ~/ 2;
                if (index < rowItems.length) {
                  final item = rowItems[index];
                  return Expanded(
                    child: IconGridItem(
                      label: item.label ?? '',
                      icon: 'assets/category/${item.icon}',
                      onTap: () => onTap?.call(item),
                    ),
                  );
                }
              }
              return const Expanded(child: SizedBox());
            }),
          ),
        );
      }).toList();
    }

    return Obx(() {
      final visibleList = isExpanded.value ? arrCategory : firstEight;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomText(
                  title,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                const Spacer(),
                if (hasMore)
                  InkWell(
                    onTap: () => isExpanded.toggle(),
                    child: CustomText(
                      isExpanded.value ? 'See Less'.tr : 'See More'.tr,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            /* grid */
            Column(children: _buildRows(visibleList)),
          ],
        ),
      );
    });
  }

  // Widget _iconItem(String img, String label) {
  //   return SizedBox(
  //     width: SizeConfig.size80,
  //     child: Column(
  //
  //       children: [
  //         Container(
  //
  //           padding:  EdgeInsets.all(SizeConfig.size6),
  //           decoration: BoxDecoration(
  //             color: AppColors.lightBlue,
  //             shape: BoxShape.circle,
  //           ),
  //           child: Image.asset(
  //             "assets/category/$img",
  //             height: SizeConfig.size40,
  //             width: SizeConfig.size40,
  //             fit: BoxFit.contain,
  //           ),
  //         ),
  //          SizedBox(height: SizeConfig.size6),
  //         CustomText(
  //           label,
  //           fontSize: 10,
  //           fontWeight: FontWeight.w600,
  //           color: AppColors.secondaryTextColor,
  //           textAlign: TextAlign.center,
  //
  //
  //         ),
  //
  //       ],
  //     ),
  //   );
  // }
}
