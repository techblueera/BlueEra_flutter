import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/add_more_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/additional_info_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/fields/add_ngo_screen.dart';
import 'package:BlueEra/features/personal/resume/fields/add_patents_screen.dart';
import 'package:BlueEra/features/personal/resume/fields/additional_info.dart';
import 'package:BlueEra/features/personal/resume/resume_profile_section_card.dart';
import 'package:BlueEra/widgets/delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Assuming EntityController and Add screens are imported

class AddMoreSection extends StatefulWidget {
  AddMoreSection({super.key});

  @override
  State<AddMoreSection> createState() => _AddMoreSectionState();
}

class _AddMoreSectionState extends State<AddMoreSection> {
  final EntityController ngoController =
      Get.put(EntityController(isPatent: false), tag: "ngo");
  final EntityController patentController =
      Get.put(EntityController(isPatent: true), tag: "patent");
  final additionalInfoController = Get.put(AdditionalInfoController());

  final getResumeController = Get.find<ProfilePicController>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getResumeController.getMyResume();
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        Obx(() {
          final items = additionalInfoController.additionalInfoList;
          return ResumeProfileSectionCard(
            title: "Additional Information",
            items: items.toList(),
            onAddPressed: items.isEmpty
                ? () {
                    additionalInfoController.clearForm();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AdditionalInfoScreen(isEdit: false)),
                    ).then((_) => getResumeController.getMyResume());
                  }
                : null,
            itemsEditCallback: (index) {
              final data = items[index];
              additionalInfoController.fillForm(data);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AdditionalInfoScreen(isEdit: true, infoId: data['_id']),
                ),
              ).then((_) => getResumeController.getMyResume());
            },
            itemsDeleteCallback: (index) {
              final data = items[index];
              final id = data['_id'] as String?;
              if (id == null) return;
              showConfirmDeleteDialog(context, () async {
                Navigator.of(context).pop();
                await additionalInfoController.deleteAdditionalInfo(id);
              });
            },
          );
        }),
        SizedBox(height: SizeConfig.size10),
        Obx(() {
          final items = ngoController.entityList;
          return ResumeProfileSectionCard(
            title: "NGO / Student Organisations",
            items: items.toList(),
            onAddPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddNgoScreen(isEdit: false)),
              ).then((_) => getResumeController.getMyResume());
            },
            itemsEditCallback: (index) {
              final data = items[index];
              final id = data['_id'] as String?;
              if (id == null) {
                print("Error: NGO ID not found for editing");
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AddNgoScreen(isEdit: true, experienceId: id)),
              ).then((_) => getResumeController.getMyResume());
            },
            itemsDeleteCallback: (index) {
              final data = items[index];
              final id = data['_id'] as String?;
              if (id == null) {
                print("Error: NGO ID not found for deletion");
                return;
              }
              showConfirmDeleteDialog(context, () async {
                Navigator.of(context).pop();
                await ngoController.deleteEntity(id);
                getResumeController.getMyResume();
              });
            },
          );
        }),
        SizedBox(height: 10),
        Obx(() {
          final items = patentController.entityList;
          return ResumeProfileSectionCard(
            title: "Patents",
            items: items.toList(),
            onAddPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddPatentsScreen(isEdit: false),
                ),
              ).then((_) => getResumeController.getMyResume());
            },
            itemsEditCallback: (index) {
              final data = items[index];
              final id = data['_id'] as String?;
              if (id == null) {
                print("Error: Patent ID not found for editing");
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddPatentsScreen(isEdit: true, experienceId: id),
                ),
              ).then((_) => getResumeController.getMyResume());
            },
            itemsDeleteCallback: (index) {
              final data = items[index];
              final id = data['_id'] as String?;
              if (id == null) {
                print("Error: Patent ID not found for deletion");
                return;
              }
              showConfirmDeleteDialog(context, () async {
                Navigator.of(context).pop();
                await patentController.deleteEntity(id);
                getResumeController.getMyResume();
              });
            },
          );
        }),
      ],
    );
  }
}
