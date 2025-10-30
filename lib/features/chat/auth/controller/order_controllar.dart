import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/api/apiService/response_model.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../business/auth/repo/business_profile_repo.dart';
import '../model/GetListOfMessageData.dart';
import '../model/get_adress_details_model.dart';
import '../model/get_porter_vechile_option_model.dart';
import '../model/payment_success_model.dart';
import '../repo/make_order_repo.dart';
import '../repo/porter_api_repo.dart';
import 'chat_view_controller.dart';

class OrderNowController extends GetxController {
  var address = "".obs;
  var lat = "".obs;
  var long = "".obs;

  Messages? openedMessage;
  Rx<ApiResponse> getAddressResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getVehicleOptionResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> viewBusinessProfileResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> paymentResponse = ApiResponse.initial('Initial').obs;
  final porterApi = PorterApiService();
  Rx<TextEditingController> nameController    = TextEditingController().obs;
  Rx<TextEditingController> phoneController    = TextEditingController().obs;
  Rx<TextEditingController> fullAddress        = TextEditingController().obs;
  Rx<TextEditingController> houseNoController  = TextEditingController().obs;
  Rx<TextEditingController> streetController   = TextEditingController().obs;
  Rx<TextEditingController> landmarkController = TextEditingController().obs;
  Rx<TextEditingController> cityController     = TextEditingController().obs;
  Rx<TextEditingController> stateController    = TextEditingController().obs;
  Rx<TextEditingController> zipController      = TextEditingController().obs;
  Rx<TextEditingController> noteController     = TextEditingController().obs;
  Rx<TextEditingController> typeController      = TextEditingController().obs;
  Rx<GetAdressDetailsModel> getAddressDetails=GetAdressDetailsModel().obs;
  Rx<GetPorterVehicleOptionModel> getPorterVehicleOptionModel=GetPorterVehicleOptionModel().obs;
  Rx<PaymentResponseModel> paymentResponseModel=PaymentResponseModel().obs;
  RxBool isDefault = false.obs;
  RxInt? selectedIndex;
  void copyLat() {
    Clipboard.setData(ClipboardData(text: lat.value));
    commonSnackBar(message: "Copied Store Lat");
  }
  void copyLong() {
    Clipboard.setData(ClipboardData(text: long.value));
    commonSnackBar(message: "Copied Store Long");
  }
  void setMessageDetails(Messages msg){
    openedMessage=msg;

  }
  Future<void> viewBusinessForLocation(String userId) async {

    try {
      ResponseModel responseModel =
      await BusinessProfileRepo().viewBusinessIdForLocation(userId);
      logs("data=== ${responseModel.response?.data}");
      if (responseModel.response?.data['success']) {
        final data = responseModel.response?.data;

        address.value=data['data']['address'].toString();
        lat.value=data['data']['business_location']['lat'].toString();
        long.value=data['data']['business_location']['lon'].toString();
        viewBusinessProfileResponse.value=ApiResponse.complete(long);
      }else{
        viewBusinessProfileResponse.value=ApiResponse.error( AppStrings.somethingWentWrong);
      }
    }catch(e){

    }
  }
  Future<void> updateOrderStatus(Map<String,dynamic> params) async {
    try {
      ResponseModel responseModel =
      await BusinessProfileRepo().updateMsgOrderStatus(params);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

      }else{

      }
    }catch(e){

    }
  }
  Future<void> sendMessageToOrderTab(
      {required Map<String,dynamic> params})
  async {
    try {
      ResponseModel? response = await MakeOrderRepo().messageToOrder(params);
      if (response.isSuccess ?? false) {
        log("Message Added Order Tab ${response.response?.data}");
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
  Future<void> getAddressApi() async {
    try {
      ResponseModel? response = await MakeOrderRepo().getAddress();
      if (response.isSuccess ?? false) {
        getAddressDetails.value=GetAdressDetailsModel.fromJson(response.response?.data);
        getAddressResponse.value= ApiResponse.complete(getAddressDetails.value);
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        getAddressResponse.value= ApiResponse.error( response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  void fetchVehicleQuotes(
      Map<String,dynamic> params
      ) async {
    getVehicleOptionResponse.value= ApiResponse.initial("Initial");

    final data = await porterApi.getQuote(params);

    if (data != null&&data['status']) {


      final vehicles = data['data']['vehicles'];
      getPorterVehicleOptionModel.value=GetPorterVehicleOptionModel.fromJson(data['data']);
      getVehicleOptionResponse.value= ApiResponse.complete(getPorterVehicleOptionModel.value);
      print("🚚 Vehicles found: $vehicles");
    } else {
      if(data!=null){
        final vehicles = data['data']['message'];
        getVehicleOptionResponse.value= ApiResponse.error(vehicles??AppStrings.somethingWentWrong);
        print("❌ Failed to fetch quotes");
      }else{
        getVehicleOptionResponse.value= ApiResponse.error(AppStrings.somethingWentWrong);
        print("❌ Failed to fetch quotes");
      }

    }
  }

  String generateRequestId() {

    final random = Random();

    // Generate a random 7-digit number
    final randomNumber = random.nextInt(9999999).toString().padLeft(7, '0');

    // Generate a UUID (version 1)


    // Combine in your format
    return "TEST_0_${randomNumber}${userId}";
  }

  Future<Map<String, String>> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final city = place.locality ?? '';
        final state = place.administrativeArea ?? '';
        final pincode = place.postalCode ?? '';


        return {
          "city": city,
          "state": state,
          "pincode": pincode,
        };
      } else {
        print("⚠️ No address found for this location");
        return {};
      }
    } catch (e) {
      print("❌ Error while getting address: $e");
      return {};
    }
  }

  void createOrder() async {
    List<AddressDetails>? addressList=getAddressDetails.value.data;
    AddressDetails? selectedAddress;
    if(addressList!=null){
      selectedAddress=addressList[selectedIndex?.value??0];
    }
    if(openedMessage!=null){
      Map<String,dynamic> addressData=await getAddressFromLatLng(double.parse(lat.value.toString()),double.parse(long.value.toString()));
      Map<String,dynamic> params={
        "request_id": "${generateRequestId()}",
        // "delivery_instructions": {
        //   "instructions_list": [
        //     {
        //       "type": "text",
        //       "description": "handle with care"
        //     }
        //   ]
        // },
        "pickup_details": {
          "address": {
            "apartment_address": "",
            "street_address1": "${(openedMessage?.seller?.location==''||openedMessage?.seller?.location==null)?"N/A":openedMessage?.seller?.location}",
            // // "street_address2": "Krishna Nagar Industrial Area",
            "landmark": "N/A",
            "city": "${addressData['city']}",
            "state": "${addressData['state']}",
            "pincode": "${addressData['pincode']}",
            "country": "India",
            "lat":double.parse(lat.value),
            "lng": double.parse(long.value),
            "contact_details": {
              "name": "${openedMessage?.seller?.name}",
              "phone_number": "${openedMessage?.seller?.contact}"
            }
          }
        },
        "drop_details": {
          "address": {
            "apartment_address": "${selectedAddress?.houseNo}",
            "street_address1": "${selectedAddress?.street}",
            // "street_address2": "This is My Order ID",
            "landmark": "${selectedAddress?.landmark}",
            "city": "${selectedAddress?.city}",
            "state": "${selectedAddress?.state}",
            "pincode": "${selectedAddress?.zipCode}",
            "country": "${selectedAddress?.country}",
            "lat": selectedAddress?.lat,
            "lng": selectedAddress?.lng,
            "contact_details": {
              "name": "${selectedAddress?.name}",
              "phone_number": "+91${selectedAddress?.phone}"
            }
          }
        },
        "additional_comments": ""
      };

      final data = await porterApi.createOrder(params);
      if (data != null) {
        paymentResponseModel.value=PaymentResponseModel.fromJson(data);
        paymentResponse.value= ApiResponse.complete(paymentResponseModel.value);
        Map<String,dynamic> addOrderTabParams={
          ApiKeys.message_id: "${openedMessage?.id}",
          ApiKeys.other_user_id : openedMessage?.seller?.id,
          ApiKeys.order : data
        };
        sendMessageToOrderTab(params: addOrderTabParams);
        final chatViewController = Get.find<ChatViewController>();

        Map<String,dynamic>datadd={
          ApiKeys.messageId: "${openedMessage?.id}",
          ApiKeys.order_status : true
        };
        await  updateOrderStatus(datadd);
        chatViewController. emitEvent("messageReceived", {
          ApiKeys.conversation_id: openedMessage?.conversationId??openedMessage?.sender?.id,
          ApiKeys.page: 1,
          ApiKeys.is_online_user: businessId,
          ApiKeys.per_page_message: 30,
        });

      } else {

        print("❌ Failed to fetch quotes");
      }
    }else{
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }

  }

    Future<bool?> cancelOrderApi(String orderId,String conversationId) async {


      final data = await porterApi.cancelOrder(orderId);
      if (data != null&&data) {

        final chatViewController = Get.find<ChatViewController>();

        Map<String,dynamic>datadd={
          ApiKeys.messageId: "${openedMessage?.id}",
          ApiKeys.order_status : true
        };
        await  updateOrderStatus(datadd);
        chatViewController. emitEvent("messageReceived", {
          ApiKeys.conversation_id: conversationId,
          ApiKeys.page: 1,
          ApiKeys.is_online_user: businessId,
          ApiKeys.per_page_message: 30,
        });
      return data;
      } else {
        print("❌ Failed to fetch quotes");


        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
      return null;


  }


  Future<void> addAddressApi(double? lat,double? long) async {
    try {
      final addressData = {
        "name": nameController.value.text.trim(),
        "phone": phoneController.value.text.trim(),
        "house_no": houseNoController.value.text.trim(),
        "street": streetController.value.text.trim(),
        "landmark": landmarkController.value.text.trim(),
        "city": cityController.value.text.trim(),
        "state": stateController.value.text.trim(),
        "zip_code": zipController.value.text.trim(),
        "note": noteController.value.text.trim(),
        "country": "India",
        "type": "Home",
        "is_default": isDefault.value,

        "lat": lat,
        "lng": long,
      };
      ResponseModel? response = await MakeOrderRepo().addAddress(addressData);
      if (response.isSuccess ?? false) {

        nameController.value.clear();
        phoneController.value.clear();
        fullAddress.value.clear();
        houseNoController.value.clear();
        streetController.value.clear();
        landmarkController.value.clear();
        cityController.value.clear();
        stateController.value.clear();
        zipController.value.clear();
        noteController.value.clear();
        typeController.value.clear();

        commonSnackBar(
            message: response?.message);
        Get.back();
        getAddressApi();
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
