import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class SocialLinksRepo extends BaseService {
  Future<ResponseModel> getSocialMediaLinks() async {
    return await ApiBaseHelper().getHTTP(
      getSocialMediaHandlers,
      showProgress: true,
    );
  }

  Future<ResponseModel> updateSocialMediaLinks({required Map<String, dynamic> params}) async {
    return await ApiBaseHelper().postHTTP(
      addSocialMediaHandler,
      params: params,
      showProgress: true,
    );
  }

}
