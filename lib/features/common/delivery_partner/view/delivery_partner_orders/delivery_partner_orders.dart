
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/delivery_partner_orders/pickup_order_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';



class DeliveryPartnerOrders extends StatefulWidget {
  const DeliveryPartnerOrders({super.key});

  @override
  State<DeliveryPartnerOrders> createState() => _DeliveryPartnerOrdersState();
}

class _DeliveryPartnerOrdersState extends State<DeliveryPartnerOrders>  {
  final controller = Get.put(DeliverPartnerOrdersController());


  @override
  void initState() {
    controller.fetchStream();
    super.initState();
  }
  @override
  void dispose() {
    controller.subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteFE,
      body: Obx(()=> Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Padding(
            padding: EdgeInsets.all(SizeConfig.size15),
            child: HorizontalTabSelector(
              tabs: controller.deliveryPartnerOrdersTabs,
              selectedIndex: controller.selectedDeliveryPartnerOrderIndex.value,
              onTabSelected: (index, value) {
                if (mounted) {
                  controller.selectedDeliveryPartnerOrderIndex.value = index;
                }
              },
              labelBuilder: (value) => value.label,
            ),
          ),
          SizedBox(height: SizeConfig.size16),
          Expanded(
            child: Builder(
              builder: (context) {
                switch (controller.selectedDeliveryPartnerOrderIndex.value) {
                  case 0:
                    return PickupOrderScreen();
                  case 1:
                    return CustomText('Coming Soon...');
                // return GroceryOrderScreen();
                  case 2:
                    return CustomText('Coming Soon...');
                // return ParcelOrderScreen();
                  case 3:
                    return CustomText('Coming Soon...');
                // return IncomeScreen();
                  default:
                    return SizedBox.shrink(); // fallback
                }
              },
            ),
          ),
        ],
      ))
    );
  }
}
