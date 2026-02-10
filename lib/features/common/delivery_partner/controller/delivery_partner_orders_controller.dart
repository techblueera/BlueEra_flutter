import 'dart:async';
import 'dart:developer';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/api/apiService/response_model.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../../../core/services/location/location_service.dart';
import '../../../../core/services/location_permission_handler.dart';
import '../../../chat/auth/model/rider_orders_details_model.dart';
import '../../../chat/auth/repo/make_order_repo.dart';
import '../../../chat/auth/stream/get_orders_stream.dart';
import '../model/rider_shops_list_grocery.dart';

class DeliverPartnerOrdersController extends GetxController {
  final List<DeliveryPartnerOrdersTab> deliveryPartnerOrdersTabs =
      DeliveryPartnerOrdersTab.values;
  RxInt selectedDeliveryPartnerOrderIndex = 0.obs;

  final List<PickUpTab> pickUpTabs = PickUpTab.values;
  Rx<PickUpTab> selectedPickUp = PickUpTab.newOrder.obs;
  RxList<RiderOrdersDetailsModel> riderOrdersList =
      <RiderOrdersDetailsModel>[].obs;
  Rx<ApiResponse> ordersListResponse = ApiResponse.initial('Initial').obs; // Declare your RxLists
  Rx<ApiResponse> orderRiderShopListResponse = ApiResponse.initial('Initial').obs; // Declare your RxLists
  Rx<ApiResponse> verifyDeliveredOtpResponse = ApiResponse.initial('Initial').obs; // Declare your RxLists
  RxList<RiderOrdersDetailsModel> riderOrdersDetailsModel = <RiderOrdersDetailsModel>[].obs;
  RxList<RiderOrdersDetailsModel> newOrders = <RiderOrdersDetailsModel>[].obs;
  RxList<RiderOrdersDetailsModel> onGoingOrders = <RiderOrdersDetailsModel>[].obs;
  RxList<RiderOrdersDetailsModel> completedOrders = <RiderOrdersDetailsModel>[].obs;
  RxList<RiderOrdersDetailsModel> cancelledOrders = <RiderOrdersDetailsModel>[].obs;
  RxList<RiderOrdersDetailsModel> rejectedOrders = <RiderOrdersDetailsModel>[].obs;
  RxList<BusinessListModel> riderBusinessList = <BusinessListModel>[].obs;
  RxList<BusinessListModel> selectedShops = <BusinessListModel>[].obs;

  late Stream<dynamic> stream;
  StreamSubscription? subscription;

  void onSelectTab(BusinessListModel id){
    if(selectedShops.contains(id)){
      selectedShops.remove(id);
    }else{
      selectedShops.add(id);
    }
  }
  Map<String, dynamic> buildGroceryOrderBody(
      List<BusinessListModel> selectedShops,
      ) {
    return {
      ApiKeys.groceryOrderDetails: {
        ApiKeys.businesses: selectedShops.map((business) {
          return {
            ApiKeys.businessId: business.businessId,
            ApiKeys.items: business.availableProducts.map((product) {
              return {
                ApiKeys.variantId: product.variant.id,
                ApiKeys.inventoryId: product.inventory.id,
                ApiKeys.isPickedUp: false,
              };
            }).toList(),
          };
        }).toList(),
      }
    };
  }

  Future<void> fetchStream() async {
    ordersListResponse.value =
        ApiResponse.complete('');
    stream = await getOrderFromUserStream();
    subscription = stream.listen((event) {
      log("jklnclsdjknclskjcnsldcjn ${event}");
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
  Future<bool> updateRideOrParcelOrderStatusApi(Map<String,dynamic> params,String orderId) async {
    try {
      ResponseModel? response = await MakeOrderRepo().updateRideOrParcelOrderStatusApi(params,orderId);
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
  Future<bool> verifyPickupOtpRideOrParcelApi(Map<String,dynamic> params,String orderId) async {
    try {
      ResponseModel? response = await MakeOrderRepo().verifyPickupOtpRideOrParcelApi(params,orderId);
      if (response.isSuccess ) {
        commonSnackBar(
            message: response.message ?? "OTP successfully verified.");
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
  Future<bool> completePickupRiderApi(String orderId) async {
    try {
      final locationResult = await LocationPermissionHandler().getCurrentLocation();
      Map<String,dynamic> params={
        ApiKeys.latitude: locationResult.position?.latitude ?? 0,
        ApiKeys.longitude:locationResult.position?.longitude??0
      };
      ResponseModel? response = await MakeOrderRepo().completePickupRiderApi(params,orderId);
      if (response.isSuccess ) {
        commonSnackBar(
            message: response.message ?? "OTP successfully verified.");
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
        final List<dynamic> json = response.response?.data;
        riderBusinessList.value = json.map((e)=> BusinessListModel.fromJson(e)).toList();
        orderRiderShopListResponse.value = ApiResponse.complete([]);
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        orderRiderShopListResponse.value = ApiResponse.error(response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      orderRiderShopListResponse.value = ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }
  Future<void> acceptOrder(String orderId) async {
    try {
      ResponseModel? response = await MakeOrderRepo().groceryAcceptOrderApi(
          orderId: orderId, params: buildGroceryOrderBody(selectedShops));
      if (response.isSuccess ) {
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  Future<void> rejectOrder(String orderId) async {
    try {
      ResponseModel? response = await MakeOrderRepo().groceryRejctOrderApi(
          orderId: orderId, params: buildGroceryOrderBody(selectedShops));
      if (response.isSuccess ) {

      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  Future<void> makeGroceryOrderConversationApi({required String orderId,required Map<String,dynamic> orderDetails}) async {
    try {
      List<String> shopsUserId=selectedShops.map((e)=>e.businessId).toList();
      Map<String,dynamic> params={
        ApiKeys.userIds:shopsUserId,
        ApiKeys.groceryorderId: orderId,
        ApiKeys.order: orderDetails,
        ApiKeys.rider: {
          ApiKeys.riderId: userId,
        },
        ApiKeys.riderId: userId,
        ApiKeys.ride_by: MakeOrderType.rider
      };
      ResponseModel? response = await MakeOrderRepo().createGroceryOrderConvo(
          params: params);
      if (response.isSuccess ) {

      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }


}
