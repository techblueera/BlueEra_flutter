import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/subscription/auth/controller/subscription_controller.dart';
import 'package:BlueEra/features/subscription/auth/model/user_subscription_model.dart';
import 'package:BlueEra/features/subscription/widget/subscription_payment_handler.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubscriptionPayButton extends StatelessWidget {
  final SubscriptionController controller;
  final UserSubscription? currentPlan;

  const SubscriptionPayButton({
    super.key,
    required this.controller,
   this.currentPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.getSubscriptionPlanResponse.value.status == Status.COMPLETE &&
          controller.selectedSubscriptionIndex.isNotEmpty) {

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8,
            vertical: SizeConfig.size15,
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [

                if(currentPlan!=null)
                  ...[
                    CustomBtn(
                      width: double.infinity,
                      textColor: AppColors.red,
                      bgColor: AppColors.white,
                      borderColor: AppColors.red,
                      title: "Cancel Subscription",
                      onTap: () {
                        controller.cancelSubscriptionController(params: {
                          'subscriptionId': currentPlan!.subscriptionId,
                          'cancel_at_cycle_end': true,
                        });
                      },
                    ),

                    SizedBox(height: SizeConfig.paddingXSL),
                  ],


                CustomBtn(
                  width: double.infinity,
                  textColor: AppColors.white,
                  bgColor: AppColors.primaryColor,
                  title: "Pay",
                  onTap: () {
                    final handler = SubscriptionPaymentHandler(controller);
                    handler.showReferralCodeDialog();
                    // handler.processSubscription();
                  },
                ),
              ],
            ),
          ),
        );
      }

      return const SizedBox.shrink();
    });
  }
}