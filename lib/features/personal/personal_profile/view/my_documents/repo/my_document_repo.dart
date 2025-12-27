import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class MyDocumentRepo extends BaseService {

  /// ridersOnboardingPersonalIdentificationRepo
  Future<ResponseModel> documentIdentificationRepo({required Map<String, dynamic> params}) async {
    var response = await ApiBaseHelper().putHTTP(
      ridersOnboardingPersonalIdentification,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// initRiderServiceUploadRepo
  Future<ResponseModel> initDocumentFileUploadRepo({required String fileType}) async {
    var response = await ApiBaseHelper().getHTTP(
      initRiderServiceUpload,
      params: {
        ApiKeys.fileType: fileType
      },
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
