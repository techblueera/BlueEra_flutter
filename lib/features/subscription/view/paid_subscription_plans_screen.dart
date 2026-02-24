import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/subscription/auth/controller/subscription_controller.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_list_details_model.dart';
import 'package:BlueEra/features/subscription/widget/active_subscription_plan_card.dart';
import 'package:BlueEra/features/subscription/widget/paid_subscription_plan_card.dart';
import 'package:BlueEra/features/subscription/widget/subscription_payment_handler.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaidSubscriptionPlansScreen extends StatelessWidget {
  final SubscriptionController controller;

  const PaidSubscriptionPlansScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // We use Obx here to make the whole screen reactive to controller changes
    return Obx(() {
      return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: SizeConfig.size8,
            right: SizeConfig.size8,
            top: SizeConfig.size15,
            bottom: SizeConfig.size40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 1. Current Active Plans Section
              _buildCurrentPlansSection(),

              SizedBox(height: SizeConfig.paddingS),

              // 2. Available Plans List
              _buildAvailablePlansList(),

              // 3. Bottom Action Button
              _buildPayButton(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCurrentPlansSection() {
    if (controller.userSubscriptionResponse.value.status == Status.LOADING) {
      return _loadingIndicator();
    }

    if (controller.currentPlansList.isEmpty) return const SizedBox();

    // 1. Find the first active plan in the list
    final activePlan = controller.currentPlansList.firstWhereOrNull(
            (plan) => plan.status == 'active'
    );

    // 2. If an active plan exists, show the ActiveSubscriptionCard
    if (activePlan != null) {
      return CustomFormCard(
        padding: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size10),
          child: ActiveSubscriptionCard(
            userSubscription: activePlan,
            index: 0,
            controller: controller,
            style: AppConstants.listOfSubsBg[0],
          ),
        ),
      );
    }

    // 3. Fallback logic for other statuses if no active plan is found
    final String status = controller.currentPlansList.first.status;

    switch (status) {
      case 'cancelled':
      case 'paused':
      case 'halted':
        return _expiredBanner();

      default:
        return Center(
          child: CustomText(
            'No active subscription found.',
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),
        );
    }
  }

  Widget _expiredBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          // Icon
          CircleAvatar(
            backgroundColor: Colors.red.shade100,
            child: Icon(Icons.timer_off_outlined, color: Colors.red.shade700),
          ),
          const SizedBox(width: 12),

          // Text Logic
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 CustomText(
                  "Plan Expired",
                  fontWeight: FontWeight.bold,
                  fontSize: SizeConfig.large,
                  color: AppColors.secondaryTextColor,
                ),
                CustomText(
                  "Recharge now to resume features.",
                  fontSize: SizeConfig.medium,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),

          // Action Button
          CustomText(
              "Recharge Now",
            fontWeight: FontWeight.bold,
            fontSize: SizeConfig.small,
            color: AppColors.red,
          ),
        ],
      ),
    );
  }

  /// Available Plans List
  Widget _buildAvailablePlansList() {
    if (controller.getSubscriptionPlanResponse.value.status == Status.LOADING) {
      return _loadingIndicator();
    }

    final subsList = controller.subscriptionPlanDetailsNewModel.value.data;

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            "Rechange Plans",
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            primary: false,
            itemCount: subsList?.length ?? 0,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final details = subsList?[index];

              return GestureDetector(
                onTap: () {
                  controller.selectedSubscriptionIndex.clear();
                  controller.selectedSubscriptionIndex.add(index);
                },
                child: PaidSubscriptionPlanCard(
                  details: details ?? SubscriptionPlanData(),
                  index: index,
                  controller: controller,
                  style: AppConstants.listOfSubsBg[index % AppConstants.listOfSubsBg.length],
                  tagText: details?.tier ?? "Premium",
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Pay Button logic moved into a separate widget
  Widget _buildPayButton() {
    if (controller.selectedSubscriptionIndex.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 30),
      child: CustomBtn(
        width: double.infinity,
        textColor: AppColors.white,
        bgColor: AppColors.primaryColor,
        title: "Proceed to Pay",
        onTap: () => _handlePaymentProcess(),
      ),
    );
  }

  Future<void> _handlePaymentProcess() async {
    final handler = SubscriptionPaymentHandler(controller);
    handler.processSubscription();
    }

  /// Custom Circular Indicator
  Widget _loadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          strokeWidth: 3,
        ),
      ),
    );
  }

}






