import '../../../../core/api/apiService/api_base_helper.dart';
import '../../../../core/api/apiService/base_service.dart';
import '../../../../core/api/apiService/response_model.dart';

class LanguageRepo extends BaseService {
  Future<ResponseModel> getLanguagesRaw() async {
    return await ApiBaseHelper().getHTTP(
      languages,
      showProgress: true,
    );
  }


  Future<ResponseModel> downloadLanguage(String languageCode) async {
    final downloadUrl = '$languagesDownload/$languageCode';
    return await ApiBaseHelper().getHTTP(
      downloadUrl,
      showProgress: true,
    );
  }
}