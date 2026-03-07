import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/personal/resume/controller/add_more_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/fields/add_patents_screen.dart';
import 'package:BlueEra/features/personal/resume/resume_profile_section_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JobSeekerPatentListingScreen extends StatefulWidget {
  const JobSeekerPatentListingScreen({super.key});

  @override
  State<JobSeekerPatentListingScreen> createState() =>
      _JobSeekerPatentListingScreenState();
}

class _JobSeekerPatentListingScreenState
    extends State<JobSeekerPatentListingScreen> {
  final patentController =
      Get.put(EntityController(isPatent: true), tag: "patent");

  final getResumeController = Get.find<ProfilePicController>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getResumeController.getMyResume();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.patents.tr,
      ),
      body: Obx(() {
        final items = patentController.entityList;
        return ResumeProfileSectionCard(
          title:"",
          items: items.toList(),
          onAddPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddPatentsScreen(isEdit: false),
              ),
            );
          },
          itemsEditCallback: (index) {
            final data = items[index];
            final id = data['_id'] as String?;
            if (id == null) {
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AddPatentsScreen(isEdit: true, experienceId: id),
              ),
            );
          },
          itemsDeleteCallback: (index) {
            final data = items[index];
            final id = data['_id'] as String?;
            if (id == null) {
              return;
            }
            showConfirmDeleteDialog(context, () async {
              Navigator.of(context).pop();
              await patentController.deleteEntity(id);
            });
          },
        );
      }),
    );
  }
}
