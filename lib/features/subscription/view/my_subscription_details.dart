import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/subscription/view/subscrption_new.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../core/api/apiService/api_keys.dart';
import '../../../core/constants/getx_utils.dart';
import '../auth/controller/subscription_controller.dart';

class MySubscriptionDetails extends StatelessWidget {
  const MySubscriptionDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => SubscriptionController());

    return Column(
      children: [
        const SizedBox(height: 16),

        /// Horizontal Tabs (NOT Sliver)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Obx(() {
            return HorizontalTabSelector(
              tabs: const [
                'Active',
                "Created",
                "Paused",
                "Completed",
                "Expired",
                "Halted",
                "Pending",
                "Canceled",
              ],
              selectedIndex: controller.myPlanSelectedTab.value,
              onTabSelected: (index, val) {
                controller.myPlanSelectedTab.value=index;
                controller.userCurrentPlanApi({
                  ApiKeys.status: val.toLowerCase(),
                });
              },
              labelBuilder: (value) => value,
            );
          }),
        ),


        /// List Area
        Expanded(
          child: Obx(() {
            if (controller.currentPlansList.isEmpty) {
              return const Center(
                child: CustomText("No Subscription Found"),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(
                  left: 8, right: 8, bottom: 30, top: 10),
              itemCount: controller.currentPlansList.length,
              itemBuilder: (context, index) {
                final details =
                    controller.currentPlansList[index].subscriptionPlanId;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: CommonSubscriptionCard(
                    details: details,
                    index: index,
                    controller: controller,
                    style: AppConstants.listOfSubsBg[index],
                    tagText: details.tier ?? "Basic",
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}