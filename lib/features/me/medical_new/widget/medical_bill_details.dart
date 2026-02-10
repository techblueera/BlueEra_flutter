import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job.dart';
import 'package:BlueEra/features/me/medical_new/controller/user_medical_controller.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MedicalBillDetails extends StatelessWidget {
  final UserMedicalController controller;

  const MedicalBillDetails({
    super.key,
    required this.controller
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return CustomFormCard(
          padding: EdgeInsets.all(SizeConfig.size10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                AppStrings.billDetails,
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
                    _commonIconTextRow(
                        imagePath: AppIconAssets.cartListIcon,
                        leftText: AppStrings.totalItems,
                        rightText: '${controller.totalItemsCount}'
                    ),

                    CommonHorizontalDivider(
                      height: 0.5,
                      color: AppColors.greyE5,
                    ),

                    _commonIconTextRow(
                        imagePath: AppIconAssets.handPriceIcon,
                        leftText: AppStrings.totalMRP,
                        rightText: '₹${controller.totalMRP.toStringAsFixed(2)}'
                    ),

                    CommonHorizontalDivider(
                      height: 0.5,
                      color: AppColors.greyE5,
                    ),

                    _commonIconTextRow(
                        imagePath: AppIconAssets.handPriceIcon,
                        leftText: AppStrings.savingsDiscount,
                        rightText: '₹${controller.totalSavings.toStringAsFixed(2)}',
                        showDiscount: true
                    ),
                  ],
                ),
              ),

              SizedBox(height: SizeConfig.size10),

              // Grand Total Box
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
                          AppStrings.grandTotalPayInINR,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryTextColor,
                        ),
                        CustomText(
                          '₹${controller.totalSellingPrice.toStringAsFixed(2)}',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                        ),
                      ],
                    ),
                  )
              ),
            ],
          )
      );
    });
  }

  Widget _commonIconTextRow({
    required String imagePath,
    required String leftText,
    required String rightText,
    EdgeInsetsGeometry padding = const EdgeInsets.all(10.0),
    bool showDiscount = false
  }) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          LocalAssets(imagePath: imagePath),

          SizedBox(width: SizeConfig.size8),

          (!showDiscount)
              ? Expanded(
            child: CustomText(
              leftText,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
            ),
          ) : Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  leftText,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                ),
                SizedBox(width: SizeConfig.size10),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size5,
                      vertical: SizeConfig.size2
                  ),
                  decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(2.0)
                  ),
                  child: CustomText(
                    '${controller.totalDiscountPercentage.toStringAsFixed(2)}%',
                    fontSize: SizeConfig.extraSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                )
              ],
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