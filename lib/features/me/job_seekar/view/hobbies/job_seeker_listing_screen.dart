import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/hobbies_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/hobbies_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_chip.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JobSeekerListingScreen extends StatefulWidget {
  const JobSeekerListingScreen({super.key});

  @override
  State<JobSeekerListingScreen> createState() => _JobSeekerListingScreenState();
}

class _JobSeekerListingScreenState extends State<JobSeekerListingScreen> {
  final hobbiesController = Get.put(HobbiesController());
  final getResumeController = Get.find<ProfilePicController>();

  @override
  void initState() {
    super.initState();
    getResumeController.getMyResume();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.hobbies.tr,
      ),
      body: CommonCardWidget(
        child: Obx(() {
          // Content based on hobbies availability
          if (hobbiesController.hobbies.isEmpty)
            // Empty state - Career Objective jaisa design
            return GestureDetector(
              onTap: () => navigatePushTo(context, HobbiesScreen()),
              child: Row(
                children: [
                  Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(width: 8),
                  CustomText(
                    AppStrings.addHobbies.tr,
                    color: AppColors.primaryColor,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            );
          // Hobbies exist - Show chips + Add button
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: hobbiesController.hobbies
                    .where((hobby) =>
                        hobby['name'] != null &&
                        hobby['name'].toString().trim().isNotEmpty)
                    .map((hobby) => CommonChip(
                          label: hobby['name'].toString(),
                          onDeleted: () {
                            showConfirmDialog(
                              context,
                              () {
                                hobbiesController
                                    .deleteHobby(hobby['_id'].toString());
                                Navigator.of(context).pop();
                              },
                              title: AppStrings.deleteHobby.tr,
                              content:
                                  "${AppStrings.deleteConfirm.tr} '${hobby['name']}'?",
                            );
                          },
                        ))
                    .toList(),
              ),
              SizedBox(height: 16),
              GestureDetector(
                // onTap: () => navigatePushTo(context, HobbiesScreen()),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HobbiesScreen()),
                  );
                  if (result == true) {
                    await getResumeController.getMyResume();
                  }
                },

                child: Row(
                  children: [
                    Icon(
                      Icons.add,
                      size: 16,
                      color: AppColors.primaryColor,
                    ),
                    SizedBox(width: 8),
                    CustomText(
                      AppStrings.addHobbies.tr,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
