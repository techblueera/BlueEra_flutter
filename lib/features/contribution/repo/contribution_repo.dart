import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// What's left of the legacy recharge API surface: the status read.
///
/// The catalog / initiate-order / verify-payment / cancel calls went with the
/// old contribution screens — buying now goes through `AccountPlanRepo`. See
/// [ContributionController].
class ContributionRepo extends BaseService {
  /// `GET /recharge/current` — returns 404 if no active recharge.
  Future<ResponseModel> fetchCurrent() {
    return ApiBaseHelper().getHTTP(rechargeCurrent, showProgress: false);
  }
}
