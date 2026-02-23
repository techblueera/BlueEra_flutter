import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/subscription/auth/controller/subscription_controller.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_list_details_model.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_plan_style_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class ActiveSubscriptionCard extends StatelessWidget {
  final SubscriptionPlanData? details;
  final int index;
  final SubscriptionController controller;
  final SubscriptionPlanStyleModel style;
  final String tagText;

  const ActiveSubscriptionCard({
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
        _background(),

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

            _planTag(),

            /// Amount
            CustomText(
              "₹${details?.amount != null ? (details!.amount! / 100) : '0'}",
              fontSize:
              (details?.amount.toString().length ?? 0) > 3
                  ? 24
                  : 36,
              fontWeight: FontWeight.w700,
              color: style.color,
              textAlign: TextAlign.center,
            ),

           Container(
             decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(10.0),
               border: Border.all(
                 color: style.color.withValues(alpha: 0.1),
               ),
             ),
             padding: EdgeInsets.symmetric(
               horizontal: SizeConfig.size8,
               vertical: SizeConfig.size4
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.center,
               children: [
                 CustomText(
                   "Used:",
                   fontSize: SizeConfig.small,
                   fontWeight: FontWeight.w400,
                   color: style.color,
                   textAlign: TextAlign.center,
                 ),
                 SizedBox(height: SizeConfig.size4),
                 CustomText(
                   "25 Rides",
                   fontSize: SizeConfig.small,
                   fontWeight: FontWeight.w600,
                   color: style.color,
                   textAlign: TextAlign.center,
                 ),
               ],
             ),
           )


          ],
        ),
      ),
    );
  }

  Widget _features() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [

        SizedBox(height: SizeConfig.paddingL),

        Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 14,
              color: style.color,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: CustomText(
                'Valid Up to : ',
                // 'Valid Up to : ${details.}',
                fontSize: 12,
                maxLines: 1,
                fontWeight: FontWeight.w400,
                color: style.color,
              ),
            ),
          ],
        ),

        SizedBox(height: SizeConfig.paddingXSL),

        Container(
          padding: EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: (tagText == "Active")
                ? AppColors.greenLight.withValues(alpha: 0.1)
                : AppColors.redLight.withValues(alpha: 0.1),
            border: Border.all(
              color: (tagText == "Active")
                    ? AppColors.greenLight
                    : AppColors.redLight
            ),
            borderRadius: BorderRadius.circular(10.0),
         ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomText(
                 'Balance: ${details?.amount}',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.redLight
              ),
              CustomText(
                tagText,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                color: AppColors.redLight
              ),
            ],
          ),
        ),

        if(tagText!='Active')
        ...[
          SizedBox(height: SizeConfig.paddingL),
          Align(
            alignment: Alignment.centerRight,
            child: CustomText(
              'Rechange Now',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
            ),
          )
        ]

        
      ],
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


