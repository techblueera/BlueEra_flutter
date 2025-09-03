import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class SubscriptionRepo extends BaseService {
  ///GET SUBSCRIPTION LIST...
  Future<ResponseModel> subscriptionPlan() async {
    final response = await ApiBaseHelper().getHTTP(
      getSubscriptionPlans,
      onError: (error) {},
      onSuccess: (data) {},
    );

    return response;
  }

  ///GET SUBSCRIPTION OFFER LIST...
  Future<ResponseModel> subscriptionOffer() async {
    final response = await ApiBaseHelper().getHTTP(
      getSubscriptionOffer,
      onError: (error) {},
      onSuccess: (data) {},
    );

    return response;
  }

  ///CREATE SUBSCRIPTION....
  Future<ResponseModel> createSubscriptionRepo(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
        params: params,
        subscriptionCreate,
        onError: (error) {},
        onSuccess: (data) {});

    return response;
  }

  ///CANCEL SUBSCRIPTION....
  Future<ResponseModel> cancelSubscriptionRepo(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        params: params,
        subscriptionCancel,
        onError: (error) {},
        onSuccess: (data) {});

    return response;
  }

  ///SUBSCRIPTION VERIFY.....
  Future<ResponseModel> verifySubscriptionRepo(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
        params: params,
        subscriptionVerification,
        onError: (error) {},
        onSuccess: (data) {});

    return response;
  }
}
