import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/features/common/food/view/food/sweetanddairy_tab.dart';
import 'package:BlueEra/features/common/food/view/food/veg_tab.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../controller/food_upload_controller.dart';
import 'bakery_tab.dart';
import 'non_veg_tab.dart';
import 'others_tab.dart';

class FoodCategoryPage extends StatefulWidget {
  const FoodCategoryPage({super.key});

  @override
  State<FoodCategoryPage> createState() => _FoodCategoryPageState();
}

class _FoodCategoryPageState extends State<FoodCategoryPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  final controller = Get.isRegistered<FoodUploadController>()
      ? Get.find<FoodUploadController>()
      : Get.put(FoodUploadController());

  @override
  void initState() {
    // TODO: implement initState
    tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: 0,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(

        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 14),

                TabBar(
                  labelPadding: EdgeInsets.symmetric(
                      horizontal: 0, vertical: 0),
                  controller: tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: Colors.lightBlue,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabAlignment: TabAlignment.fill,
                  indicator: UnderlineTabIndicator(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(style: BorderStyle.solid,
                        width: 4,
                        color: Colors.lightBlue),
                    insets: EdgeInsets.symmetric(
                        horizontal: 2), // wider underline
                  ),
                  tabs: const [
                    Tab(text: "Foods"),
                    Tab(text: "Services"),
                    Tab(text: "Others"),
                  ],
                ),

                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      LocalAssets(imagePath: AppIconAssets.toggol_buttons),
                      HorizontalTabSelector(horizontalMargin: 8,
                        tabs: [
                          'Veg',
                          'Non-Veg',
                          'Sweet & Dairy',
                          'Bakery',
                          'Others',
                        ],
                        selectedIndex: controller.selectedFoodSubTabIndex.value,
                        onTabSelected: (index, value) {
                          controller.onChangeFoodSubTab(index);
                        },
                        labelBuilder: (label) => "$label",
                      ),
                    ],
                  ),
                ),
                if(controller.selectedFoodSubTabIndex.value==0)
                VegCategoryPage()
                else if(controller.selectedFoodSubTabIndex.value==1)
                  NonVegCategoryPage()
                else if(controller.selectedFoodSubTabIndex.value==2)
                    SweetAndBakeCategoryPage()
                  else if(controller.selectedFoodSubTabIndex.value==3)
                  BakeryCategoryPage()
                else
                  OthersTab(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
    });
  }

}

