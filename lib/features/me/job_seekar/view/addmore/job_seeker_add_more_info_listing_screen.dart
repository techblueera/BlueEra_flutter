import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/personal/resume/controller/additional_info_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/fields/additional_info.dart';
import 'package:BlueEra/features/personal/resume/resume_profile_section_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JobSeekerAddMoreInfoListingScreen extends StatefulWidget {
  const JobSeekerAddMoreInfoListingScreen({super.key});

  @override
  State<JobSeekerAddMoreInfoListingScreen> createState() =>
      _JobSeekerAddMoreInfoListingScreenState();
}

class _JobSeekerAddMoreInfoListingScreenState
    extends State<JobSeekerAddMoreInfoListingScreen> {
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
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.addAdditionalInformation.tr,
      ),
      body: Obx(() {
        final items = additionalInfoController.additionalInfoList;
        return ResumeProfileSectionCard(
          title: "",
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
    );
  }
}
