import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/model/rider_onboarding_status.dart';
import 'package:BlueEra/features/common/delivery_partner/view/aadhar_card_widget.dart';
import 'package:BlueEra/features/common/delivery_partner/view/common_rider_bottom_sheet.dart';
import 'package:BlueEra/features/common/delivery_partner/view/driving_licence_card_widget.dart';
import 'package:BlueEra/features/common/delivery_partner/view/info_display_card_widget.dart';
import 'package:BlueEra/features/common/delivery_partner/view/pan_card_widget.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rc_book_card_widget.dart';
import 'package:BlueEra/features/common/delivery_partner/view/vehicle_images_riding_widget.dart';
import 'package:BlueEra/features/common/delivery_partner/view/vehicle_information_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RiderProfileStatusScreen extends StatefulWidget {
  RiderProfileStatusScreen({super.key});

  @override
  State<RiderProfileStatusScreen> createState() =>
      _RiderProfileStatusScreenState();
}

class _RiderProfileStatusScreenState extends State<RiderProfileStatusScreen> {
  final controller = Get.put(DeliveryPartnerController());
  RiderOnboardingStatusData riderOnboardingStatusData =
      RiderOnboardingStatusData();

  @override
  void initState() {
    if (userProfessionGlobal == SELF_EMPLOYED &&
        userWorkTypeGlobal == DELIVERY_RIDER) {
      controller.ridersOnboardingStatusRepoApi();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.appBackgroundColor,
      child: SafeArea(
        child: Obx(() {
          // TODO: implement initState
          riderOnboardingStatusData =
              controller.riderOnboardingStatusData.value ??
                  RiderOnboardingStatusData();
          logs(
              "riderOnboardingStatusData ${riderOnboardingStatusData.verificationStatus}");
          return SingleChildScrollView(
            child: Column(
              children: [
                InfoDisplayCard(
                  title: AppStrings.vehicleInformation,
                  value:
                      (riderOnboardingStatusData.vehicleNo?.isNotEmpty ?? false)
                          ? riderOnboardingStatusData.vehicleNo ?? ""
                          : 'E.g. WB5454',
                  status: riderOnboardingStatusData.vehicleInformation ?? false,
                  onTap: (riderOnboardingStatusData.vehicleInformation ?? false)
                      ? () => null
                      : () {
                          Get.bottomSheet(
                            CommonBottomSheet(
                              title: AppStrings.vehicleInformation,
                              height: MediaQuery.of(context).size.height * 0.80,
                              child: VehicleInformationWidget(),
                            ),
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                          );
                        }, // green tick visible
                ),
                InfoDisplayCard(
                  title: AppStrings.aadharNumber,
                  value:
                      (riderOnboardingStatusData.aadharNo?.isNotEmpty ?? false)
                          ? riderOnboardingStatusData.aadharNo ?? ""
                          : 'E.g. 5678 1234 6679 9012',
                  status: riderOnboardingStatusData.aadhar ?? false,
                  onTap: (riderOnboardingStatusData.aadhar ?? false)
                      ? () => null
                      : () {
                          Get.bottomSheet(
                            CommonBottomSheet(
                              title: "Aadhar Card",
                              height: MediaQuery.of(context).size.height * 0.40,
                              child: AadharCardWidget(),
                            ),
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                          );
                        }, // no tick
                ),
                InfoDisplayCard(
                  title: AppStrings.panNumber,
                  value: (riderOnboardingStatusData.panNo?.isNotEmpty ?? false)
                      ? riderOnboardingStatusData.panNo ?? ""
                      : 'E.g. ABCDE1234F',
                  status: riderOnboardingStatusData.pan ?? false,
                  onTap: (riderOnboardingStatusData.pan ?? false)
                      ? () => null
                      : () {
                          Get.bottomSheet(
                            CommonBottomSheet(
                              title: "Pan Card",
                              height: MediaQuery.of(context).size.height * 0.40,
                              child: PanCardWidget(),
                            ),
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                          );
                        }, // no tick
                ),
                InfoDisplayCard(
                  title: AppStrings.drivingLicenceNumber,
                  value: (riderOnboardingStatusData.dlNo?.isNotEmpty ?? false)
                      ? riderOnboardingStatusData.dlNo ?? ""
                      : 'E.g. DL0120110012345',
                  status: riderOnboardingStatusData.dl ?? false,
                  onTap: (riderOnboardingStatusData.dl ?? false)
                      ? () => null
                      : () {
                          Get.bottomSheet(
                            CommonBottomSheet(
                              title: "Driving Licence",
                              height: MediaQuery.of(context).size.height * 0.40,
                              child: DrivingLicenceCardWidget(),
                            ),
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                          );
                        }, // no tick
                ),
                InfoDisplayCard(
                  title: AppStrings.rcNumber,
                  value: (riderOnboardingStatusData.rcNo?.isNotEmpty ?? false)
                      ? riderOnboardingStatusData.rcNo ?? ""
                      : 'E.g. WB12 AB 1234',
                  status: riderOnboardingStatusData.rc ?? false,
                  onTap: (riderOnboardingStatusData.rc ?? false)
                      ? () => null
                      : () {
                          Get.bottomSheet(
                            CommonBottomSheet(
                              title: "RC",
                              height: MediaQuery.of(context).size.height * 0.40,
                              child: RcBookCardWidget(),
                            ),
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                          );
                        }, // no tick
                ),
                InfoDisplayCard(
                  title: AppStrings.vehicleImages,
                  value: 'Upload Vehicle image',
                  status: riderOnboardingStatusData.vehicleImages ?? false,
                  onTap: (riderOnboardingStatusData.vehicleImages ?? false)
                      ? () => null
                      : () {
                          Get.bottomSheet(
                            CommonBottomSheet(
                              title: AppStrings.vehicleImages,
                              height: MediaQuery.of(context).size.height * 0.80,
                              child: VehicleImagesRidingWidget(),
                            ),
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                          );
                        }, // no tick
                ),
                SizedBox(
                  height: SizeConfig.size100,
                )
              ],
            ),
          );
        }),
      ),
    );
  }
}
