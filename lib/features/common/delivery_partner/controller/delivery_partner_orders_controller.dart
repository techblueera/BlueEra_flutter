import 'dart:async';
import 'dart:convert';
import 'dart:developer';


import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/api/apiService/response_model.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../../chat/auth/model/rider_orders_details_model.dart';
import '../../../chat/auth/repo/make_order_repo.dart';
import '../../../chat/auth/stream/get_orders_stream.dart';

class DeliverPartnerOrdersController extends GetxController {
  final List<DeliveryPartnerOrdersTab> deliveryPartnerOrdersTabs =
      DeliveryPartnerOrdersTab.values;
  RxInt selectedDeliveryPartnerOrderIndex = 0.obs;

  final List<PickUpTab> pickUpTabs = PickUpTab.values;
  Rx<PickUpTab> selectedPickUp = PickUpTab.newOrder.obs;
  RxList<RiderOrdersDetailsModel> riderOrdersList =
      <RiderOrdersDetailsModel>[].obs;
  Rx<ApiResponse> ordersListResponse = ApiResponse.initial('Initial').obs; // Declare your RxLists
  Rx<ApiResponse> verifyDeliveredOtpResponse = ApiResponse.initial('Initial').obs; // Declare your RxLists
  RxList<RiderOrdersDetailsModel> riderOrdersDetailsModel = <RiderOrdersDetailsModel>[].obs;
  RxList<RiderOrdersDetailsModel> newOrders = <RiderOrdersDetailsModel>[].obs;
  RxList<RiderOrdersDetailsModel> onGoingOrders = <RiderOrdersDetailsModel>[].obs;
  RxList<RiderOrdersDetailsModel> completedOrders = <RiderOrdersDetailsModel>[].obs;
  RxList<RiderOrdersDetailsModel> cancelledOrders = <RiderOrdersDetailsModel>[].obs;
  RxList<RiderOrdersDetailsModel> rejectedOrders = <RiderOrdersDetailsModel>[].obs;

  late Stream<dynamic> stream;
  StreamSubscription? subscription;

  Future<void> fetchStream() async {
    stream = await getOrderFromUserStream();
    subscription = stream.listen((event) {
      if (event is List) {
        List<RiderOrdersDetailsModel> riderOrdersList = event
            .map((item) => RiderOrdersDetailsModel.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList();

        updateOrders(riderOrdersList);

      } else {
        ordersListResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    }, onError: (error) {
      ordersListResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }, onDone: () {});
  }

  void updateOrders(List<RiderOrdersDetailsModel> list) {
    riderOrdersList.value = list;

    // pending, accepted, rejected, in-progress, picked-up, completed, cancelled

    // Filter by status
    newOrders.value = list.where((e) => e.status == 'pending').toList();
    onGoingOrders.value = list.where((e) => e.status == 'in-progress' || e.status == 'picked-up' || e.status == 'accepted').toList();
    // completedOrders.value = list.where((e) => e.status == 'completed').toList();
    // cancelledOrders.value = list.where((e) => e.status == 'cancelled').toList();
    // rejectedOrders.value = list.where((e) => e.status == 'rejected').toList();

    ordersListResponse.value = ApiResponse.complete(riderOrdersList);

  }

  Future<void> updateOrderStatusFromPialot(Map<String,dynamic> params,String orderId) async {
    try {
      ResponseModel? response = await MakeOrderRepo().updateOrderStatusFromPt(params,orderId);
      if (response.isSuccess ) {
        commonSnackBar(
            message: response.message ?? "Order Status Updated Successfully");
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> getRidersBookingOrders() async {
    try {
      ordersListResponse.value = ApiResponse.initial('initial');
      ResponseModel? response = await MakeOrderRepo().getRidersBookingOrders();
      if (response.isSuccess ) {


        if (response.response?.data is List) {
          final parsedList = (response.response?.data as List)
              .map((item) => RiderOrdersDetailsModel.fromJson(
            Map<String, dynamic>.from(item),
          ))
              .toList();

          // List<RiderOrdersDetailsModel> riderOrdersDetailsModel = parsedList;

          completedOrders.value =
              parsedList.where((e) => e.status?.toLowerCase() == 'confirmed').toList();

          cancelledOrders.value =
              parsedList.where((e) => e.status?.toLowerCase() == 'cancelled').toList();

          rejectedOrders.value =
              parsedList.where((e) => e.status?.toLowerCase() == 'pending').toList();

          ordersListResponse.value = ApiResponse.complete(parsedList);
        }else{
          ordersListResponse.value=ApiResponse.error();
        }

      } else {
        ordersListResponse.value = ApiResponse.error(response.message ?? AppStrings.somethingWentWrong);

        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
      }

    } catch (e) {
      ordersListResponse.value = ApiResponse.error(AppStrings.somethingWentWrong);
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  final otpVerifiedMap = <String, bool>{}.obs;
  final verifyingOtpMap = <String, bool>{}.obs;

  Future<void> verifyDeliveredOtp(String orderId, String deliveredOtp) async {
    try {
      // Start loader for this order
      verifyingOtpMap[orderId] = true;
      otpVerifiedMap[orderId] = false;

      final response = await MakeOrderRepo().deliverOtpVerifyRepo(
        orderId: orderId,
        params: {ApiKeys.deliveryOTP: deliveredOtp},
      );

      // Stop loader
      verifyingOtpMap[orderId] = false;

      if (response.isSuccess) {
        // OTP verified successfully
        otpVerifiedMap[orderId] = true;
        commonSnackBar(message: response.message ?? 'OTP successfully verified.');
      } else {
        // OTP verification failed
        otpVerifiedMap[orderId] = false;
        verifyDeliveredOtpResponse.value = ApiResponse.error(
          response.message ?? AppStrings.somethingWentWrong,
        );
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      // Stop loader even if exception
      verifyingOtpMap[orderId] = false;
      otpVerifiedMap[orderId] = false;

      verifyDeliveredOtpResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> cancelOrderFromPialot(Map<String,dynamic> params, String orderId) async {
    try {
      ResponseModel? response = await MakeOrderRepo().updateOrderStatusFromAdminRepo(params, orderId);
      if (response.isSuccess ) {
        commonSnackBar(
            message: response.message ?? "Order Status Updated Successfully");
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

}
