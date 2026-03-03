import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/social/controller/social_activity_controller.dart';
import 'package:BlueEra/features/me/social/view/social_activity_form_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/delete_dialog.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialActivityListScreen extends StatelessWidget {
  final controller = Get.put(SocialActivityController());

  SocialActivityListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
          title: AppStrings.socialActivity,
          isCreateSocialWidget: () {
            return Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () {
                      controller.clearForm();
                      Get.to(() => SocialActivityFormScreen());
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child:  CustomText(AppStrings.createNew,
                        color: AppColors.primaryColor, fontSize: 12),
                  ),
                ),
              ),
            );
          }),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.activityList.isEmpty) {
          return const Center(child: CustomText(AppStrings.noActivitiesFound));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 50,right: 16,left: 16),
          itemCount: controller.activityList.length,
          itemBuilder: (context, index) {
            final item = controller.activityList[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CachedAvatarWidget(
                            imageUrl: userProfileGlobal,
                            size:  SizeConfig.size42,
                            borderColor: AppColors.transparent,
                            borderRadius: 25),
                        SizedBox(width: SizeConfig.size10,),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                item.title ?? "No Title",
                                // fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: CustomText(
                                      formattedCreatedAt(item.date ?? ""),
                                      fontSize: SizeConfig.size12,
                                      maxLines: 1,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: CustomText(
                                      "@${item.role ?? 'User'}",
                                      fontSize: 12,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              controller.setEditData(item);
                              Get.to(() => SocialActivityFormScreen());
                            } else if (value == 'delete') {
                              showConfirmDialog(
                                context,
                                () {
                                  Navigator.pop(context);
                                  controller.deleteActivity(item.sId ?? "");
                                },
                                title: AppStrings.delete,
                                content:
                                AppStrings.deleteActivityConfirm,
                              );
                            }
                          },child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: LocalAssets(imagePath: AppIconAssets.more_vertical),
                          ),
                          itemBuilder: (BuildContext context) {
                            return { AppStrings.edit.tr,  AppStrings.delete.tr,}.map((String choice) {
                              return PopupMenuItem<String>(
                                value: choice.toLowerCase(),
                                child: CustomText(choice),
                              );
                            }).toList();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    if (item.location?.name != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: AppColors.primaryColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: CustomText(
                              item.location?.name ?? "",
                              color: AppColors.primaryColor,
                              fontSize: 12,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    CustomText(
                      item.description ?? "",
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      color: AppColors.secondaryTextColor,
                    ),
                    if (item.mediaUrl != null && item.mediaUrl!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: (){
                          Get.to(
                                () => ImageViewScreen(
                              appBarTitle: item.title??"",
                              imageUrls: [item.mediaUrl??""],
                              initialIndex: 0,
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.mediaUrl??"",
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(
                                    height: 250,
                                    child:
                                        Center(child: Icon(Icons.broken_image))),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
