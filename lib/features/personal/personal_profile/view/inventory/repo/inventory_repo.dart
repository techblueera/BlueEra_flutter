import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class InventoryRepo extends BaseService {

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

  ///Get Own Products...
  Future<ResponseModel> fetchOwnDraftedAndPublicProductsApi({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      getOwnDraftedAndPublicProducts,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Fetch InventoryBasedSearchProduct...
  Future<ResponseModel> fetchInventoryBasedSearchProductApi({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      getInventoryBasedSearchProduct,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Clone Product Variant...
  Future<ResponseModel> cloneProductVariantApi({required List<Map<String, dynamic>> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      cloneProductInventory,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


}