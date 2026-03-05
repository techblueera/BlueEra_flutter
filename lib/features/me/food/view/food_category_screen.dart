import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/view/grocery_product_selection_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Ensure you add this to pubspec.yaml

class FoodCategoryMenuScreen extends StatefulWidget {
  const FoodCategoryMenuScreen({super.key});

  @override
  State<FoodCategoryMenuScreen> createState() => _FoodCategoryMenuScreenState();
}

class _FoodCategoryMenuScreenState extends State<FoodCategoryMenuScreen> {
  // List mapped to your specific local assets
  final foodServiceController = Get.put(FoodServiceController());

  @override
  void initState() {
    // TODO: implement initState
    foodServiceController.getFoodCategoryController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (foodServiceController.getFoodCategoryResponse.value.status ==
              Status.COMPLETE) {
            if (foodServiceController.foodSubCateList.isNotEmpty) {
              return Padding(
                padding: EdgeInsets.only(bottom: 80.0),
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: foodServiceController.foodSubCateList.length,
                  itemBuilder: (context, index) {
                    final item = foodServiceController.foodSubCateList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: LocalAssets(
                            imagePath:
                                "${AppConstants.baseFoodAssetsPath}${item.key ?? " "}.svg",
                            width: 30,
                            height: 30,
                          ),
                          title: CustomText(
                            item.name,
                            fontSize: 15,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w400,
                          ),
                          onTap: () {
                            foodServiceController.selectedFoodTypeID.value =
                                item.id ?? "";
                            // Action for item tap
                            Get.to(ProductSelectionScreen(
                              foodCategoryData: item,
                            ));
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            } else {
              return Center(child: CustomText(AppStrings.noDataFound));
            }
          } else if (foodServiceController.getFoodCategoryResponse.value ==
              Status.ERROR) {
            return Center(child: CustomText(AppStrings.somethingWentWrong));
          }
          return SizedBox();
        }),
      ),
    );
  }
}
