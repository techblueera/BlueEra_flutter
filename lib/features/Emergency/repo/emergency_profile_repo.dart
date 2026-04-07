import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class EmergencyProfileRepo1 extends BaseService {
  Future<ResponseModel> getEmergencyProfileUserId() async {
    final response = await ApiBaseHelper().getHTTP(
      '$getEmergencyProfile1',
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
