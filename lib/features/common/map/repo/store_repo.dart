
import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';


class StoreDataRepo extends BaseService {
  Future<ResponseModel> fetchStoreList({required String lat,required String lng}) async {
    final response = await ApiBaseHelper().getHTTP(
      getStoreByLat(lat,lng),
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> fetchStoreDetails({required String storeId}) async {
    final response = await ApiBaseHelper().getHTTP(
      getStoreById(storeId),
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> storeByViewCountIDApi({required String id}) async {
    var response = await ApiBaseHelper().postHTTP(
      postByID,
      params: {ApiKeys.id: id},
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }



}
