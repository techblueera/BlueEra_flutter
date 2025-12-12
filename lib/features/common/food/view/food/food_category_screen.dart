import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/food/controller/food_category_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryGridPage extends StatelessWidget {
  final controller = Get.find<FoodCategoryController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.getFoodCategoryResponse.value.status == Status.ERROR) {
        return Center(child: CustomText(AppStrings.somethingWentWrong));
      }
      if (controller.foodCategoryDataList.isEmpty) {
        return Center(child: CustomText(AppStrings.noDataFound));
      }
      if (controller.foodCategoryDataList.isNotEmpty) {
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: controller.foodCategoryDataList.length,
          itemBuilder: (context, index) {
            final category = controller.foodCategoryDataList[index];
            if (category.children?.isNotEmpty ?? false) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- HEADER ----------
                  CustomText(
                    category.name ?? "",
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 12),

                  // ---------- GRID ----------
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: category.children?.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, childIndex) {
                      final item = category.children?[childIndex];

                      return Column(
                        children: [
                          // IMAGE circle
                          Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              color: const Color(0xffEAF2FF),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(
                             // "assets/category/foods/all_food_category/CORNFLAKES.png",
                             "assets/category/foods/all_food_category/${item?.key}.png",
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.fastfood),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // TITLE
                          CustomText(
                            item?.name ?? "",
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                ],
              );
            }
            return SizedBox.shrink();
          },
        );
      }
      return SizedBox();
    });
  }
}
