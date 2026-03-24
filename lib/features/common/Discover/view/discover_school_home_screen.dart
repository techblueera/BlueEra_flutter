import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/school_academics_page.dart';
import 'package:BlueEra/features/me/school/view/category/campus_life/campus_life_listing_screen.dart';
import 'package:BlueEra/features/me/school/view/category/career_jobs/school_job_listing_screen.dart';
import 'package:BlueEra/features/me/school/view/category/notice_news/notice_news_screen.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_campus_photo_gallery_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_contact_us_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_course_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_director_card_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_header_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_management_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_student_corner.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_cart_icon.dart';
import 'package:get/get.dart';

class DiscoverSchoolHomeScreen extends StatelessWidget {
  DiscoverSchoolHomeScreen({super.key});

  final schoolAboutUsController = Get.find<SchoolAboutUsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
     appBar: CommonBackAppBar(title: AppStrings.school, buildCustomActionWidget: () => const DiscoverCartIcon(),),
      bottomNavigationBar:schoolAboutUsController
          .schoolDetailsData?.value.ownerId != userId
          ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
              left: 12.0, right: 12, bottom: 15, top: 10),
          child: Row(
            children: [
              Expanded(
                child: PositiveCustomBtn(
                    onTap: () async {
                      final chatViewController =
                      Get.find<ChatViewController>();
                      chatViewController.checkChatConnectionAndOpenChat(
                        userId: schoolAboutUsController
                            .schoolDetailsData?.value.ownerId ?? '',
                      );
                    },
                    title: AppStrings.chat),
              ),
              SizedBox(
                width: 10,
              ),
              Expanded(
                child: PositiveCustomBtn(
                    onTap: () {
                      commonSnackBar(message: 'Coming Soon....');
                    },
                    title: AppStrings.bookInquiry),
              ),
            ],
          ),
        ),
      )
          : null,
     body:  SingleChildScrollView(
         child: Column(
           children: [
             SchoolHeaderView(schoolAboutUsController: schoolAboutUsController),
             DirectorCard(
               schoolAboutUsController: schoolAboutUsController,
             ),
             SchoolManagementSection(
               managementData: schoolAboutUsController
                   .schoolDetailsData?.value.aboutId?.management,
             ),
             SchoolCourseSection(
               courses:
               schoolAboutUsController.schoolDetailsData?.value.courses ??
                   [], isEdit: false,
             ),
             CampusPhotoGallery(
               campusLife:
               schoolAboutUsController.schoolDetailsData?.value.campusLife ??
                   [],
             ),
             InkWell(
               onTap: () {
                 Get.to(SchoolJobListingScreen(isEdit: false,));
               },
               child: cardViewWidget(title:AppStrings.jobVacancy),
             ),
             InkWell(
               onTap: () {
                 Get.to(SchoolAcademicsPage(isEdit: false,));
               },
               child: cardViewWidget(title: AppStrings.academics),
             ),
             InkWell(
               onTap: () {
                 Get.to(SchoolStudentCorner(isEdit: false,));
               },
               child: cardViewWidget(title:AppStrings.studentCorner),
             ),
             // InkWell(
             //   onTap: () {
             //     Get.to(CampusLifeListingScreen());
             //   },
             //   child: cardViewWidget(title: "Campus Life"),
             // ),
             InkWell(
               onTap: () {
                 Get.to(NoticeNewsScreen(isEdit: false,));
               },
               child: cardViewWidget(title: AppStrings.noticesNews),
             ),
             SizedBox(
               height: 10,
             ),
             ContactUsSection(
               isEdit: false,
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
               BusinessLocationWidget(
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
             SizedBox(
               height: kBottomNavigationBarHeight + 50,
             ),
           ],
         )),
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

