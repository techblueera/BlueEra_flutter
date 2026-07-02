import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/utils/photo_presign_uploader.dart';

/// REST surface for the "other" business enquiry flow
/// (`be_other_service` → `/other-enquiries` → chat card
/// `message_type: business_enquiry`). Covers every non-hospital/finance
/// vertical the doc groups under `be_other_service` — banking, insurance,
/// loans, capital-market, data — with one JSON-only contract.
///
/// Photos are sent as already-uploaded public S3 URLs (see
/// [uploadPhotosViaPresign]) — the create endpoint does not accept
/// multipart uploads (§2 of `lib/docs/other-enquiry-ui-integration.md`).
class OtherEnquiryRepo extends BaseService {
  /// POST a new "other" business enquiry. [params] must include
  /// `business_id`; at least one of `selections` (non-empty groups) or
  /// `note` is server-required, else the API returns 400. Photos, if any,
  /// go as pre-uploaded public S3 URLs under `photos` (max 5).
  Future<ResponseModel> sendOtherEnquiry({
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().postHTTP(
      otherEnquiries,
      params: params,
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  /// PUT: Business owner accepts / declines an enquiry. Emits
  /// `businessEnquiryStatusUpdated` to both parties. Only valid while the
  /// enquiry is `pending` — a different decision after settle → 409, which
  /// the controller treats as idempotent success.
  Future<ResponseModel> updateOtherEnquiryStatus({
    required String enquiryId,
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().putHTTP(
      otherEnquiryStatus(enquiryId),
      params: params,
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  /// GET one — used by the owner chat card to hydrate the enquiry's
  /// current server-side status.
  Future<ResponseModel> getOtherEnquiryById(String enquiryId) async {
    return ApiBaseHelper().getHTTP(
      otherEnquiryById(enquiryId),
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// GET the enquiries the current customer has sent. Supports
  /// `status=pending|accepted|declined&page=1&limit=20` (limit ≤ 100) per
  /// §4 of the integration doc.
  Future<ResponseModel> getMyOtherEnquiries({
    Map<String, dynamic>? query,
  }) async {
    return ApiBaseHelper().getHTTP(
      otherEnquiriesMe,
      params: query,
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// GET the enquiries received on the current owner's listings.
  Future<ResponseModel> getOwnerOtherEnquiries({
    Map<String, dynamic>? query,
  }) async {
    return ApiBaseHelper().getHTTP(
      otherEnquiriesOwnerMe,
      params: query,
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// Upload each local photo via the shared user-service presign helper
  /// (`GET user-service/upload/init` → `PUT` bytes to `uploadURL` →
  /// public `fileUrl`) and return the public URLs in the same order.
  /// Failures are silently skipped — matches the healthcare-business
  /// endpoint behaviour so partial photo failures don't block the
  /// enquiry submission.
  Future<List<String>> uploadPhotosViaPresign(List<String> photoPaths) =>
      uploadFilesViaUserPresign(photoPaths);

  /// GET the server-driven chip catalog for [category]
  /// (`predefined-enquiry/{CATEGORY}`). Response envelope is
  /// `{ success, data: { category, groups: [...] } }`. See
  /// lib/docs/predefined-enquiry-ui-integration.md §1.
  Future<ResponseModel> getPredefinedEnquiryOptions(String category) async {
    return ApiBaseHelper().getHTTP(
      predefinedEnquiry(category),
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }
}
