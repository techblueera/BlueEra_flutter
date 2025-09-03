import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class IntroVideoRepo extends BaseService {


  Future<ResponseModel> fetchIntroVideo() async {
    return await ApiBaseHelper().getHTTP(
      getLiveVideo,
      showProgress: false,
    );
  }
}
