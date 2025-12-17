
import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class SymbolRepo extends BaseService {
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

}
