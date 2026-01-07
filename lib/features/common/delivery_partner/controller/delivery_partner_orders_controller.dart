import 'dart:async';
import 'dart:developer';
import 'package:geolocator/geolocator.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/api/apiService/response_model.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../../../core/services/location/location_service.dart';
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
    ordersListResponse.value =
        ApiResponse.complete('');
    stream = await getOrderFromUserStream();
    subscription = stream.listen((event) {
     log("kadskasdjchnsdkjs ${event}");
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
      log("kadskasdjchnsdkjs Error :: ${error}");
      ordersListResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }, onDone: () {});
  }

  void updateOrders(List<RiderOrdersDetailsModel> list) {
    riderOrdersList.value = list;

    // pending, accepted, rejected, in-progress, picked-up, completed, cancelled

    // Filter by status
    newOrders.value = list.where((e) => e.status == 'pending').toList();
    onGoingOrders.value = list.where((e)
               => e.status == 'in-progress'
                   || e.status == 'picked-up'
                     || e.status == 'accepted'|| e.status == 'confirmed'
                      || e.status == 'payment-pending').toList();

    ordersListResponse.value = ApiResponse.complete(riderOrdersList);

  }

  Future<bool> updateOrderStatusFromPialot(Map<String,dynamic> params,String orderId) async {
    try {
      ResponseModel? response = await MakeOrderRepo().updateOrderStatusFromPt(params,orderId);
      if (response.isSuccess ) {
        commonSnackBar(
            message: response.message ?? "${params[ApiKeys.action]=='reject'?"Your Ride Order Rejected Successfully":"Your Ride Order Accepted Successfully" }");
      return true;
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
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
              parsedList.where((e) => e.status?.toLowerCase() == 'completed').toList();

          cancelledOrders.value =
              parsedList.where((e) => e.status?.toLowerCase() == 'cancelled').toList();

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
  Future<void> getRiderRejectOrderList() async {
    try {
      ordersListResponse.value = ApiResponse.initial('initial');
      ResponseModel? response = await MakeOrderRepo().getRiderRejectOrderList();
      if (response.isSuccess ) {

        if (response.response?.data is List) {
          final parsedList = (response.response?.data as List)
              .map((item) => RiderOrdersDetailsModel.fromJson(
            Map<String, dynamic>.from(item),
          ))
              .toList();
          rejectedOrders.value =parsedList;
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
      verifyingOtpMap[orderId] = true;
      otpVerifiedMap[orderId] = false;

      final response = await MakeOrderRepo().deliverOtpVerifyRepo(
        orderId: orderId,
        params: {ApiKeys.deliveryOTP: deliveredOtp},
      );


      verifyingOtpMap[orderId] = false;

      if (response.isSuccess) {

        otpVerifiedMap[orderId] = true;
        commonSnackBar(message: response.message ?? 'OTP successfully verified.');
      } else {

        otpVerifiedMap[orderId] = false;
        verifyDeliveredOtpResponse.value = ApiResponse.error(
          response.message ?? AppStrings.somethingWentWrong,
        );
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {

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
  Future<void> getGroceryShopsList(String orderId) async {
    try {
      Map<String, dynamic>? locationMap= await LocationService.fetchLocation(openSettingsOnDeny: true);
      Position? position=locationMap?['position'];
      ResponseModel? response = await MakeOrderRepo().getGroceryShopsList(orderId: orderId,longitude: '${position?.longitude}',latitude: '${position?.latitude}');
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
