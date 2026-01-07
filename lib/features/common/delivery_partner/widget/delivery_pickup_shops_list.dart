import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/horizontal_tab_selector.dart';
import '../controller/delivery_partner_orders_controller.dart';

class DeliveryPickupShopsList extends StatefulWidget {
  const DeliveryPickupShopsList({super.key, required this.orderId});

  final String orderId;

  @override
  State<DeliveryPickupShopsList> createState() =>
      _DeliveryPickupShopsListState();
}

class _DeliveryPickupShopsListState extends State<DeliveryPickupShopsList> {
  final controller = getOrPut(() => DeliverPartnerOrdersController());

  @override
  void initState() {
    // TODO: implement initState
    controller.getGroceryShopsList(widget.orderId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      print("lsdkcmlskdcm ${controller.orderRiderShopListResponse.value.status}");
      return Scaffold(
        appBar: CommonBackAppBar(
          orderAcceptBgColor: AppColors.redLite.withValues(alpha: 0.1),
          orderAcceptBorderColor: AppColors.redLite,
          orderAcceptTextColor: AppColors.redLite,
          orderAcceptText: AppStrings.reject,
          onTabAcceptBtn: () {

          },
          isShowAcceptOrRejectBtn: true,
          title: "Items",
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                child: HorizontalTabSelector(horizontalMargin: 0,
                  tabs: ["Suggested", "Cheapest", "Nearest", "Manually"],
                  selectedIndex: 0,
                  onTabSelected: (index, value) {
                    // if (mounted) {
                    //   controller.selectedDeliveryPartnerOrderIndex
                    //       .value = index;
                    // }
                  },
                  labelBuilder: (value) => value,
                ),
              ),
              if(controller.orderRiderShopListResponse.value.status==Status.COMPLETE)
                if(controller.riderBusinessList.value.businesses.isNotEmpty)
                  Expanded(
                  child: ListView.builder(itemCount: controller.riderBusinessList.value.businesses.length,
                    itemBuilder: (BuildContext context,
                        int index,) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.whiteFE,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: EdgeInsets.all(10),
                        child: Row(mainAxisAlignment: MainAxisAlignment
                            .spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 40,
                                  width: 40,
                                ),
                                SizedBox(width: SizeConfig.size10,),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      "Gupta General Store",
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    SizedBox(height: SizeConfig.size6,),
                                    CustomText(
                                      "10 Items Available  ₹ 600 Price",
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ],
                                )
                              ],
                            ),
                            Container(
                              height: 24,
                              width: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: AppColors.black.withOpacity(0.4),
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                height: 12,
                                width: 12,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white),
                                  // color: AppColors.primaryColor
                                ),
                                // child: isSelected
                                //     ? Center(
                                //   child: const Icon(
                                //     Icons.check,
                                //     color: Colors.white,
                                //     size: 12,
                                //   ),
                                // )
                                //     : null,
                              ),
                            )
                          ],),
                      );
                    },

                  ),
                )
                  else
                    Center(
                      child: CustomText("No Shops Found in This Product"),
                    )
              else
                Center(
                  child: CircularProgressIndicator(),
                )
            ],
          ),
        ),
      );
    });
  }
}
