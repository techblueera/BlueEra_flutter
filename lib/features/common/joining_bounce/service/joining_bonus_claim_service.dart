import 'package:BlueEra/features/personal/personal_profile/view/wallet/repo/joining_bounce_repo.dart';

/// Claiming the joining bonus from the scratch card.
class JoiningBonusClaimService {
  JoiningBonusClaimService({JoiningBounceRepo? repo})
      : _repo = repo ?? JoiningBounceRepo();

  final JoiningBounceRepo _repo;

  /// `POST /joining-bounce/createclaim { tag_id, account_type? }`. `tag_id` is
  /// the only required field — without it the backend can't resolve the plan;
  /// [accountType] is resolved from the JWT when omitted. [message] is the
  /// server's wording, if any. Throws when the call itself fails.
  Future<({bool ok, String? message})> claim({
    required String tagId,
    String? accountType,
  }) async {
    final res = await _repo.createClaim(tagId: tagId, accountType: accountType);
    final message = res.message?.toString();
    return (
      ok: res.isSuccess,
      message: message != null && message.isNotEmpty ? message : null,
    );
  }
}
