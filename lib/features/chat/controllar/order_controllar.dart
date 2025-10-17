import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/api/apiService/api_keys.dart';
import '../../../core/api/apiService/response_model.dart';
import '../../business/auth/controller/view_business_details_controller.dart';
import '../../business/auth/repo/business_profile_repo.dart';
import '../auth/controller/chat_view_controller.dart';

class OrderNowController extends GetxController {
  var lat = "".obs;
  var long = "".obs;

  void copyLat() {
    Clipboard.setData(ClipboardData(text: lat.value));
    commonSnackBar(message: "Copied Store Lat");
  }
  void copyLong() {
    Clipboard.setData(ClipboardData(text: long.value));
    commonSnackBar(message: "Copied Store Long");
  }
  Future<void> viewBusinessForLocation(String userId) async {
    // try {
      ResponseModel responseModel =
      await BusinessProfileRepo().viewBusinessIdForLocation(userId);

      if (responseModel.response?.data['success']) {
        final data = responseModel.response?.data;
        lat.value=data['data']['business_location']['lat'].toString();
        long.value=data['data']['business_location']['lon'].toString();

      }else{

      }
    // }catch(e){
    //
    // }
  }
  Future<void> updateOrderStatus(Map<String,dynamic> params) async {
    // try {
      ResponseModel responseModel =
      await BusinessProfileRepo().updateMsgOrderStatus(params);
      log("adlskc;sldkcl;skdc order Update ${responseModel.response?.data}");
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        log("adlskc;sldkcl;skdc order Update ${data}");
      }else{

      }
    // }catch(e){
    //
    // }
  }

}

class OrderNowDialog {
  static void showDialogBox(String businessId,String messageId,String conversationId) async {
    // final viewProfileController = await Get.put(ViewBusinessDetailsController());
    //   // ..viewBusinessProfileById(businessId);
    final controller = Get.put(OrderNowController())..viewBusinessForLocation(businessId);
    final chatViewController = Get.find<ChatViewController>();


    Get.dialog(
       Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            backgroundColor: Color(0xffF1F1F3),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CustomText("Order Now",
                          fontSize: 22, fontWeight: FontWeight.bold),
                      InkWell(
                          onTap: () {
                            Get.back();
                          },
                          child: LocalAssets(
                              imagePath: AppIconAssets.close_black))
                    ],
                  ),
                  SizedBox(height: SizeConfig.size10),

                  // Step 1
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: AppColors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CustomText("Step 1",
                            fontSize: 18, fontWeight: FontWeight.w600),
                        const SizedBox(height: 5),
                        const CustomText("Copy Store Location Lat & Long",
                            color: AppColors.secondaryTextColor),
                        const SizedBox(height: 10),
                        const CustomText("Lat",
                            color: AppColors.secondaryTextColor),
                        const SizedBox(height: 4),
                        // Address Box with Copy Button

                        Obx(() =>
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      child: CustomText(
                                        controller.lat.value,
                                        fontSize: 16,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded,
                                        color: Colors.black54),
                                    onPressed: controller.copyLat,
                                  ),
                                ],
                              ),
                            )),
                        const CustomText("Log",
                            color: AppColors.secondaryTextColor),
                        const SizedBox(height: 4),
                        Obx(() =>
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      child: CustomText(
                                        controller.long.value,
                                        fontSize: 16,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded,
                                        color: Colors.black54),
                                    onPressed: controller.copyLong,
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 25),

                        // Step 2
                        const CustomText("Step 2",
                            fontSize: 18, fontWeight: FontWeight.w600),
                        const SizedBox(height: 5),
                        const CustomText(
                          "Now Book Delivery Partner",
                          color: AppColors.secondaryTextColor,
                        ),
                        const SizedBox(height: 12),

                        // Buttons (Rapido & Porter)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  side: BorderSide(color: AppColors.primaryColor),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding: EdgeInsets.symmetric(
                                      vertical: SizeConfig.size8),
                                ),
                                icon: LocalAssets(
                                  imagePath: AppIconAssets.rapido,
                                  height: SizeConfig.size30,
                                  width: SizeConfig.size30,
                                ),
                                label: const CustomText("Rapido",
                                    fontWeight: FontWeight.w600),
                                onPressed: () async{
                                  Map<String,dynamic>data={
                                    "messageId": "${messageId}",
                                    "order_status": true
                                  };
                                  await  controller.updateOrderStatus(data);
                                  chatViewController. emitEvent("messageReceived", {
                                    ApiKeys.conversation_id: conversationId,
                                    ApiKeys.page: 1,
                                    ApiKeys.is_online_user: businessId,
                                    ApiKeys.per_page_message: 30,
                                  });
                                  Get.back();
                                  Get.to(CommonWebView(
                                    urlLink: AppConstants.rapidoLink,
                                    urlTitle: 'Rapido',
                                  ));
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  side: BorderSide(color: AppColors.primaryColor),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding: EdgeInsets.symmetric(
                                      vertical: SizeConfig.size8),
                                ),
                                icon: LocalAssets(
                                    imagePath: AppIconAssets.porter,
                                    height: SizeConfig.size30,
                                    width: SizeConfig.size30),
                                label: const CustomText("Porter",
                                    fontWeight: FontWeight.w600),
                                onPressed: () async{
                                  Map<String,dynamic>data={
                                    "messageId": "${messageId}",
                                  "order_status": true
                                };
                                 await  controller.updateOrderStatus(data);
                                 chatViewController. emitEvent("messageReceived", {
                                    ApiKeys.conversation_id: conversationId,
                                    ApiKeys.page: 1,
                                    ApiKeys.is_online_user: businessId,
                                    ApiKeys.per_page_message: 30,
                                  });
                                  Get.back();

                                  Get.to(CommonWebView(
                                    urlLink: AppConstants.porterLink,
                                    urlTitle: 'Porter',
                                  ));
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
    );
  }
}
