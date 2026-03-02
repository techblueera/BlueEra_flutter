import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/emergency/emergency_critical_care_view.dart';
import 'package:BlueEra/features/me/hospital/view/gallery/hospital_home_gallery_widget.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_job_listing_screen.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_contact_us_view.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_department_widget.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_header_view.dart';
import 'package:BlueEra/features/me/hospital/view/widget/managment_card_widget.dart';
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
      bottomNavigationBar: Obx(() {
        return controller.hospitalDataResModel?.value.data?.userId != userId
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 12.0, right: 12, bottom: 15, top: 10),
                  child: Row(
                    children: [

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
            : SizedBox.shrink();
      }),
      appBar: CommonBackAppBar(
        title: AppStrings.hospital,
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
            EmergencyCriticalCareView(),

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
              child: cardViewWidget(title: AppStrings.jobVacancy.tr),
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

            if ((controller.hospitalDataResModel?.value.data?.contacts?.firstOrNull?.branch?.location?.coordinates?.isNotEmpty ?? false) &&
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
              BusinessLocationWidget(
                  locationText: controller.hospitalDataResModel?.value.data?.contacts?.firstOrNull?.branch?.location?.name,
                  latitude: double.parse(controller.hospitalDataResModel?.value.data?.contacts?.firstOrNull?.branch?.location?.coordinates?[1].toString() ?? "0.0"),
                  longitude: double.parse(controller.hospitalDataResModel?.value.data?.contacts?.firstOrNull?.branch?.location?.coordinates?[0].toString() ?? "0.0"),
                  businessName: controller.hospitalDataResModel?.value.data?.name ?? "",
                  padding: 0,
                  isTitleShow: true),

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
    final emergencyNo = controller.hospitalDataResModel?.value.data
            ?.emergencyContactData?.emergencyNumber ??
        "";
    final appointmentNo = controller.hospitalDataResModel?.value.data
            ?.emergencyContactData?.appointmentNumber ??
        "";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              icon: "assets/svg/call_24.svg",
              // Your 24/7 Phone Icon
              title: AppStrings.emergencyContact,
              subtitle: "24/7 Immediate Help",
              buttonText: AppStrings.callNow,
              isEmergency: true,
              phoneNo: emergencyNo,
              onTap: () => _launchCaller(emergencyNo),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              icon: "assets/svg/support_helth.svg",
              // Your Calendar Icon
              title: AppStrings.appointmentNumber,
              subtitle: "Schedule Your Visit Easily",
              buttonText: "Book Now",
              isEmergency: false,
              phoneNo: appointmentNo,
              onTap: () async {
                final chatViewController = Get.find<ChatViewController>();
                Map<String, dynamic> detas = {
                  ApiKeys.user_id:
                      controller.hospitalDataResModel?.value.data?.userId,
                };
                Map<String, dynamic>? checkCompleted =
                    await chatViewController.checkChatConnection(detas);
                chatViewController.openAnyOneChatFunction(
                  profileImage:
                      controller.hospitalDataResModel?.value.data?.logoUrl,
                  otherUserId: (checkCompleted?[ApiKeys.conversation_id] == '')
                      ? (checkCompleted?[ApiKeys.other_user_id])
                      : null,
                  // businessId: widget.businessProfileDetails.id,
                  type: "business",
                  isInitialMessage: true,
                  userId: controller.hospitalDataResModel?.value.data?.userId,
                  conversationId:
                      checkCompleted?[ApiKeys.conversation_id] ?? '',
                  contactName:
                      controller.hospitalDataResModel?.value.data?.name,
                  contactNo: "",
                );
              },
            ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 1. Icon Section
          LocalAssets(imagePath: icon, height: 50, width: 50),
          const SizedBox(height: 16),

          // 2. Text Section
          CustomText(
            title,
            // fontSize: 16,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          // CustomText(
          //   phoneNo,
          //   color: Colors.grey.shade600,
          // ),
          // const SizedBox(height: 4),

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
          borderRadius: BorderRadius.circular(10),
          border:
              isEmergency ? null : Border.all(color: AppColors.primaryColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isEmergency)
              Icon(
                Icons.phone,
                size: 18,
                color: isEmergency ? Colors.white : Colors.black54,
              ),
            const SizedBox(width: 8),
            CustomText(
              text,
              color: isEmergency ? Colors.white : AppColors.primaryColor,
              textAlign: TextAlign.center,
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
        commonSnackBar(
          message: "Error Could not open the dialer",
        );
      }
    } catch (e) {
      debugPrint("Error launching dialer: $e");
    }
  }
}
