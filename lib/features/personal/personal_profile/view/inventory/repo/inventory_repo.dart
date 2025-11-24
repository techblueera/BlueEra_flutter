import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class InventoryRepo extends BaseService {

  /// Generate Ai Product...
  Future<ResponseModel> generateAiProductContentRepo({required Map<String, dynamic> params}) async {
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
  Future<ResponseModel> fetchOwnDraftedAndPublicProductsRepo({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      getOwnDraftedAndPublicProducts,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Fetch InventoryBasedSearchProduct...
  Future<ResponseModel> fetchInventoryBasedSearchProductRepo({required Map<String, dynamic> queryParams}) async {
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
  Future<ResponseModel> cloneProductVariantRepo({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      cloneProductInventory,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Fetch Suggested Products...
  Future<ResponseModel> fetchSuggestedProductRepo({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      storesByCategory,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

}