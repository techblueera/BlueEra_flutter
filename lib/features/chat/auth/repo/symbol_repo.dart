
import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class SymbolRepo extends BaseService {
  Future<ResponseModel> fetchSymbolFeed({Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().getHTTP(
        symbolFeedApi,
        params: params,
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> createSymbol(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        createSymbolApi,
        showProgress: true,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> getAllSymbolsSingleUser(String id) async {
    final response = await ApiBaseHelper().getHTTP(
        getAllSymbolOneUser(id),
        showProgress: false,
         onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> deleteSymbol(String sumbolId) async {
    final response = await ApiBaseHelper().deleteHTTP(
        deleteSymbolApi(sumbolId),
        showProgress: true,
         onError: (error) {}, onSuccess: (data) {});
    return response;
  }

}
