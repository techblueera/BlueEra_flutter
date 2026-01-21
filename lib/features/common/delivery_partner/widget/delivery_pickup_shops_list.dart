import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/horizontal_tab_selector.dart';
import '../../../chat/auth/model/rider_orders_details_model.dart';
import '../controller/delivery_partner_orders_controller.dart';
import '../model/rider_shops_list_grocery.dart';

class DeliveryPickupShopsList extends StatefulWidget {
  const DeliveryPickupShopsList({super.key, required this.orderId, required this.rideOrderId, required this.order});

  final String orderId;
  final String rideOrderId;
  final RiderOrdersDetailsModel order;

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
    controller.selectedShops.clear();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        appBar: CommonBackAppBar(
          orderAcceptBgColor:controller.selectedShops.isEmpty?
          AppColors.redLite.withValues(alpha: 0.1):AppColors.green0B.withValues(alpha: 0.1),
          orderAcceptBorderColor: controller.selectedShops.isEmpty?AppColors.redLite:AppColors.green0B,
          orderAcceptTextColor: controller.selectedShops.isEmpty?AppColors.redLite:AppColors.green0B,
          orderAcceptText: controller.selectedShops.isEmpty?AppStrings.reject: AppStrings.accept,
          onTabAcceptBtn: () {
            if(controller.selectedShops.isEmpty){
              controller.rejectOrder(widget.rideOrderId);
            }else{
              controller.acceptOrder(widget.rideOrderId);
              // controller.makeGroceryOrderConversationApi(orderId: widget.rideOrderId, orderDetails: widget.order.toJson());
            }
          },
          isShowAcceptOrRejectBtn: true,
          title: "Available Shops",
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
                if(controller.riderBusinessList.isNotEmpty)
                  Expanded(
                  child: ListView.builder(itemCount: controller.riderBusinessList.length,
                    itemBuilder: (BuildContext context,
                        int index,) {
                      BusinessListModel? model = controller.riderBusinessList[index];
                      bool isSelected=controller.selectedShops.contains(model);
                      return InkWell(
                        onTap: (){
                          controller.onSelectTab(model);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.whiteFE,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          padding: EdgeInsets.all(10),
                          child: Row(mainAxisAlignment: MainAxisAlignment
                              .spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(40),
                                      image: DecorationImage(image: NetworkImage(model.profilePicture))
                                    ),
                                  ),
                                  SizedBox(width: SizeConfig.size10,),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustomText(
                                        "${model.name}",
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      SizedBox(height: SizeConfig.size6,),
                                      CustomText(
                                        "${model.noOfItemsAvailable} Items Available  ₹ ${model.totalPriceForAvailableItems} Price",
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      SizedBox(height: SizeConfig.size6,),
                                      CustomText(
                                        "${double.parse(model.distance.toString()).roundToDouble()} Distance",
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
                                  height: 14,
                                  width: 14,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.white),
                                    color: isSelected?AppColors.primaryColor:null
                                  ),
                                  child: isSelected
                                      ? Center(
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  )
                                      : null,
                                ),
                              )
                            ],),
                        ),
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
