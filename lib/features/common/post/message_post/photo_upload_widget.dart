import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/message_post/message_post_preview_screen_new.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
                  commonSnackBar(
                      message: "At least 1 photo is required");
                  return;
                }
                Get.off(() => MessagePostPreviewScreenNew(
                      postVia: PostVia.profile, isEdit: false,
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

class PhotoUploadWidget extends StatelessWidget {
  PhotoUploadWidget({super.key, this.isFromRepost=false});
  final bool isFromRepost;
  final msgController = Get.find<MessagePostController>();

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Obx(() {
        return SingleChildScrollView(
          child: Column(
            children: [

              Align(
                  alignment: Alignment.centerLeft,
                  child: CustomText(isFromRepost?"Upload Photo":"Upload Photo (at least 1 photo required)")),
              SizedBox(height: SizeConfig.size10),
              InkWell(
                onTap:(){
                  msgController.pickImageFrom(context);
                },
                child: Container(
                  width: SizeConfig.screenWidth,
                  height: SizeConfig.size50 + 2,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    // White background
                    borderRadius: BorderRadius.circular(10.0),
                    // Rounded corners
                    border: Border.all(width: 1, color: AppColors.greyE5),
                    boxShadow: [AppShadows.textFieldShadow],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LocalAssets(imagePath: AppIconAssets.black_gallery),
                        SizedBox(width: SizeConfig.size8),
                        CustomText(
                          'Upload Photos',
                          color: AppColors.secondaryTextColor,
                          fontSize: SizeConfig.large,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size15),
              ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.all(SizeConfig.size1),
                physics: NeverScrollableScrollPhysics(),
                itemCount: msgController.imagesList.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                          // width:300 ,
                            height: 300,
                            // height: Get.width * 0.5,
                            // // height: Get.width * 0.5,
                            // width: msgController
                            //             .imagesList[index].imgCropMode ==
                            //     AppConstants.Square
                            //     ? Get.width * 0.5
                            //     : double.parse(
                            //         msgController.imagesList[index].imgWidth ??
                            //             Get.width.toString()),
                            decoration: BoxDecoration(
                              // borderRadius: BorderRadius.circular(
                              //     msgController.imagesList[index].imgCropMode ==
                              //         AppConstants.Square
                              //         ? 0
                              //         : 12),
                              image: DecorationImage(
                                image: FileImage(File(msgController
                                        .imagesList[index].imageFile?.path ??
                                    "")),
                                fit: BoxFit.fitWidth,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => msgController.removePhoto(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),

                        // --- Crop button ---------------------------
                        // Positioned(
                        //   bottom: 6,
                        //   right: 6,
                        //   child: _photoPhotoPopUpMenu(index),
                        // ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }),
    );
  }


}
