import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/food/controller/user_grocery_controller.dart';
import 'package:BlueEra/features/common/food/model/grocery_product_model.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroceryCartScreen extends StatefulWidget {
  const GroceryCartScreen({super.key});

  @override
  State<GroceryCartScreen> createState() => _GroceryCartScreenState();
}

class _GroceryCartScreenState extends State<GroceryCartScreen> {
  final controller = getOrPut(() => UserGroceryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Your Cart',
      ),
      body: SingleChildScrollView(
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
                      '₹${controller.totalSelectedVariantsSellingPrice}, ${controller.selectedGroceriesVariants.length} Products',
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                    ListView.builder(
                        itemCount: controller.selectedGroceriesVariants.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          vertical: SizeConfig.size15
                        ),
                        itemBuilder: (context, index){
                          final variant = controller.selectedGroceriesVariants[index];

                          return _variantItem(
                            variant: variant,
                            onAdd: () {
                              // onAdd(variant);
                              // Navigator.pop(context);
                            },
                          );
                        }
                    ),
                  ],
                )
             ),
            SizedBox(height: SizeConfig.paddingXSL),
            CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'Bill Details',
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(height: SizeConfig.size15),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: AppColors.greyE5),
                      ),
                      child: Column(
                        children: [
                          commonIconTextRow(
                              imagePath: AppIconAssets.cartListIcon,
                              leftText: 'Total Items',
                              rightText: '06'
                          ),
                          CommonHorizontalDivider(
                           height: 0.5,
                            color: AppColors.greyE5,
                          ),
                          commonIconTextRow(
                              imagePath: AppIconAssets.handPriceIcon,
                              leftText: 'Total MRP',
                              rightText: '₹2100'
                          ),
                          CommonHorizontalDivider(
                            height: 0.5,
                            color: AppColors.greyE5,
                          ),
                          commonIconTextRow(
                              imagePath: AppIconAssets.handPriceIcon,
                              leftText: 'Savings (Discount)',
                              rightText: '₹900'
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: SizeConfig.size10,
                    ),

                    DashedBorderContainer(
                        borderColor: AppColors.primaryColor,
                        strokeWidth: 0.5,
                        borderRadius: 10.0,
                        child: Container(
                          padding: EdgeInsets.all(SizeConfig.size10),
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText(
                                'Grand total (pay INR)',
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryTextColor,
                              ),
                              CustomText(
                                '₹1,200',
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w600,
                                color: AppColors.mainTextColor,
                              ),
                            ],
                          ),
                        )
                    )
                  ],
                )
            ),
            SizedBox(height: SizeConfig.paddingXSL),

          ],
        ),
      ),
    );
  }

  Widget _variantItem({
    required VariantsData variant,
    required VoidCallback onAdd,
  }) {
    // final price = groceryController.getPriceDetails(variant.pricing);

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

          // ClipRRect(
          //   borderRadius: BorderRadius.circular(6),
          //   child: CachedNetworkImage(
          //     imageUrl: variant.images?.first.url ?? '',
          //     width: SizeConfig.size50,
          //     height: SizeConfig.size50,
          //     fit: BoxFit.cover,
          //     errorWidget: (_, __, ___) =>
          //         LocalAssets(imagePath: AppIconAssets.place_holder_image),
          //   ),
          // ),

          SizedBox(width: SizeConfig.size10),

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
                          '₹${variant.pricing?[0].sellingPrice}',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor
                      ),
                      SizedBox(width: SizeConfig.size6),
                      CustomText(
                          '₹${variant.pricing?[0].mrp}',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor
                      ),
                    ]
                )
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size10),

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

          /// Add Button
          Obx(() {
            final bool isAdded = controller.selectedGroceriesVariants
                .any((v) => v.sId == variant.sId);

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomText(
                      '₹${variant.pricing?[0].sellingPrice}',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(width: SizeConfig.size4),
                    CustomText(
                      '₹${variant.pricing?[0].mrp}',
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
                      IconButton(
                          onPressed: () {  },
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.remove, color: AppColors.secondaryTextColor, size: SizeConfig.size12)
                      ),
                      CustomText(
                        '2',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                      IconButton(
                          onPressed: () {  },
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.add, color: AppColors.secondaryTextColor, size: SizeConfig.size12)
                      ),
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

  Widget commonIconTextRow({
    required String imagePath,
    required String leftText,
    required String rightText,
    EdgeInsetsGeometry padding = const EdgeInsets.all(10.0),
  }) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          LocalAssets(imagePath: imagePath),

          SizedBox(width: SizeConfig.size8),

          Expanded(
            child: CustomText(
              leftText,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
            ),
          ),

          CustomText(
            rightText,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }


}
