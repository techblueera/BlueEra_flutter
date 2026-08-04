
import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class MakeOrderRepo extends BaseService {
  Future<ResponseModel> messageToOrder(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        messageToOrderTab,
        isMultipart: false,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> uploadThePickupOtp(Map<String,dynamic> params,String orderId) async {
    final response = await ApiBaseHelper().postHTTP(
      updateThePickupOtpUrl(orderId),
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  /// Claim a route order (ROUTE_ORDER_AVAILABLE notification → "Claim Order").
  /// Returns the raw ResponseModel so the caller can branch on the
  /// 200/409/422/400 status codes documented in the notifications guide.
  Future<ResponseModel> claimRouteOrderApi(String orderId) async {
    final response = await ApiBaseHelper().postHTTP(
      claimRouteOrder(orderId),
      showProgress: false,
      params: {},
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Multi-shop: rider arrives at a shop. No body. See the master guide §5.3.
  Future<ResponseModel> multiShopStopArriveApi(
      {required String orderId, required String businessId}) async {
    final response = await ApiBaseHelper().patchHTTP(
      multiShopStopArrive(orderId, businessId),
      showProgress: false,
      params: {},
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Multi-shop: rider enters that shop's pickup OTP. Body: `{pickupOTP}`.
  /// 400 if missing/wrong; on success that shop's card flips to consumed.
  Future<ResponseModel> multiShopStopPickupApi(
      {required String orderId,
      required String businessId,
      required String pickupOTP}) async {
    final response = await ApiBaseHelper().patchHTTP(
      multiShopStopPickup(orderId, businessId),
      showProgress: false,
      params: {'pickupOTP': pickupOTP},
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> verifyPayment(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        verifyPaymentApi,
        isMultipart: false,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  // NOTE: `updateLiveLocationRep` lived here — a second POST to
  // `map-service/api/provider/location` taking a free-form params map, which is
  // how the body drifted to include `userId`. There is now one implementation
  // with a fixed { lat, lng } body: MapServiceRepo.publishProviderLocationRepo.

  Future<ResponseModel> getAddress() async {
    final response = await ApiBaseHelper().getHTTP(
        getAddressApi,
        showProgress: false,
     onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> addAddress(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        getAddressApi,
        showProgress: false,
     params: params,
     onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> updateAddress(Map<String,dynamic> params,String AddressId) async {
    final response = await ApiBaseHelper().putHTTP(
        updateExistingAddress(AddressId),
        showProgress: true,
     params: params,
     onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> deleteAddress(String AddressId) async {
    final response = await ApiBaseHelper().deleteHTTP(
        updateExistingAddress(AddressId),
        showProgress: true,
     onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> sendOrderRequestToRider(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        sendOrderReqToRider,
        showProgress: false,
     params: params,
     onError: (error) {}, onSuccess: (data) {});

    return response;
  }
  Future<ResponseModel> getOrderFareFrom(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        getOrderFare,
        showProgress: false,
     params: params,
     onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> updateOrderStatusFromPt(Map<String,dynamic> params,String orderId) async {
    final response = await ApiBaseHelper().patchHTTP(
        updateOrderStatusFromPialot(orderId),
        showProgress: true,

     params: params,
     onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> updateRideOrParcelOrderStatusApi(Map<String,dynamic> params,String orderId) async {
    final response = await ApiBaseHelper().patchHTTP(
        updateRideOrParcelOrderStatus(orderId),
        // No global progress dialog: accept/reject happens on ONE card in a
        // list, and a full-screen blocker hides the very card the rider just
        // acted on. The card shows its own inline loader instead.
        showProgress: false,

     params: params,
     onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> verifyPickupOtpRideOrParcelApi(Map<String,dynamic> params,String orderId) async {
    final response = await ApiBaseHelper().postHTTP(
        verifyPickupOtpRideOrParcel(orderId),
        showProgress: false,
     params: params,
     onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> completePickupRiderApi(Map<String,dynamic> params,String orderId) async {
    final response = await ApiBaseHelper().postHTTP(
        completePickupRider(orderId),
        // No global progress dialog — the slide-to-complete controls show their
        // own inline "Completing…" loader while this runs.
        showProgress: false,
     params: params,
     onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  /// Rider rates the customer of a completed order. One vote per order —
  /// a repeat comes back as `alreadyRated` rather than a hard failure.
  Future<ResponseModel> rateCustomerApi({
    required String userId,
    required String orderId,
    required int rating,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
        rateCustomer(userId),
        showProgress: false,
        params: {'rating': rating, 'orderId': orderId},
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  /// Read a customer's rider-given rating aggregate `{ average, count }`.
  Future<ResponseModel> getCustomerRatingApi(String userId) async {
    final response = await ApiBaseHelper().getHTTP(
        customerRating(userId),
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> rideActionApi(Map<String, dynamic> params, String orderId) async {
    final response = await ApiBaseHelper().postHTTP(
        rideAction(orderId),
        showProgress: false,
        params: params,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> cancelFareCallQueueApi(String orderId) async {
    final response = await ApiBaseHelper().postHTTP(
        cancelFareCallQueue(orderId),
        showProgress: false,
        params: {},
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> getRidersBookingOrders() async {
    final response = await ApiBaseHelper().getHTTP(
        getRiderBookingList,
        showProgress: false,
     onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> getRiderRejectOrderList() async {
    final response = await ApiBaseHelper().getHTTP(
        getRiderRejectOrder,
        showProgress: false,
     onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> updatePaymentStausByUser(String orderId) async {
    final response = await ApiBaseHelper().patchHTTP(
        updatePaymentStaus(orderId),
        showProgress: false,

     onError: (error) {}, onSuccess: (data) {});
    return response;
  }  Future<ResponseModel> cancelOrderForce(String orderId,Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().patchHTTP(
        cancelOrderForceFully(orderId),
        showProgress: false,
     params:params ,
     onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> deliverOtpVerifyRepo(
      {
        required String orderId,
        required Map<String, dynamic> params
      }
      ) async {
    final response = await ApiBaseHelper().postHTTP(
        deliverOtpVerify(orderId),
        showProgress: false,
        params:params ,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> updateOrderStatusFromAdminRepo(Map<String,dynamic> params, String orderId) async {
    final response = await ApiBaseHelper().patchHTTP(
        updateOrderStatusFromAdmin(orderId),
        showProgress: false,
        params: params,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> getGroceryShopsList({required String orderId,required String latitude,required String longitude}) async {
    final response = await ApiBaseHelper().getHTTP(
        getGroceryAvailableShops(latitude: latitude,longitude: longitude,orderId: orderId),
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> groceryAcceptOrderApi({required String orderId,required Map<String,dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
        groceryAcceptOrder(orderId),
        params: params,
        showProgress: true,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
 Future<ResponseModel> groceryRejctOrderApi({required String orderId,required Map<String,dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
        groceryRejectOrder(orderId),
        params: params,
        showProgress: true,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

 Future<ResponseModel> createGroceryOrderConvo({required Map<String,dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
        createGroceryOrderConvoApi,
        params: params,
        showProgress: true,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }


}
