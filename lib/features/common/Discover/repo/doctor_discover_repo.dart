import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// Customer-side reads for the standalone-doctor Discover flow.
///
/// The listing feed is `user-service/business/filter` — NOT
/// `hospital-service/doctors`. That endpoint returns `DoctorProfile`
/// documents whose `_id` cannot be used to book or enquire; only the business
/// listing carries the `Business._id` / `Business.user_id` pair the rest of
/// the flow needs (guide §5.8, §14).
class DoctorDiscoverRepo extends BaseService {
  /// `GET /business/filter?category=DOCTORS`. Public — the auth interceptor
  /// still attaches a token when the user is logged in, which is harmless.
  ///
  /// `CLINICS` is an equally valid category and behaves identically.
  Future<ResponseModel> getDoctorListings({
    String category = 'DOCTORS',
    int page = 1,
    int limit = 20,
  }) async {
    return ApiBaseHelper().getHTTP(
      '$businessFilter?category=$category&page=$page&limit=$limit',
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }
}
