import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/introduction_video_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UploadVideoWidget extends StatelessWidget {
  UploadVideoWidget({super.key});


  final viewProfileController = Get.put(ViewPersonalDetailsController());
  final introVideoController = Get.find<IntroductionVideoController>();

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      color: const Color(0xffD2D2D2),
      strokeWidth: 1.5,
      borderType: BorderType.RRect,
      radius: const Radius.circular(8),
      dashPattern: const [6, 4],
      child: Container(
        width: double.infinity,
        height: SizeConfig.size140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LocalAssets(imagePath: AppIconAssets.self_video_upload),
              const SizedBox(height: 8),
              (introVideoController.selectedVideo.value != null)
                  ? Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                      child: CustomText(
                        "${introVideoController.selectedVideo.value?.path.split("/").last}",
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    )
                  : CustomText(
                      'Upload your Introduction Video',
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
