import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';

/// Following another user, for callers that word their own feedback.
class FollowService {
  FollowService({UserRepo? repo}) : _repo = repo ?? UserRepo();

  final UserRepo _repo;

  /// Follows [userId]. Returns whether the server accepted it; a failed call
  /// counts as not accepted.
  Future<bool> follow(String userId) async {
    try {
      return (await _repo.followUser(followUserId: userId)).isSuccess;
    } catch (_) {
      return false;
    }
  }
}
