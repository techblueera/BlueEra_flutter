import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/emergency/emergency_critical_care_view.dart';
import 'package:BlueEra/features/me/hospital/view/gallery/hospital_home_gallery_widget.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_job_listing_screen.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_contact_us_view.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_department_widget.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_header_view.dart';
import 'package:BlueEra/features/me/hospital/view/widget/managment_card_widget.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_contact_us_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_home_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DiscoverHospitalHomeScreen extends StatefulWidget {
  const DiscoverHospitalHomeScreen({super.key});

  @override
  State<DiscoverHospitalHomeScreen> createState() =>
      _DiscoverHospitalHomeScreenState();
}

class _DiscoverHospitalHomeScreenState
    extends State<DiscoverHospitalHomeScreen> {
  final controller = Get.find<HospitalServiceAiController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteE5,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.only(bottom: 20, right: 15, left: 15, top: 10),
          child: PositiveCustomBtn(
              onTap: () {
                commonSnackBar(message: "Coming soon....");
              },
              title: "Inquirie Now"),
        ),
      ),
      appBar: CommonBackAppBar(
        title: "Hospital",
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ///HEADER VIEW...
            HospitalHeaderView(
              isReadOnly: true,
            ),
            EmergencyActionCard(),
            HospitalBookingScreen(),
            CommonCardWidget(child: EmergencyCriticalCareView()),
            ManagementCardListWidget(),
            Padding(
              padding: const EdgeInsets.all(10),
              child: HospitalHomeGalleryWidget(
                photos: controller.hospitalDataResModel?.value.data?.gallery,
              ),
            ),

            InkWell(
              onTap: () {
                Get.to(HospitalJobListingScreen(
                  isReadOnly: true,
                ));
              },
              child: cardViewWidget(title: "Job Vacancy"),
            ),
            SizedBox(
              height: 10,
            ),
            HospitalContactUsView(
              contacts:
                  controller.hospitalDataResModel?.value.data?.contacts ?? [],
              isReadOnly: true,
            ),
            SizedBox(
              height: 10,
            ),

            if ((controller
                        .hospitalDataResModel
                        ?.value
                        .data
                        ?.contacts
                        ?.firstOrNull
                        ?.branch
                        ?.location
                        ?.coordinates
                        ?.isNotEmpty ??
                    false) &&
                controller.hospitalDataResModel?.value.data?.contacts
                        ?.firstOrNull?.branch?.location?.coordinates?[0] !=
                    null &&
                controller.hospitalDataResModel?.value.data?.contacts
                        ?.firstOrNull?.branch?.location?.coordinates?[1] !=
                    null &&
                controller.hospitalDataResModel?.value.data?.contacts
                        ?.firstOrNull?.branch?.location?.coordinates?[0] !=
                    0.0 &&
                controller.hospitalDataResModel?.value.data?.contacts
                        ?.firstOrNull?.branch?.location?.coordinates?[1] !=
                    0.0)
              CommonCardWidget(
                padding: 5,
                child: BusinessLocationWidget(
                    locationText: controller.hospitalDataResModel?.value.data
                        ?.contacts?.firstOrNull?.branch?.location?.name,
                    latitude: double.parse(controller
                            .hospitalDataResModel
                            ?.value
                            .data
                            ?.contacts
                            ?.firstOrNull
                            ?.branch
                            ?.location
                            ?.coordinates?[1]
                            .toString() ??
                        "0.0"),
                    longitude: double.parse(
                        controller.hospitalDataResModel?.value.data?.contacts?.firstOrNull?.branch?.location?.coordinates?[0].toString() ??
                            "0.0"),
                    businessName: controller.hospitalDataResModel?.value.data?.name ?? "",
                    padding: 0,
                    isTitleShow: true),
              ),

            SizedBox(
              height: kBottomNavigationBarHeight + 10,
            )
          ],
        ),
      ),
    );
  }
}

class EmergencyActionCard extends StatelessWidget {
  EmergencyActionCard({super.key});

  final controller = Get.find<HospitalServiceAiController>();

  @override
  Widget build(BuildContext context) {
    return CommonCardWidget(
      padding: 9,
      // padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(16),
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.black.withOpacity(0.05),
      //       blurRadius: 10,
      //       spreadRadius: 2,
      //     ),
      //   ],
      // ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // If the screen is too narrow, we stack them or use a scrollable row
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionItem(
                icon: "assets/svg/call_24.svg",
                // Replace with your custom assets
                title: "Emergency Number",
                buttonText: controller
                        .hospitalDataResModel
                        ?.value
                        .data
                        ?.contacts
                        ?.firstOrNull
                        ?.departments
                        ?.firstOrNull
                        ?.phone ??
                    "",
                isButton: false,
              ),
              _buildDivider(),
              _buildActionItem(
                icon: "assets/svg/support_helth.svg",
                title: "Appointment",
                buttonText: controller
                        .hospitalDataResModel
                        ?.value
                        .data
                        ?.contacts
                        ?.firstOrNull
                        ?.departments
                        ?.firstOrNull
                        ?.phone ??
                    "",
                isButton: false,
                hasDropdown: true,
              ),
              // _buildDivider(),
              // _buildActionItem(
              //   icon: "assets/svg/helth_calender.svg",
              //   title: "Book",
              //   subtitle: "Appointment",
              //   buttonText: "Book Now",
              //   isButton: true,
              // ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 80,
      width: 1,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  Widget _buildActionItem({
    required String icon,
    required String title,
    required String buttonText,
    bool isButton = false,
    bool hasDropdown = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          LocalAssets(imagePath: icon),
          // Use Image.asset for your specific icons
          const SizedBox(height: 8),
          CustomText(title,
              textAlign: TextAlign.center,
              fontSize: 12,
              color: AppColors.secondaryTextColor),
          // CustomText(subtitle,
          //     textAlign: TextAlign.center,
          //     fontSize: 10,
          //     color: AppColors.secondaryTextColor),
          const SizedBox(height: 12),
          isButton
              ? _buildBlueButton(buttonText)
              : _buildGreyPill(buttonText, hasDropdown),
        ],
      ),
    );
  }

  Widget _buildGreyPill(String text, bool hasDropdown) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.phone_outlined, size: 14, color: Colors.black54),
          const SizedBox(width: 4),
          CustomText(
            text,
            fontSize: 12,
            color: AppColors.secondaryTextColor,
          ),
          // if (hasDropdown) const Icon(Icons.keyboard_arrow_down, size: 16),
        ],
      ),
    );
  }

  Widget _buildBlueButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        text,
        color: AppColors.primaryColor,
        fontWeight: FontWeight.w400,
        fontSize: 10,
      ),
    );
  }
}
