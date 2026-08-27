import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

import '../model/loan_application.dart';

/// Repository for the user-facing half of Loan Applications.
///
/// See docs/backend/FLUTTER_LOAN_APPLICATION_GUIDE.md. The admin endpoints
/// (`/loan-applications/admin/*`) are deliberately absent — the app never calls
/// them, and the applicant identity on every call below comes from the auth
/// token, so **no request here carries a `userId`**.
class LoanApplicationRepo extends BaseService {
  /// `POST /loan-applications` — always lands as `pending`.
  ///
  /// `applicationStatus` is never sent: only an admin moves the status and the
  /// backend drops the field from user payloads.
  ///
  /// `showProgress: false`: the Apply button carries its own loader and stays
  /// disabled for the duration, which is more locatable than a full-screen
  /// overlay over a form the user may want to re-read.
  Future<ResponseModel> submit(LoanApplicationDraft draft) {
    return ApiBaseHelper().postHTTP(
      loanApplications,
      params: draft.toJson(),
      showProgress: false,
    );
  }

  /// `GET /loan-applications/options` — the dropdown enums.
  ///
  /// Optional by design: the values are stable, so the form opens on bundled
  /// defaults and only upgrades if this answers. Nothing waits on it.
  Future<ResponseModel> options() {
    return ApiBaseHelper().getHTTP(
      loanApplicationOptions,
      showProgress: false,
    );
  }
}
