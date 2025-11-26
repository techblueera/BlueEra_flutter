import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddBusinessLivePhoto extends StatefulWidget {
  const AddBusinessLivePhoto({super.key});

  @override
  State<AddBusinessLivePhoto> createState() => _AddBusinessLivePhotoState();
}

class _AddBusinessLivePhotoState extends State<AddBusinessLivePhoto> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
          isLeading: true,
          title: AppStrings.businessDetailsTitle
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
          vertical: SizeConfig.size15,
        ),
        child: CustomFormCard(
          padding: EdgeInsets.all(SizeConfig.size10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      AppStrings.uploadYourLivePhoto,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(width: SizeConfig.size8),
                    CustomText(
                      AppStrings.minimumThreeImages,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),

                SizedBox(height: SizeConfig.size16),

                /// LayoutBuilder to adapt image size
                LayoutBuilder(
                  builder: (context, constraints) {
                    final spacing = SizeConfig.size10;
                    final containerWidth = (constraints.maxWidth - (spacing * 2)) / 3;

                    return GetBuilder<ViewBusinessDetailsController>(
                      id: 'livePhotos',
                      builder: (controller) {
                        final apiPhotos = controller.businessProfileDetails?.data?.livePhotos ?? [];

                        final totalCount = apiPhotos.length;
                        final emptySlots = (3 - totalCount).clamp(0, 3);

                        List<Widget> allPhotos = [];

                        // API Photos (Already uploaded)
                        for (int i = 0; i < apiPhotos.length; i++) {
                          allPhotos.add(_buildImageContainer(
                            context,
                            apiPhotos[i],
                            i,
                            controller,
                            containerWidth,
                            apiPhotos,
                          ));
                        }

                        // Empty slots for remaining photos
                        for (int i = 0; i < emptySlots; i++) {
                          allPhotos.add(_buildImageContainer(
                            context,
                            "",
                            apiPhotos.length + i,
                            controller,
                            containerWidth,
                            apiPhotos,
                          ));
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: allPhotos,
                        );
                      },
                    );
                  },
                ),

                SizedBox(height: SizeConfig.size16),

                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                      borderRadius: BorderRadius.circular(10.0),
                      onTap: ()=> Get.until((route) => route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute()),
                      child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size20,
                        vertical: SizeConfig.size6
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.secondaryTextColor),
                        borderRadius: BorderRadius.circular(10.0)
                      ),
                      child: CustomText(
                        AppStrings.skip,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ),
                )
              ],
            )
        ),
      ),
    );
  }

  Widget _buildImageContainer(
      BuildContext context,
      String? imagePath,
      int index,
      ViewBusinessDetailsController controller,
      double size,
      List<String> allPhotos,
      ) {
    final isEmpty = imagePath == null || imagePath.isEmpty;

    return Stack(
      children: [
        GestureDetector(
          onTap: () async {
            if (isEmpty) {
              // Pick and upload new image
              final imgStr = await SelectProfilePictureDialog.pickFromCamera(context);
              if (imgStr != null) {
                await controller.saveBusinessImages(imgStr, controller);
                controller.update(['livePhotos']);
              }
            } else {
              // View full image
              navigatePushTo(
                context,
                ImageViewScreen(
                  subTitle: '',
                  appBarTitle: AppStrings.imageViewer,
                  imageUrls: allPhotos,
                  initialIndex: index,
                ),
              );
            }
          },
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(
                color: AppColors.greyE5,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: isEmpty ? [] : [AppShadows.textFieldShadow],
              image: !isEmpty
                  ? DecorationImage(
                image: NetworkImage(imagePath),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LocalAssets(imagePath: AppIconAssets.profile_camera_pic),
                  SizedBox(height: 4),
                  CustomText(
                    AppStrings.addLiveStorePhoto,
                    textAlign: TextAlign.center,
                    fontSize: SizeConfig.extraSmall,
                    decoration: TextDecoration.underline,
                    color: AppColors.mainTextColor,
                  ),
                ],
              ),
            )
                : null,
          ),
        ),
        if (!isEmpty)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () async {
                Map<String, dynamic> data = {ApiKeys.image_url: imagePath};
                await controller.deleteLiveStoreImage(data);
                controller.businessProfileDetails?.data?.livePhotos?.removeAt(index);
                controller.update(['livePhotos']);
              },
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white,
                child: Icon(Icons.close, size: 16, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

}
