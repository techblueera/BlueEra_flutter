import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
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
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RiderProfileStatusScreen extends StatefulWidget {
  RiderProfileStatusScreen({
    super.key,
    required this.screeName,
  });

  final String screeName;

  @override
  State<RiderProfileStatusScreen> createState() =>
      _RiderProfileStatusScreenState();
}

class _RiderProfileStatusScreenState extends State<RiderProfileStatusScreen> {
  final controller = getOrPut(() => DeliveryPartnerController());

  @override
  void initState() {
    controller.ridersOnboardingStatusRepoApi();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.screeName != "from_tab_view"
        ? Scaffold(
            appBar: CommonBackAppBar(
              title: AppStrings.deliveryPartner,
            ),
            body: RiderFormWidget(
              deliveryPartnerController: controller,
            ),
          )
        : Material(
            color: AppColors.appBackgroundColor,
            child: RiderFormWidget(
              deliveryPartnerController: controller,
            ));
  }
}

class RiderFormWidget extends StatefulWidget {
  RiderFormWidget({
    super.key,
    required this.deliveryPartnerController,
  });

  final DeliveryPartnerController deliveryPartnerController;

  @override
  State<RiderFormWidget> createState() => _RiderFormWidgetState();
}

class _RiderFormWidgetState extends State<RiderFormWidget> {
  RiderOnboardingStatusData riderOnboardingStatusData =
      RiderOnboardingStatusData();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(() {
        // TODO: implement initState
        riderOnboardingStatusData =
            widget.deliveryPartnerController.riderOnboardingStatusData.value ??
                RiderOnboardingStatusData();

        final state = widget.deliveryPartnerController.riderVerificationState;
        final allCompleted = widget.deliveryPartnerController.stepStatus.values
            .every((s) => s == true);
        return SingleChildScrollView(
          child: Column(
            children: [
              if (state == RiderVerificationState.pending && allCompleted)
                Padding(
                  padding: EdgeInsets.only(top: SizeConfig.size10),
                  child: SizedBox(
                    width: Get.width,
                    child: CommonCardWidget(
                        bgColor: AppColors.primaryColor,
                        child: CustomText(
                          AppStrings.verificationPending,
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )),
                  ),
                ),
              if (state == RiderVerificationState.rejected && allCompleted)
                Padding(
                  padding: EdgeInsets.only(top: SizeConfig.size10),
                  child: SizedBox(
                    width: Get.width,
                    child: CommonCardWidget(
                        bgColor: AppColors.red00,
                        child: CustomText(
                          textAlign: TextAlign.center,
                          AppStrings.verificationRejected,
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )),
                  ),
                ),
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
                            child: VehicleInformationWidget(
                              screeName: 'from_bottom_view',
                            ),
                          ),
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                        );
                      }, // green tick visible
              ),
              InfoDisplayCard(
                title: AppStrings.aadharNumber,
                value: (riderOnboardingStatusData.aadharNo?.isNotEmpty ?? false)
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
    );
  }
}
