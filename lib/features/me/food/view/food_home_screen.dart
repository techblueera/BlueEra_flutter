import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/food/controller/home_food_controller.dart';
import 'package:BlueEra/features/me/food/model/food_home_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/food_home_profile_header.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class RestaurantHomeScreen extends StatelessWidget {
  final controller = Get.put(RestaurantController());
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.appBackgroundColor,
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = controller.restaurantData.value;
        if (data == null)
          return const Center(child: CustomText("No Data Found"));

        return RefreshIndicator(
          onRefresh: () async{
            controller.fetchHomeData();
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ///FOOD HOTEL....
                CommonCardWidget(
                  cardMargin: 10,
                  padding: 0,
                  child: FoodHomeProfileHeader(
                    details: viewBusinessDetailsController
                        .businessProfileDetails?.data,
                    controller: viewBusinessDetailsController,
                  ),
                ),

                ///Food Selection (Horizontal List)
                if (controller.allFoodItems.isNotEmpty)
                  CommonCardWidget(
                    cardMargin: 10,
                    padding: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 10,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 15.0),
                          child: CustomText("Food Selection",
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        _buildHorizontalFoodList(),
                      ],
                    ),
                  ),

                ///FOOD MENU...
                if (data.foodMenu?.isNotEmpty ?? false)
                  CommonCardWidget(
                    cardMargin: 10,
                    padding: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 10,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 15.0),
                          child: CustomText("Our Menu",
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        _buildMenuCategories(data.foodMenu ?? []),
                      ],
                    ),
                  ),
                SizedBox(
                  height: 100,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHorizontalFoodList() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.allFoodItems.length,
        itemBuilder: (context, index) {
          final item = controller.allFoodItems[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.product?.images?.firstOrNull ?? "",
                    height: 120,
                    width: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.secondaryTextColor)),
                          height: 120,
                          width: 160,
                          child: const Icon(Icons.fastfood)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CustomText(
                  item.product?.name ?? "",
                  fontWeight: FontWeight.bold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                CustomText(
                    "${item.price?.currency} ${item.price?.sellingPrice}",
                    fontWeight: FontWeight.w500),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuCategories(List<FoodMenu> menus) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final category = menus[index];
        return Container(
          height: 160,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: AssetImage('assets/category/foods/${category.key}.png'),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
