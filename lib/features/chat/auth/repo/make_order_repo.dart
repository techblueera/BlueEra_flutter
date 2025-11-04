
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
  Future<ResponseModel> verifyPayment(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        verifyPaymentApi,
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

}
