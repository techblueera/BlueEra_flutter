import 'package:BlueEra/core/api/model/gst_verify_model.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';

/// The government GSTIN check.
class GstVerifyService {
  GstVerifyService({AuthRepo? repo}) : _repo = repo ?? AuthRepo();

  final AuthRepo _repo;

  /// Verifies [gstin]. On success, [gstin] in the result is the number the
  /// verifier echoed back (same number, normalised by whoever holds the
  /// record) or the typed one if it echoed none. [verified] is false both when
  /// the call failed ([failed]) and when the number did not verify; [message] is the
  /// server's wording, if any.
  Future<({bool verified, bool failed, String? gstin, String? message})> verify(
      String gstin) async {
    final res = await _repo.getUserVerifyGstRepo(gstNumber: gstin);
    final message = res.message?.toString();
    if (!res.isSuccess) {
      return (verified: false, failed: true, gstin: null, message: message);
    }
    final model = GstVerifyModel.fromJson(res.response?.data);
    if (model.isVerified != true) {
      return (verified: false, failed: false, gstin: null, message: message);
    }
    final echoed = model.data?.gstin?.trim() ?? '';
    return (
      verified: true,
      failed: false,
      gstin: echoed.isNotEmpty ? echoed.toUpperCase() : gstin,
      message: message,
    );
  }
}
