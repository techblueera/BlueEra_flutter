import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/publications_controller.dart';
import 'package:BlueEra/features/personal/resume/fields/add_publishing_screen.dart';
import 'package:BlueEra/features/personal/resume/resume_profile_section_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JobSeekerPublicationListingScreen extends StatefulWidget {
  const JobSeekerPublicationListingScreen({super.key});

  @override
  State<JobSeekerPublicationListingScreen> createState() =>
      _JobSeekerPublicationListingScreenState();
}

class _JobSeekerPublicationListingScreenState
    extends State<JobSeekerPublicationListingScreen> {
  final getResumeController = Get.find<ProfilePicController>();
  final publicationsController = Get.put(PublicationsController());

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
        title: AppStrings.publications,
      ),
      body: Obx(() {
        final publications = publicationsController.publications;

        return ResumeProfileSectionCard(
          title: "",
          items: publications.map((pub) {
            final pubDate = pub['publishedDate'];
            String pubDateStr = '';
            if (pubDate != null && pubDate is Map) {
              final date = pubDate['date']?.toString() ?? '';
              final month = pubDate['month']?.toString() ?? '';
              final year = pubDate['year']?.toString() ?? '';
              pubDateStr = '$date/$month/$year';
            }

            return {
              'title': pub['title'] ?? '',
              'subtitle1': pub['link'] ?? '',
              'subtitle2': pubDateStr,
              'subtitle3': pub['description'] ?? '',
              '_id': pub['_id'],
            };
          }).toList(),
          titleColor: AppColors.black28,
          subtitle1Color: AppColors.primaryColor,
          onAddPressed: () async {
            navigatePushTo(context, const AddPublishingScreen());
          },
          itemsEditCallback: (index) async {
            publicationsController.fillFormForEdit(publications[index]);
            navigatePushTo(
              context,
              AddPublishingScreen(publicationData: publications[index]),
            );
          },
          itemsDeleteCallback: (index) {
            showConfirmDeleteDialog(context, () async {
              Navigator.of(context).pop();
              await publicationsController.deletePublicationApi(
                  publications[index]['_id'], index);
              commonSnackBar(message: AppStrings.publicationDeleted);
            });
          },
        );
      }),
    );
  }
}
