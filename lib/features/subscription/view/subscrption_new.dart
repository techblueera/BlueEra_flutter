import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/date_time_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/subscription/view/paid_subscription_plans_screen.dart';
import 'package:BlueEra/features/subscription/view/free_trial_plans_screen.dart';
import 'package:BlueEra/features/subscription/widget/free_subscription_plan_card.dart';
import 'package:BlueEra/features/subscription/widget/paid_subscription_plan_card.dart';
import 'package:BlueEra/features/subscription/widget/subscription_banner_video.dart';
import 'package:BlueEra/features/subscription/widget/subscription_payment_handler.dart';
import 'package:BlueEra/features/subscription/widget/welcome_subscription_offer_text.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:get/get.dart';
import '../../../core/api/apiService/api_response.dart';
import '../../../core/constants/getx_utils.dart';
import '../auth/controller/subscription_controller.dart';

class SubscriptionScreenNew extends StatefulWidget {
  const SubscriptionScreenNew({super.key});

  @override
  State<SubscriptionScreenNew> createState() => _SubscriptionScreenNewState();
}

class _SubscriptionScreenNewState extends State<SubscriptionScreenNew> with SingleTickerProviderStateMixin{

  final controller = getOrPut(() => SubscriptionController());

  @override
  void initState() {
    super.initState();
    getInitial();
    controller.subscriptionPlansGetApi();
  }

  void getInitial() {
    controller.userCurrentPlanApi(
        params: {
      // ApiKeys.status: AppConstants.active
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(
          appBarColor: AppColors.white,
          title: "Contribution"
          // title: "Subscription"
      ),

      body: Obx(() {
        if(controller.userSubscriptionResponse.value == Status.INITIAL){
          return Center(child: CircularProgressIndicator());
        }

        if(controller.userSubscriptionResponse.value == Status.ERROR){
          return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  LocalAssets(imagePath: AppIconAssets.warningRedIcon),
                  SizedBox(height: SizeConfig.paddingXSL),
                  CustomText(
                    "oops.. something went wrong.",
                    fontSize: SizeConfig.extraLarge22,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                  ),
                ]
            ),
          );
        }

        return _buildSubscriptionBody();

      }),
    );
  }

  Widget _buildSubscriptionBody() {
    // 1. Handle the Empty State First
    if (controller.currentPlansList.isEmpty) {
      return FreeTrialPlanScreen(controller: controller);
    }

    // 2. Extract the status for readability
    final String status = controller.currentPlansList.first.status;
    final bool isTrial = controller.currentPlansList.first.isTrial;

    // 3. Use a Switch for different subscription states
    switch (status) {
      case 'created':
        if(isTrial)
        return _buildFreeTrialPlanList();
        else
        return _buildPaidPlanList();

      case 'authenticated':
      // Free trial period widget
      return _buildFreeTrialActivateWidget();

      case 'active':
      case 'cancelled':
      case 'paused':
      case 'halted':
      return PaidSubscriptionPlansScreen(
        controller: controller
      );

      default:
        return FreeTrialPlanScreen(controller: controller);
    }
  }

  Widget _buildFreeTrialPlanList() {
    // Guard check to ensure the list isn't empty before accessing .first
    if (controller.currentPlansList.isEmpty) {
      return const Center(child: CustomText("No active trial plans found."));
    }

    // Directly access the single created plan
    final currentPlan = controller.currentPlansList.first;
    final details = currentPlan.subscriptionPlanData;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: SizeConfig.size8,
        right: SizeConfig.size8,
        top: SizeConfig.size15,
        bottom: SizeConfig.size40,
      ),
      child: Column(
        children: [
          // 1. Banner Video
          SubscriptionBannerVideo(
              videoUrl: controller.subscriptionPlanDetailsNewModel.value.bannerVideoUrl ?? ''
          ),

          SizedBox(height: SizeConfig.paddingXSL),

          // 2. Single Plan Card (Removed ListView)
          CustomFormCard(
            padding: EdgeInsets.all(SizeConfig.size10),
            child: Column(
              children: [

                WelcomeSubscriptionOfferText(),

                SizedBox(height: SizeConfig.paddingXSL),

                FreeTrialSubscriptionCard(
                  details: details,
                  index: 0, // Explicitly the first index
                  controller: controller,
                  style: AppConstants.listOfSubsBg[0],
                  tagText: details.tier ?? "Basic",
                ),
              ],
            ),
          ),

          SizedBox(height: SizeConfig.paddingL),

          CustomBtn(
            width: double.infinity,
            textColor: AppColors.red,
            bgColor: AppColors.white,
            borderColor: AppColors.red,
            title: "Cancel Subscription",
            onTap: () {
              controller.cancelSubscriptionController(params: {
                'subscriptionId': currentPlan.subscriptionId,
                'cancel_at_cycle_end': true,
              });
            },
          ),

          SizedBox(height: SizeConfig.paddingXSL),

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
    );
  }

  Widget _buildPaidPlanList() {
    // 1. Guard check to ensure a plan actually exists
    if (controller.currentPlansList.isEmpty) {
      return const Center(
          child: CustomText("No active plan details found.")
      );
    }

    // 2. Directly access the single current plan
    final currentPlan = controller.currentPlansList.first;
    final details = currentPlan.subscriptionPlanData;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: SizeConfig.size8,
        right: SizeConfig.size8,
        top: SizeConfig.size15,
        bottom: SizeConfig.size40,
      ),
      child: Column(
        children: [
          // Banner Video Header
          SubscriptionBannerVideo(
              videoUrl: controller.subscriptionPlanDetailsNewModel.value.bannerVideoUrl ?? ''
          ),

          SizedBox(height: SizeConfig.paddingXSL),

          // Single Paid Plan Display (Replaced ListView)
          CustomFormCard(
            padding: EdgeInsets.all(SizeConfig.size10),
            child: PaidSubscriptionPlanCard(
              details: details,
              index: 0, // Explicitly the first item
              controller: controller,
              style: AppConstants.listOfSubsBg[0],
              tagText: details.tier ?? "Basic",
            ),
          ),

          CustomBtn(
            width: double.infinity,
            textColor: AppColors.red,
            bgColor: AppColors.white,
            borderColor: AppColors.red,
            title: "Cancel Subscription",
            onTap: () {
              controller.cancelSubscriptionController(params: {
                'subscriptionId': currentPlan.subscriptionId,
                'cancel_at_cycle_end': true,
              });
            },
          ),

          SizedBox(height: SizeConfig.paddingXSL),

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
    );
  }

  Widget _buildFreeTrialActivateWidget(){
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomText(
                  "Congratulations",
                  fontSize: SizeConfig.extraLarge22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.paddingM),
                CustomText(
                  "Enjoying Premium? Your 7-day free trial is currently active!",
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                ),
                SizedBox(height: SizeConfig.size2),
                CustomText(
                  "Start Date - ${formatISO8601Date(controller.currentPlansList.first.trialStart)}",
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                ),
                SizedBox(height: SizeConfig.size2),
                CustomText(
                  "End date - ${formatISO8601Date(controller.currentPlansList.first.trialEnd)}",
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }


  // Widget _buildTabbedPlanView() {
  //   return Column(
  //     children: [
  //       TabBar(
  //         controller: _tabController,
  //         labelColor: AppColors.mainTextColor,
  //         unselectedLabelColor: AppColors.secondaryTextColor,
  //         indicatorColor: AppColors.primaryColor,
  //         indicatorWeight: 4,
  //         tabs: const [
  //           Tab(text: "My Plan"),
  //           Tab(text: "Other Plans"),
  //         ],
  //       ),
  //       Expanded(
  //         child: TabBarView(
  //           controller: _tabController,
  //           children: [
  //             const MySubscriptionDetails(),
  //             // AllSubscriptionPlansWidget(controller: controller),
  //           ],
  //         ),
  //       )
  //     ],
  //   );
  // }


}



