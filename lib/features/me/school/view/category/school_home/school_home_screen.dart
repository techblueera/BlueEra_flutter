import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/school_academics_page.dart';
import 'package:BlueEra/features/me/school/view/category/career_jobs/school_job_listing_screen.dart';
import 'package:BlueEra/features/me/school/view/category/notice_news/notice_news_screen.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_campus_photo_gallery_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_contact_us_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_course_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_director_card_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_header_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_management_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_student_corner.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SchoolHomeScreen extends StatelessWidget {
  SchoolHomeScreen({super.key});

  final schoolAboutUsController = Get.find<SchoolAboutUsController>();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.appBackgroundColor,
      child: RefreshIndicator(onRefresh: () async {
        await schoolAboutUsController.getSchoolByIdController();
      }, child: Obx(() {
        return SingleChildScrollView(
            child: Column(
          children: [
            SchoolHeaderView(schoolAboutUsController: schoolAboutUsController,isEdit: true,),
            DirectorCard(
              schoolAboutUsController: schoolAboutUsController,
              isEdit: true,
            ),
            SchoolManagementSection(
              managementData: schoolAboutUsController
                  .schoolDetailsData?.value.aboutId?.management,
              isEdit: true,
            ),
            SchoolCourseSection(
              courses:
                  schoolAboutUsController.schoolDetailsData?.value.courses ??
                      [], isEdit: true,
            ),
            CampusPhotoGallery(
              campusLife:
                  schoolAboutUsController.schoolDetailsData?.value.campusLife ??
                      [],
              isEdit: true,
            ),
            InkWell(
              onTap: () {
                Get.to(SchoolJobListingScreen(isEdit: true,));
              },
              child: cardViewWidget(title: AppStrings.jobVacancy),
            ),
            InkWell(
              onTap: () {
                Get.to(SchoolAcademicsPage(isEdit: true,));
              },
              child: cardViewWidget(title: AppStrings.academics),
            ),
            InkWell(
              onTap: () {
                Get.to(SchoolStudentCorner(isEdit: true,));
              },
              child: cardViewWidget(title:AppStrings.studentCorner),
            ),
            InkWell(
              onTap: () {
                Get.to(NoticeNewsScreen(isEdit: true,));
              },
              child: cardViewWidget(title: AppStrings.noticesNews),
            ),
            SizedBox(
              height: 10,
            ),
            ContactUsSection(
              isEdit: true,
              contacts:
                  schoolAboutUsController.schoolDetailsData?.value.contacts ??
                      [],
            ),
            SizedBox(
              height: 10,
            ),
            if ((schoolAboutUsController.schoolDetailsData?.value.location
                        ?.coordinates?.isNotEmpty ??
                    false) &&
                schoolAboutUsController
                        .schoolDetailsData?.value.location?.coordinates?[0] !=
                    null &&
                schoolAboutUsController
                        .schoolDetailsData?.value.location?.coordinates?[1] !=
                    null &&
                schoolAboutUsController
                        .schoolDetailsData?.value.location?.coordinates?[0] !=
                    0.0 &&
                schoolAboutUsController
                        .schoolDetailsData?.value.location?.coordinates?[1] !=
                    0.0)
              CommonCardWidget(
                padding: 5,
                child: BusinessLocationWidget(
                    locationText:
                        schoolAboutUsController.schoolDetailsData?.value.name,
                    latitude: double.parse(schoolAboutUsController
                            .schoolDetailsData?.value.location?.coordinates?[0]
                            .toString() ??
                        "0.0"),
                    longitude: double.parse(schoolAboutUsController
                            .schoolDetailsData?.value.location?.coordinates?[1]
                            .toString() ??
                        "0.0"),
                    businessName:
                        schoolAboutUsController.schoolDetailsData?.value.name ??
                            "",
                    padding: 0,
                    isTitleShow: true),
              ),
            SizedBox(
              height: kBottomNavigationBarHeight + 50,
            ),
          ],
        ));
      })),
    );
  }

}
Widget cardViewWidget({required String title}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
    child: CommonCardWidget(
        cardMargin: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ServiceHomeTitleWidget(
              title: title,
            ),
            CustomText(
               AppStrings.view,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ],
        )),
  );
}

