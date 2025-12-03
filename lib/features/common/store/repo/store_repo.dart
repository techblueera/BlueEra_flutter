import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';

class StoreRepo extends BaseService {
  ///GET STORE......
  Future<ResponseModel> getStore({required int page, required String? lat, String? long}) async {
    int limit = 40;
    String? url = getStoreListing;
    if ((lat?.isNotEmpty ?? false) && (long?.isNotEmpty ?? false)) {
      url = "$getStoreListing?page=$page&limit=$limit&lat=$lat&lng=$long&radius=$kmRadius1000";
    } else {
      url = "$getStoreListing?page=$page&limit=$limit&radius=$kmRadius1000";
    }

    // if ((lat?.isNotEmpty ?? false) && (long?.isNotEmpty ?? false)) {
    //   url = "$getStoreListing?page=$page&lat=$lat&lng=$long";
    // } else {
    //   url = "$getStoreListing?page=$page";
    // }

    final response = await ApiBaseHelper().getHTTP(
      url,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// SEARCH STORES
  Future<ResponseModel> searchStores({required String query}) async {
    String url = "$getStoreListing?radius=$kmRadius1000&query=$query";
    final response = await ApiBaseHelper().getHTTP(
      url,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// homePageProduct
  Future<ResponseModel> homePageProductRepo({
    required int page,
    String? lat,
    String? long,
  }) async {
    const int limit = 20;

    // Build query parameters dynamically
    final Map<String, dynamic> queryParams = {
      ApiKeys.page: page,
      ApiKeys.limit: limit,
      ApiKeys.maxDistance: kmRadius1000,
    };

    if ((lat?.isNotEmpty ?? false) && (long?.isNotEmpty ?? false)) {
      queryParams[ApiKeys.latitude] = lat;
      queryParams[ApiKeys.longitude] = long;
    }

    final response = await ApiBaseHelper().getHTTP(
      homePageProduct,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );

    return response;
  }


  ///GET STORE FEED(PRODUCTS, SERVICE , STORES)......
  Future<ResponseModel> getAllStoresFeed({required int page, String? lat, String? long}) async {
    Map<String, dynamic> queryParams = {};
    if ((lat?.isNotEmpty ?? false) && (long?.isNotEmpty ?? false)) {
      queryParams = {
        'lat': lat,
        'lng': long,
      };
    }
    queryParams['radius'] = kmRadius1000;
    queryParams['page'] = page;

    final response = await ApiBaseHelper().getHTTP(
      storesFeed,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> businessByViewCountIDApi({required String businessId}) async {
    var response = await ApiBaseHelper().postHTTP(
      businessViews(businessId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// productSearchFilterRepo
  Future<ResponseModel> productSearchFilterRepo({
    required int page,
    String? lat,
    String? long,
    String? query,
  }) async {
    const int limit = 20;

    // Build query parameters dynamically
    final Map<String, dynamic> queryParams = {
      ApiKeys.page: page,
      ApiKeys.limit: limit,
      ApiKeys.maxDistance: kmRadius1000,
    };

    if ((lat?.isNotEmpty ?? false) && (long?.isNotEmpty ?? false)) {
      queryParams[ApiKeys.latitude] = lat;
      queryParams[ApiKeys.longitude] = long;
    }

    if ((query?.isNotEmpty ?? false)) {
      queryParams[ApiKeys.searchTerm] = query;
    }


    final response = await ApiBaseHelper().getHTTP(
      productSearchFilter,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );

    return response;
  }

  ///GET SPECIFIC STORES......
  Future<ResponseModel> getSpecificStores({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      getStoreListing,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET SPECIFIC STORES......
  Future<ResponseModel> askAiInventoryRepo({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      aiInventoryAsk,
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


}
