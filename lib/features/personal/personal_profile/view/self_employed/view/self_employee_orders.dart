import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_employee_new_orders.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelfEmployeeOrders extends StatefulWidget {
  const SelfEmployeeOrders({super.key});

  @override
  State<SelfEmployeeOrders> createState() => _SelfEmployeeOrdersState();
}

class _SelfEmployeeOrdersState extends State<SelfEmployeeOrders>  {
  final controller = getOrPut(() => EarnServiceController());
  // final deliveryPartnerController = getOrPut(() => DeliveryPartnerController());

  // @override
  // void initState() {
  //   if (deliveryPartnerController.riderVerificationState == RiderVerificationState.completed) {
  //     controller.fetchStream();
  //   }
  //   super.initState();
  // }
  //
  // @override
  // void dispose() {
  //   if (deliveryPartnerController.riderVerificationState == RiderVerificationState.completed){
  //     controller.subscription?.cancel();
  //   }
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Obx(()=> Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.size15,
                  horizontal: SizeConfig.size8,
              ),
              child: HorizontalTabSelector(
                tabs: controller.earnServiceOrdersTabs,
                selectedIndex: controller
                    .selectedEarnServiceOrderIndex.value,
                onTabSelected: (index, value) {
                  if (mounted) {
                    controller.selectedEarnServiceOrderIndex.value =
                        index;
                  }
                },
                labelBuilder: (value) => value.label,
                unSelectedBackgroundColor: AppColors.white,
              ),
            ),

            Expanded(
              child: Builder(
                builder: (context) {
                  switch (controller.selectedEarnServiceOrderIndex
                      .value) {
                    case 0:
                      return SelfEmployeeNewOrders();
                    case 1:
                      return Center(child: CustomText(AppStrings.comingSoon));
                  // return EarnServiceCompletedOrderScreen();
                    case 2:
                      return Center(child: CustomText(AppStrings.comingSoon));
                  // return EarnServiceCancelledOrderScreen();
                    default:
                      return SizedBox.shrink(); // fallback
                  }
                },
              ),
            ),
          ],
        ));
  }

  void showStatusDialog(BuildContext context, String title, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: CustomText(title),
          content: CustomText(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: CustomText(AppStrings.ok),
            ),
          ],
        ),
      );
    });
  }


}
