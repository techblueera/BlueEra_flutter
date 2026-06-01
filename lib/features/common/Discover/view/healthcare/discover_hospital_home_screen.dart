import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
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
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/widgets/visit_business_stats_card.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:BlueEra/widgets/website_preview_card.dart';
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
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();
  final storeController = getOrPut(() => StoreController());

  @override
  void initState() {
    super.initState();
    final id = controller.hospitalDataResModel?.value.data?.id ?? '';
    if (id.isNotEmpty) {
      viewBusinessDetailsController.viewBusinessProfileById(id);
      storeController.trackStoreDetailView(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteE5,
      bottomNavigationBar: _buildBottomBar(),
      appBar: CommonBackAppBar(
        title: AppStrings.hospital.tr,
      ),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: () async {
          await controller.getHospitalFullDetailsController();
        },
        child: Obx(() {
          final data = controller.hospitalDataResModel?.value.data;

          if (data == null) {
            return _buildFullEmptyState();
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                HospitalHeaderView(isReadOnly: true),

                SizedBox(height: SizeConfig.paddingXS),
                Obx(() {
                  viewBusinessDetailsController.profileVersion.value;
                  return VisitBusinessStatsCard(
                    details: viewBusinessDetailsController
                        .visitedBusinessProfileDetails?.data,
                  );
                }),
                SizedBox(height: SizeConfig.paddingXS),

                /// EMERGENCY ACTION CARDS
                _buildEmergencyActionCards(),

                /// OPD / IPD DEPARTMENTS
                _buildSectionWithEmptyCheck(
                  hasData: data.departments?.isNotEmpty ?? false,
                  icon: Icons.local_hospital_outlined,
                  title: AppStrings.opdDoctors.tr,
                  emptyMessage: AppStrings.noDepartmentsAvailable.tr,
                  child: HospitalBookingScreen(),
                ),

                SizedBox(height: SizeConfig.paddingXS),

                /// EMERGENCY & CRITICAL CARE
                _buildSectionWithEmptyCheck(
                  hasData: _hasEmergencyData(),
                  icon: Icons.emergency_outlined,
                  title: AppStrings.otherFacilities.tr,
                  emptyMessage: AppStrings.noEmergencyServicesListed.tr,
                  child: EmergencyCriticalCareView(),
                ),

                SizedBox(height: SizeConfig.paddingXS),

                /// MANAGEMENT
                _buildSectionWithEmptyCheck(
                  hasData: data.management?.isNotEmpty ?? false,
                  icon: Icons.people_outline,
                  title: AppStrings.managementTrust.tr,
                  emptyMessage: AppStrings.noManagementDetailsAvailable.tr,
                  child: ManagementCardListWidget(),
                ),

                SizedBox(height: SizeConfig.paddingXS),

                /// GALLERY
                _buildGallerySection(),

                SizedBox(height: SizeConfig.paddingXS),

                /// JOB VACANCY
                _buildJobVacancyCard(),

                SizedBox(height: SizeConfig.paddingXS),

                /// CONTACT US
                _buildContactSection(),

                SizedBox(height: SizeConfig.paddingXS),

                /// WEBSITE PREVIEW
                WebsitePreviewCard(
                  url: data.contacts?.firstOrNull?.branch?.website ?? '',
                ),

                /// LOCATION MAP
                _buildLocationSection(),

                SizedBox(
                    height: kBottomNavigationBarHeight + SizeConfig.paddingXSL),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Full-screen empty state when no hospital data exists
  Widget _buildFullEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: EmptyStateWidget(
          message: AppStrings.noHospitalDataFound.tr,
        ),
      ),
    );
  }

  /// Bottom navigation bar with Book/Inquiry button
  Widget _buildBottomBar() {
    return Obx(() {
      return controller.hospitalDataResModel?.value.data?.userId != userId
          ? SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: SizeConfig.paddingS,
                  right: SizeConfig.paddingS,
                  bottom: SizeConfig.paddingM,
                  top: SizeConfig.paddingXSL,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PositiveCustomBtn(
                        onTap: () {
                          commonSnackBar(
                              message: AppStrings.comingSoonLabel.tr);
                        },
                        title: AppStrings.bookInquiry.tr,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink();
    });
  }

  /// Emergency action cards (Call Now + Book Now)
  Widget _buildEmergencyActionCards() {
    final emergencyNo = controller.hospitalDataResModel?.value.data
            ?.emergencyContactData?.emergencyNumber ??
        "";
    final appointmentNo = controller.hospitalDataResModel?.value.data
            ?.emergencyContactData?.appointmentNumber ??
        "";

    if (emergencyNo.isEmpty && appointmentNo.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.paddingS,
        vertical: SizeConfig.paddingXS,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (emergencyNo.isNotEmpty)
              Expanded(
                child: _buildActionCard(
                  icon: "assets/svg/call_24.svg",
                  title: AppStrings.emergencyContact.tr,
                  subtitle: AppStrings.immediateHelp24x7.tr,
                  buttonText: AppStrings.callNow.tr,
                  isEmergency: true,
                  phoneNo: emergencyNo,
                  onTap: () => _launchCaller(emergencyNo),
                ),
              ),
            if (emergencyNo.isNotEmpty && appointmentNo.isNotEmpty)
              SizedBox(width: SizeConfig.paddingS),
            if (appointmentNo.isNotEmpty)
              Expanded(
                child: _buildActionCard(
                  icon: "assets/svg/support_helth.svg",
                  title: AppStrings.appointmentNumber.tr,
                  subtitle: AppStrings.scheduleYourVisitEasily.tr,
                  buttonText: AppStrings.bookNow.tr,
                  isEmergency: false,
                  phoneNo: appointmentNo,
                  onTap: () async {
                    final chatViewController = Get.find<ChatViewController>();
                    chatViewController.checkChatConnectionAndOpenChat(
                      userId:
                          controller.hospitalDataResModel?.value.data?.userId ??
                              '',
                      route: AppConstants.route_discover,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Section wrapper with empty state fallback
  Widget _buildSectionWithEmptyCheck({
    required bool hasData,
    required IconData icon,
    required String title,
    required String emptyMessage,
    required Widget child,
  }) {
    if (!hasData) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.paddingXSL,
          vertical: SizeConfig.paddingXSmall,
        ),
        child: CommonCardWidget(
          cardMargin: 0,
          child: Column(
            children: [
              _sectionHeader(icon: icon, title: title),
              SizedBox(height: SizeConfig.paddingM),
              EmptyStateWidget(
                message: emptyMessage,
                imageSize: SizeConfig.size60,
              ),
              SizedBox(height: SizeConfig.paddingS),
            ],
          ),
        ),
      );
    }
    return child;
  }

  /// Section header row with icon and title
  Widget _sectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: SizeConfig.size20),
        SizedBox(width: SizeConfig.paddingXS),
        ServiceHomeTitleWidget(title: title),
      ],
    );
  }

  /// Gallery section with empty state
  Widget _buildGallerySection() {
    final gallery = controller.hospitalDataResModel?.value.data?.gallery;
    final allImages =
        gallery?.expand((photo) => photo.images ?? <String>[]).toList() ?? [];

    if (allImages.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
        child: CommonCardWidget(
          cardMargin: 0,
          child: Column(
            children: [
              _sectionHeader(
                icon: Icons.photo_library_outlined,
                title: AppStrings.gallery.tr,
              ),
              SizedBox(height: SizeConfig.paddingM),
              EmptyStateWidget(
                message: AppStrings.noPhotosAvailable.tr,
                imageSize: SizeConfig.size60,
              ),
              SizedBox(height: SizeConfig.paddingS),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(SizeConfig.paddingXSL),
      child: HospitalHomeGalleryWidget(
        photos: gallery,
      ),
    );
  }

  /// Job vacancy card with icon and arrow
  Widget _buildJobVacancyCard() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.paddingXSL,
        vertical: SizeConfig.paddingXSmall,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Get.to(HospitalJobListingScreen(isReadOnly: true));
        },
        child: CommonCardWidget(
          cardMargin: 0,
          child: Row(
            children: [
              Icon(
                Icons.work_outline,
                color: AppColors.primaryColor,
                size: SizeConfig.size20,
              ),
              SizedBox(width: SizeConfig.paddingXS),
              Expanded(
                child: ServiceHomeTitleWidget(title: AppStrings.jobVacancy.tr),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.primaryColor,
                size: SizeConfig.size16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Contact us section with empty state
  Widget _buildContactSection() {
    final contacts =
        controller.hospitalDataResModel?.value.data?.contacts ?? [];

    if (contacts.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
        child: CommonCardWidget(
          cardMargin: 0,
          child: Column(
            children: [
              _sectionHeader(
                icon: Icons.phone_outlined,
                title: AppStrings.contactUs.tr,
              ),
              SizedBox(height: SizeConfig.paddingM),
              EmptyStateWidget(
                message: AppStrings.noContactDetailsAvailable.tr,
              ),
              SizedBox(height: SizeConfig.paddingS),
            ],
          ),
        ),
      );
    }

    return HospitalContactUsView(
      contacts: contacts,
      isReadOnly: true,
      description: controller.hospitalDataResModel?.value.data?.description,
    );
  }

  /// Location section - only shown when valid coordinates exist
  Widget _buildLocationSection() {
    final contacts = controller.hospitalDataResModel?.value.data?.contacts;
    final coordinates = contacts?.firstOrNull?.branch?.location?.coordinates;

    if (coordinates == null ||
        coordinates.length < 2 ||
        coordinates[0] == 0.0 ||
        coordinates[1] == 0.0) {
      return const SizedBox.shrink();
    }

    return BusinessLocationWidget(
      locationText: contacts?.firstOrNull?.branch?.location?.name,
      latitude: double.tryParse(coordinates[1].toString()) ?? 0.0,
      longitude: double.tryParse(coordinates[0].toString()) ?? 0.0,
      businessName: controller.hospitalDataResModel?.value.data?.name ?? "",
      padding: 0,
      isTitleShow: true,
    );
  }

  /// Check if any emergency or facility data is available
  bool _hasEmergencyData() {
    final data = controller.hospitalDataResModel?.value.data;
    final ec = data?.emergencyCare;
    final of = data?.otherFacilities;

    if (ec == null && of == null) return false;

    return (ec?.emergencyCasualty ?? false) ||
        (ec?.traumaCare ?? false) ||
        (ec?.icu ?? false) ||
        (ec?.ccu ?? false) ||
        (ec?.nicu ?? false) ||
        (ec?.picu ?? false) ||
        (of?.ambulance ?? false) ||
        (of?.bloodBank ?? false) ||
        (of?.diagnosticDepartments ?? false) ||
        (of?.medicalStore ?? false) ||
        (of?.pmSwasthyaBimaYojana ?? false);
  }

  /// Action card for emergency/appointment
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
          LocalAssets(imagePath: icon, height: 50, width: 50),
          SizedBox(height: SizeConfig.paddingM),
          CustomText(
            title,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          _buildCallButton(buttonText, isEmergency, onTap),
        ],
      ),
    );
  }

  Widget _buildCallButton(String text, bool isEmergency, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.paddingM,
          vertical: SizeConfig.paddingXSL,
        ),
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
                size: SizeConfig.size18,
                color: Colors.white,
              ),
            if (isEmergency) SizedBox(width: SizeConfig.paddingXS),
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
    final cleanNumber = number.replaceAll(RegExp(r'\s+\b|\b\s+'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        commonSnackBar(
          message: AppStrings.errorCouldNotOpenDialer.tr,
        );
      }
    } catch (e) {
      debugPrint("Error launching dialer: $e");
    }
  }
}
