import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/message_post/message_post_preview_screen_new.dart';
import 'package:BlueEra/features/common/post/message_post/photo_upload_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PhotoListingWidget extends StatelessWidget {
  const PhotoListingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        title: "Edit photo",
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
              left: SizeConfig.size15,
              right: SizeConfig.size15,
              bottom: SizeConfig.size15,
              top: SizeConfig.size5),
          child: PositiveCustomBtn(
              onTap: () {
                final msgController = Get.find<MessagePostController>();

                if (msgController.imagesList.length < 1) {
                  commonSnackBar(message: "At least 1 photo or video is required");
                  return;
                }
                Get.off(() => MessagePostPreviewScreenNew(
                  postVia: PostVia.profile,
                  isEdit: false,
                ));
              },
              title: "Next"),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size20),
          child: PhotoUploadWidget(),
        ),
      ),
    );
  }
}
