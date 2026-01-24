import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';

import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/controller/order_controllar.dart';
import '../../../auth/model/GetListOfMessageData.dart';

class RiderRequestMsgCard extends StatefulWidget {
  final Messages message;

  const RiderRequestMsgCard({super.key, required this.message});

  @override
  State<RiderRequestMsgCard> createState() => _RiderRequestMsgCardState();
}

class _RiderRequestMsgCardState extends State<RiderRequestMsgCard> {
  final controller = Get.isRegistered<DeliverPartnerOrdersController>()
      ? Get.find<DeliverPartnerOrdersController>()
      : Get.put(DeliverPartnerOrdersController());
  final orderController = Get.put(OrderNowController());
  final chatViewController = Get.find<ChatViewController>();
  String? pickupLocation;
  String? dropLocation;

  void _handleRejectOrder(
    String messageId,
  ) async {
    bool value = await controller.updateOrderStatusFromPialot(
      {ApiKeys.action: "reject"},
      widget.message.id ?? "",
    );
    if (value) {
      Map<String, dynamic> datadd = {
        ApiKeys.messageId: "${messageId}",
        ApiKeys.order_status: false
      };
      orderController.updateMessageOrderStatus(datadd);
      chatViewController.emitEvent(ChatEmitEvents.messageReceived, {
        ApiKeys.conversation_id:
            widget.message.conversationId ?? widget.message.sender?.id,
        ApiKeys.page: 1,
        ApiKeys.is_online_user: widget.message.sender?.id,
        ApiKeys.per_page_message: 30,
        ApiKeys.orders_conversation: true
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    getAddress();
    super.initState();
  }

  void getAddress() async {
    pickupLocation = await getAddressFromLatLngAsString(
        lat: widget.message.metadata?.order?.pickupLocation?.location
                ?.coordinates?[1] ??
            0,
        lng: widget.message.metadata?.order?.pickupLocation?.location
                ?.coordinates?[0] ??
            0);
    dropLocation = await getAddressFromLatLngAsString(
        lat: widget.message.metadata?.order?.dropLocation?.location
                ?.coordinates?[1] ??
            0,
        lng: widget.message.metadata?.order?.dropLocation?.location
                ?.coordinates?[0] ??
            0);
  }

  void _handleAcceptOrder(String messageId) async {
    bool value = await controller.updateOrderStatusFromPialot(
      {ApiKeys.action: "accept"},
      widget.message.id ?? "",
    );
    if (value) {
      Map<String, dynamic> datadd = {
        ApiKeys.messageId: "${messageId}",
        ApiKeys.order_status: true
      };
      orderController.updateMessageOrderStatus(datadd);
      chatViewController.emitEvent(ChatEmitEvents.messageReceived, {
        ApiKeys.conversation_id:
            widget.message.conversationId ?? widget.message.sender?.id,
        ApiKeys.page: 1,
        ApiKeys.is_online_user: widget.message.sender?.id,
        ApiKeys.per_page_message: 30,
        ApiKeys.orders_conversation: true
      });
    }
  }

  Future<String?> getAddressFromLatLngAsString(
      {required double lat, required double lng}) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        lat,
        lng,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String locationString =
            "${place.name ?? ''}, ${place.subLocality ?? ''}, ${place.subAdministrativeArea ?? ''}, ${place.locality ?? ''} - ${place.postalCode ?? ''}"
                .trim();

        return locationString;
      } else {
        return AppStrings.viewOrderAddress.tr;
      }
    } catch (e) {
      return AppStrings.viewOrderAddress.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 2),
      width: SizeConfig.screenWidth * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: SizeConfig.size10,
                ),
                CustomText(
                  AppStrings.newDeliveryOrderReceived,
                  fontSize: SizeConfig.size14,
                  fontWeight: FontWeight.w500,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                SizedBox(
                  height: SizeConfig.size10,
                ),
                CustomText(
                  AppStrings.proceedToPickupPoint,
                  fontSize: SizeConfig.size12,
                  fontWeight: FontWeight.w400,
                  overflow: TextOverflow.ellipsis,
                  color: AppColors.primaryColor,
                  maxLines: 2,
                ),
                SizedBox(height: SizeConfig.size8),
                Container(
                  decoration: BoxDecoration(
                      color: AppColors.blueLightShade,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.greyE5),
                      boxShadow: [AppShadows.bottomShadow]),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        "${AppStrings.pickupLocation.tr} : ${pickupLocation ?? AppStrings.fetchingLocation.tr}",
                        fontSize: SizeConfig.size12,
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.secondaryTextColor,
                        maxLines: 2,
                      ),
                      SizedBox(
                        height: SizeConfig.size4,
                      ),
                      CustomText(
                        "${AppStrings.dropLocation.tr} : ${pickupLocation ?? AppStrings.fetchingLocation.tr}",
                        fontSize: SizeConfig.size12,
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.secondaryTextColor,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.size8),
                Row(
                  children: [
                    CustomText(
                      "${AppStrings.rideCharge.tr}  - ",
                      fontSize: SizeConfig.size12,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w400,
                      maxLines: 1,
                      color: AppColors.secondaryTextColor,
                    ),
                    CustomText(
                      "₹${widget.message.metadata?.order?.fare}",
                      fontSize: SizeConfig.size16,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size10),
          const Divider(
            height: 1,
            color: Colors.grey,
          ),
          SizedBox(height: SizeConfig.size8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: (widget.message.metadata?.orderStatus == null)
                ? Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              _handleRejectOrder(widget.message.id ?? ''),
                          child: Row(
                            children: [
                              SizedBox(
                                width: SizeConfig.size4,
                              ),
                              const Icon(
                                Icons.close,
                                color: Colors.red,
                              ),
                              SizedBox(
                                width: SizeConfig.size8,
                              ),
                              CustomText(
                                AppStrings.rejectOrder,
                                color: Colors.red,
                                fontWeight: FontWeight.w900,
                              ),
                            ],
                          ),
                        ),
                      ),
                      VerticalDivider(
                        width: 2,
                        color: Colors.grey,
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              _handleAcceptOrder(widget.message.id ?? ''),
                          child: Row(
                            children: [
                              SizedBox(
                                width: SizeConfig.size4,
                              ),
                              const Icon(
                                Icons.check,
                                color: AppColors.primaryColor,
                              ),
                              SizedBox(
                                width: SizeConfig.size8,
                              ),
                              CustomText(
                                AppStrings.acceptOrder,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w900,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: InkWell(
                          // onTap:()=> _handleAcceptOrder(),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  (widget.message.metadata?.orderStatus == true)
                                      ? Icons.check
                                      : Icons.close,
                                  color:
                                      (widget.message.metadata?.orderStatus ==
                                              true)
                                          ? AppColors.green0B
                                          : AppColors.red,
                                ),
                                const SizedBox(width: 6),
                                CustomText(
                                  '${AppStrings.order.tr} ${(widget.message.metadata?.orderStatus == true) ? AppStrings.accepted : AppStrings.rejected}',
                                  color:
                                      (widget.message.metadata?.orderStatus ==
                                              true)
                                          ? AppColors.green0B
                                          : AppColors.red,
                                  fontWeight: FontWeight.w900,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          SizedBox(
            height: SizeConfig.size10,
          )
        ],
      ),
    );
  }
}
