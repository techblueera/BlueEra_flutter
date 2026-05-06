import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/grocery/controller/my_grocery_order_controller.dart';
import 'package:BlueEra/features/me/grocery/view/my_grocery_orders/my_grocery_pending_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyGroceryOrders extends StatefulWidget {
  const MyGroceryOrders({super.key});

  @override
  State<MyGroceryOrders> createState() => _MyGroceryOrdersState();
}

class _MyGroceryOrdersState extends State<MyGroceryOrders> {
  final controller = getOrPut(() => MyGroceryOrdersController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Obx(()=> Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Padding(
              padding: EdgeInsets.only(
                  left: SizeConfig.size8,
                  right: SizeConfig.size8,
                  bottom: SizeConfig.size15
              ),
              child: HorizontalTabSelector<MyGroceryOrdersTab>(
                tabs: controller.groceryOrdersTabs,
                selectedIndex: controller.groceryOrdersTabs.indexOf(controller.groceryOrderStatus.value),
                unSelectedBackgroundColor: Colors.white,
                unSelectedBorderColor: AppColors.borderBox,
                onTabSelected: (index, value) {
                  if (mounted) {
                    final selectedGroceryOrderStatus = controller.groceryOrdersTabs[index];

                    if (controller.groceryOrderStatus == selectedGroceryOrderStatus) return;

                    controller.groceryOrderStatus.value = selectedGroceryOrderStatus;
                  }
                },
                labelBuilder: (value) => value.label,
              ),
            ),

            Expanded(
              child: Builder(
                builder: (context) {
                  switch (controller.groceryOrderStatus.value) {
                    case MyGroceryOrdersTab.pending:
                      return MyGroceryPendingScreen();

                    case MyGroceryOrdersTab.completed:
                      return Center(child: CustomText(AppStrings.comingSoon));
                  // return MyGroceryCompletedScreen();

                    case MyGroceryOrdersTab.cancelled:
                      return Center(child: CustomText(AppStrings.comingSoon));
                  // return MyGroceryCancelledScreen();

                    case MyGroceryOrdersTab.payment:
                      return Center(child: CustomText(AppStrings.comingSoon));
                  // return MyGroceryPendingPaymentScreen();

                  }
                },
              ),
            ),

          ],
         )
        )
      );
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
