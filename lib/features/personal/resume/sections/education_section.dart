import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/education_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/fields/education_screen.dart';
import 'package:BlueEra/features/personal/resume/resume_profile_section_card.dart';
import 'package:BlueEra/widgets/delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EducationSection extends StatefulWidget {
  @override
  State<EducationSection> createState() => _EducationSectionState();
}

class _EducationSectionState extends State<EducationSection> {
  final EducationController controller = Get.put(EducationController());

  final getResumeController = Get.find<ProfilePicController>();
@override
  void initState() {
    // TODO: implement initState
  getResumeController.getMyResume();

  super.initState();
  }
  @override
  Widget build(BuildContext context) {
    // Fetch education details once when widget builds first time

    return Column(
      children: [
        Obx(() {
          final items = controller.educationList;
          return ResumeProfileSectionCard(
            title: "Education",
            items: items.toList(),
            onAddPressed: () {
              controller.clearAll();
              controller.editingId.value = null;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EducationScreen(isEdit: false),
                ),
              ).then((_) => getResumeController.getMyResume());
            },
            itemsEditCallback: (index) {
              final item = items[index];
              controller.clearAll();
              controller.setEditFieldsFromCard(item);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EducationScreen(isEdit: true),
                ),
              ).then((_) {
                controller.clearAll();
                controller.editingId.value = null;
                getResumeController.getMyResume();
              });
            },
            itemsDeleteCallback: (index) {
              final id = items[index]['_id'];
              if (id == null) return;
              showConfirmDeleteDialog(context, () async {
                Navigator.of(context).pop(); // close dialog
                await controller.deleteEducation(id);
              });
            },
            subtitle1Color: AppColors.black28,
          );
        }),
        SizedBox(height: SizeConfig.size10),
      ],
    );
  }
}
