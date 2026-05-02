import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_order_model.dart';
import 'package:BlueEra/features/me/grocery/controller/my_grocery_order_controller.dart';
import 'package:BlueEra/features/me/grocery/view/my_grocery_orders/grocery_order_card.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyGroceryPendingScreen extends StatefulWidget {
  const MyGroceryPendingScreen({super.key});

  @override
  State<MyGroceryPendingScreen> createState() => _MyGroceryPendingScreenState();
}

class _MyGroceryPendingScreenState extends State<MyGroceryPendingScreen> {
  final controller = getOrPut(() => MyMedicalOrdersController());

  @override
  void initState() {
    controller.fetchGroceryOrders(
        groceryOrderStatus: 'inprogress'
    );
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(()=> controller.groceryPendingOrders.isEmpty
          ? Center(
        child: EmptyStateWidget(message: AppStrings.groceryViewYouHaveNoOrders.tr),
      )
          :  ListView.builder(
          itemCount: controller.groceryPendingOrders.length,
          padding: EdgeInsets.only(
              top: SizeConfig.size10,
              bottom: kBottomNavigationBarHeight + SizeConfig.size40,
              left: SizeConfig.size15,
              right: SizeConfig.size15),
          itemBuilder: (context, index) {
            GroceryOrdersModel pendingOrder = controller.groceryPendingOrders[index];
            return GroceryOrderCard(
              order: pendingOrder,
            );
          })),

    );
  }
}
