import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// Inactive-account data purge (docs/backend/FLUTTER_INACTIVE_USER_DATA_PURGE_GUIDE.md).
///
/// Both calls act on the TOKEN's own account; neither takes a userId.
class InactivityRepo extends BaseService {
  /// Reads the purge state AND counts as activity server-side — calling it is
  /// what takes an opening user out of the purge cohort, so it must never be
  /// skipped as an optimisation.
  ///
  /// `showProgress: false` throughout: this runs on launch and on every
  /// resume, and a full-screen loader over the home shell for a background
  /// ping would be worse than the problem it reports.
  Future<ResponseModel> getInactivityStatus() async {
    return ApiBaseHelper().getHTTP(
      inactivityStatus,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// Clears the server's `data_purged` flag after the user has read the
  /// "your data was removed" screen. The backend's audit trail is permanent,
  /// so nothing is lost by clearing it.
  Future<ResponseModel> acknowledgePurge() async {
    return ApiBaseHelper().postHTTP(
      inactivityAcknowledge,
      params: const {},
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }
}
