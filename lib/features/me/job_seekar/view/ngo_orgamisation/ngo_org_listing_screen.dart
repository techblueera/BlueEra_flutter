import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/personal/resume/controller/add_more_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/fields/add_ngo_screen.dart';
import 'package:BlueEra/features/personal/resume/resume_profile_section_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NgoOrgListingScreen extends StatefulWidget {
  const NgoOrgListingScreen({super.key});

  @override
  State<NgoOrgListingScreen> createState() => _NgoOrgListingScreenState();
}

class _NgoOrgListingScreenState extends State<NgoOrgListingScreen> {
  final ngoController = Get.put(EntityController(isPatent: false), tag: "ngo");
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
      appBar: CommonBackAppBar(title: AppStrings.ngoStudentOrganisations.tr),
      body: Obx(() {
        final items = ngoController.entityList;
        return ResumeProfileSectionCard(
          title: "",
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
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddNgoScreen(isEdit: true, experienceId: id)),
            ).then((_) => getResumeController.getMyResume());
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
              getResumeController.getMyResume();
            });
          },
        );
      }),
    );
  }
}
