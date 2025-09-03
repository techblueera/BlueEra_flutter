import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class PaymentRepo extends BaseService {
  ///Channel UnMute User...
  Future<ResponseModel> bankDetailsRepo(
      {required String channelId, required Map<String, dynamic> params}) async {
    String bankDetailsUrl = bankDetails(channelId);
    final response = await ApiBaseHelper().putHTTP(
      bankDetailsUrl,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getBankDetailsRepo(
      {required String channelId}) async {
    String bankDetailsUrl = bankDetails(channelId);
    final response = await ApiBaseHelper().getHTTP(
      bankDetailsUrl,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> deleteBankDetailsRepo(
      {required String channelId}) async {
    String bankDetailsUrl = bankDetails(channelId);
    final response = await ApiBaseHelper().deleteHTTP(
      bankDetailsUrl,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

}
