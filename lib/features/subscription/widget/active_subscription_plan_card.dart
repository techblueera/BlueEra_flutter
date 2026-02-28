import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/date_time_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/subscription/auth/controller/subscription_controller.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_list_details_model.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_plan_style_model.dart';
import 'package:BlueEra/features/subscription/auth/model/user_subscription_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class ActiveSubscriptionCard extends StatefulWidget {
  final UserSubscription? userSubscription;
  final int index;
  final SubscriptionController controller;
  final SubscriptionPlanStyleModel style;

  const ActiveSubscriptionCard({
    Key? key,
    required this.userSubscription,
    required this.index,
    required this.controller,
    required this.style,
  }) : super(key: key);

  @override
  State<ActiveSubscriptionCard> createState() => _ActiveSubscriptionCardState();
}

class _ActiveSubscriptionCardState extends State<ActiveSubscriptionCard> {

  late SubscriptionPlanData? _details;
  late bool _isSubscribed;
  late String _validUpTo;

  @override
  initState(){
    super.initState();
    _details = widget.userSubscription?.subscriptionPlanData;
    _isSubscribed = widget.userSubscription?.isSubscribed ?? false;
    _validUpTo = widget.userSubscription?.validUpto ?? '';
  }

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
        imagePath: widget.style.bg,
        height: SizeConfig.screenHeight * 0.21,
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
            FittedBox(
              child: CustomText(
                "₹${_details?.amount != null ? (_details!.amount! / 100) : '0'}",
                fontSize:
                (_details?.amount.toString().length ?? 0) > 3
                    ? 24
                    : 36,
                fontWeight: FontWeight.w700,
                color: widget.style.color,
                textAlign: TextAlign.center,
              ),
            ),

           Container(
             decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(10.0),
               border: Border.all(
                 color: widget.style.color.withValues(alpha: 0.1),
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
                   color: widget.style.color,
                   textAlign: TextAlign.center,
                 ),
                 SizedBox(height: SizeConfig.size4),
                 CustomText(
                   "25 Rides",
                   fontSize: SizeConfig.small,
                   fontWeight: FontWeight.w600,
                   color: widget.style.color,
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
              color: widget.style.color,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: CustomText(
                'Valid Up to : ${formatISO8601Date(_validUpTo)}',
                fontSize: 12,
                maxLines: 1,
                fontWeight: FontWeight.w400,
                color: widget.style.color,
              ),
            ),
          ],
        ),

        SizedBox(height: SizeConfig.paddingXSL),

        Container(
          padding: EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: (_isSubscribed)
                ? AppColors.blueLight.withValues(alpha: 0.1)
                : AppColors.redLight.withValues(alpha: 0.1),
            border: Border.all(
              color: (_isSubscribed)
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
                 'Balance: ₹${_details?.amount != null ? (_details!.amount! / 100) : '0'}',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: _isSubscribed ? widget.style.color : AppColors.redLight
              ),
              CustomText(
                _isSubscribed ? 'Active' : 'In-Active',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                color: _isSubscribed ? widget.style.color : AppColors.redLight
              ),
            ],
          ),
        ),

        if(!_isSubscribed)
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
        color: widget.style.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6.0),
        boxShadow: [
          BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: Offset(0, 2)
          ),
        ],
      ),
      child: CustomText(
        _details?.tier ?? 'Basic',
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w600,
        color: widget.style.color,
      ),
    );
  }
}


