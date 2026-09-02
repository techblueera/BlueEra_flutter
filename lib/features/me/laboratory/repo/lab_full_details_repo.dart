import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class LabFullDetailsRepo extends BaseService {
  final String baseUrl = "lab-service/laboratory-profiles/full-details";

  /// `showProgress: false` — the Lab "Me" screen's own load
  /// (`LabHomeScreenV2.initState` + pull-to-refresh); the controller carries
  /// its own loading state, so a blocking dialog only greys out the screen.
  Future<ResponseModel> getFullDetailsByUser() async {
    return await ApiBaseHelper()
        .getHTTP("$testLabServiceFullDetails/$userId", showProgress: false);
  }

  /// Same call for someone else's lab (the public profile) — a read that backs
  /// a screen's own loading state, so likewise no dialog.
  Future<ResponseModel> getFullDetailsByUserId(String targetUserId) async {
    return await ApiBaseHelper().getHTTP(
        "$testLabServiceFullDetails/$targetUserId",
        showProgress: false);
  }
}
