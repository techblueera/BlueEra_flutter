import 'package:BlueEra/core/constants/app_strings.dart';
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
    // No SizedBox separators between the cards: every card here is a
    // CommonCardWidget, which already carries `margin: EdgeInsets.all(10)`,
    // so adjacent cards sit 20dp apart on their own.
    // `stretch` keeps every card the same width — without it a card whose
    // list is empty (title + Add row only) shrink-wraps and sits narrower
    // than its filled neighbours.
    //
    // The add/edit screens are pushed WITHOUT a `.then(getMyResume())`: a plain
    // back press means nothing was added or updated, so re-fetching the resume
    // there is a wasted network call. When something IS saved or deleted, the
    // controllers (EntityController.add/update/deleteEntity and
    // AdditionalInfoController.add/update/deleteAdditionalInfo) already refresh
    // the resume themselves before the screen pops, and the lists below are
    // Obx-bound, so the cards update on their own.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          final items = additionalInfoController.additionalInfoList;
          return ResumeProfileSectionCard(
            title: AppStrings.addAdditionalInformation.tr,
            items: items.toList(),
            onAddPressed: items.isEmpty
                ? () {
                    additionalInfoController.clearForm();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AdditionalInfoScreen(isEdit: false)),
                    );
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
              );
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
        Obx(() {
          final items = ngoController.entityList;
          return ResumeProfileSectionCard(
            title: AppStrings.ngoStudentOrganisations.tr,
            items: items.toList(),
            onAddPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddNgoScreen(isEdit: false)),
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
                        AddNgoScreen(isEdit: true, experienceId: id)),
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
                await ngoController.deleteEntity(id);
              });
            },
          );
        }),
        Obx(() {
          final items = patentController.entityList;
          return ResumeProfileSectionCard(
            title: AppStrings.patents.tr,
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
      ],
    );
  }
}
