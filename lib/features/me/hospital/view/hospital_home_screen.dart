import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/emergency/emergency_critical_care_view.dart';
import 'package:BlueEra/features/me/hospital/view/gallery/hospital_home_gallery_widget.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_job_listing_screen.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_contact_us_view.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_department_widget.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_header_view.dart';
import 'package:BlueEra/features/me/hospital/view/widget/managment_card_widget.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalHomeScreen extends StatefulWidget {
  const HospitalHomeScreen({super.key});

  @override
  State<HospitalHomeScreen> createState() => _HospitalHomeScreenState();
}

class _HospitalHomeScreenState extends State<HospitalHomeScreen> {
  final controller = Get.find<HospitalServiceAiController>();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.whiteE5,
      child: RefreshIndicator(
        onRefresh: () async {
          await controller.getHospitalFullDetailsController();
        },
        child: SingleChildScrollView(
          child: bodyWidget(),
        ),
      ),
    );
  }

  bodyWidget() {
    return Column(
      children: [
        ///HEADER VIEW...
        HospitalHeaderView(
          isReadOnly: false,
        ),
        // EmergencyActionCard(),

        HospitalBookingScreen(),
       EmergencyCriticalCareView(),


        ManagementCardListWidget(),
        if (controller.hospitalDataResModel?.value.data?.gallery?.isNotEmpty ??
            false) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: HospitalHomeGalleryWidget(
              photos: controller.hospitalDataResModel?.value.data?.gallery,
            ),
          ),
          SizedBox(
            height: 10,
          ),
        ],
        // HospitalFaqWidget(),
        InkWell(
          onTap: () {
            Get.to(HospitalJobListingScreen(
              isReadOnly: false,
            ));
          },
          child: cardViewWidget(title: AppStrings.jobVacancy.tr),
        ),
        SizedBox(
          height: 10,
        ),
        HospitalContactUsView(
          contacts: controller.hospitalDataResModel?.value.data?.contacts ?? [],
          isReadOnly: false,
        ),
        SizedBox(
          height: 10,
        ),

        if ((controller.hospitalDataResModel?.value.data?.contacts?.firstOrNull
                    ?.branch?.location?.coordinates?.isNotEmpty ??
                false) &&
            controller.hospitalDataResModel?.value.data?.contacts?.firstOrNull
                    ?.branch?.location?.coordinates?[0] !=
                null &&
            controller.hospitalDataResModel?.value.data?.contacts?.firstOrNull
                    ?.branch?.location?.coordinates?[1] !=
                null &&
            controller.hospitalDataResModel?.value.data?.contacts?.firstOrNull
                    ?.branch?.location?.coordinates?[0] !=
                0.0 &&
            controller.hospitalDataResModel?.value.data?.contacts?.firstOrNull
                    ?.branch?.location?.coordinates?[1] !=
                0.0)
          BusinessLocationWidget(
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
              longitude: double.parse(controller
                      .hospitalDataResModel
                      ?.value
                      .data
                      ?.contacts
                      ?.firstOrNull
                      ?.branch
                      ?.location
                      ?.coordinates?[0]
                      .toString() ??
                  "0.0"),
              businessName: controller.hospitalDataResModel?.value.data?.name ?? "",
              padding: 0,
              isTitleShow: true),

        SizedBox(
          height: kBottomNavigationBarHeight + 10,
        )
      ],
    );
  }
}
