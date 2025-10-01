import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';

class StoreRepo extends BaseService {
  ///GET STORE......
  Future<ResponseModel> getStore({required String? lat, String? long}) async {
    String? url = getStoreListing;
    if ((lat?.isNotEmpty ?? false) && (long?.isNotEmpty ?? false)) {
      url = "$getStoreListing?lat=$lat&lng=$long&radius=$kmRadius1000";
    } else {
      url = "$getStoreListing?radius=$kmRadius1000";
    }
    final response = await ApiBaseHelper().getHTTP(
      url,
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
      {required String? lat, required String? long}) async {
    String? url;
    if ((lat?.isNotEmpty ?? false) && (long?.isNotEmpty ?? false)) {
      url =
          "$homePageProduct?${ApiKeys.latitude}=$lat&${ApiKeys.longitude}=$long&${ApiKeys.maxDistance}=$kmRadius100";
    } else {
      url = "$homePageProduct?${ApiKeys.maxDistance}=$kmRadius100";
    }
    final response = await ApiBaseHelper().getHTTP(
      url,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
