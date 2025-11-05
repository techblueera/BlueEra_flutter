import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/order_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_enum.dart';

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
          Expanded(
            child: Obx(() {
              switch (controller.selectedPickUp.value) {
                case PickUpTab.newOrder || PickUpTab.onGoing:
                  return _buildOrder();

                case PickUpTab.completed:
                  return CustomText(
                      'Coming Soon..'
                  );
                  // return CompletedPickupOrderScreen();

                case PickUpTab.cancel:
                  return CustomText(
                    'Coming Soon..'
                  );
                  // return CancelledPickupOrderScreen();

                case PickUpTab.rejected:
                  return CustomText(
                      'Coming Soon..'
                  );
                  // return RejectedPickupOrderScreen();
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _filterButtons() {
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
                  },
                  child: CustomText(
                    tab.label,
                    decoration: TextDecoration.underline,
                    color: isSelected ? Colors.blue : Colors.black54,
                    decorationColor: isSelected ? Colors.blue : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrder(){
    return ListView.builder(
        itemCount: 5,
        padding: EdgeInsets.only(
            top: SizeConfig.size10,
            bottom: kBottomNavigationBarHeight + SizeConfig.size40,
            left: SizeConfig.size15,
            right: SizeConfig.size15
        ),
        itemBuilder: (context, index){
          return OrderCard(
              selectedPickUp: controller.selectedPickUp.value
          );
        }
    );
  }

}
