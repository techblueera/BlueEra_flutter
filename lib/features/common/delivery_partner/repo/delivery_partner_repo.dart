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
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// ridersOnboardingDeleteDocumentRepo
  /// [documentType] — aadhar | pan | dl | rc | vehicle-images | vehicle-information
  Future<ResponseModel> ridersOnboardingDeleteDocumentRepo(
      {required String documentType}) async {
    var response = await ApiBaseHelper().deleteHTTP(
      ridersOnboardingDeleteDocument(documentType),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ── Aadhaar OKYC (OTP) verification (be_user_service) ──────────────
  // Generic per-user Aadhaar identity verification. See
  // docs/backend/aadhaar-verification-ui-integration.md.

  /// GET current Aadhaar verification status for the logged-in user.
  Future<ResponseModel> aadhaarStatusRepo() async {
    var response = await ApiBaseHelper().getHTTP(
      aadhaarStatus,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// POST — send an OTP to the Aadhaar-linked mobile.
  /// [params] = { aadhaar_number, consent: "Y", reason? }.
  Future<ResponseModel> aadhaarGenerateOtpRepo(
      {required Map<String, dynamic> params}) async {
    var response = await ApiBaseHelper().postHTTP(
      aadhaarGenerateOtp,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// POST — verify the 6-digit OTP against the reference_id from generate-otp.
  /// [params] = { reference_id, otp }.
  Future<ResponseModel> aadhaarVerifyOtpRepo(
      {required Map<String, dynamic> params}) async {
    var response = await ApiBaseHelper().postHTTP(
      aadhaarVerifyOtp,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// initRiderServiceUploadRepo
  Future<ResponseModel> initRiderServiceFileUploadRepo({required String fileType}) async {
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

  /// Fetch Vehicle Enum. When [type] (the rider's profession) is provided, the
  /// backend returns only the options valid for that profession — the app no
  /// longer filters locally. Omitting [type] returns the full catalog (used by
  /// the rental flow). See docs/backend/VEHICLE_ENUMS_BY_PROFESSION_GUIDE.md.
  Future<ResponseModel> fetchVehicleDataEnumRepo({String? type}) async {
    var response = await ApiBaseHelper().getHTTP(
      vehicleEnums,
      params: (type != null && type.isNotEmpty) ? {'type': type} : null,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Submit a rider "Contact Us" support query.
  /// [params] = { category, description }.
  /// See docs/backend/SUPPORT_QUERY_FRONTEND_GUIDE.md.
  Future<ResponseModel> submitSupportQueryRepo(
      {required Map<String, dynamic> params}) async {
    var response = await ApiBaseHelper().postHTTP(
      supportQueries,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Send association request to a business/rider
  Future<ResponseModel> sendAssociationRequestRepo({required String targetUserId}) async {
    var response = await ApiBaseHelper().postHTTP(
      ridersAssociationRequest,
      params: {'targetUserId': targetUserId},
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Respond to an association request (accept/reject)
  Future<ResponseModel> respondToAssociationRepo({
    required String associationId,
    required String action,
    String? reason,
  }) async {
    final params = <String, dynamic>{'action': action};
    if (reason != null && reason.isNotEmpty) {
      params['reason'] = reason;
    }
    var response = await ApiBaseHelper().patchHTTP(
      '$ridersAssociationRespond/$associationId/respond',
      params: params,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Create / activate the rider's en-route route (pickup→drop corridor).
  /// Supersedes any previous active route — one active route at a time.
  /// See docs/backend/RIDER_ROUTE_ENROUTE_ORDERS_FRONTEND_GUIDE.md §1.
  Future<ResponseModel> createRiderRouteRepo({required Map<String, dynamic> params}) async {
    var response = await ApiBaseHelper().postHTTP(
      riderRoutes,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Get Associated Shops for rider
  Future<ResponseModel> getAssociatedShopsRepo({required Map<String, dynamic> params}) async {
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    var response = await ApiBaseHelper().getHTTP(
      '$ridersAssociatedShops?$query',
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
