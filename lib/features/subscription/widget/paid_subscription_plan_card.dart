import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/subscription/auth/controller/subscription_controller.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_list_details_model.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_plan_style_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaidSubscriptionPlanCard extends StatelessWidget {
  final SubscriptionPlanData details;
  final int index;
  final SubscriptionController controller;
  final SubscriptionPlanStyleModel style;
  final String tagText;

  const PaidSubscriptionPlanCard({
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
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _priceBlock(),
                SizedBox(
                  width: SizeConfig.screenWidth * 0.07,
                ),
                Expanded(
                    child: _features()),
              ],
            ),
          ),
        ),

        /// Tag
        // Positioned(
        //   left: 36,
        //   top: 16,
        //   child: _planTag(),
        // ),
      ],
    );
  }

  Widget _background() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: LocalAssets(
        imagePath: style.bg,
        height: SizeConfig.screenHeight * 0.21,
        width: double.infinity,
        boxFix: BoxFit.fill,
      ),
    );
  }

  Widget _priceBlock() {
    return Container(
      // color: Colors.yellow,
      width: SizeConfig.screenWidth * 0.25,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// Tag
          _planTag(),
          // const SizedBox(height: 16),

          /// Amount
          FittedBox(
            child: CustomText(
              "₹${details.amount != null ? (details.amount! / 100) : '0'}",
              fontSize:
              (details.amount.toString().length) > 3
                  ? 24
                  : 36,
              fontWeight: FontWeight.w700,
              color: style.color,
              textAlign: TextAlign.center,
            ),
          ),

          /// period
          FittedBox(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CustomText(
                details.period?.capitalizeFirst ?? "",
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
                color: AppColors.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _features() {
    return Builder(
        builder: (context) {

          int perkCount = details.perks?.length ?? 0;
          double _bottomPadding = perkCount < 5 ? 12.0 : (perkCount < 7 ? 8.0 : 4.0);

          return FittedBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                /// Description
                _featureItem(
                    details.description == '' || details.description == null
                        ? "N/A"
                        : details.description??'',
                    bottomPadding: _bottomPadding
                ),

                /// Perks
                ...details.perks?.map(
                      (e) => _featureItem(
                      e == '' ? "N/A" : e,
                      bottomPadding: _bottomPadding
                  ),
                ) ??
                    [],
                
              ],
            ),
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
          CustomText(
            text,
            fontSize: 12,
            maxLines: 1,
            fontWeight: FontWeight.w400,
            color: style.color,
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
        color: AppColors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
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


