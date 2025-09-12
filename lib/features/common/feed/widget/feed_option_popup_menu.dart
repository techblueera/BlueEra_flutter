import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/post/message_post/message_post_preview_screen_new.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FeedPopUpMenu extends StatelessWidget {
  final Post post;
  final PostType postFilteredType;

  const FeedPopUpMenu(
      {super.key, required this.post, required this.postFilteredType});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(-6, 36),
      color: AppColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) async {
        if (value == 'Edit Post') {
          if (post.type == AppConstants.MESSAGE_POST) {
            Get.to(MessagePostPreviewScreenNew(
              isEdit: true,
              post: post,
            ));
            // Get.toNamed(RouteHelper.getCreateMessagePostScreenRoute(),
            //     arguments: {ApiKeys.post: post, ApiKeys.isEdit: true});
          }

          if (post.type == AppConstants.POLL_POST) {
            Get.toNamed(RouteHelper.getPollInputScreenRoute(),
                arguments: {ApiKeys.post: post, ApiKeys.isEdit: true});
          }
          if (post.type == AppConstants.PHOTO_POST) {
            Get.toNamed(RouteHelper.getPhotoPostScreenRoute(),
                arguments: {ApiKeys.post: post, ApiKeys.isEdit: true});
          }
        } else if (value == 'Delete Post') {
          await showCommonDialog(
              context: context,
              text: 'Are you sure you want to delete this post?',
              confirmCallback: () async {
                Get.find<FeedController>()
                    .postDelete(postId: post.id, type: postFilteredType);
              },
              cancelCallback: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              confirmText: AppLocalizations.of(context)!.yes,
              cancelText: AppLocalizations.of(context)!.no);
        }
      },
      icon: Icon(Icons.more_vert),
      itemBuilder: (context) => popupPostMenuItems(),
    );
  }
}
