
import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';


class AddJobRepo extends BaseService {
  Future<ResponseModel> fetchJobList({required String lat,required String lng}) async {
    final response = await ApiBaseHelper().getHTTP(
      getJobByLat(lat,lng),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

}
