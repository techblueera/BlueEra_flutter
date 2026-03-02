import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/school/controller/faculty_controller.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/faculty_details_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FacultyProfileListScreen extends StatelessWidget {
  final controller = Get.put(FacultyController());
  final bool isEdit;

   FacultyProfileListScreen({super.key, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title:  AppStrings.faculty,
      ),
      bottomNavigationBar:isEdit? SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
              right: 10.0, left: 10.0, bottom: 40, top: 10),
          child: PositiveCustomBtn(
              bgColor: AppColors.white,
              textColor: AppColors.primaryColor,
              borderColor: AppColors.primaryColor,
              onTap: () {
                Get.to(FacultyFormScreen());
              },
              title:  AppStrings.addFacility,),
        ),
      ):null,
      body: Obx(() {
        if (controller.getAllFacultyResponse.value.status == Status.COMPLETE) {
          if (controller.profiles.isEmpty) {
            return CustomText(AppStrings.noFacultyFound);
          }
          if (controller.profiles.isNotEmpty) {
            return ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: controller.profiles.length +
                  (controller.hasNext.value ? 1 : 0),
              itemBuilder: (context, index) {
                // Pagination: Load more when reaching the end
                if (index == controller.profiles.length) {
                  controller.currentPage++;
                  controller.fetchProfiles();
                  return Center(child: CircularProgressIndicator());
                }

                final user = controller.profiles[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(user.photo ?? ''),
                      backgroundColor: Colors.grey[200],
                    ),
                    title: CustomText(user.name?.toUpperCase() ?? "N/A",
                        fontWeight: FontWeight.bold),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                            "${user.position} • ${user.experience?.years}${AppStrings.yearsExp.tr}"),
                        CustomText(user.email ?? ""),
                      ],
                    ),
                    trailing:isEdit?
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          Get.to(FacultyFormScreen(isEdit: true,facultyData: user,));
                        } else if (value == 'delete') {
                          await showCommonDialog(
                              context: context,
                              text:
                              AppStrings.deleteFacultyConfirm,
                              confirmCallback: () async {
                                await controller.deleteFacultyProfileController(
                                    facultyID: user.id!);
                              },
                              cancelCallback: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              confirmText: AppStrings.yes,
                              cancelText: AppStrings.no);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                CustomText(AppStrings.edit)
                              ],
                            )),
                        PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                CustomText(AppStrings.delete, color: Colors.red)
                              ],
                            )),
                      ],
                    ):null,
                  ),
                );
              },
            );
          }
        }
        if (controller.getAllFacultyResponse.value.status == Status.ERROR) {
          return CustomText(AppStrings.somethingWentWrong);
        }
        return SizedBox();
      }),
    );
  }
}
