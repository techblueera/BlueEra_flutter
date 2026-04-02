
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
  Future<ResponseModel> verifyPayment(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        verifyPaymentApi,
        isMultipart: false,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> updateLiveLocationRep(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        updateLiveLocation,
        isMultipart: false,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
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
        showProgress: true,

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
        showProgress: true,
     params: params,
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
