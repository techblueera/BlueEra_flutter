import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/response_model.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../business/auth/controller/view_business_details_controller.dart';
import '../../../business/auth/repo/business_profile_repo.dart';
import '../repo/make_order_repo.dart';
import 'chat_view_controller.dart';

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
    try {
      ResponseModel responseModel =
      await BusinessProfileRepo().viewBusinessIdForLocation(userId);

      if (responseModel.response?.data['success']) {
        final data = responseModel.response?.data;
        logs("data=== ${data}");
        lat.value=data['data']['address'].toString();

      }else{

      }
    }catch(e){

    }
  }
  Future<void> updateOrderStatus(Map<String,dynamic> params) async {
    // try {
      ResponseModel responseModel =
      await BusinessProfileRepo().updateMsgOrderStatus(params);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

      }else{

      }
    // }catch(e){
    //
    // }
  }
  Future<void> CreateOrder(
      {required Map<String,dynamic> params}) async {
    try {
      ResponseModel? response = await MakeOrderRepo().createOrder(params);
      if (response.isSuccess ?? false) {
        print("Create Order Response :: ${response.response?.data}");
      } else {
        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  Future<void> VerifyPayment(
      {required Map<String,dynamic> params}) async {
    try {
      ResponseModel? response = await MakeOrderRepo().verifyPayment(params);
      if (response.isSuccess ?? false) {
        print("Create Order Response :: ${response.response?.data}");
      } else {
        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
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
                        Row(
                          children: [
                            const CustomText("Step 1 :",
                                fontSize: 14, fontWeight: FontWeight.w700,color: AppColors.secondaryTextColor,),
                            Expanded(
                              child: const CustomText(" Copy Store Address",
                                  fontSize: 14, fontWeight: FontWeight.w700,color: AppColors.black,),
                            ),
                          ],
                        ),


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
                                        color: AppColors.primaryColor,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
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
                    /*    const CustomText("Log",
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
                        const SizedBox(height: 25),*/

                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const CustomText("Step 2 :",
                              fontSize: 14, fontWeight: FontWeight.w700,color: AppColors.secondaryTextColor,),
                            Expanded(
                              child: const CustomText(" Now Book Delivery Partner",
                                fontSize: 14, fontWeight: FontWeight.w700,color: AppColors.black,),
                            ),
                          ],
                        ),
                        // Step 2

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
                                  if (!await launchUrl( Uri.parse(AppConstants.rapidoLink))) {
                                    // throw Exception('Could not launch $_url');
                                  }
                                  // Get.to(CommonWebView(
                                  //   urlLink: AppConstants.rapidoLink,
                                  //   urlTitle: 'Rapido',
                                  // ));
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
                                  if (!await launchUrl( Uri.parse(AppConstants.porterLink))) {
                                    // throw Exception('Could not launch $_url');
                                  }
                                  // Get.to(CommonWebView(
                                  //   urlLink: AppConstants.porterLink,
                                  //   urlTitle: 'Porter',
                                  // ));
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
