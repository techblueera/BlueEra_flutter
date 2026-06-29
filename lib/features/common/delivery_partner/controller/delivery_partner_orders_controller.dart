import 'dart:async';
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
import '../../../../core/services/keyed_json_cache.dart';
import '../../../../core/services/location/location_service.dart';
import '../../../../core/services/location_permission_handler.dart';
import '../../../chat/auth/model/rider_orders_details_model.dart';
import '../../../chat/auth/repo/make_order_repo.dart';
import '../../../chat/auth/stream/get_orders_stream.dart';
import '../model/rider_shops_list_grocery.dart';
import 'package:flutter/services.dart';



class DeliverPartnerOrdersController extends GetxController {
  final List<DeliveryPartnerOrdersTab> deliveryPartnerOrdersTabs =
      DeliveryPartnerOrdersTab.values;
  RxInt selectedDeliveryPartnerOrderIndex = 0.obs;

  final List<PickUpTab> pickUpTabs = [
    PickUpTab.orders,
    PickUpTab.completed,
    PickUpTab.cancel,
    PickUpTab.rejected,
  ];
  Rx<PickUpTab> selectedPickUp = PickUpTab.orders.obs;
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
  final MethodChannel platformData =
  const MethodChannel('com.vahcare.lab/pip');
  late Stream<dynamic> stream;
  StreamSubscription? subscription;

  // Guards against opening a second SSE connection when fetchStream is
  // called by more than one consumer (e.g. the rider screen owning the
  // stream while DeliveryPartnerOrders is also mounted). Each call to
  // getOrderFromUserStream() opens a fresh HTTP/SSE connection, so we
  // must keep exactly one alive at a time.
  bool isStreaming = false;

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
    // Idempotent: a stream is already live, so don't open another SSE
    // connection (multiple consumers share this singleton controller).
    if (isStreaming) return;
    isStreaming = true;
    ordersListResponse.value =
        ApiResponse.complete('');
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
    }, onDone: () {
      // Connection closed by the server — clear the flag so a later
      // fetchStream() can re-open it.
      isStreaming = false;
    });
  }

  /// Cancels the live SSE subscription and resets [isStreaming] so the
  /// stream can be cleanly restarted later. Used by the owning screen
  /// (e.g. RiderServiceScreen) on dispose.
  void stopStream() {
    subscription?.cancel();
    subscription = null;
    isStreaming = false;
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
    if(onGoingOrders.isEmpty){
      setPipStatus(false);
    } else {
      setPipStatus(true);
    }
    ordersListResponse.value = ApiResponse.complete(riderOrdersList);

  }
  Future<void> setPipStatus(bool isEnabled) async {
    await platformData.invokeMethod(
      'updatePipStatus',
      {"isEnabled": isEnabled},
    );
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
  /// Accept or reject a fare-call ride order using the ride-action endpoint.
  Future<bool> rideAction(String action, String orderId) async {
    try {
      final response = await MakeOrderRepo().rideActionApi(
        {'action': action},
        orderId,
      );
      if (response.isSuccess) {
        commonSnackBar(
            message: response.message ?? (action == 'reject'
                ? 'Ride order rejected'
                : 'Ride order accepted'));
        return true;
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  /// Claims an order surfaced on the rider's active route (the
  /// ROUTE_ORDER_AVAILABLE notification → "Claim Order"). Returns true only
  /// when the claim succeeds (200). Handles the documented failure codes:
  ///   409 → just taken by another rider (refresh the list)
  ///   422 → no longer on route / preference mismatch
  ///   400 → rider has no active route
  /// See docs/backend/NEW_NOTIFICATIONS_FRONTEND_GUIDE.md.
  Future<bool> claimRouteOrder(String orderId) async {
    try {
      final response = await MakeOrderRepo().claimRouteOrderApi(orderId);
      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? 'Order claimed');
        // Refresh so the claimed order moves into the active list.
        fetchStream();
        return true;
      }
      final code = response.statusCode ?? response.response?.statusCode;
      switch (code) {
        case 409:
          commonSnackBar(
              message: response.message ?? 'Just taken by another rider');
          fetchStream();
          break;
        case 422:
          commonSnackBar(
              message: response.message ??
                  'This order is no longer available on your route');
          fetchStream();
          break;
        case 400:
          commonSnackBar(
              message: response.message ?? 'You have no active route');
          break;
        default:
          commonSnackBar(
              message: response.message ?? AppStrings.somethingWentWrong);
      }
      return false;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  /// Multi-shop: tells the backend the rider has reached [businessId]'s shop.
  /// Returns true on success. See the master integration guide §5.3.
  Future<bool> multiShopStopArrive(String orderId, String businessId) async {
    try {
      final response = await MakeOrderRepo()
          .multiShopStopArriveApi(orderId: orderId, businessId: businessId);
      if (response.isSuccess) {
        return true;
      }
      commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      return false;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  /// Multi-shop: verifies [businessId]'s pickup OTP. The matching pickup card
  /// flips to consumed (via the `riderOtpUpdated` socket) on success. A 400
  /// means a missing/wrong OTP. Returns true only when the pickup is accepted.
  Future<bool> multiShopStopPickup(
      String orderId, String businessId, String pickupOTP) async {
    try {
      final response = await MakeOrderRepo().multiShopStopPickupApi(
          orderId: orderId, businessId: businessId, pickupOTP: pickupOTP);
      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? 'Picked up');
        return true;
      }
      final code = response.statusCode ?? response.response?.statusCode;
      commonSnackBar(
          message: response.message ??
              (code == 400
                  ? 'Incorrect OTP'
                  : AppStrings.somethingWentWrong));
      return false;
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
            message: response.message ?? "Ride Completed Successfully!");
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

  /// Guards against overlapping network fetches (e.g. screen re-entry /
  /// pull-to-refresh firing while a previous request is still in flight).
  bool _ordersInFlight = false;

  /// Loads the rider's booking-orders list.
  ///
  /// Stale-while-revalidate so the dashboard opens smoothly: on first load it
  /// renders the last-cached orders instantly (no spinner), then refreshes
  /// from the network in the background and re-caches. The cache is keyed by
  /// user id and wiped on logout. Concurrent calls are de-duplicated, and the
  /// LOADING/ERROR state is only surfaced when there's nothing cached to show.
  Future<void> getRidersBookingOrders({bool forceRefresh = false}) async {
    // 1) Instant render from cache on the first load.
    final hasData =
        completedOrders.isNotEmpty || cancelledOrders.isNotEmpty;
    if (!forceRefresh && !hasData) {
      final cached = await riderOrdersCache.get(userId);
      final cachedList = cached?['orders'];
      if (cachedList is List && cachedList.isNotEmpty) {
        ordersListResponse.value = ApiResponse.complete(_applyOrders(cachedList));
      }
    }

    // 2) De-dupe concurrent network refreshes.
    if (_ordersInFlight) return;
    _ordersInFlight = true;

    // Only show a loading state when we have nothing on screen yet; otherwise
    // refresh silently behind the already-rendered (cached) list.
    final hasAnythingToShow =
        completedOrders.isNotEmpty || cancelledOrders.isNotEmpty;
    if (!hasAnythingToShow) {
      ordersListResponse.value = ApiResponse.loading('loading');
    }

    try {
      ResponseModel? response = await MakeOrderRepo().getRidersBookingOrders();
      if (response.isSuccess) {
        if (response.response?.data is List) {
          final rawList = response.response?.data as List;
          ordersListResponse.value = ApiResponse.complete(_applyOrders(rawList));
          // Cache the raw list for an instant render next time.
          await riderOrdersCache.save(userId, {'orders': rawList});
        } else if (!hasAnythingToShow) {
          ordersListResponse.value = ApiResponse.error();
        }
      } else if (!hasAnythingToShow) {
        // Surface the error only when there's no cached list to fall back on.
        ordersListResponse.value = ApiResponse.error(
            response.message ?? AppStrings.somethingWentWrong);
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
      }
    } catch (e) {
      if (!hasAnythingToShow) {
        ordersListResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } finally {
      _ordersInFlight = false;
    }
  }

  /// Parses a raw orders list (from cache or API) into the bucketed reactive
  /// lists and returns the flat parsed list.
  List<RiderOrdersDetailsModel> _applyOrders(List rawList) {
    final parsedList = rawList
        .map((item) => RiderOrdersDetailsModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
    completedOrders.value = parsedList
        .where((e) => e.status?.toLowerCase() == 'completed')
        .toList();
    cancelledOrders.value = parsedList
        .where((e) => e.status?.toLowerCase() == 'cancelled')
        .toList();
    return parsedList;
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
        // Mark order as delivered/completed after OTP verification
        await completePickupRiderApi(orderId);
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
