import 'dart:math' hide log;

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/api/apiService/response_model.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../business/auth/repo/business_profile_repo.dart';
import '../model/GetBlueeraPiolotModel.dart';
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
  Rx<ApiResponse> getFaireAmountResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getVehicleOptionResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> viewBusinessProfileResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getRidersListResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> paymentResponse = ApiResponse.initial('Initial').obs;
  final TextEditingController orderValueController = TextEditingController();
  final porterApi = PorterApiService();
  Rx<TextEditingController> nameController = TextEditingController().obs;
  Rx<TextEditingController> phoneController = TextEditingController().obs;
  Rx<TextEditingController> fullAddress = TextEditingController().obs;
  Rx<TextEditingController> houseNoController = TextEditingController().obs;
  Rx<TextEditingController> streetController = TextEditingController().obs;
  Rx<TextEditingController> landmarkController = TextEditingController().obs;
  Rx<TextEditingController> cityController = TextEditingController().obs;
  Rx<TextEditingController> stateController = TextEditingController().obs;
  Rx<TextEditingController> zipController = TextEditingController().obs;
  Rx<TextEditingController> noteController = TextEditingController().obs;
  Rx<TextEditingController> typeController = TextEditingController().obs;
  Rx<GetAdressDetailsModel> getAddressDetails = GetAdressDetailsModel().obs;
  Rx<GetBlueeraPiolotModel> getBlueeraPiolotModel = GetBlueeraPiolotModel().obs;
  Rx<GetPorterVehicleOptionModel> getPorterVehicleOptionModel =
      GetPorterVehicleOptionModel().obs;
  Rx<PaymentResponseModel> paymentResponseModel = PaymentResponseModel().obs;
  RxBool isDefault = false.obs;
  RxBool ownerOtpLoading = false.obs;
  RxInt? selectedIndex;
  RxList<Riders?> selectedIndexes = <Riders>[].obs;
  RxString fare = "0.0".obs;

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
        return "";
      }
    } catch (e) {
      return "Location not found";
    }
  }

  void calculateDistanceInKm(
      {required double startLat,
      required double startLng,
      required double endLat,
      required double endLng}) {
    // double distanceInMeters = Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
    // double distanceInKm = distanceInMeters / 1000; // convert meters to km
    // distanceKm.value=double.parse(distanceInKm.toStringAsFixed(2));
    // return double.parse(distanceInKm.toStringAsFixed(2)); // round to 2 decimals
    Map<String, dynamic> params = {
      ApiKeys.pickupLocation: {
        ApiKeys.latitude: endLat,
        ApiKeys.longitude: endLng
      },
      ApiKeys.dropLocation: {
        ApiKeys.latitude: startLat,
        ApiKeys.longitude: startLng
      }
    };
    getOrderFareFrom(params);
  }

  void setMessageDetails(Messages msg) {
    openedMessage = msg;
  }

  Future<void> viewBusinessForLocation(String userId, String userType) async {
    lat.value = '0.0';
    long.value = '0.0';
    try {
      ResponseModel responseModel = await BusinessProfileRepo()
          .viewBusinessIdForLocation(userId, userType);
      if ((userType == 'INDIVIDUAL')
          ? (responseModel.response?.data['status'])
          : (responseModel.response?.data['success'])) {
        final data = responseModel.response?.data;

        if (userType == 'INDIVIDUAL') {
          lat.value = data['data']['user']['user_location']['lat'].toString();
          long.value = data['data']['user']['user_location']['lon'].toString();
        } else {
          address.value = data['data']['address'].toString();
          lat.value = data['data']['business_location']['lat'].toString();
          long.value = data['data']['business_location']['lon'].toString();
        }
        viewBusinessProfileResponse.value = ApiResponse.complete(long);
      } else {
        viewBusinessProfileResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } catch (e) {
      viewBusinessProfileResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  Future<List<Riders>?> getRidersNearByShop(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().getNearByRiders(params);
      if (responseModel.response?.data != null) {
        final data = responseModel.response?.data;

        getBlueeraPiolotModel.value = GetBlueeraPiolotModel.fromJson(data);

        if (getBlueeraPiolotModel.value.users != null &&
            getBlueeraPiolotModel.value.users!.length > 4) {
          getBlueeraPiolotModel.value.users =
              getBlueeraPiolotModel.value.users!.take(4).toList();
        }

        //6307790308
        selectedIndexes.addAll(getBlueeraPiolotModel.value.users ?? []);
        getRidersListResponse.value =
            ApiResponse.complete(getBlueeraPiolotModel);
        return getBlueeraPiolotModel.value.users;
      } else {
        getRidersListResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
        return null;
      }
    } catch (e) {
      getRidersListResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
      return null;
    }
  }

  Future<void> updateOrderStatus(Map<String, dynamic> params) async {
    try {
      // ResponseModel responseModel =
      // await BusinessProfileRepo().updateMsgOrderStatus(params);

      // if (responseModel.isSuccess) {
      //   final data = responseModel.response?.data;
      //
      // }else{
      //
      // }
    } catch (e) {}
  }

  Future<void> updateMessageOrderStatus(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().updateMsgOrderStatus(params);
      if (responseModel.isSuccess) {
      } else {}
    } catch (e) {}
  }

  Future<void> uploadThePickupOtp(
      Map<String, dynamic> params, String orderId) async {
    try {
      ownerOtpLoading.value = true;
      ResponseModel responseModel =
          await MakeOrderRepo().uploadThePickupOtp(params, orderId);
      if (responseModel.isSuccess) {
        commonSnackBar(message: AppStrings.pickupOrderVerifiedSuccessfully);
      } else {
        commonSnackBar(message: responseModel.message);
      }
      ownerOtpLoading.value = false;
    } catch (e) {
      ownerOtpLoading.value = false;
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<bool> sendMessageToOrderTab(
      {required Map<String, dynamic> params}) async {
    // try {
    ResponseModel? response = await MakeOrderRepo().messageToOrder(params);

    if (response.isSuccess) {
      return true;
    } else {
      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
      return false;
    }
    // } catch (e) {
    //   commonSnackBar(message: AppStrings.somethingWentWrong);
    //   return false;
    // }
  }

  Future<void> getAddressApi() async {
    try {
      getAddressResponse.value = ApiResponse.initial("Initial");
      ResponseModel? response = await MakeOrderRepo().getAddress();

      if (response.isSuccess) {
        getAddressDetails.value =
            GetAdressDetailsModel.fromJson(response.response?.data);
        getAddressResponse.value =
            ApiResponse.complete(getAddressDetails.value);
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        getAddressResponse.value = ApiResponse.error(
            response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> sendOrderRequestToRider(Map<String, dynamic> params) async {
    try {
      ResponseModel? response =
          await MakeOrderRepo().sendOrderRequestToRider(params);

      if (response.isSuccess) {
        commonSnackBar(
            message: response.message ??
                AppStrings.riderWillAcceptSoon);
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> updatePaymentStausByUser(String params) async {
    try {
      ResponseModel? response =
          await MakeOrderRepo().updatePaymentStausByUser(params);

      if (response.isSuccess) {
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> cancelOrderForce(
      String orderId, Map<String, dynamic> params) async {
    try {
      ResponseModel? response =
          await MakeOrderRepo().cancelOrderForce(orderId, params);

      if (response.isSuccess) {
        commonSnackBar(message: response.message);
      } else {}
    } catch (e) {}
  }

  Future<void> getOrderFareFrom(Map<String, dynamic> params) async {
    try {
      ResponseModel? response = await MakeOrderRepo().getOrderFareFrom(params);

      if (response.isSuccess) {
        Map<String, dynamic> data = response.response?.data;
        fare.value = data['fare'].toString();
        // distanceKm.value = data['distance'].toString();
        getFaireAmountResponse.value = ApiResponse.complete(data);
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        getFaireAmountResponse.value = ApiResponse.error(response.message);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getFaireAmountResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  void fetchVehicleQuotes(Map<String, dynamic> params) async {
    getVehicleOptionResponse.value = ApiResponse.initial("Initial");

    final data = await porterApi.getQuote(params);

    if (data != null && data['status']) {
      getPorterVehicleOptionModel.value =
          GetPorterVehicleOptionModel.fromJson(data['data']);
      getVehicleOptionResponse.value =
          ApiResponse.complete(getPorterVehicleOptionModel.value);
    } else {
      if (data != null) {
        final vehicles = data['data']['message'];
        getVehicleOptionResponse.value =
            ApiResponse.error(vehicles ?? AppStrings.somethingWentWrong);
      } else {
        getVehicleOptionResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
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

  Future<Map<String, String>> getAddressFromLatLng(
      double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final city = place.locality ?? '';
        final state = place.administrativeArea ?? '';
        final pincode = place.postalCode ?? '';

        return {
          ApiKeys.city: city,
          ApiKeys.state: state,
          ApiKeys.pincode: pincode,
        };
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  void createOrder() async {
    List<AddressDetails>? addressList = getAddressDetails.value.data;
    AddressDetails? selectedAddress;
    if (addressList != null) {
      selectedAddress = addressList[selectedIndex?.value ?? 0];
    }
    if (openedMessage != null) {
      Map<String, dynamic> addressData = await getAddressFromLatLng(
          double.parse(lat.value.toString()),
          double.parse(long.value.toString()));
      Map<String, dynamic> params = {
        ApiKeys.request_id: "${generateRequestId()}",
        // "delivery_instructions": {
        //   "instructions_list": [
        //     {
        //       "type": "text",
        //       "description": "handle with care"
        //     }
        //   ]
        // },
        ApiKeys.pickup_details: {
          ApiKeys.address: {
            ApiKeys.apartment_address: "",
            ApiKeys.street_address1:
                "${(openedMessage?.seller?.location == '' || openedMessage?.seller?.location == null) ? "N/A" : openedMessage?.seller?.location}",
            // // "street_address2": "Krishna Nagar Industrial Area",
            ApiKeys.landmark: "N/A",
            ApiKeys.city: "${addressData['city']}",
            ApiKeys.state: "${addressData['state']}",
            ApiKeys.pincode: "${addressData['pincode']}",
            ApiKeys.country: "India",
            ApiKeys.lat: double.parse(lat.value),
            ApiKeys.lng: double.parse(long.value),
            ApiKeys.contact_details: {
            ApiKeys.name: "${openedMessage?.seller?.name}",
            ApiKeys.phone_number: "${openedMessage?.seller?.contact}"
            }
          }
        },
          ApiKeys.drop_details: {
      ApiKeys.address: {
      ApiKeys.apartment_address: "${selectedAddress?.houseNo}",
      ApiKeys.street_address1: "${selectedAddress?.street}",
      ApiKeys.landmark: "${selectedAddress?.landmark}",
      ApiKeys.city: "${selectedAddress?.city}",
      ApiKeys.state: "${selectedAddress?.state}",
      ApiKeys.pincode: "${selectedAddress?.zipCode}",
      ApiKeys.country: "${selectedAddress?.country}",
      ApiKeys.lat: selectedAddress?.lat,
      ApiKeys.lng: selectedAddress?.lng,
      ApiKeys.contact_details: {
      ApiKeys.name: "${selectedAddress?.name}",
      ApiKeys.phone_number: "+91${selectedAddress?.phone}"
            }
          }
        },
ApiKeys.additional_comments: ""
      };

      final data = await porterApi.createOrder(params);
      if (data != null) {
        paymentResponseModel.value = PaymentResponseModel.fromJson(data);
        paymentResponse.value =
            ApiResponse.complete(paymentResponseModel.value);

        Map<String, dynamic> addOrderTabPara = {
          ApiKeys.message_id: openedMessage?.id,
          ApiKeys.other_user_id: openedMessage?.seller?.id,
          ApiKeys.price: "${orderValueController.text}",
          ApiKeys.order: data,
          // "rider": {},

          ApiKeys.ride_by: MakeOrderType.porter
        };
        sendMessageToOrderTab(params: addOrderTabPara);
        final chatViewController = Get.find<ChatViewController>();

        Map<String, dynamic> datadd = {
          ApiKeys.messageId: "${openedMessage?.id}",
          ApiKeys.order_status: true
        };
        await updateOrderStatus(datadd);
        chatViewController.emitEvent(ChatEmitEvents.messageReceived, {
          ApiKeys.conversation_id:
              openedMessage?.conversationId ?? openedMessage?.sender?.id,
          ApiKeys.page: 1,
          ApiKeys.is_online_user: businessId,
          ApiKeys.per_page_message: 30,
        });
      } else {}
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  void createSelfPickupOrder(
    String? messageId,
    String? userid,
    String? conversationId,
  ) async {
    Map<String, dynamic> addOrderTabPara = {
      ApiKeys.message_id: "$messageId",
      ApiKeys.other_user_id: userid,
      ApiKeys.price: "${orderValueController.text}",
      // "order": {},
      // "rider": {},
      ApiKeys.rider_id: "$userId",
      ApiKeys.ride_by: MakeOrderType.self
    };
    bool value = await sendMessageToOrderTab(params: addOrderTabPara);
    if (value) {
      commonSnackBar(
          message: AppStrings.orderCreatedBySelfPickup.tr);
      final chatViewController = Get.find<ChatViewController>();

      Map<String, dynamic> datadd = {
        ApiKeys.messageId: messageId,
        ApiKeys.order_status: true
      };
      await updateOrderStatus(datadd);
      chatViewController.emitEvent(ChatEmitEvents.messageReceived, {
        ApiKeys.conversation_id: conversationId ?? userId,
        ApiKeys.page: 1,
        ApiKeys.is_online_user: businessId,
        ApiKeys.per_page_message: 30,
      });
    }
  }

  void createRiderPickupOrder(
    String? messageId,
    String? userid,
    String? conversationId,
  ) async {
    Map<String, dynamic> addOrderTabPara = {
      ApiKeys.message_id: "$messageId",
      ApiKeys.other_user_id: userid,
      ApiKeys.price: "${orderValueController.text}",
      // "order": {},
      // "rider": {},
      // ApiKeys.rider_id: "$userId",
      ApiKeys.ride_by: MakeOrderType.rider
    };
    bool value = await sendMessageToOrderTab(params: addOrderTabPara);

    if (value) {
      final chatViewController = Get.find<ChatViewController>();

      // Map<String,dynamic>datadd={
      //   ApiKeys.messageId: messageId,
      //   ApiKeys.order_status : true
      // };
      // await updateOrderStatus(datadd);
      chatViewController.emitEvent(ChatEmitEvents.messageReceived, {
        ApiKeys.conversation_id: conversationId ?? userId,
        ApiKeys.page: 1,
        ApiKeys.is_online_user: businessId,
        ApiKeys.per_page_message: 30,
      });
    }
  }

  Future<bool?> cancelOrderApi(String orderId, String conversationId) async {
    final data = await porterApi.cancelOrder(orderId);
    if (data != null && data) {
      commonSnackBar(message: AppStrings.orderDeletedSuccessfully);
      final chatViewController = Get.find<ChatViewController>();

      chatViewController.emitEvent(ChatEmitEvents.messageReceived, {
        ApiKeys.conversation_id: conversationId,
        ApiKeys.page: 1,
        ApiKeys.is_online_user: businessId,
        ApiKeys.per_page_message: 30,
      });
      return data;
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
    return null;
  }

  Future<void> addAddressApi(double? lat, double? long) async {
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
      if (response.isSuccess) {
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

        commonSnackBar(message: response.message);
        Get.back();
        getAddressApi();
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> updateAddressApi(
      double? lat, double? long, String addressId) async {
    try {
      final addressData = {
        ApiKeys.name: nameController.value.text.trim(),
        ApiKeys.phone: phoneController.value.text.trim(),
        ApiKeys.house_no: houseNoController.value.text.trim(),
        ApiKeys.street: streetController.value.text.trim(),
        ApiKeys.landmark: landmarkController.value.text.trim(),
        ApiKeys.city: cityController.value.text.trim(),
        ApiKeys.state: stateController.value.text.trim(),
        ApiKeys.zip_code: zipController.value.text.trim(),
        ApiKeys.note: noteController.value.text.trim(),
        ApiKeys.country: "India",
        ApiKeys.type: "Home",
        ApiKeys.is_default: isDefault.value,
        ApiKeys.lat: lat,
        ApiKeys.lng: long,
      };
      ResponseModel? response =
          await MakeOrderRepo().updateAddress(addressData, addressId);
      if (response.isSuccess) {
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

        commonSnackBar(message: response.message);
        Get.back();
        getAddressApi();
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      ResponseModel? response = await MakeOrderRepo().deleteAddress(addressId);
      if (response.isSuccess) {
        commonSnackBar(message: response.message);
        Get.back();
        getAddressApi();
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

}
