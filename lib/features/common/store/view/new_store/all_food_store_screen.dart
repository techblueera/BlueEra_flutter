import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/food/model/get_food_details_model.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/common/store/view/store_food_service_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class AllFoodStoreScreen extends StatefulWidget {
  final bool isShowInGrid;
  const AllFoodStoreScreen({
    super.key,
    required this.isShowInGrid
  });

  @override
  State<AllFoodStoreScreen> createState() => _AllFoodStoreScreenState();
}

class _AllFoodStoreScreenState extends State<AllFoodStoreScreen> {
  final controller = Get.isRegistered<NewStoreController>()
      ? Get.find<NewStoreController>()
      : Get.put(NewStoreController());
  final ScrollController storesScrollController = ScrollController();


  @override
  void initState() {

    controller.getAllFoodServiceNearBy();
    super.initState();

    storesScrollController.addListener(() {
      if (storesScrollController.position.pixels >=
          storesScrollController.position.maxScrollExtent - 200) {
        controller.getAllFoodServiceNearBy(isLoadMore: true);
      }
    });
  }

  @override
  void dispose() {
    storesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = SizeConfig.screenWidth;

    double dynamicSize(double base) =>
        base * (width / 390);

    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Food',
      ),

      body: SafeArea(
        child: Obx(() {
          // First time loading
          if (controller.isFoodDataFirstLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final foodList = List<GetFoodDetailsModel>.from(controller.foodDataList);

          // Empty state
          if (foodList.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CustomText("Not found any food item."),
              ),
            );
          }


          return  widget.isShowInGrid
              ? Padding(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size8,
                vertical: SizeConfig.size8
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = 2;
                final crossSpacing = 10.0;
                final mainSpacing = 15.0;

                final childAspectRatio = 0.73; // Adjust as needed

                return GridView.builder(
                  controller: storesScrollController,
                  padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size8,
                      vertical: SizeConfig.size10
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: crossSpacing,
                    mainAxisSpacing: mainSpacing,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: foodList.length +
                      (controller.isFoodDataLoadingMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= foodList.length) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final foodItem = foodList[index];

                    return StoreFoodServiceCard(
                      foodDetailsData: foodItem,
                      isShowInGrid: widget.isShowInGrid,
                    );
                  },
                );
              },
            ),
          ) : ListView.builder(
            controller: storesScrollController,
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size8,
                vertical: SizeConfig.size8
            ),
            itemCount: foodList.length +
                (controller.isFoodDataLoadingMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              // Pagination Loader
              if (index >= foodList.length) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final foodItem = foodList[index];

              return Padding(
                padding: EdgeInsets.only(bottom: dynamicSize(10)),
                child: StoreFoodServiceCard(
                  foodDetailsData: foodItem,
                  isShowInGrid: widget.isShowInGrid,
                ),
              );
            },
          );
        }),
      ),
    );
  }

}
