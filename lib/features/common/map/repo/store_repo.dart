
import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
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


}
