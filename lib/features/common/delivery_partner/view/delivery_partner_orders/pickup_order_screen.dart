import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/order_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/app_enum.dart';
import '../../../../chat/auth/model/rider_orders_details_model.dart';

class PickupOrderScreen extends StatefulWidget {
  const PickupOrderScreen({super.key});

  @override
  State<PickupOrderScreen> createState() => _PickupOrderScreenState();
}

class _PickupOrderScreenState extends State<PickupOrderScreen> {
  final controller = Get.isRegistered<DeliverPartnerOrdersController>()
      ? Get.find<DeliverPartnerOrdersController>()
      : Get.put(DeliverPartnerOrdersController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filterButtons(),
          _buildTabViews(),
        ],
      ),
    );
  }

  Widget _filterButtons() {
    return Obx(() {
      return SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size15),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            LocalAssets(imagePath: AppIconAssets.channelFilterIcon),
            SizedBox(width: SizeConfig.size10),
            Row(
              children: controller.pickUpTabs.map((tab) {
                final isSelected = controller.selectedPickUp.value == tab;
                return Padding(
                  padding: EdgeInsets.only(right: SizeConfig.size14),
                  child: GestureDetector(
                    onTap: () {
                      controller.selectedPickUp.value = tab;
                      print("lsdkmclksdmc ${controller.selectedPickUp.value != PickUpTab.newOrder && controller.selectedPickUp.value != PickUpTab.onGoing}");
                      if(controller.selectedPickUp.value != PickUpTab.newOrder && controller.selectedPickUp.value != PickUpTab.onGoing){
                        controller.getRidersBookingOrders();
                      }
                    },
                    child: CustomText(
                      tab.label,
                      decoration: TextDecoration.underline,
                      color: isSelected ? Colors.blue : Colors.black54,
                      decorationColor:
                          isSelected ? Colors.blue : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTabViews(){
    return Expanded(
      child: Obx(() {
        if (controller.ordersListResponse.value.status ==
            Status.COMPLETE) {
          switch (controller.selectedPickUp.value) {

            case PickUpTab.newOrder:
              return _buildOrderList(controller.newOrders);

            case PickUpTab.onGoing:
              return _buildOrderList(controller.onGoingOrders);

            case PickUpTab.completed:
              return _buildOrderList(controller.completedOrders);

            case PickUpTab.cancel:
              return _buildOrderList(controller.cancelledOrders);

            case PickUpTab.rejected:
              return _buildOrderList(controller.rejectedOrders);
          }
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      }),
    );
  }

  Widget _buildOrderList(List<RiderOrdersDetailsModel> ordersList) {
    return
      ordersList.isEmpty
        ? Center(
      child: CustomText("No Orders Found"),
    )
        : ListView.builder(
        itemCount: ordersList.length,
        padding: EdgeInsets.only(
            top: SizeConfig.size10,
            bottom: kBottomNavigationBarHeight + SizeConfig.size40,
            left: SizeConfig.size15,
            right: SizeConfig.size15),
        itemBuilder: (context, index) {
          RiderOrdersDetailsModel rider = ordersList[index];
          return OrderCard(
              order: rider,
              selectedPickUp: controller.selectedPickUp.value);
        });
  }

  // Widget _buildCancelled(List<RiderOrdersDetailsModel> ordersList) {
  //   return ordersList.isEmpty
  //       ? Center(
  //     child: CustomText("No Orders Found"),
  //   )
  //       : ListView.builder(
  //       itemCount: ordersList.length,
  //       padding: EdgeInsets.only(
  //           top: SizeConfig.size10,
  //           bottom: kBottomNavigationBarHeight + SizeConfig.size40,
  //           left: SizeConfig.size15,
  //           right: SizeConfig.size15),
  //       itemBuilder: (context, index) {
  //         RiderOrdersDetailsModel rider = ordersList[index];
  //         return OrderCard(
  //             order: rider,
  //             selectedPickUp: controller.selectedPickUp.value);
  //       });
  // }
}
