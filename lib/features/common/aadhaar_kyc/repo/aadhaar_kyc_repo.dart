import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// Repository for the generic per-user Aadhaar OKYC (OTP) verification flow,
/// owned by be_user_service. Reusable across any screen that needs to verify
/// a user's Aadhaar identity (rider onboarding, personal documents, …).
/// See docs/backend/aadhaar-verification-ui-integration.md.
class AadhaarKycRepo extends BaseService {
  /// GET /user/aadhaar/status — current verification status.
  Future<ResponseModel> statusRepo() async {
    var response = await ApiBaseHelper().getHTTP(
      aadhaarStatus,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// POST /user/aadhaar/generate-otp — send OTP to the Aadhaar-linked mobile.
  /// [params] = { aadhaar_number, consent: "Y", reason? }.
  Future<ResponseModel> generateOtpRepo(
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

  /// POST /user/aadhaar/verify-otp — verify the 6-digit OTP.
  /// [params] = { reference_id, otp }.
  Future<ResponseModel> verifyOtpRepo(
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
}
