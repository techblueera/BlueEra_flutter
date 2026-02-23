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
  Future<ResponseModel> subscriptionPlansGetApi({required Map<String, String> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
        subscriptionPlansGet,
        params: queryParams,
        onError: (error) {},
        showProgress: false,
        onSuccess: (data) {});

    return response;
  }
  Future<ResponseModel> userCurrentPlanApi(Map<String,dynamic>? params) async {
    final response = await ApiBaseHelper().getHTTP(
        userCurrentPlan,
        onError: (error) {},
        params: params,
        showProgress: true,
        onSuccess: (data) {});

    return response;
  }

  /// Trial SUBSCRIPTION....
  Future<ResponseModel> subscriptionTrialInitiateRepo(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
        params: params,
        subscriptionTrialInitiate,
        onError: (error) {},
        onSuccess: (data) {});

    return response;
  }

  /// VERIFY TRIAL SUBSCRIPTION .....
  Future<ResponseModel> verifyTrialSubscriptionRepo(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
        params: params,
        subscriptionVerification,
        onError: (error) {},
        onSuccess: (data) {});

    return response;
  }

}
