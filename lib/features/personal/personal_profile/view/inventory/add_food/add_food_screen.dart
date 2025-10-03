import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../../../core/constants/snackbar_helper.dart';
import '../../../../../../widgets/common_card_widget.dart';
import '../../../../../common/auth/views/dialogs/select_profile_picture_dialog.dart';
import '../../../../../common/food/controller/food_upload_controller.dart';
import '../../../../../common/food/food_ai_res_model.dart';
import '../widget/add_services_screen.dart';


class SubmitFoodProductPage extends StatefulWidget {
  SubmitFoodProductPage(
      {Key? key, required this.foodData, required this.foodDatas, required this.imagePath, required this.categoryTag, required this.subCategory})
      : super(key: key);
  final FoodAiResModel foodDatas;
  final Map<String, dynamic> foodData;
  final String imagePath;
  final String categoryTag;
  final String subCategory;

  @override
  State<SubmitFoodProductPage> createState() => _SubmitFoodProductPageState();
}

class _SubmitFoodProductPageState extends State<SubmitFoodProductPage> {

  final controller = Get.find<FoodUploadController>();

  @override
  void initState() {
    controller.imageLocalPaths.add(widget.imagePath);
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Food',
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
                        Text("Upload Images",
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        Text("Min-1 / Max-2",
                            style: TextStyle(color: Colors.grey)),
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
                                    "Select Photo",
                                  );
                                  if ((selected?.isNotEmpty ?? false) &&
                                      selected != null) {
                                    controller.imageLocalPaths.add(selected);
                                  } else {
                                    commonSnackBar(
                                        message: "Something went wrong please try again");
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
                                          color: Colors.black.withOpacity(0.5),
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

                    _buildTextField("Food Name", "E.g. Paneer Butter Masala...",
                        controller: controller.foodNameCtrl),

                    SizedBox(height: SizeConfig.size10),

                    // Category
                    Obx(() {
                      return _buildDropdown(
                          "Category tag", "E.g. Main Course...",
                          selectedValue: controller.selectedCategory.value,
                          onChanged: (v) =>

                          controller.selectedCategory.value = v!,
                          items: controller.foodType1Options);
                    }),

                    SizedBox(height: SizeConfig.size6),


                    Obx(() {
                      return _buildDropdown(
                          "Sub Category", "E.g. Veg, North Indian...",
                          selectedValue: controller.selectedSubCategory.value,
                          onChanged: (v) =>
                          controller.selectedSubCategory.value = v!,
                          items: controller.foodType2Options);
                    }),

                    SizedBox(height: SizeConfig.size10),

                    // Description
                    _buildTextField("Food Description",
                        "Horem ipsum dolor sit amet, consectetur adipiscing...",
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
                        title: const Text("Add ons"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddOnsPage(
                                    initialAddOns: controller
                                        .addOns, // 👈 pass previous list
                                  ),
                            ),
                          );

                          if (result != null && result is List<
                              Map<String, dynamic>>) {
                            setState(() {
                              controller.addOns.value = result;
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 10,),
                    Obx(() {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(controller.addOns.length, (
                            index) {
                          final item = controller.addOns[index];
                          return Chip(
                            label: Text(
                              "${item['name']} (+₹${item['price']})",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500),
                            ),
                            backgroundColor: AppColors.skyBlueDF.withOpacity(
                                0.1),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              controller.addOns.removeAt(index);
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
                              _buildSectionTitle("Key Ingredients"),
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
                              _buildSectionTitle("Serving Options"),
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
                                          "Serves ${e["serves"]}"),
                                    ),
                                  );
                                }).toList(),
                              ),

                              SizedBox(height: SizeConfig.size12),

                              // 🔹 Accompaniments
                              _buildSectionTitle("Accompaniments"),
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
                                  "Nutritional Summary (per 100g)"),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceAround,
                                children: [
                                  _nutritionCard(
                                      "Calories",
                                      widget
                                          .foodData["nutritionalSummary_per100g"]
                                      ["calories_kcal"]),
                                  _nutritionCard(
                                      "Protein",
                                      widget
                                          .foodData["nutritionalSummary_per100g"]
                                      ["protein_g"]),
                                  _nutritionCard(
                                      "Carbs",
                                      widget
                                          .foodData["nutritionalSummary_per100g"]
                                      ["carbs_g"]),
                                  _nutritionCard(
                                      "Fat",
                                      widget
                                          .foodData["nutritionalSummary_per100g"]
                                      ["fat_g"]),
                                ],
                              ),

                              SizedBox(height: SizeConfig.size12),

                              // 🔹 Key Minerals
                              _buildSectionTitle("Key Minerals"),
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
                              _buildSectionTitle("SEO Tags"),
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
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText("Price",),
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
                                  "Single Product", fontSize: 12,)
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
                                const CustomText("Multiple type", fontSize: 12,)
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size10,),

                    Obx(
                            () {
                          return (controller.isSingleProduct.value)? Obx(() {
                            return Row(
                              children: [
                                (controller.isSingleProduct.value)
                                    ? SizedBox()
                                    : Expanded(
                                  child: CommonTextField(
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 12),

                                    hintText: "E.g. Small",
                                    textEditController: TextEditingController(),
                                    keyBoardType: TextInputType.number,
                                  ),
                                ),
                                SizedBox(width: SizeConfig.size10),
                                Expanded(
                                  child: CommonTextField(
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 12),
                                    hintText: "E.g. ₹300",
                                    textEditController: controller
                                        .singlePriceController,
                                    keyBoardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            );
                          }): PriceOptionsWidget();
                        }
                    ),
                    //

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
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: SizeConfig.paddingM),
                        ),

                        onPressed: () async {

                          controller.addFoodServices(widget.foodData);
                        },
                        child: const CustomText(
                          "Post Food",
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
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
  AddOnsPage({Key? key, required this.initialAddOns}) : super(key: key);
  final List<Map<String, dynamic>> initialAddOns;

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
    // TODO: implement initState
    addOns = widget.initialAddOns;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, addOns); // 👈 send back data on back press
        return false; // prevent default pop (we already popped)
      },
      child: Scaffold(
        appBar: CommonBackAppBar(onBackTap: () {
          Navigator.pop(context, addOns);
        },
          title: 'Add Ons',
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
                const Text(
                    "Extra Add", style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: extraCtrl,
                  decoration: InputDecoration(
                    hintText: "e.g. Butter Naan",
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
                const Text(
                    "Price", style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "e.g. ₹30",
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
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: AppColors.skyBlueDF.withOpacity(0.1),
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
                      "Save",
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
                      hintText: "E.g. Small",
                      textEditController: option.labelController,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Price field
                  Expanded(
                    child: CommonTextField(
                      hintText: "E.g. ₹300",
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
                    child: const CustomText("Add Size/Price",color: Colors.blue,)),
              ),
            ],
          ),

        ],
      );
    });
  }
}