import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';

/// One-off actions on a video post: delete, block its author, report it.
///
/// Callable from any screen (feed cards, the video player) without a
/// registered controller. Each tells the user how it went and returns true on
/// success; closing dialogs and updating lists is up to the caller.
class VideoActions {
  VideoActions({ChannelRepo? channelRepo, AuthRepo? authRepo})
      : _channelRepo = channelRepo ?? ChannelRepo(),
        _authRepo = authRepo ?? AuthRepo();

  final ChannelRepo _channelRepo;
  final AuthRepo _authRepo;

  /// Deletes the user's own video.
  Future<bool> deleteVideo(String videoId) async {
    try {
      final response = await _channelRepo.deleteVideo(videoId: videoId);
      if (!response.isSuccess) return false;
      commonSnackBar(message: response.message ?? AppStrings.success);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Blocks [otherUserId] fully.
  Future<bool> blockUser(String otherUserId) async {
    try {
      final response = await _authRepo.blockUser(params: {
        ApiKeys.blockedTo: otherUserId,
        ApiKeys.type: BlockedType.full.label,
        ApiKeys.duration: 0,
      });
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      // Only the message is needed; parsing the whole BlockUserResponse would
      // turn a successful block into an error if any record field is missing.
      commonSnackBar(
          message: response.response?.data?['message']?.toString() ??
              AppStrings.success,
          isFromHomeScreen: true);
      return true;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  /// Reports a post with the reason the user picked ([params]).
  Future<bool> reportPost(Map<String, dynamic> params) async {
    try {
      final response = await _authRepo.report(params: params);
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      return true;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }
}
