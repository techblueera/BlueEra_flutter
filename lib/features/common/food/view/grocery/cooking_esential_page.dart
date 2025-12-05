import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/food/controller/grocery_controller.dart';
import 'package:BlueEra/features/common/food/view/grocery/add_grocery_screen.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/local_assets.dart';
import '../../../../../widgets/common_back_app_bar.dart';

class GroceryModel {
  final String name;
  final String image;
  final String weight;
  final int price;
  final int oldPrice;
  final String discount;

  GroceryModel({
    required this.name,
    required this.image,
    required this.weight,
    required this.price,
    required this.oldPrice,
    required this.discount,
  });
}

class CookingEssentialsPage extends StatefulWidget {
  const CookingEssentialsPage({super.key});

  @override
  State<CookingEssentialsPage> createState() => _CookingEssentialsPageState();
}

class _CookingEssentialsPageState extends State<CookingEssentialsPage> {
  final controller = getOrPut(() => GroceryController());

  @override
  Widget build(BuildContext context) {
    String currentCategory = controller.categories[controller.selectedIndex.value];
    List<String> tabs = controller.categoryTabs[currentCategory]!;
    List<GroceryModel> groceries = controller. categoryProducts[currentCategory]!;

    return Obx((()=> Scaffold(
      appBar: const CommonBackAppBar(
        title: "Cooking Essentials",
        isShadowShow: false,
        isGrocery: true,
      ),
      bottomNavigationBar: controller.selectedGroceries.isEmpty
          ? null
          : Material(
        elevation: 8.0,
        child: Container(
          color: AppColors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size15,
                vertical: SizeConfig.size15),
            child: SafeArea(
              child: CustomBtn(
                onTap: () async {
                  Get.to(()=> AddGroceryScreen());
                },
                isValidate: true,
                radius: SizeConfig.size8,
                title: AppStrings.next,
                // isLoading: authController.isAddBusinessUserLoading.value
              ),
            ),
          ),
        ),
      ),
      body: Row(
        children: [
          leftCategoryList(),
          Expanded(child: rightContent(tabs, groceries)),
        ],
       ),
      )
     )
    );
  }

  Widget leftCategoryList() {
    return Container(
      width: 94,
      color: AppColors.white,
      child: ListView.builder(
        itemCount: controller.categories.length,
        itemBuilder: (context, index) {
          return _categoryItem(
            controller.leftIcons[index],
            controller.categories[index],
            selected: controller.selectedIndex.value == index,
            onTap: () {
                controller.selectedIndex.value = index;
                controller.selectedTabIndex.value = 0;
            },
          );
        },
      ),
    );
  }

  Widget _categoryItem(String icon, String label,
      {bool selected = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: selected ? 11 : 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.skyBlueE4,
                AppColors.skyBlueE4.withValues(alpha: 0.3),
              ],
            ),
            border: selected
                ? const Border(
                    left: BorderSide(
                        color: AppColors.primaryColor,
                        width: 3,
                        style: BorderStyle.solid))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? null : AppColors.skyBlueE4),
                  padding: EdgeInsets.all(selected ? 0 : 6),
                  child: LocalAssets(
                    imagePath: icon,
                    // boxFix: BoxFit.cover,
                    height: 40,
                    width: 40,
                  )),
              const SizedBox(height: 6),
              CustomText(
                label,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.black : AppColors.grayText,
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget rightContent(List<String> tabs, List<GroceryModel> products) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Max Limit Error
          if (controller.isMaxLimitHit)
            Container(
              width: SizeConfig.screenWidth,
              decoration: BoxDecoration(
                color: AppColors.redBE,
                borderRadius: BorderRadius.circular(10.0)
              ),
              margin: EdgeInsets.only(bottom: SizeConfig.size10),
              padding: EdgeInsets.symmetric(
                vertical: SizeConfig.size4,
                horizontal: SizeConfig.size10
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    LocalAssets(
                      imagePath: AppIconAssets.warningOutlineIcon,
                      width: SizeConfig.size20,
                      height: SizeConfig.size20
                    ),
                    SizedBox(width: SizeConfig.size8),
                    CustomText(
                      'You can’t select more than ${controller.maxLimit} products at a time.',
                      color: AppColors.redLite,
                      fontSize: SizeConfig.extraSmall,
                      fontWeight: FontWeight.w400,
                    ),
                  ],
                ),
              ),
            ),


          // TABS
          SizedBox(
            height: 28,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (_, i) {
                bool selected = controller.selectedTabIndex.value == i;
                return InkWell(
                  onTap: () {
                      controller.selectedTabIndex.value = i;
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: i == 0 ? 0 : 3,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          selected ? AppColors.primaryColor : AppColors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: selected
                          ? null
                          : Border.all(color: AppColors.greyLite, width: 0.5),
                    ),
                    child: Center(
                      child: CustomText(
                        tabs[i],
                        color: selected
                            ? AppColors.white
                            : AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 8),

          // GRID
          Expanded(
            child: GridView.builder(
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.692,
              ),
              itemBuilder: (_, i) => groceryCard(products[i]),
            ),
          )
        ],
      ),
    );
  }

  Widget groceryCard(GroceryModel p) {
    final bool isSelected = controller.selectedGroceries.contains(p);

    return GestureDetector(
      onTap: () => controller.toggleSelection(p),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.white,
                      image: DecorationImage(
                          image: AssetImage(
                            p.image,
                          ),
                          fit: BoxFit.cover)),
                ),
                Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryColor
                              : AppColors.blackMite,
                          borderRadius: BorderRadius.circular(20)),
                      child: Center(
                        child: Container(
                          height: SizeConfig.size12,
                          width: SizeConfig.size12,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              border:
                                  Border.all(width: 1, color: AppColors.white)),
                         alignment: Alignment.center,
                          child: isSelected ? Icon(
                            Icons.check,
                            size: SizeConfig.size10,
                            color: AppColors.white,
                          ) : null,
                        ),
                      ),
                    ))
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 9.0, vertical: SizeConfig.size6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "${p.name}",
                    fontSize: 10,
                    maxLines: 2,
                    color: Colors.black,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: SizeConfig.size6),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            border:
                                Border.all(color: AppColors.green00, width: 1),
                            borderRadius: BorderRadius.circular(2)),
                        padding: EdgeInsets.all(3.5),
                        child: Container(
                          height: 7,
                          width: 7,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              color: AppColors.green00),
                        ),
                      ),
                      SizedBox(width: SizeConfig.size6),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border:
                                Border.all(width: 0.5, color: AppColors.greyE5)),
                        padding:
                            EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                        child: CustomText(
                          p.weight,
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size6),
                  Row(
                    children: [
                      CustomText(
                        "₹${p.price.toString()}",
                        fontSize: 10,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(width: 4),
                      CustomText(
                        "₹${p.oldPrice.toString()}",
                        fontSize: 10,
                        color: AppColors.grayText,
                      ),
                      SizedBox(width: 4),
                      CustomText(
                        "${p.discount} Off",
                        fontSize: 10,
                        color: AppColors.green00,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
