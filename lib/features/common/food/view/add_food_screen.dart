import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/view/earn_with_blueera_new_screen.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:get/get.dart';
import '../../../../widgets/common_card_widget.dart';
import '../../auth/views/dialogs/select_profile_picture_dialog.dart';
import '../controller/food_upload_controller.dart';
import '../model/food_ai_res_model.dart';
import '../../service/view/add_services_screen.dart';


class SubmitFoodProductPage extends StatefulWidget {
  final ProductServiceProviderType providerType;
  final EarnWithBlueEraServiceTypes? serviceSubType;
  final FoodAiResModel foodDatas;
  final Map<String, dynamic> foodData;
  final String imagePath;
  final String categoryTag;
  final String subCategory;

  SubmitFoodProductPage(
      { Key? key,
        required this.providerType,
        required this.foodData,
        required this.foodDatas,
        required this.imagePath,
        required this.categoryTag,
        required this.subCategory,
        this.serviceSubType,
      })
      : super(key: key);

  @override
  State<SubmitFoodProductPage> createState() => _SubmitFoodProductPageState();
}

class _SubmitFoodProductPageState extends State<SubmitFoodProductPage> {
  final controller = getOrPut(() => FoodUploadController());

  @override
  void initState() {
    if(controller.imageLocalPaths.isEmpty){
      controller.imageLocalPaths.add(widget.imagePath);
    }
    // TODO: implement initState
    controller.foodNameCtrl.text =
        widget.foodDatas.productName?.join(",") ?? '';
    controller.descCtrl.text = widget.foodDatas.shortDescription.toString();
    controller.selectedCategory.value = widget.categoryTag;
    controller.selectedSubCategory.value = widget.subCategory;
    controller.ingredients.value =
    List<String>.from(widget.foodDatas.keyIngredients ?? []);
    controller.accompaniments.value =
    List<String>.from(widget.foodDatas.accompaniments ?? []);
    super.initState();
  }

  RxList<DiscountCoupon> coupons = <DiscountCoupon>[].obs;

  Widget _discountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       
        Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomText(AppStrings.discountOptional, fontWeight: FontWeight.w400),
            SizedBox(
              height: SizeConfig.size8,
            ),
            coupons.isEmpty
                ? Container(
              decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [AppShadows.textFieldShadow],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.greyE5,
                  )),
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size16,
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: CustomText(
                  AppStrings.discountCoupon,
                  fontFamily: "Arial",
                ),
                trailing: const Icon(CupertinoIcons.chevron_forward),
                onTap: () {
                  showDiscountCouponDialog(context);
                  setState(() {

                  });
                },
              ),
            )
                : ListView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: List.generate(
                coupons.length,
                    (index) {
                  final coupon = coupons[index];

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin:
                        const EdgeInsets.symmetric(vertical: 12),
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size12,
                            vertical: SizeConfig.size15),
                        decoration: BoxDecoration(
                            color: AppColors.white,
                            boxShadow: [AppShadows.textFieldShadow],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.greyE5,
                            )),
                        child: Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    "Discount worth ₹${coupon.totalOff.toStringAsFixed(0)} T&Cs",
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.mainTextColor,
                                  ),
                                  SizedBox(height: 6),
                                  CustomText(coupon.description,
                                      fontSize: SizeConfig.small,
                                      color: AppColors
                                          .secondaryTextColor,
                                      fontWeight: FontWeight.w400),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      DottedBorder(
                                        borderType: BorderType.RRect,
                                        radius: Radius.circular(6),
                                        dashPattern: [6, 3],
                                        // 6px dash, 3px gap
                                        color: Colors.green,
                                        strokeWidth: 1.0,
                                        child: Container(
                                          padding:
                                          EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6),
                                          child: CustomText(
                                              coupon.codeName ??
                                                  "N/A",
                                              fontSize:
                                              SizeConfig.small,
                                              color: AppColors
                                                  .mainTextColor,
                                              fontWeight:
                                              FontWeight.w400),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      CustomText(
                                          coupon.discountType ==
                                              DiscountType
                                                  .inPercentage
                                              ? "${coupon.totalOff}% Off"
                                              : "₹${coupon.totalOff} Off",
                                          fontSize: SizeConfig.small,
                                          color: AppColors.green7F,
                                          fontWeight:
                                          FontWeight.w600),
                                    ],
                                  )
                                ],
                              ),
                            ),

                            // Right side - Icon
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.white,
                                  border: Border.all(
                                      color: AppColors.primaryColor,
                                      width: 1.1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.08),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                      spreadRadius: 0,
                                    )
                                  ]),
                              child: Icon(
                                Icons.percent,
                                color: AppColors.orange27,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                          right: 6,
                          top: -6,
                          child: InkWell(
                            onTap: () {
                              coupons.removeAt(index);
                              setState(() {

                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: AppColors.white,
                                  boxShadow: [
                                    AppShadows.textFieldShadow
                                  ],
                                  border: Border.all(
                                    color: AppColors.greyE5,
                                  ),
                                  shape: BoxShape.circle),
                              child: Icon(
                                Icons.close,
                                size: 18,
                              ),
                            ),
                          ))
                    ],
                  );
                },
              ),
            ),
            SizedBox(
              height: SizeConfig.size8,
            ),
            if (coupons.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      showDiscountCouponDialog(context);
                    },
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.add,
                          color: Colors.blue,
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        const CustomText(
                          AppStrings.addMoreCoupon,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ),
                  ),
                ],
              )
          ],
        ))
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.food,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size8,
              vertical: SizeConfig.size15,
          ),
          child: Obx(()=> AbsorbPointer(
            absorbing: controller.isAddFoodLoading.value,
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Upload images
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            CustomText(AppStrings.uploadImages,
                                fontWeight: FontWeight.w500),
                            CustomText(AppStrings.min1Max2,
                                color: Colors.grey),
                          ],
                        ),

                        const SizedBox(height: 8),
                        SizedBox(
                          height: 90,
                          child: Obx(() {
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: controller.imageLocalPaths.length < 2
                                  ? controller.imageLocalPaths.length +
                                  1 // add + button
                                  : controller.imageLocalPaths.length, // max 2
                              // +1 for add button
                              itemBuilder: (context, index) {
                                if (index == controller.imageLocalPaths.length) {
                                  // Add Button
                                  return InkWell(
                                    onTap: () async {
                                      final String? selected =
                                      await SelectProfilePictureDialog
                                          .showLogoDialog(
                                        context,
                                        AppStrings.selectPhoto.tr,
                                      );
                                      if ((selected?.isNotEmpty ?? false) &&
                                          selected != null) {
                                        controller.imageLocalPaths.add(selected);
                                      }
                                    },
                                    child: Container(
                                      height: 80,
                                      width: 80,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.whiteFE,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: AppColors.whiteE5),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.photo,
                                        color: AppColors.greyAF,
                                      ),
                                    ),
                                  );
                                } else {
                                  // Image Item
                                  return Stack(
                                    children: [
                                      Container(
                                        height: 80,
                                        width: 80,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.whiteFE,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                              color: AppColors.whiteE5),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            File(controller.imageLocalPaths[index]),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      // Cancel Icon
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () {
                                            controller.imageLocalPaths.removeAt(
                                                index);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                            AppStrings.foodName,
                            AppStrings.egPaneerButterMasala,
                            controller: controller.foodNameCtrl),

                        SizedBox(height: SizeConfig.size10),

                        // Category
                        Obx(() {
                          return AbsorbPointer(
                            absorbing: widget.providerType == ProductServiceProviderType.user,
                            child: _buildDropdown(
                                AppStrings.categoryTag,
                                AppStrings.egMainCourse,
                                selectedValue: controller.selectedCategory.value,
                                onChanged: (v) =>
                                controller.selectedCategory.value = v!,
                                items: controller.foodType1Options),
                          );
                        }),

                        SizedBox(height: SizeConfig.size6),


                        Obx(() {
                          return _buildDropdown(
                              AppStrings.subCategory,
                              AppStrings.egVegNorthIndian,
                              selectedValue: controller.selectedSubCategory.value,
                              onChanged: (v) =>
                              controller.selectedSubCategory.value = v!,
                              items: controller.foodType2Options);
                        }),

                        SizedBox(height: SizeConfig.size10),

                        // Description
                        _buildTextField(
                            AppStrings.foodDescription,
                            AppStrings.egFreshSpicyAndWellCooked,
                            controller: controller.descCtrl,
                            maxLines: 5),

                        const SizedBox(height: 16),
                        // Add Ons
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.whiteE5
                              )
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.add_circle_outline),
                            title: const CustomText(AppStrings.addOns),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddOnsPage(
                                        initialAddOns: List<Map<String, dynamic>>.from(controller.addOns),
                                      ),
                                ),
                              );

                              if (result != null && result is List<Map<String, dynamic>>) {
                                log('result length  before  -- > $result');
                                controller.addOns.assignAll(result);
                                 log('result length after -- > ${controller.addOns.length}');
                              }
                            },
                          ),
                        ),
                        SizedBox(height: 10),
                        Obx(() {
                          final addOns = controller.addOns;

                          if (addOns.isEmpty) {
                            return const SizedBox();
                          }
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(addOns.length, (index) {
                              final item = addOns[index];
                              return Chip(
                                label: Text(
                                  "${item['name']} (+₹${item['price']})",
                                  style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.mainTextColor),
                                ),
                                backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () {
                                   addOns.removeAt(index);
                                },
                              );
                            }),
                          );
                        }),

                        SafeArea(
                          child: CommonCardWidget(
                            padding: 0,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 🔹 Key Ingredients
                                  const SizedBox(height: 10),
                                  _buildSectionTitle(AppStrings.cookingMethod),
                                  const SizedBox(height: 6),
                                  CustomText("${controller.selectedCookingMethod.value}",fontSize: 16,fontWeight: FontWeight.w500,),
                                  const SizedBox(height: 10),
                                  _buildSectionTitle(AppStrings.itemNature),
                                  const SizedBox(height: 6),
                                  CustomText("${controller.selectedItemNature.value}",fontSize: 16,fontWeight: FontWeight.w500,),
                                  const SizedBox(height: 10),
                                  _buildSectionTitle(AppStrings.keyIngredients),
                                  const SizedBox(height: 4),
                                  Obx(() {
                                    return Wrap(
                                      spacing: 8,
                                      children: controller.ingredients.map((e) {
                                        return Chip(
                                          shadowColor: AppColors.secondaryTextColor,
                                          elevation: 1,
                                          label: CustomText(e),
                                          backgroundColor: AppColors.white
                                              .withValues(
                                              alpha: 0.5),
                                          deleteIcon: const Icon(
                                              Icons.close, size: 18),
                                          onDeleted: () {
                                            setState(() {
                                              controller.ingredients.remove(e);
                                            });
                                          },
                                        );
                                      }).toList(),
                                    );
                                  }),

                                  SizedBox(height: SizeConfig.size12),

                                  // 🔹 Serving Options
                                  _buildSectionTitle(AppStrings.servingOptions),
                                  const SizedBox(height: 4),
                                  Column(
                                    children: List<Map<String, dynamic>>.from(
                                        widget.foodData["servingOptions"] ?? [])
                                        .map((e) {
                                      return Card(
                                        child: ListTile(
                                          leading: const Icon(Icons.restaurant),
                                          title: CustomText("${e["size"]}"),
                                          subtitle: CustomText(
                                              "${AppStrings.serves} ${e["serves"]}"),
                                        ),
                                      );
                                    }).toList(),
                                  ),

                                  SizedBox(height: SizeConfig.size12),

                                  // 🔹 Accompaniments
                                  _buildSectionTitle(AppStrings.accompaniments),
                                  const SizedBox(height: 4),

                                  Obx(() {
                                    return Wrap(
                                      spacing: 8,
                                      children: controller.accompaniments.map((e) {
                                        return Chip(
                                          shadowColor: AppColors.secondaryTextColor,
                                          elevation: 1,
                                          label: CustomText(e),
                                          backgroundColor: AppColors.white
                                              .withValues(
                                              alpha: 0.5),
                                          deleteIcon: const Icon(
                                              Icons.close, size: 18),
                                          onDeleted: () {
                                            // 9789
                                            controller.accompaniments.remove(e);
                                          },
                                        );
                                      }).toList(),
                                    );
                                  }),

                                  SizedBox(height: SizeConfig.size12),

                                  // 🔹 Nutrition Summary
                                  _buildSectionTitle(
                                      AppStrings.nutritionalSummaryPer100g),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceAround,
                                    children: [
                                      _nutritionCard(
                                          AppStrings.caloriesKcal,
                                          widget
                                              .foodData["nutritionalSummary_per100g"]
                                          ["calories_kcal"]),
                                      _nutritionCard(
                                          AppStrings.proteinG,
                                          widget
                                              .foodData["nutritionalSummary_per100g"]
                                          ["protein_g"]),
                                      _nutritionCard(
                                          AppStrings.carbsG,
                                          widget
                                              .foodData["nutritionalSummary_per100g"]
                                          ["carbs_g"]),
                                      _nutritionCard(
                                          AppStrings.fatG,
                                          widget
                                              .foodData["nutritionalSummary_per100g"]
                                          ["fat_g"]),
                                    ],
                                  ),

                                  SizedBox(height: SizeConfig.size12),

                                  // 🔹 Key Minerals
                                  _buildSectionTitle(AppStrings.keyMinerals),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    children:
                                    List<String>.from(
                                        widget.foodData["keyMinerals"] ?? [])
                                        .map((e) {
                                      return Chip(
                                        backgroundColor: Colors.teal[50],
                                        label: CustomText(e),
                                      );
                                    }).toList(),
                                  ),

                                  SizedBox(height: SizeConfig.size12),

                                  // 🔹 SEO Tags
                                  _buildSectionTitle(AppStrings.seoTags),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    children:
                                    List<String>.from(
                                        widget.foodData["seoTags"] ?? [])
                                        .map((e) {
                                      return Chip(
                                        backgroundColor: Colors.orange[50],
                                        label: CustomText("#$e"),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildSectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: SizeConfig.size10),
                        _discountSection(),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText(AppStrings.price),
                            Row(
                              children: [
                                Row(
                                  children: [
                                    Obx(() {
                                      return Radio(
                                        visualDensity: const VisualDensity(
                                            horizontal: -4, vertical: -4),
                                        value: true,
                                        groupValue: controller.isSingleProduct
                                            .value,
                                        onChanged: (v) =>
                                        controller.isSingleProduct.value = true,
                                      );
                                    }),
                                    const CustomText(
                                      AppStrings.singleProduct, fontSize: 12,)
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Row(
                                  children: [
                                    Obx(() {
                                      return Radio(
                                        visualDensity: const VisualDensity(
                                            horizontal: -4, vertical: -4),
                                        value: false,
                                        groupValue: controller.isSingleProduct
                                            .value,
                                        onChanged: (v) =>
                                            setState(() =>
                                            controller.isSingleProduct.value =
                                            false),
                                      );
                                    }),
                                    const CustomText(AppStrings.multipleType, fontSize: 12,)
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.size10,),

                        Obx(() {
                              return (controller.isSingleProduct.value)? Obx(() {
                                return Row(
                                  children: [
                                    (controller.isSingleProduct.value)
                                        ? SizedBox()
                                        : Expanded(
                                      child: CommonTextField(
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 14, horizontal: 12),
                                        hintText: AppStrings.egSmall,
                                        textEditController: TextEditingController(),
                                        keyBoardType: TextInputType.number,
                                      ),
                                    ),
                                    SizedBox(width: SizeConfig.size10),
                                    Expanded(
                                      child: CommonTextField(
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 14, horizontal: 12),
                                        hintText: AppStrings.egRs300,
                                        textEditController: controller
                                            .singlePriceController,
                                        keyBoardType: TextInputType.number,
                                        isValidate: true
                                      ),
                                    ),
                                  ],
                                );
                              }): PriceOptionsWidget();
                            }
                        ),

                        // SizedBox(height: SizeConfig.size10,),
                        // Obx(() {
                        //     return (controller.isSingleProduct.value) ? SizedBox() : Row(
                        //       children: [
                        //         Expanded(
                        //           child: CommonTextField(
                        //             contentPadding: EdgeInsets.symmetric(
                        //                 vertical: 14, horizontal: 12),
                        //
                        //             hintText: "E.g. Medium",
                        //             textEditController: TextEditingController(),
                        //             keyBoardType: TextInputType.number,
                        //           ),
                        //         ),
                        //         SizedBox(width: SizeConfig.size10),
                        //         Expanded(
                        //           child: CommonTextField(
                        //             contentPadding: EdgeInsets.symmetric(
                        //                 vertical: 14, horizontal: 12),
                        //             hintText: "E.g. ₹300",
                        //             textEditController: TextEditingController(),
                        //             keyBoardType: TextInputType.number,
                        //           ),
                        //         ),
                        //       ],
                        //     );
                        //   }
                        // ),
                        // Obx(() {
                        //     return (controller.isSingleProduct.value) ? SizedBox() : SizedBox(
                        //       height: SizeConfig.size10,);
                        //   }
                        // ),
                        // Obx(
                        //   () {
                        //     return (controller.isSingleProduct.value) ? SizedBox() : Row(
                        //       children: [
                        //         Expanded(
                        //           child: CommonTextField(
                        //             contentPadding: EdgeInsets.symmetric(
                        //                 vertical: 14, horizontal: 12),
                        //
                        //             hintText: "E.g. Large",
                        //             textEditController: TextEditingController(),
                        //             keyBoardType: TextInputType.number,
                        //           ),
                        //         ),
                        //         SizedBox(width: SizeConfig.size10),
                        //         Expanded(
                        //           child: CommonTextField(
                        //             contentPadding: EdgeInsets.symmetric(
                        //                 vertical: 14, horizontal: 12),
                        //             hintText: "E.g. ₹300",
                        //             textEditController: TextEditingController(),
                        //             keyBoardType: TextInputType.number,
                        //           ),
                        //         ),
                        //       ],
                        //     );
                        //   }
                        // ),


                        const SizedBox(height: 10),


                        // Column(
                        //   crossAxisAlignment: CrossAxisAlignment.start,
                        //   children: [
                        //     const CustomText(
                        //         "Discount", fontWeight: FontWeight.w400),
                        //     SizedBox(
                        //       height: SizeConfig.size8,
                        //     ),
                        //     Container(
                        //       decoration: BoxDecoration(
                        //           borderRadius: BorderRadius.circular(10),
                        //           border: Border.all(
                        //               color: AppColors.whiteE5
                        //           )
                        //       ),
                        //       padding: EdgeInsets.symmetric(horizontal: SizeConfig
                        //           .size14),
                        //       child: ListTile(
                        //         contentPadding: EdgeInsets.zero,
                        //         title: CustomText("Discount Coupon",
                        //           fontFamily: "Arial",
                        //         ),
                        //         trailing: const Icon(
                        //             CupertinoIcons.chevron_forward),
                        //         onTap: () {},
                        //       ),
                        //     ),
                        //     SizedBox(
                        //       height: SizeConfig.size8,
                        //     ),
                        //     Row(mainAxisAlignment: MainAxisAlignment.end,
                        //       children: [
                        //         GestureDetector(
                        //           onTap: () {
                        //             showDiscountCouponDialog(context);
                        //           },
                        //           child: Row(
                        //             children: [
                        //               const Icon(
                        //                 CupertinoIcons.add, color: Colors.blue,
                        //                 size: 20,),
                        //               SizedBox(width: 6),
                        //               const CustomText(
                        //                 "Add More Coupon",
                        //                 color: Colors.blue,
                        //                 fontWeight: FontWeight.w500,
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       ],
                        //     )
                        //   ],
                        // )
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: EdgeInsets.all(SizeConfig.size16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      // boxShadow: [AppShadows.textFieldShadow],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        //     CustomText("Add More Details",
                        //       fontWeight: FontWeight.w600,),
                        //     GestureDetector(
                        //       onTap: () {
                        //         showAddMoreDetailsDialog(context);
                        //       },
                        //       child: Container(
                        //           height: 28,
                        //           width: 28,
                        //           decoration: BoxDecoration(
                        //               borderRadius: BorderRadius.circular(8),
                        //               color: Colors.blue
                        //           ),
                        //           child: Center(child: const Icon(CupertinoIcons.add,
                        //             color: Colors.white,size: 21,))),
                        //     ),
                        //   ],
                        // ),
                        // SizedBox(height: SizeConfig.size30,),
                        SizedBox(
                          width: double.infinity,
                          child: CustomBtn(
                            onTap: ()  {
                              controller.addFoodServices(
                                  widget.foodData,
                                  widget.providerType,
                                  serviceSubType: widget.serviceSubType);
                            },
                            title: controller.isAddFoodLoading.value
                                ? null
                                : AppStrings.postFood,
                            isLoading: controller.isAddFoodLoading.value,
                            bgColor: AppColors.primaryColor,
                          ),
                        ),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return CustomText(title,
        fontSize: SizeConfig.size16, fontWeight: FontWeight.w400);
  }

  Widget _nutritionCard(String title, String value) {
    return Column(
      children: [
        CustomText(value,
            fontSize: SizeConfig.size16, fontWeight: FontWeight.bold),
        const SizedBox(height: 4),
        CustomText(title, fontSize: SizeConfig.small, color: Colors.grey),
      ],
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300)),
      child: child,
    );
  }

  Widget _buildTextField(String label, String hint,
      {TextEditingController? controller,
        int maxLines = 1,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonTextField(
          maxLine: maxLines,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          title: label,
          hintText: hint,
          textEditController: controller,
          isValidate: true,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String hint,
      {ValueChanged<String?>? onChanged, required List<
          String> items, required String selectedValue}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedValue,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: CustomText(item),
            );
          }).toList(),

          hint: CustomText(hint, color: AppColors.grey9A,
            fontSize: 16,
            fontWeight: FontWeight.w600,),
          onChanged: onChanged,

          // 👇 this changes the selected text color inside the field
          style: TextStyle(
            color: AppColors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),


          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.black,
          ),
        )

      ],
    );
  }
}


class AddOnsPage extends StatefulWidget {
  final List<Map<String, dynamic>> initialAddOns;

  const AddOnsPage({Key? key, required this.initialAddOns}) : super(key: key);

  @override
  State<AddOnsPage> createState() => _AddOnsPageState();
}

class _AddOnsPageState extends State<AddOnsPage> {
  final extraCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  List<Map<String, dynamic>> addOns = [];

  void _addAddOn() {
    if (extraCtrl.text
        .trim()
        .isEmpty || priceCtrl.text
        .trim()
        .isEmpty) return;

    setState(() {
      addOns.add({
        "name": extraCtrl.text.trim(),
        "price": priceCtrl.text.trim(),
      });
      extraCtrl.clear();
      priceCtrl.clear();
    });
  }

  void _removeAddOn(int index) {
    setState(() {
      addOns.removeAt(index);
    });
  }

  @override
  void initState() {
    addOns = List<Map<String, dynamic>>.from(widget.initialAddOns);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, addOns);
        return false;
      },
      child: Scaffold(
        appBar: CommonBackAppBar(onBackTap: () {
          Navigator.pop(context, addOns);
        },
          title: AppStrings.addOnsTitle,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 👈 Auto adjust height
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Extra Add field
                const CustomText(
                    AppStrings.extraAdd,
                    fontWeight: FontWeight.w500),
                const SizedBox(height: 6),
                TextField(
                  controller: extraCtrl,
                  decoration: InputDecoration(
                    hintText: AppStrings.egButterNaan.tr,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Price field
                const CustomText(
                    AppStrings.price, fontWeight: FontWeight.w500),
                const SizedBox(height: 6),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: AppStrings.egRs300.tr,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Added AddOns Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(addOns.length, (index) {
                    final item = addOns[index];
                    return Chip(
                      label: Text(
                        "${item['name']} (+₹${item['price']})",
                        style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.mainTextColor),
                      ),
                      backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeAddOn(index),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addAddOn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      AppStrings.save,
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

      ),
    );
  }

}

class PriceOptionsWidget extends StatelessWidget {
  final controller = Get.put(FoodUploadController());

  PriceOptionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(crossAxisAlignment: CrossAxisAlignment.end,mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ...controller.priceOptions.asMap().entries.map((entry) {
            int index = entry.key;
            var option = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  // Label field
                  Expanded(
                    child: CommonTextField(
                      hintText: AppStrings.egSmall,
                      textEditController: option.labelController,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Price field
                  Expanded(
                    child: CommonTextField(
                      hintText: AppStrings.egRs300,
                      keyBoardType: TextInputType.number,
                      textEditController: option.priceController,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Cancel button
                  InkWell(
                    onTap: (){
                      controller.removePriceOption(index);
                    },
                    child: const Icon(Icons.cancel, color: Colors.red),

                  ),
                ],
              ),
            );
          }),

          // Add button
          Row(mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(height: 4,),
              Align(
                alignment: Alignment.centerLeft,
                child:  InkWell(
                    onTap: controller.addPriceOption,
                    child: const CustomText(AppStrings.addSizePrice, color: Colors.blue,)),
              ),
            ],
          ),

        ],
      );
    });
  }
}