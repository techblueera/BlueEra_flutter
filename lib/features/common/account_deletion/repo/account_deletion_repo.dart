import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class AccountDeletionRepo extends BaseService {
  /// Initiates account deletion (V2). Returns an init_token and the web URL
  /// to open in an in-app browser. Auth token is attached by ApiBaseHelper.
  Future<ResponseModel> initAccountDeletionRepo() async {
    final response = await ApiBaseHelper().postHTTP(
      accountDeletionInit,
      params: const {},
      // No global progress dialog — the confirm dialog shows an inline button
      // loader + a dim overlay while this runs.
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
