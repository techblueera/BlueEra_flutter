import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class LabFullDetailsRepo extends BaseService {
  final String baseUrl = "lab-service/laboratory-profiles/full-details";

  Future<ResponseModel> getFullDetailsByUser() async {
    return await ApiBaseHelper().getHTTP("$testLabServiceFullDetails/$userId");
  }
}
