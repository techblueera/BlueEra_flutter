import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class MyDocumentRepo extends BaseService {

  /// initRiderServiceUploadRepo
  Future<ResponseModel> initDocumentFileUploadRepo({required String fileType}) async {
    var response = await ApiBaseHelper().getHTTP(
      initDocumentServiceUpload,
      params: {
        ApiKeys.fileType: fileType
      },
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// ridersOnboardingPersonalIdentificationRepo
  Future<ResponseModel> addDocument({required Map<String, dynamic> params}) async {
    var response = await ApiBaseHelper().postHTTP(
      documents,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// initRiderServiceUploadRepo
  Future<ResponseModel> getAllDocument() async {
    var response = await ApiBaseHelper().getHTTP(
      documents,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// initRiderServiceUploadRepo
  Future<ResponseModel> getAllDocumentStatus() async {
    var response = await ApiBaseHelper().getHTTP(
      documentsStatus,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
