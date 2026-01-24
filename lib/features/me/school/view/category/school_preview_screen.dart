import 'package:BlueEra/core/api/model/institution_fetch_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SchoolPreviewScreen extends StatelessWidget {
  final controller = Get.find<SchoolController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: "Institution Details"),
      body: SafeArea(
        child: Obx(() {
          InstitutionFetchData data =
              controller.institutionFetchModel?.value.data ??
                  InstitutionFetchData();
          if (data.name == null)
            return Center(child: CustomText("No Data Found"));

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // About Us Section
                _buildSectionTitle("About University"),
                CustomText(data.aboutUs?.history ?? ""),
                SizedBox(height: 10),
                CustomText("Vision & Mission", fontWeight: FontWeight.bold),
                CustomText(data.aboutUs?.visionAndMission ?? ""),

                // Management Horizontal List
                _buildManagementList(data.aboutUs?.management ?? []),

                // Academics Section
                _buildSectionTitle("Courses Offered"),
                _buildCourseList(data.academics?.courses ?? []),

                // Campus Life
                _buildSectionTitle("Campus Infrastructure"),
                _buildInfrastructure(data.campusLife?.infrastructure),

                // Contact Section
                _buildSectionTitle("Contact Us"),
                Card(
                  child: ListTile(
                    leading: LocalAssets(imagePath: AppIconAssets.location_new),
                    title: CustomText(data.contactUs?.address ?? ""),
                    subtitle: CustomText(
                        "Email: ${data.contactUs?.email}\nPhone: ${data.contactUs?.phone}"),
                  ),
                ),
                SizedBox(height: 20),
                PositiveCustomBtn(
                    onTap: () async {
                      await controller.createSchoolController();
                    },
                    title: "Create School"),
                SizedBox(height: 50),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: CustomText(title,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900),
    );
  }


  Widget _buildCourseList(List<Courses> courses) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return    Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // Keeps fees aligned at the top if title wraps
                  children: [
                    // 1. Wrap the large text in Expanded
                    Expanded(
                      child: CustomText(
                        course.name ?? "Course Name",
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        // Optional: overflow: TextOverflow.ellipsis, // Adds "..." if too long
                      ),
                    ),
                    const SizedBox(width: 10), // Space between text and fees
                    // 2. Fees stay on the right
                    Flexible(
                      child: CustomText(
                        course.fees ?? "",
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CustomText(
                  "Eligibility: ${course.eligibility}",
                  color: Colors.grey[700],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManagementList(List<Management> managers) {
    return Container(
      height: 110,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: managers.length,
        itemBuilder: (context, index) {
          return Container(
            width: 130,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 5,
                    ),
                    Expanded(
                        child: LocalAssets(
                      imagePath: AppIconAssets.userNew,
                      height: 25,
                      width: 25,
                    )),
                    SizedBox(
                      height: 5,
                    ),
                    CustomText(
                      managers[index].name ?? "",
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    CustomText(managers[index].position ?? "",
                        textAlign: TextAlign.center, maxLines: 1, fontSize: 10),
                    SizedBox(
                      height: 5,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfrastructure(Infrastructure? infra) {
    if (infra == null) return SizedBox();
    return Wrap(
      spacing: 10,
      children: [
        Chip(
            avatar: Icon(Icons.hotel),
            label: CustomText("Hostel: ${infra.hostel?.capacity} beds")),
        Chip(
            avatar: Icon(Icons.computer),
            label: CustomText("Labs: ${infra.labs}")),
        Chip(
            avatar: Icon(Icons.meeting_room),
            label: CustomText("Classrooms: ${infra.classrooms}")),
      ],
    );
  }
}
