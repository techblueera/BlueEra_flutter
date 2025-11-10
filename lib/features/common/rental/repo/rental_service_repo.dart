import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class RentalServiceRepo extends BaseService{

  ///GET RENTAL SERVICE...
  Future<ResponseModel> addRentalServiceRepo({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      addRentalService,
      isMultipart: true,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET RENTAL SERVICE...
  Future<ResponseModel> generateHomeRentalServiceRepo({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      generateHomeRentalService,
      isMultipart: true,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


}