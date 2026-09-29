import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:get/get.dart';

/// Reposts [postId] as it is, without a message of the user's own (the
/// "Repost" option of the feed's repost sheet). Tells the user how it went and
/// marks the feed for a refresh; returns true when it was reposted.
Future<bool> quickRepost(String postId, {PostRepo? repo}) async {
  final response = await (repo ?? PostRepo()).addRePostNewRepo(reqDataData: {
    ApiKeys.type: AppConstants.MESSAGE_POST,
    ApiKeys.repostId: postId,
  });
  if (!response.isSuccess) {
    commonSnackBar(message: AppStrings.alreadyReposted);
    return false;
  }
  commonSnackBar(message: AppStrings.repostedSuccessfully);
  Get.find<NavigationHelperController>().shouldRefreshBottomBar.value = true;
  return true;
}
