import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class StoreRepo extends BaseService {
  ///GET STORE......
  Future<ResponseModel> getStore({required String? lat, String? long}) async {
    String? url = getStoreListing;
    if ((lat?.isNotEmpty ?? false) && (long?.isNotEmpty ?? false)) {
      url = "$getStoreListing?lat=$lat&lng=$long&radius=1000";
    } else {
      url = "$getStoreListing?radius=1000";
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
    String url = "$getStoreListing?radius=1000&query=$query";
    final response = await ApiBaseHelper().getHTTP(
      url,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
