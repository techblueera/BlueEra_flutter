import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/subscription/auth/controller/subscription_controller.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_list_details_model.dart';
import 'package:BlueEra/features/subscription/widget/free_subscription_plan_card.dart';
import 'package:BlueEra/features/subscription/widget/subscription_banner_video.dart';
import 'package:BlueEra/features/subscription/widget/subscription_payment_handler.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FreeTrialPlanScreen extends StatelessWidget {
  final SubscriptionController controller;

  FreeTrialPlanScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {

    return Obx(() {
      if (controller.getSubscriptionPlanResponse.value.status ==
          Status.COMPLETE) {

        List<SubscriptionPlanData>? subsList = controller
            .subscriptionPlanDetailsNewModel.value.data;
        return SingleChildScrollView(
          padding: EdgeInsets.only(
              left: SizeConfig.size8,
              right: SizeConfig.size8,
              top: SizeConfig.size15,
              bottom: SizeConfig.size40,
          ),
          child: Column(
            children: [
              SubscriptionBannerVideo(
                videoUrl: controller
                    .subscriptionPlanDetailsNewModel.value.bannerVideoUrl??''
              ),
              SizedBox(height: SizeConfig.paddingXSL),
              CustomFormCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                itemCount: subsList?.length ?? 0,
                physics: NeverScrollableScrollPhysics(),
                primary: false,
                shrinkWrap: true,
                padding: EdgeInsets.all(SizeConfig.size10),
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  SubscriptionPlanData? details = subsList?[index];

                  int styleIndex = index % AppConstants.listOfSubsBg.length;

                  return GestureDetector(
                    onTap: () {
                      if(controller.selectedSubscriptionIndex.contains(index)) return;
                      controller.selectedSubscriptionIndex.clear();
                      controller.selectedSubscriptionIndex.add(index);
                      print('final amount to pay -- ${controller.finalAmount}');
                    },
                    child: FreeTrialSubscriptionCard(
                      details: details,
                      index: index,
                      controller: controller,
                      style: AppConstants.listOfSubsBg[styleIndex],
                      tagText: details?.tier ?? "Basic",
                    ),
                  );
                },
                                ),
              ),

              (controller.selectedSubscriptionIndex.isNotEmpty)
                  ? Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 30),
                child: Column(
                  children: [
                    // CustomBtn(
                    //   width: double.infinity,
                    //   textColor: AppColors.red,
                    //   bgColor: Colors.transparent,
                    //   borderColor: AppColors.red,
                    //   title: "Cancel",
                    //   onTap: () async {
                    //     SubscriptionPlanData?
                    //     subscriptionPlanData = controller
                    //         .subscriptionPlanDetailsNewModel
                    //         .value
                    //         .data?[controller.selectedSubscriptionIndex.first];
                    //
                    //     await controller
                    //         .cancelSubscriptionController(
                    //         params: {
                    //           ApiKeys.subscriptionId: subscriptionPlanData?.id,
                    //           ApiKeys.cancel_at_cycle_end: true,
                    //         });
                    //     if (controller
                    //         .cancelSubscriptionResponse
                    //         .value
                    //         .status ==
                    //         Status.COMPLETE) {
                    //
                    //       controller.mySubscriptionAvailable.value = false;
                    //
                    //     }
                    //   },
                    // ),
                    // SizedBox(height: SizeConfig.paddingXSL),
                    CustomBtn(
                      width: double.infinity,
                      textColor: AppColors.white,
                      bgColor: AppColors.primaryColor,
                      title: "Pay",
                      onTap: () {
                        final handler = SubscriptionPaymentHandler(controller);
                        handler.processSubscription();
                      },
                    )
                  ],
                ),
              )
                  : SizedBox(),
            ],
          ),
        );
      } else {
        return Center(
          child: CircularProgressIndicator(),
        );
      }
    });
  }


}