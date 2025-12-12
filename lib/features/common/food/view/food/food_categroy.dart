import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/food/controller/food_category_controller.dart';
import 'package:BlueEra/features/common/food/model/food_tab_model.dart';
import 'package:BlueEra/features/common/food/view/food/food_category_screen.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../../../core/constants/app_icon_assets.dart';

class FoodCategoryPage extends StatefulWidget {
  const FoodCategoryPage({super.key});

  @override
  State<FoodCategoryPage> createState() => _FoodCategoryPageState();
}

class _FoodCategoryPageState extends State<FoodCategoryPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  List<FoodModel> foodTabList = [
    FoodModel(slug_id: 'veg_tab', slug_type: 'Veg', title: 'Veg'),
    FoodModel(slug_id: 'non_veg_tab', slug_type: 'Non-Veg', title: 'Non-Veg'),
    FoodModel(
        slug_id: 'sweet_dairy_tab',
        slug_type: 'Sweets_Dairy',
        title: 'Sweets & Dairy'),
    FoodModel(slug_id: 'bakery_tab', slug_type: 'Bakery', title: 'Bakery'),
    FoodModel(slug_id: 'others_tab', slug_type: 'Others', title: 'Others'),
  ];
  final foodCategoryController = Get.put(FoodCategoryController());

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    foodCategoryController.getFoodCategoryById(
        tabName: foodTabList.firstOrNull?.slug_type ?? "Veg");
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Obx(() {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: SizeConfig.size10),
                /// Category TAB
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(width: SizeConfig.size10),
                      LocalAssets(imagePath: AppIconAssets.toggol_buttons),
                      HorizontalTabSelector(
                        horizontalMargin: SizeConfig.size8,
                        tabs: foodTabList.map((e) => e.title).toList(),
                        selectedIndex: foodCategoryController
                            .selectedFoodSubTabIndex.value,
                        onTabSelected: (index, value) {
                          foodCategoryController.onChangeFoodSubTab(index);
                          foodCategoryController.getFoodCategoryById(
                              tabName: foodTabList[index].slug_type);
                        },
                        labelBuilder: (label) => "$label",
                      ),
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.size16),
                /// Category Page
                CategoryGridPage(),
                SizedBox(height: SizeConfig.size40),
              ],
            ),
          ),
        );
      }),
    );
  }
}
