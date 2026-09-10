import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/profile_category/model/profile_category_models.dart';

/// The two calls behind the one-time profile-category change (§5 and §7 of
/// docs/backend/FLUTTER_PROFILE_CATEGORY_CHANGE_GUIDE.md).
///
/// Unlike the repos around it, these return TYPED models and THROW
/// [ProfileCategoryException] rather than handing back a raw [ResponseModel].
/// The reason is §8: every failure here carries a stable `code` that decides
/// what the UI does — retry, disable the row, reload the picker, close the
/// sheet — and leaving each caller to dig that out of `response.data` is how
/// one of them ends up switching on message text instead.
///
/// `showProgress: false` throughout — this flow lives in a bottom sheet with
/// its own button spinner, and the global progress dialog would land on top
/// of it.
class ProfileCategoryRepo extends BaseService {
  /// §5 — "should I show this row at all, and is the change still available?"
  ///
  /// Call it when the Settings screen loads.
  Future<ProfileCategoryState> fetchState() async {
    final ResponseModel response = await _send(
      () => ApiBaseHelper().getHTTP(
        profileCategory,
        showProgress: false,
        onError: (error) {},
        onSuccess: (data) {},
      ),
    );

    if (!response.isSuccess) throw _exceptionFrom(response);

    final data = response.data;
    if (data is! Map) {
      // 2xx with a body we can't read. Treated as a failure rather than as
      // "unsupported", so the caller can retry instead of silently deciding
      // this account has no category.
      throw const ProfileCategoryException(
        code: ProfileCategoryErrorCode.serverError,
        message: 'profile-category returned no object',
      );
    }
    return ProfileCategoryState.fromJson(data);
  }

  /// §7 — perform the change. Returns the new state on success.
  ///
  /// [tagId] is the canonical catalog tag and the only form new code should
  /// send (the backend also accepts the catalog `_id` or the exact display
  /// name, for older clients).
  ///
  /// Omitted optional fields are CLEARED server-side, deliberately: they
  /// described the old category. [designation] belongs to individuals,
  /// [subCategoryId] to businesses, and [licenseNumber] only to the six
  /// medical business categories (PHARMACY, HOSPITALS, CLINICS, DOCTORS,
  /// DIAGNOSTIC, ALTERNATIVE_HEALTH), which reject the change without one
  /// unless a licence is already on file.
  ///
  /// Note there is no `profileType` here and there must not be: the backend
  /// derives it from the chosen profession's catalog entry, and sending one is
  /// ignored. That is what guarantees a profession can't be filed under the
  /// wrong profile type.
  Future<ProfileCategoryChangeResult> changeCategory({
    required String tagId,
    String? designation,
    String? subCategoryId,
    String? licenseNumber,
  }) async {
    final ResponseModel response = await _send(
      () => ApiBaseHelper().postHTTP(
        profileCategoryChange,
        params: {
          'tag_id': tagId,
          if (designation != null) 'designation': designation,
          if (subCategoryId != null) 'sub_category_id': subCategoryId,
          if (licenseNumber != null) 'license_number': licenseNumber,
        },
        showProgress: false,
        onError: (error) {},
        onSuccess: (data) {},
      ),
    );

    if (!response.isSuccess) throw _exceptionFrom(response);

    final data = response.data;
    if (data is! Map) {
      // A 200 has already spent the allowance, so this must NOT be reported as
      // retryable — the change happened, we just can't read the new state. The
      // caller re-reads it with [fetchState].
      throw const ProfileCategoryException(
        code: ProfileCategoryErrorCode.serverError,
        message: 'change succeeded but returned no object',
        statusCode: 200,
      );
    }
    return ProfileCategoryChangeResult.fromJson(data);
  }

  /// Runs a call and converts a transport failure into a retryable exception.
  ///
  /// [ApiBaseHelper] answers a 4xx/5xx by RETURNING a ResponseModel that still
  /// carries the error body — which is where the `code` lives — but answers a
  /// timeout or a dead connection by THROWING the message string. Without this
  /// the second kind would escape as a bare `String` and every caller would
  /// need its own `catch`.
  Future<ResponseModel> _send(Future<ResponseModel> Function() call) async {
    try {
      return await call();
    } on ProfileCategoryException {
      rethrow;
    } catch (e) {
      logs('[ProfileCategory] request failed before a response: $e');
      throw ProfileCategoryException(
        code: ProfileCategoryErrorCode.networkError,
        message: e.toString(),
      );
    }
  }

  /// Reads the documented `code` out of an error body.
  ///
  /// Falls back to `server_error` — retryable — only when the body has no code
  /// at all AND the status isn't one we can name. A 4xx without a code is NOT
  /// made retryable: retrying a request the server rejected on its content
  /// just fails again.
  ProfileCategoryException _exceptionFrom(ResponseModel response) {
    final status = response.statusCode ?? 0;
    final code = response.getExtraData('code');
    final rawErrors = response.getExtraData('errors');

    return ProfileCategoryException(
      code: code is String && code.isNotEmpty
          ? code
          : (status == 401
              ? ProfileCategoryErrorCode.unauthenticated
              : status >= 400 && status < 500
                  // Rejected on content, with no code to say why. NOT mapped
                  // to a named code — guessing `unknown_category` here would
                  // send the UI off to reload a picker that is fine — and NOT
                  // retryable, since repeating it fails the same way.
                  ? ProfileCategoryErrorCode.unspecified
                  : ProfileCategoryErrorCode.serverError),
      message: response.message is String ? response.message as String : null,
      errors: rawErrors is List
          ? rawErrors.map((e) => e.toString()).toList()
          : const [],
      statusCode: status,
    );
  }
}
