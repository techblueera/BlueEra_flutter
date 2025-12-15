import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class DeliveryPartnerRepo extends BaseService {

  /// ridersOnboardingPersonalInformationRepo
  Future<ResponseModel> ridersOnboardingPersonalInformationRepo({required Map<String, dynamic> params}) async {
    var response = await ApiBaseHelper().putHTTP(
      ridersOnboardingPersonalInformation,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// ridersOnboardingAddressRepo
  Future<ResponseModel> ridersOnboardingAddressRepo({required Map<String, dynamic> params}) async {
    var response = await ApiBaseHelper().putHTTP(
      ridersOnboardingAddress,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


  /// ridersOnboardingPersonalIdentificationRepo
  Future<ResponseModel> ridersOnboardingPersonalIdentificationRepo({required Map<String, dynamic> params}) async {
    var response = await ApiBaseHelper().putHTTP(
      ridersOnboardingPersonalIdentification,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// ridersOnboardingDrivingVerificationRepo
  Future<ResponseModel> ridersOnboardingDrivingVerificationRepo({required Map<String, dynamic> params}) async {
    var response = await ApiBaseHelper().putHTTP(
      ridersOnboardingDrivingVerification,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// ridersOnboardingVehicleImagesRepo
  Future<ResponseModel> ridersOnboardingVehicleImagesRepo({required Map<String, dynamic> params}) async {
    var response = await ApiBaseHelper().putHTTP(
      ridersOnboardingVehicleImages,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// ridersOnboardingVehicleInformationRepo
  Future<ResponseModel> ridersOnboardingVehicleInformationRepo({required Map<String, dynamic> params}) async {
    var response = await ApiBaseHelper().putHTTP(
      ridersOnboardingVehicleInformation,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// ridersOnboardingStatusRepo
  Future<ResponseModel> ridersOnboardingStatusRepo() async {
    var response = await ApiBaseHelper().getHTTP(
      ridersOnboardingStatus,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// initRiderServiceUploadRepo
  Future<ResponseModel> initRiderServiceUploadRepo({required String fileType}) async {
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
