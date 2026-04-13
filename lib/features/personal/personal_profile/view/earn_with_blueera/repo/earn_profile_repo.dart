import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class EarnProfileRepo extends BaseService {

  /// Create Earn Profile — sends JSON body with image content types.
  /// Returns pre-signed S3 URLs for uploading images.
  Future<ResponseModel> createEarnProfileRepo({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      earnProfiles,
      params: params,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
