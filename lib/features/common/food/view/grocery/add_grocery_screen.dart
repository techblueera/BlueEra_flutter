import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/food/controller/grocery_controller.dart';
import 'package:BlueEra/features/common/food/view/grocery/cooking_esential_page.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddGroceryScreen extends StatefulWidget {
  const AddGroceryScreen({super.key});

  @override
  State<AddGroceryScreen> createState() => _AddGroceryScreenState();
}

class _AddGroceryScreenState extends State<AddGroceryScreen> {
  final controller = getOrPut(() => GroceryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonBackAppBar(),
      bottomNavigationBar: Material(
        elevation: 8.0,
        child: Container(
          color: AppColors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size15, vertical: SizeConfig.size15),
            child: SafeArea(
              child: CustomBtn(
                onTap: () => showEditProductBottomSheet(context),
                isValidate: true,
                radius: SizeConfig.size8,
                title: 'Post ${controller.selectedGroceries.length} Products',
                // isLoading: authController.isAddBusinessUserLoading.value
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
          vertical: SizeConfig.size20,
        ),
        child: Obx(() => GridView.builder(
              itemCount: controller.selectedGroceries.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.86,
              ),
              itemBuilder: (_, i) =>
                  groceryCard(controller.selectedGroceries[i], i),
            )),
      ),
    );
  }

  Widget groceryCard(GroceryModel p, int index) {
    return Container(
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
                height: SizeConfig.size150,
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
                  top: SizeConfig.size2,
                  right: SizeConfig.size2,
                  child: _groceryPopUpMenu(index))
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
                  fontSize: SizeConfig.small,
                  maxLines: 2,
                  color: AppColors.mainTextColor,
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
    );
  }

  Widget _groceryPopUpMenu(int i) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(-6, 36),
      color: AppColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) async {
        if (value == AppConstants.EDIT) {
          Get.back(result: true);
        } else if (value == AppConstants.REMOVE) {
          controller.selectedGroceries.removeAt(i);
          if (controller.selectedGroceries.length == 0) {
            Get.back(result: true);
          }
        }
      },
      icon: Container(
        padding: EdgeInsets.all(6),
        decoration:
            BoxDecoration(color: AppColors.blackMite, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(
          Icons.more_vert,
          size: SizeConfig.size12,
          color: AppColors.white,
        ),
      ),
      itemBuilder: (context) => groceryPopupMenuItems(),
    );
  }

  void showEditProductBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CommonDraggableBottomSheet(
          initialChildSize: 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          backgroundColor: AppColors.whiteF1,
          boxShadow: [
            BoxShadow(
                color: AppColors.black.withValues(alpha: 0.1),
                blurRadius: 4.0,
                offset: Offset(0, -3))
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          padding: EdgeInsets.only(
              top: SizeConfig.size10,
              bottom: kToolbarHeight),
          builder: (scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  /// --- Top Drag Handle ---
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: EdgeInsets.only(bottom: SizeConfig.size5),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryTextColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            "Edit Product",
                            fontSize: SizeConfig.medium,
                            color: AppColors.mainTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: SizeConfig.size8),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: Icon(
                            Icons.close,
                            size: SizeConfig.size20,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.size10),
                  ListView.separated(
                    // controller: scrollController,
                    itemCount: controller.selectedGroceries.length,
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.only(
                        bottom: SizeConfig.size12
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final groceryItem = controller.selectedGroceries[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// --- Image Carousel (Horizontal) ---
                            Container(
                              padding: EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10.0)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 80,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemBuilder: (_, index) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: LocalAssets(
                                            imagePath: groceryItem.image,
                                            width: 80,
                                            height: 80,
                                            boxFix: BoxFit.cover,
                                          ),
                                        );
                                      },
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 10),
                                      itemCount: 4,
                                    ),
                                  ),

                                  SizedBox(height: SizeConfig.size10),

                                  /// --- Product Title ---
                                  CustomText(
                                    groceryItem.name,
                                    fontSize: SizeConfig.medium,
                                    color: AppColors.mainTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),

                                  SizedBox(height: SizeConfig.size8),

                                  /// --- Price Row ---
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(4.0),
                                        decoration: BoxDecoration(
                                            color: AppColors.white,
                                            borderRadius:
                                                BorderRadius.circular(4.0),
                                            border: Border.all(
                                                color: AppColors.greyE5,
                                                width: 0.5)),
                                        child: CustomText(
                                          groceryItem.weight,
                                          fontSize: SizeConfig.small,
                                          color: AppColors.secondaryTextColor,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      SizedBox(width: SizeConfig.size10),
                                      CustomText(
                                        "₹${groceryItem.price}",
                                        fontSize: SizeConfig.medium,
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      SizedBox(width: SizeConfig.size8),
                                      CustomText(
                                        "₹${groceryItem.oldPrice}",
                                        fontSize: SizeConfig.small,
                                        color: AppColors.secondaryTextColor,
                                        fontWeight: FontWeight.w400,
                                        decoration: TextDecoration.lineThrough,
                                        decorationColor:
                                            AppColors.secondaryTextColor,
                                      ),
                                      SizedBox(width: SizeConfig.size8),
                                      CustomText(groceryItem.discount,
                                          fontSize: SizeConfig.small,
                                          color: AppColors.greenShade,
                                          fontWeight: FontWeight.w400),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: SizeConfig.size16),

                            /// --- Original MRP ---
                            CustomText(
                              "Original MRP",
                              fontSize: SizeConfig.medium,
                              color: AppColors.mainTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                            SizedBox(height: SizeConfig.size10),
                            Row(
                              children: [
                                Expanded(
                                  child: _TextFieldBox(
                                      title: 'Unit', hint: "E.g. 100G"),
                                ),
                                SizedBox(width: SizeConfig.size8),
                                Expanded(
                                  child: _TextFieldBox(
                                      title: 'Price', hint: "E.g. ₹1,999"),
                                ),
                              ],
                            ),

                            SizedBox(height: SizeConfig.size16),

                            /// --- Selling Price ---
                            CustomText(
                              "What Is Your Selling price",
                              fontSize: SizeConfig.medium,
                              color: AppColors.mainTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                            SizedBox(height: SizeConfig.size10),
                            Row(
                              children: [
                                Expanded(
                                  child: _TextFieldBox(
                                      title: 'Unit', hint: "E.g. 100G"),
                                ),
                                SizedBox(width: SizeConfig.size8),
                                Expanded(
                                  child: _TextFieldBox(
                                      title: 'Selling Price',
                                      hint: "E.g. ₹1,999"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: SizeConfig.size15),
                          child:
                              index != controller.selectedGroceries.length - 1
                                  ? CommonHorizontalDivider(
                                      color: AppColors.shadowColor,
                                    )
                                  : SizedBox());
                    },
                  ),

                  SizedBox(height: SizeConfig.size20),

                  /// --- Update Button ---
                  CustomBtn(onTap: () {},
                      title: "Update",
                      bgColor: AppColors.primaryColor,
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _TextFieldBox({required String title, required String hint}) {
    return CommonTextField(
      textEditController: TextEditingController(),
      title: title,
      hintText: hint,
    );
  }
}
