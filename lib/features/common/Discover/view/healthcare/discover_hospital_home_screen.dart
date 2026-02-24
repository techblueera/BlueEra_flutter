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
import 'package:url_launcher/url_launcher.dart';

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
            CommonCardWidget(
              padding: 10,
              child: EmergencyCriticalCareView(),
              bgColor: Color(0xff0085FE).withOpacity(0.08),
            ),
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
    // Extracting numbers for cleaner code
    final emergencyNo = controller.hospitalDataResModel?.value.data?.emergencyContactData?.emergencyNumber ?? "";
    final appointmentNo = controller.hospitalDataResModel?.value.data?.emergencyContactData?.appointmentNumber ?? "";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          _buildActionCard(
            icon: "assets/svg/call_24.svg", // Your 24/7 Phone Icon
            title: "Emergency Number",
            subtitle: "24/7 Immediate Help",
            buttonText: "Call Now",
            isEmergency: true,
            phoneNo: emergencyNo,
            onTap: () => _launchCaller(emergencyNo),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: "assets/svg/helth_calender.svg", // Your Calendar Icon
            title: "Book Appointment",
            subtitle: "Schedule Your Visit Easily",
            buttonText: "Call Now",
            isEmergency: false,
            phoneNo: appointmentNo,

            onTap: () => _launchCaller(appointmentNo),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required String phoneNo,
    required bool isEmergency,
    required VoidCallback onTap,
  }) {
    return CommonCardWidget(
      cardMargin: 0,
      child: Row(
        children: [
          // 1. Icon Section
          LocalAssets(imagePath: icon, height: 50, width: 50),
          const SizedBox(width: 16),

          // 2. Text Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                ),
                const SizedBox(height: 4),
                CustomText(
                  phoneNo,
                    color: Colors.grey.shade600,
                ),
              ],
            ),
          ),

          // 3. Action Button
          _buildCallButton(buttonText, isEmergency, onTap),
        ],
      ),
    );
  }

  Widget _buildCallButton(String text, bool isEmergency, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isEmergency ? const Color(0xFFC8554D) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: isEmergency ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.phone,
              size: 18,
              color: isEmergency ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isEmergency ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _launchCaller(String number) async {
    // Remove any spaces or special characters from the string
    final cleanNumber = number.replaceAll(RegExp(r'\s+\b|\b\s+'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        // Handle the error if the dialer cannot be opened (e.g., on a Tablet without a SIM)
        commonSnackBar(message:
          "Error Could not open the dialer",
        );
      }
    } catch (e) {
      debugPrint("Error launching dialer: $e");
    }
  }
}

