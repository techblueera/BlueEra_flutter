import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';

class StoreRepo extends BaseService {
  ///GET STORE......
  Future<ResponseModel> getStore({required int page, required String? lat, String? long}) async {
    String? url = getStoreListing;
    if ((lat?.isNotEmpty ?? false) && (long?.isNotEmpty ?? false)) {
      url = "$getStoreListing?page=$page&lat=$lat&lng=$long&radius=$kmRadius1000";
    } else {
      url = "$getStoreListing?page=$page&radius=$kmRadius1000";
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

  Future<ResponseModel> homePageProductRepo(
      {required int page, required String? lat, required String? long}) async {
    String? url;
    if ((lat?.isNotEmpty ?? false) && (long?.isNotEmpty ?? false)) {
      url =
          "$homePageProduct?${ApiKeys.page}=$page&${ApiKeys.latitude}=$lat&${ApiKeys.longitude}=$long&${ApiKeys.maxDistance}=$kmRadius1000";
    } else {
      url = "$homePageProduct?${ApiKeys.page}=$page&${ApiKeys.maxDistance}=$kmRadius1000";
    }
    final response = await ApiBaseHelper().getHTTP(
      url,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET STORE......
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


}
