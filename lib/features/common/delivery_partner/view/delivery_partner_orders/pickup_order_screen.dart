import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
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
  final controller = getOrPut(() => DeliverPartnerOrdersController());

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
                      if(controller.selectedPickUp.value != PickUpTab.newOrder && controller.selectedPickUp.value != PickUpTab.onGoing&& controller.selectedPickUp.value != PickUpTab.rejected){
                        controller.getRidersBookingOrders();
                      }else if(controller.selectedPickUp.value == PickUpTab.rejected){
                        controller.getRiderRejectOrderList();
                      }
                    },
                    child: CustomText(
                      tab.label,
                      decoration: TextDecoration.underline,
                      color: isSelected ? AppColors.primaryColor : AppColors.secondaryTextColor,
                      decorationColor:
                          isSelected ? AppColors.primaryColor : AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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
    final groupedOrders = groupOrdersByOrderFor(ordersList);
    final orderForKeys = groupedOrders.keys.toList();

    return
      ordersList.isEmpty
        ? Center(
      child: CustomText(AppStrings.noOrdersFound),
    )
        : ListView.builder(
        padding: EdgeInsets.only(
          top: SizeConfig.size10,
          bottom: kBottomNavigationBarHeight + SizeConfig.size40,
          left: SizeConfig.size15,
          right: SizeConfig.size15,
        ),
        itemCount: orderForKeys.length,
        itemBuilder: (context, index) {
          final orderFor = orderForKeys[index];
          final orders = groupedOrders[orderFor]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 TITLE
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: CustomText(
                  getOrderForTitle(orderFor),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                ),
              ),

              /// 🔹 LIST UNDER TITLE
              ...orders.map((rider) {
                return OrderCard(
                  order: rider,
                  selectedPickUp: controller.selectedPickUp.value,
                );
              }).toList(),
            ],
          );
        },
      );
    ;
  }
  Map<String, List<RiderOrdersDetailsModel>> groupOrdersByOrderFor(
      List<RiderOrdersDetailsModel> orders) {
    final Map<String, List<RiderOrdersDetailsModel>> grouped = {};

    for (var order in orders) {
      final key = order.orderFor ?? 'unknown';

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(order);
    }

    return grouped;
  }
  String getOrderForTitle(String orderFor) {
    switch (orderFor) {
      case 'product':
        return 'PRODUCT';
      case 'grocery':
        return 'GROCERY';
      case 'food':
        return 'FOOD';
      case 'medical':
        return 'MEDICAL';
      case 'InCity':
        return 'PASSENGER';
      case 'OutStation':
        return 'PASSENGER';
      case 'HourlyRental':
        return 'HOURLY RENTAL';
      case 'Parcel':
        return 'PARCEL';
      default:
        return orderFor.toUpperCase();
    }
  }

}
