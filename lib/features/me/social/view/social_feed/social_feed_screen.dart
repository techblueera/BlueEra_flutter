import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/social/controller/social_feed_controller.dart';
import 'package:BlueEra/features/me/social/view/social_feed/add_social_feed_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
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
    // TODO: implement initState
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
      appBar: CommonBackAppBar(title: "Activity Feed"),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding:
              EdgeInsets.only(left: 15.0, right: 15.0, bottom: 30, top: 10),
          child: PositiveCustomBtn(
              bgColor: AppColors.white,
              borderColor: AppColors.primaryColor,
              textColor: AppColors.primaryColor,
              onTap: () {
                Get.to(() => AddSocialFeedScreen());
              },
              title: "Add Activity Feed"),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.departmentList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.departmentList.isEmpty) {
          return Center(child: CustomText("No Activity Feed found."));
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchDepartments(isRefresh: true),
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: controller.departmentList.length ,
            itemBuilder: (context, index) {
              if (index < controller.departmentList.length) {
                return DepartmentCard(
                  data: controller.departmentList[index],
                  onEdit: () {
                    Get.to(() => AddSocialFeedScreen(
                          isEdit: true,
                          departmentData: controller.departmentList[index],
                        ));
                  },
                  onDelete: () async {
                    await showCommonDialog(
                        context: context,
                        text: 'Are you sure you want to delete this Activity Feed?',
                        confirmCallback: () async {
                          controller.deleteSchoolDepartmentController(
                              departmentId:
                                  controller.departmentList[index].id!);
                        },
                        cancelCallback: () {
                          Navigator.of(context).pop(); // Close the dialog
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
      {required this.data, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [

                Expanded(
                    child: CustomText(data.title ?? "",
                        fontSize: 18, fontWeight: FontWeight.bold)),
                PopupMenuButton(
                  onSelected: (val) => val == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'edit', child: CustomText("Edit")),
                    const PopupMenuItem(
                        value: 'delete',
                        child: CustomText("Delete", color: AppColors.red00)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 5),
            CustomText("Description: ${data.description}",
                color: Colors.grey[700], maxLines: 2),
            const SizedBox(height: 10),

            // Image Gallery Row
            if (data.mediaUrls != null)
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.mediaUrls.length,
                  itemBuilder: (context, i) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                          image: NetworkImage(data.mediaUrls[i]),
                          fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),

            const Divider(),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(
                text: label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
