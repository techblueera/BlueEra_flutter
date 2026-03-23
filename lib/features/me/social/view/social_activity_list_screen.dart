import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialActivityListScreen extends StatelessWidget {
  final controller = Get.put(SocialActivityController());

  SocialActivityListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.socialActivity),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.clearForm();
          Get.to(() => SocialActivityFormScreen());
        },
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: CustomText(AppStrings.createNew,
            color: Colors.white,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.activityList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.volunteer_activism,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                CustomText(AppStrings.noActivitiesFound,
                    color: AppColors.secondaryTextColor,
                    fontSize: SizeConfig.medium),
                const SizedBox(height: 8),
                CustomText("Tap + to add your first social activity",
                    color: Colors.grey[400],
                    fontSize: SizeConfig.small),
              ],
            ),
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.only(bottom: 80, right: 14, left: 14, top: 14),
          itemCount: controller.activityList.length,
          itemBuilder: (context, index) {
            final item = controller.activityList[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image at top
                  if (item.mediaUrl != null &&
                      item.mediaUrl!.isNotEmpty)
                    InkWell(
                      onTap: () {
                        Get.to(() => ImageViewScreen(
                              appBarTitle: item.title ?? "",
                              imageUrls: [item.mediaUrl ?? ""],
                              initialIndex: 0,
                            ));
                      },
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: CachedNetworkImage(
                          imageUrl: item.mediaUrl ?? "",
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(height: 200, color: Colors.grey[200]),
                          errorWidget: (_, __, ___) => Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                                child: Icon(Icons.broken_image)),
                          ),
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User info + menu
                        Row(
                          children: [
                            CachedAvatarWidget(
                                imageUrl: userProfileGlobal,
                                size: SizeConfig.size42,
                                borderColor: AppColors.transparent,
                                borderRadius: 25),
                            SizedBox(width: SizeConfig.size10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    item.title ?? "No Title",
                                    fontWeight: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (item.date != null)
                                        _tagChip(
                                            formattedCreatedAt(
                                                item.date ?? "")),
                                      if (item.role != null) ...[
                                        const SizedBox(width: 6),
                                        _tagChip(
                                            "@${item.role ?? 'User'}"),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(Icons.more_vert,
                                  color: Colors.grey[600],
                                  size: 20),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  controller.setEditData(item);
                                  Get.to(() =>
                                      SocialActivityFormScreen());
                                } else if (value == 'delete') {
                                  showConfirmDialog(
                                    context,
                                    () {
                                      Navigator.pop(context);
                                      controller.deleteActivity(
                                          item.sId ?? "");
                                    },
                                    title: AppStrings.delete,
                                    content: AppStrings
                                        .deleteActivityConfirm,
                                  );
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined,
                                          color:
                                              AppColors.primaryColor,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      CustomText(
                                          AppStrings.edit.tr),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline,
                                          color: Colors.red,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      CustomText(
                                          AppStrings.delete.tr,
                                          color: Colors.red),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Location
                        if (item.location?.name != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: AppColors.primaryColor),
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
                        ],

                        // Description
                        if (item.description != null &&
                            item.description!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          CustomText(
                            item.description!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            color: AppColors.secondaryTextColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _tagChip(String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomText(
        text,
        fontSize: 11,
        color: AppColors.secondaryTextColor,
      ),
    );
  }
}
