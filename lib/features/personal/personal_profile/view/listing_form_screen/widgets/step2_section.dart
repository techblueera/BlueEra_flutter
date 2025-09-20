import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/add_more_details_screen/add_more_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/listing_form_screen_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/widgets/add_more_details_dialog.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Step2Section extends StatelessWidget {
  final ManualListingScreenController controller;
  const Step2Section({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size15),
      child: Form(
        key: controller.formKeyStep2,
        child: Column(
          children: [

            CustomFormCard(
              margin: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Field
                  CustomText(
                    controller.productNameController.text,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w400,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  CustomText(
                    controller.selectedBreadcrumb.value
                        ?.map((e) => e.name.toString())
                        .join(' - ') ?? '',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryTextColor,
                  ),


                ],
              ),
            ),

            SizedBox(height: SizeConfig.size12),

            _buildProductFeaturesSection(controller),

            SizedBox(height: SizeConfig.size12),

            _buildAddOption(context),

            SizedBox(height: SizeConfig.size30),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
              child: CustomBtn(
                title: 'Create',
                onTap: controller.onNext,
                bgColor: AppColors.primaryColor,
                textColor: AppColors.white,
                height: SizeConfig.size40,
                radius: 10.0,
              ),
            ),


            // Container(
            //   margin: EdgeInsets.all(SizeConfig.size15),
            //   padding: EdgeInsets.all(SizeConfig.size15),
            //   decoration: BoxDecoration(
            //     color: AppColors.white,
            //     borderRadius: BorderRadius.circular(10.0),
            //     // boxShadow: [AppShadows.textFieldShadow],
            //   ),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       // Title Field
            //       CustomText(
            //         'Title',
            //         fontSize: SizeConfig.medium,
            //         fontWeight: FontWeight.w600,
            //         color: AppColors.black,
            //       ),
            //       SizedBox(height: SizeConfig.size8),
            //       CommonTextField(
            //         textEditController: controller.titleController,
            //         hintText: 'e.g. Size',
            //         validator: controller.validateTitle,
            //         showLabel: false,
            //       ),
            //
            //       SizedBox(height: SizeConfig.size20),
            //
            //       // Variant Field
            //       CustomText(
            //         'Details',
            //         fontSize: SizeConfig.medium,
            //         fontWeight: FontWeight.w600,
            //         color: AppColors.black,
            //       ),
            //       SizedBox(height: SizeConfig.size8),
            //       CommonTextField(
            //         textEditController: controller.variantController,
            //         hintText: 'e.g. Wireless Earbuds Bo....',
            //         validator: controller.validateVariant,
            //         showLabel: false,
            //       ),
            //
            //       SizedBox(height: SizeConfig.size16),
            //
            //
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductFeaturesSection(
      ManualListingScreenController controller) {
    // min- 20
    return CustomFormCard(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Add Product Features',
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
          SizedBox(height: SizeConfig.size16),
          Obx(() => Column(
            children:
            List.generate(controller.featureControllers.length, (i) {
              return Padding(
                padding: EdgeInsets.only(bottom: SizeConfig.size16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CommonTextField(
                        title: 'Feature ${i + 1}',
                        hintText: 'E.g. Vorem ipsum dolor sit amet,',
                        textEditController: controller.featureControllers[i],
                        maxLine: 2,
                        validator: (value)=> controller.validateFeatures(value, i),
                        maxLength: 140,
                        isCounterVisible: true,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size8),
                    if (controller.featureControllers.length > 1)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => controller.removeFeature(i),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: EdgeInsets.only(top: SizeConfig.size20),
                            child: Icon(
                              Icons.delete_outline,
                              color: AppColors.primaryColor,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          )),
          SizedBox(height: SizeConfig.size16),
          GestureDetector(
            onTap: controller.addFeature,
            child: Row(
              children: [
                LocalAssets(imagePath: AppIconAssets.addBlueIcon),
                SizedBox(width: SizeConfig.size10),
                CustomText("Add More Option", color: AppColors.primaryColor),
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size16),
          GestureDetector(
            onTap: controller.showLinkField.toggle,
            child: Row(
              children: [
                LocalAssets(imagePath: AppIconAssets.addBlueIcon),
                SizedBox(width: SizeConfig.size10),
                CustomText("Add Link (Reference / Website)",
                    color: AppColors.primaryColor),
              ],
            ),
          ),
          Obx(() => controller.showLinkField.isTrue
              ? Padding(
            padding: EdgeInsets.only(top: SizeConfig.size15),
            child: HttpsTextField(
              title: "Link (Reference / Website)",
              hintText: "https://example.com",
              controller: controller.linkController,
              isUrlValidate: false
            ),
          )
              : const SizedBox.shrink()),

          // SizedBox(height: SizeConfig.size20),
          // CustomText(
          //   'Options',
          //   fontSize: SizeConfig.medium,
          //   fontWeight: FontWeight.bold,
          //   color: AppColors.black,
          // ),
          // SizedBox(height: SizeConfig.size12),
          // Obx(() => Column(
          //   children: List.generate(
          //       controller.optionAttributeControllers.length, (i) {
          //     return Padding(
          //       padding: EdgeInsets.only(bottom: SizeConfig.size12),
          //       child: Row(
          //         children: [
          //           Expanded(
          //             child: CommonTextField(
          //               title: 'Attribute',
          //               hintText: 'e.g. Color',
          //               textEditController:
          //               controller.optionAttributeControllers[i],
          //             ),
          //           ),
          //           SizedBox(width: SizeConfig.size8),
          //           Expanded(
          //             child: CommonTextField(
          //               title: 'Value',
          //               hintText: 'e.g. Black',
          //               textEditController:
          //               controller.optionValueControllers[i],
          //             ),
          //           ),
          //           SizedBox(width: SizeConfig.size8),
          //           if (controller.optionAttributeControllers.length > 1)
          //             Material(
          //               color: Colors.transparent,
          //               child: InkWell(
          //                 onTap: () => controller.removeOption(i),
          //                 borderRadius: BorderRadius.circular(8),
          //                 child: Padding(
          //                   padding: const EdgeInsets.all(8.0),
          //                   child: const Icon(Icons.delete_outline,
          //                       color: AppColors.primaryColor),
          //                 ),
          //               ),
          //             ),
          //         ],
          //       ),
          //     );
          //   }),
          // )),
          // SizedBox(height: SizeConfig.size8),
          // GestureDetector(
          //   onTap: controller.addOption,
          //   child: Row(
          //     children: [
          //       Image.asset("assets/icons/add_icon.png",
          //           color: AppColors.primaryColor),
          //       SizedBox(width: SizeConfig.size10),
          //       CustomText("Add Option", color: AppColors.primaryColor),
          //     ],
          //   ),
          // ),
          // SizedBox(height: SizeConfig.size24),

        ],
      ),
    );
  }

  Widget _buildAddOption(BuildContext context){
    return CustomFormCard(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
      child: Column(
        children: [
          Obx(()=> controller.detailsList.isNotEmpty ? Column(
            children: List.generate(
              controller.detailsList.length,
                  (index) {
                final item = controller.detailsList[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: SizeConfig.size15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      if(index==0)...[
                        CustomText(
                          'Details',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w500,
                          color: AppColors.black,
                        ),

                        SizedBox(height: SizeConfig.size12),
                      ],

                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: AppColors.white,
                                  boxShadow: [AppShadows.textFieldShadow],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.greyE5,
                                  )),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title + Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CustomText(
                                          item.title,
                                          fontSize: SizeConfig.large,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.mainTextColor,
                                        ),
                                        const SizedBox(height: 4),
                                        CustomText(
                                          item.details,
                                          fontSize: SizeConfig.medium,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.secondaryTextColor,
                                        ),
                                      ],
                                    ),
                                  ),

                                ],
                              ),
                            ),
                          ),
                          Positioned(
                              right: 6,
                              top: -15,
                              child: InkWell(
                                onTap: () => controller.removeDetail(index),
                                child: Container(
                                  padding: EdgeInsets.all(6),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: AppColors.white,
                                      boxShadow: [AppShadows.textFieldShadow],
                                      border: Border.all(
                                        color: AppColors.greyE5,
                                      ),
                                      shape: BoxShape.circle
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 18,
                                  ),
                                ),
                              )
                          )
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ) : SizedBox.shrink()),

          InkWell(
            onTap: ()=> showAddMoreDetailsDialog(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  'Add More Details',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
                GestureDetector(

                  child: Container(
                    width: 32,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showAddMoreDetailsDialog(BuildContext context) async {
    if(controller.detailsList.length==5){
      commonSnackBar(message: 'You can\'t add more than five detail');
      return;
    }

   showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const AddMoreDetailsDialog(
        fromScreen: RouteConstant.listingFormScreen
      ),
    );

  }


}
