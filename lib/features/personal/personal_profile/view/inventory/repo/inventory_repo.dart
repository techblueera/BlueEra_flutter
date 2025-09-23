import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class InventoryRepo extends BaseService{

  ///Add Product...
  Future<ResponseModel> addService({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      createService,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Add Product...
  Future<ResponseModel> generateAiProductContent({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      generateAiContent,
      params: params,
      isMultipart: true,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

}