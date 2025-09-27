import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/reel/view/channel/reel_upload_details_screen.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReelVideoPopUpMenu extends StatelessWidget {
  final ShortFeedItem videoFeedItem;
  final Color? popUpMenuColor;
  final VideoType video;

  const ReelVideoPopUpMenu({
    super.key,
    required this.videoFeedItem,
    this.popUpMenuColor,
    required this.video
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(-6, 36),
      color: AppColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) async {
        if (value == 'Edit Video') {
          Navigator.pushNamed(
            context,
            RouteHelper.getCreateReelScreenRoute(),
            arguments: {
              ApiKeys.videoPath:
              (Platform.isAndroid)
                  ? videoFeedItem.video?.transcodedUrls?.master ?? videoFeedItem.video?.videoUrl??''
                  : videoFeedItem.video?.videoUrl??'',
              ApiKeys.videoType: Video.video,
              ApiKeys.videoId: videoFeedItem.videoId,
              ApiKeys.argPostVia: videoFeedItem.channel?.id != null ? PostVia.channel : PostVia.profile,
            },
          );
        } else if (value == 'Delete Video') {
          await showCommonDialog(
              context: context,
              text: 'Are you sure you want to delete this video?',
              confirmCallback: () {
                logs("videoFeedItem.video?.id === ${videoFeedItem.video?.id}");
                Get.back();
                Get.find<VideoController>().videoDelete(video: video, videoId: videoFeedItem.video?.id ?? '');
              },
              cancelCallback: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              confirmText: AppLocalizations.of(context)!.yes,
              cancelText: AppLocalizations.of(context)!.no);
        }
      },
      icon: Icon(Icons.more_vert, color: popUpMenuColor ?? AppColors.white),
      itemBuilder: (context) => popupVideoMenuItems(),
    );
  }



}

