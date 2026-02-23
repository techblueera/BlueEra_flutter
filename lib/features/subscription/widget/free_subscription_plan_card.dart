import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/subscription/auth/controller/subscription_controller.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_list_details_model.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_plan_style_model.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FreeTrialSubscriptionCard extends StatelessWidget {
  final SubscriptionPlanData? details;
  final int index;
  final SubscriptionController controller;
  final SubscriptionPlanStyleModel style;
  final String tagText;

  const FreeTrialSubscriptionCard({
    Key? key,
    required this.details,
    required this.index,
    required this.controller,
    required this.style,
    this.tagText = "BASIC",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Obx(() {
          final isSelected =
          controller.selectedSubscriptionIndex.contains(index);

          return isSelected
              ? Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primaryColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                  AppColors.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _background(),
          )
              : _background();
        }),


        /// Content
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                _priceBlock(),
                SizedBox(
                  width: SizeConfig.screenWidth * 0.07,
                ),
                Expanded(
                    flex: 2,
                    child: _features()),
              ],
            ),
          ),
        ),

        /// Tag
        Positioned(
          top: 0,
          right: 0,
          child: _planTag(),
        ),
      ],
    );
  }

  Widget _background() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: LocalAssets(
        imagePath: style.bg,
        height: SizeConfig.screenHeight * 0.2,
        width: double.infinity,
        boxFix: BoxFit.fill,
      ),
    );
  }

  Widget _priceBlock() {
    return Container(
      width: SizeConfig.screenWidth * 0.25,
      child: Container(
        height: SizeConfig.screenHeight * 0.2 - 20,
        padding: EdgeInsets.all(SizeConfig.size10),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.4)
          )
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size6,
                  vertical: SizeConfig.size2
              ),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: AppColors.white.withValues(alpha: 0.4),
                  boxShadow: [
                    BoxShadow(
                        color: Color(0xFFACC6FE),
                        blurRadius: 3,
                        offset: Offset(0, 1)
                    )
                  ]
              ),
              child: CustomText(
                'Join Now',
                fontSize: SizeConfig.extraSmall,
                fontWeight: FontWeight.w600,
                color: style.color,
              ),
            ),

            SizedBox(
              height: SizeConfig.screenHeight * 0.004,
            ),

            CustomText(
              '₹1',
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: style.color,
            ),

            SizedBox(
              height: SizeConfig.screenHeight * 0.002,
            ),

            CustomText(
              '7 Days',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),

            SizedBox(
              height: SizeConfig.screenHeight * 0.007,
            ),

            CommonHorizontalDivider(
              color: AppColors.white.withValues(alpha: 0.4),
            ),

            SizedBox(
              height: SizeConfig.screenHeight * 0.007,
            ),

            /// Amount & period

            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "₹${details?.amount != null ? (details!.amount! / 100).toStringAsFixed(0) : '0'}",
                    style: TextStyle(
                      fontSize: (details?.amount.toString().length ?? 0) > 3
                          ? SizeConfig.large
                          : SizeConfig.extraLarge22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                  TextSpan(
                    text: " /${details?.period ?? ""}",
                    style: TextStyle(
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: SizeConfig.screenHeight * 0.003,
            ),

            Text.rich(
              TextSpan(
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.secondaryTextColor
                ),
                children: [
                  TextSpan(
                    text: "₹${details?.amountBeforeDiscount != null ? (details!.amountBeforeDiscount! / 100).toStringAsFixed(0) : '0'}",
                    style: TextStyle(
                      fontSize: (details?.amountBeforeDiscount.toString().length ?? 0) > 3
                          ? SizeConfig.large
                          : SizeConfig.extraLarge22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                  TextSpan(
                    text: " /${details?.period ?? ""}",
                    style: TextStyle(
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),


          ],
        ),
      ),
    );
  }

  Widget _features() {
    return Builder(
        builder: (context) {

          int perkCount = details?.perks?.length ?? 0;
          double _bottomPadding = perkCount < 5 ? 12.0 : (perkCount < 7 ? 8.0 : 4.0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // CustomText(
              //   "Features",
              //   fontSize: 16,
              //   fontWeight: FontWeight.w600,
              //   color: style.textColor,
              // ),
              // const SizedBox(height: 6),

              /// Description
              _featureItem(
                  details?.description == '' || details?.description == null
                      ? "N/A"
                      : details!.description??'',
                  bottomPadding: _bottomPadding
              ),

              /// Perks
              ...details?.perks?.map(
                    (e) => _featureItem(
                    e == '' ? "N/A" : e,
                    bottomPadding: _bottomPadding
                ),
              ) ??
                  [],
            ],
          );
        }
    );
  }

  Widget _featureItem(String text, {required double bottomPadding}) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14,
            color: style.color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: CustomText(
              text,
              fontSize: 12,
              maxLines: 1,
              fontWeight: FontWeight.w400,
              color: style.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planTag() {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(6),
            topRight: Radius.circular(6),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: Offset(0, 2)
          ),
        ],
      ),
      child: CustomText(
        tagText.toUpperCase(),
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w600,
        color: style.color,
      ),
    );
  }
}


