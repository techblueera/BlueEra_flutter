import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/personal/resume/certificate_screen.dart';
import 'package:BlueEra/features/personal/resume/controller/certifications_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/resume_profile_section_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JobSeekerCertificationListingScreen extends StatefulWidget {
  const JobSeekerCertificationListingScreen({super.key});

  @override
  State<JobSeekerCertificationListingScreen> createState() =>
      _JobSeekerCertificationListingScreenState();
}

class _JobSeekerCertificationListingScreenState
    extends State<JobSeekerCertificationListingScreen> {
  final certificationsController = Get.put(CertificationsController());
  final getResumeController = Get.find<ProfilePicController>();

  @override
  void initState() {
    // TODO: implement initState
    getResumeController.getMyResume();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.certifications,
      ),
      body: Obx(() {
        final items = certificationsController.certificationsList;

        return ResumeProfileSectionCard(
          title: "",
          items: items.toList(),
          onAddPressed: () {
            certificationsController.clearForm();
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CertificateScreen(isEdit: false)),
            );
          },
          itemsEditCallback: (index) {
            final items = certificationsController.certificationsList;
            if (index < 0 || index >= items.length) return;
            final data = items[index];
            certificationsController.fillForm(data);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CertificateScreen(
                    isEdit: true, certificationId: data['_id']),
              ),
            ).then((_) => getResumeController.getMyResume());
          },
          itemsDeleteCallback: (index) {
            final data = items[index];
            final id = data['_id'] as String?;
            if (id == null) return;
            showConfirmDeleteDialog(context, () async {
              Navigator.of(context).pop();
              await certificationsController.deleteCertification(id, index);
            });
          },
          titleColor: AppColors.black28,
        );
      }),
    );
  }
}
