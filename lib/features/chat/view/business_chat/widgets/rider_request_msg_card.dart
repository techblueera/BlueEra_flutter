import 'dart:developer';

import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import '../../../auth/model/GetListOfMessageData.dart';
class RiderRequestMsgCard extends StatefulWidget {
  final  Messages message;
  const RiderRequestMsgCard({super.key, required this.message});

  @override
  State<RiderRequestMsgCard> createState() => _RiderRequestMsgCardState();
}

class _RiderRequestMsgCardState extends State<RiderRequestMsgCard> {
  final controller = Get.isRegistered<DeliverPartnerOrdersController>()
      ? Get.find<DeliverPartnerOrdersController>()
      : Get.put(DeliverPartnerOrdersController());
  void _handleRejectOrder() {
    controller.updateOrderStatusFromPialot(
      {ApiKeys.action: "reject"},
      widget.message.id ?? "",
    );
  }

  void _handleAcceptOrder() {
    // callShow();
    controller.updateOrderStatusFromPialot(
      {ApiKeys.action: "accept"},
      widget.message.id ?? "",
    );
  }
  void callShow()async{
    CallKitParams callKitParams = CallKitParams(
      id: "_currentUuid",
      nameCaller: 'New Delivery Order',
      appName: 'Callkit',
      avatar: 'https://i.pravatar.cc/100',
      handle: "Akash Krish's order waiting for ride",
      type: 0,
      textAccept: 'Accept',
      textDecline: 'Reject',
      missedCallNotification: NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'You Missed an Order of Akash Krish',
        callbackText: 'Chat Now',
      ),
      callingNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Akash Krish order waiting for your confirmation',
        callbackText: 'Chat',
      ),
      duration: 30000,
      extra: <String, dynamic>{'userId': '1a2b3c4d'},
      headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
      android: const AndroidParams(
          isImportant: true,
          isCustomNotification: false,
          isShowLogo: false,
          logoUrl: 'https://i.pravatar.cc/100',
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0955fa',
          backgroundUrl: 'https://i.pravatar.cc/500',
          actionColor: '#4CAF50',
          textColor: '#ffffff',
          incomingCallNotificationChannelName: "New Delivery Order",
          missedCallNotificationChannelName: "You Missed an Order of Akash Krish",
          isShowCallID: false
      ),
      ios: IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
  }
  @override
  Widget build(BuildContext context) {

    return Container(
      margin: EdgeInsets.only(bottom: 2),
      width: SizeConfig.screenWidth*0.7,
      // height: 310,
      // responsive width
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
            padding:  EdgeInsets.symmetric(horizontal: SizeConfig.size10,),

            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: SizeConfig.size10,),
                CustomText(
                  "Hello,  You’ve received a new delivery order.",
                  fontSize: SizeConfig.size14,
                  fontWeight: FontWeight.w500,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                SizedBox(height: SizeConfig.size10,),
                CustomText(
                  "Please proceed to the pickup point and confirm the delivery status in the app once collected.",
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
                      border: Border.all(
                          color: AppColors.greyE5
                      ),
                      boxShadow: [
                        AppShadows.bottomShadow
                      ]
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8,vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        "Pickup Location: 2.5 KM,\nLaxmi Nagar, Gupta General Store, 2.5K Orders, Lucknow Gomtinagar",
                        fontSize: SizeConfig.size12,
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.secondaryTextColor,
                        maxLines: 3,
                      ),
                      SizedBox(height: SizeConfig.size10,),
                      CustomText(
                        "Drop Location: 10KM.\nBishnupur, Lucknow Gomtinagar, Shiva Samaddar",
                        fontSize: SizeConfig.size12,
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.secondaryTextColor,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.size8),
                Row(
                  children: [
                    CustomText(
                      "Ride Charge  - ",
                      fontSize: SizeConfig.size12,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w400,
                      maxLines: 1,
                      color: AppColors.secondaryTextColor,
                    ),
                    CustomText(
                      "₹108",
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
          const Divider(height: 1,color: Colors.grey,),
          SizedBox(height: SizeConfig.size8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child:(widget.message.metadata?.orderStatus==null)?Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _handleRejectOrder(),
                    child: Row(
                      children: [
                        SizedBox(width: SizeConfig.size4,),
                        const Icon(Icons.close, color: Colors.red,),
                        SizedBox(width: SizeConfig.size8,),
                        CustomText(
                          'Reject Order',
                          color: Colors.red,
                          fontWeight: FontWeight.w900,
                        ),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(width: 2,color: Colors.grey,),
                Expanded(
                  child: InkWell(
                    onTap: () => _handleAcceptOrder(),
                    child: Row(
                      children: [
                        SizedBox(width: SizeConfig.size4,),
                        const Icon(Icons.check,color: AppColors.primaryColor, ),
                        SizedBox(width: SizeConfig.size8,),
                        CustomText(
                          'Accept Order',
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ): Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: InkWell(
                    onTap:()=> _handleAcceptOrder(),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            (widget.message.metadata?.orderStatus == true)
                                ? Icons.check
                                : Icons.close,
                            color: (widget.message.metadata?.orderStatus == true)
                                ? AppColors.green0B
                                : AppColors.red,
                          ),
                          const SizedBox(width: 6),
                          CustomText(
                            'Order ${(widget.message.metadata?.orderStatus == true) ? "Accepted" : "Rejected"}',
                            color: (widget.message.metadata?.orderStatus == true)
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
            ) ,
          ),
          SizedBox(height: SizeConfig.size10,)

        ],
      ),
    );
  }
}
