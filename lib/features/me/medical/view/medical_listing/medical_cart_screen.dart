import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/medical/model/medical_product_model.dart';
import 'package:BlueEra/features/me/medical/controller/user_medical_controller.dart';
import 'package:BlueEra/features/me/medical/widget/medical_bill_details.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/dashed_border_container.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MedicalCartScreen extends StatefulWidget {
  const MedicalCartScreen({super.key});

  @override
  State<MedicalCartScreen> createState() => _MedicalCartScreenState();
}

class _MedicalCartScreenState extends State<MedicalCartScreen> {
  final controller = getOrPut(() => UserMedicalController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.yourCart,
      ),
      body: Obx((){
        // If cart is empty, show a message (Optional)
        if (controller.selectedMedicalProductVariants.isEmpty) {
          return Center(child: CustomText(AppStrings.yourCartIsEmpty, color: AppColors.secondaryTextColor));
        }

        return  SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size15,
              vertical: SizeConfig.size8
          ),
          child: Column(
            children: [
              CustomFormCard(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'â‚¹${controller.totalSellingPrice.toStringAsFixed(2)}, ${controller.selectedMedicalProductVariants.length} ${AppStrings.productsCountSuffix.tr}',
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextColor,
                      ),
                      ListView.builder(
                          itemCount: controller.selectedMedicalProductVariants.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                              vertical: SizeConfig.size15
                          ),
                          itemBuilder: (context, index){
                            final variant = controller.selectedMedicalProductVariants[index];

                            return _variantItem(
                              variant: variant,
                            );
                          }
                      ),
                      SizedBox(height: SizeConfig.size5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          PositiveCustomBtn(
                              onTap: ()=> Get.back(),
                              height: SizeConfig.size30,
                              width: SizeConfig.size100,
                              title: AppStrings.addMoreItems,
                              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size6),
                              textColor: AppColors.secondaryTextColor,
                              isLeadingShow: true,
                              leadingIconPath: AppIconAssets.add,
                              leadingIconColor: AppColors.secondaryTextColor,
                              bgColor: Colors.transparent,
                              borderColor: AppColors.secondaryTextColor,
                          ),
                          SizedBox(width: SizeConfig.paddingXSL),
                          Obx(()=> CustomBtn(
                            onTap: ()=> controller.addMedicalOrderApi(),
                            height: SizeConfig.size30,
                            width: SizeConfig.size100,
                            title: controller.isAddMedicalOrderLoading.value
                                ? null
                                : AppStrings.submit,
                            bgColor: AppColors.primaryColor,
                            isLoading: controller.isAddMedicalOrderLoading.value,
                          )),
                        ],
                      )
                    ],
                  )
              ),

              SizedBox(height: SizeConfig.paddingXSL),

             // Bill Details
              MedicalBillDetails(controller: controller),

              SizedBox(height: SizeConfig.paddingXSL),

            ],
          ),
        );

      })

    );
  }

  Widget _variantItem({
    required VariantsData variant,
  }) {
    final sellingPrice = variant.pricing?.first.sellingPrice ?? 0;
    final mrp = variant.pricing?.first.mrp ?? 0;

    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      child: Row(
        children: [
          /// Variant Image
          (variant.images != null && variant.images!.isNotEmpty)
              ? CustomImageSlideshow(
            isLoading: false,
            width: SizeConfig.size50,
            height: SizeConfig.size50,
            imagePaths: variant.images!.map((i) => i.url ?? '').toList(),
            borderRadius: BorderRadius.circular(6),
          )
              : ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LocalAssets(
              imagePath: AppIconAssets.place_holder_image,
              boxFix: BoxFit.fill,
              width: SizeConfig.size50,
              height: SizeConfig.size50,
            ),
          ),


          SizedBox(width: SizeConfig.paddingXSL),

          /// Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  variant.variantName ?? '',
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 4),
                Row(
                    children: [
                      CustomText(
                          '${variant.weight} ${variant.unit}',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor
                      ),
                      SizedBox(width: SizeConfig.size6),
                      Container(
                        width: 0.5,
                        height: SizeConfig.size12,
                        color: AppColors.secondaryTextColor,
                      ),
                      SizedBox(width: SizeConfig.size6),
                      CustomText(
                          'â‚¹$sellingPrice',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor
                      ),
                      SizedBox(width: SizeConfig.size6),
                      CustomText(
                          'â‚¹$mrp',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor
                      ),
                    ]
                )
              ],
            ),
          ),

          SizedBox(width: SizeConfig.paddingXSL),

          /// Dashed Border Container
          DashedBorderContainer(
            borderColor: AppColors.greyE5,
            strokeWidth: 1,
            dashLength: 2,
            child: SizedBox(
              height: SizeConfig.size50,
              width: 1,
            ),
          ),
          SizedBox(width: SizeConfig.size10),

          /// Actions Button
          Obx(() {
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomText(
                      'â‚¹$sellingPrice',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(width: SizeConfig.size4),
                    CustomText(
                      'â‚¹$mrp',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.secondaryTextColor,
                    ),
                  ],
                ),

                SizedBox(height: SizeConfig.size4),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: AppColors.white,
                    border: Border.all(
                        color: AppColors.greyE5,
                    ),
                    boxShadow: [AppShadows.textFieldShadow]
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: ()=> controller.removeFromCart(variant),
                            borderRadius: BorderRadius.circular(20),
                            splashColor: AppColors.primaryColor.withValues(alpha: 0.2),
                            highlightColor: AppColors.primaryColor.withValues(alpha: 0.1),
                            child: SizedBox(
                              width: 30,   // tap area
                              height: 30,  // tap area
                              child: Center(
                                child: Icon(
                                    Icons.remove,
                                    color: AppColors.secondaryTextColor,
                                    size: SizeConfig.size12
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      CustomText(
                        '${controller.getQuantity(variant.sId)}',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              controller.addToCart(variant);
                            },
                            borderRadius: BorderRadius.circular(20),
                            splashColor: AppColors.primaryColor.withValues(alpha: 0.2),
                            highlightColor: AppColors.primaryColor.withValues(alpha: 0.1),
                            child: SizedBox(
                              width: 30,   // tap area
                              height: 30,  // tap area
                              child: Center(
                                child: Icon(
                                  Icons.add,
                                  size: SizeConfig.size12, // visual size
                                  color: AppColors.secondaryTextColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )


                   ]

                  ),
                )
              ],
            );
          }),

        ],
      ),
    );
  }



}
