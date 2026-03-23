import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/social/controller/social_feed_controller.dart';
import 'package:BlueEra/features/me/social/view/social_feed/add_social_feed_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialFeedScreen extends StatefulWidget {
  SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final controller = Get.put(SocialFeedController());
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        controller.loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.activityFeed),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => AddSocialFeedScreen()),
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: CustomText(AppStrings.addActivityFeed,
            color: Colors.white,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.departmentList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.departmentList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.post_add, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                CustomText(AppStrings.noDataFound,
                    color: AppColors.secondaryTextColor,
                    fontSize: SizeConfig.medium),
                const SizedBox(height: 8),
                CustomText("Tap + to create your first activity feed",
                    color: Colors.grey[400], fontSize: SizeConfig.small),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchDepartments(isRefresh: true),
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: controller.departmentList.length,
            itemBuilder: (context, index) {
              if (index < controller.departmentList.length) {
                return DepartmentCard(
                  data: controller.departmentList[index],
                  onEdit: () {
                    Get.to(() => AddSocialFeedScreen(
                          isEdit: true,
                          departmentData:
                              controller.departmentList[index],
                        ));
                  },
                  onDelete: () async {
                    await showCommonDialog(
                        context: context,
                        text: AppStrings.deleteConfirm,
                        confirmCallback: () async {
                          controller.deleteSchoolDepartmentController(
                              departmentId:
                                  controller.departmentList[index].id!);
                        },
                        cancelCallback: () {
                          Navigator.of(context).pop();
                        },
                        confirmText: AppStrings.yes,
                        cancelText: AppStrings.no);
                  },
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        );
      }),
    );
  }
}

class DepartmentCard extends StatelessWidget {
  final dynamic data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DepartmentCard(
      {super.key,
      required this.data,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image gallery at top
          if (data.mediaUrls != null && (data.mediaUrls as List).isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: (data.mediaUrls as List).length == 1
                    ? CachedNetworkImage(
                        imageUrl: data.mediaUrls[0],
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey[200]),
                        errorWidget: (_, __, ___) =>
                            Container(color: Colors.grey[200]),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: (data.mediaUrls as List).length,
                        itemBuilder: (context, i) => Container(
                          width: 200,
                          margin: EdgeInsets.only(
                              right: i < (data.mediaUrls as List).length - 1
                                  ? 2
                                  : 0),
                          child: CachedNetworkImage(
                            imageUrl: data.mediaUrls[i],
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: Colors.grey[200]),
                            errorWidget: (_, __, ___) =>
                                Container(color: Colors.grey[200]),
                          ),
                        ),
                      ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Menu
                Row(
                  children: [
                    Expanded(
                      child: CustomText(data.title ?? "",
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    PopupMenuButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.more_vert,
                          color: Colors.grey[600], size: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      onSelected: (val) =>
                          val == 'edit' ? onEdit() : onDelete(),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined,
                                  color: AppColors.primaryColor, size: 18),
                              const SizedBox(width: 8),
                              CustomText(AppStrings.edit),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  color: AppColors.red, size: 18),
                              const SizedBox(width: 8),
                              CustomText(AppStrings.delete,
                                  color: AppColors.red00),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (data.description != null &&
                    (data.description as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  CustomText(
                    data.description,
                    color: AppColors.secondaryTextColor,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
