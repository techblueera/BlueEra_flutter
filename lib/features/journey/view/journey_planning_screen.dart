import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/core/routes/route_helper.dart'; // Added import for route navigation
import 'package:BlueEra/features/journey/controller/journey_planning_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JourneyPlanningScreen extends StatefulWidget {
  JourneyPlanningScreen({Key? key}) : super(key: key);

  @override
  State<JourneyPlanningScreen> createState() => _JourneyPlanningScreenState();
}

class _JourneyPlanningScreenState extends State<JourneyPlanningScreen> {
  final JourneyPlanningController controller =
      Get.put(JourneyPlanningController());

  @override
  void dispose() {
    // TODO: implement dispose
    Get.delete<JourneyPlanningController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: CommonBackAppBar(
          title: "Start Journey",
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(SizeConfig.size15),
            child: CommonCardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Start From
             
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        RouteHelper.getSearchLocationScreenRoute(),
                        arguments: {
                          'onPlaceSelected':
                              (double? lat, double? lng, String? address) {
                            if (address != null) {
                              controller.startFromController.text = address;
                              controller.setStartLocation(lat, lng, address);
                              controller.validateForm();
                            }
                          },
                          ApiKeys.fromScreen: RouteConstant.journeyPlanningScreen
                        },
                      );
                    },
                    child: CommonTextField(
                      textEditController: controller.startFromController,
                      hintText: "E.g., Rajiv Chowk, Delhi",
                      isValidate: false,
                      title:
                      "Start From",


                      onChange: (value) => controller.validateForm(),
                      readOnly: true,
                      // Make it read-only since we'll use the search screen
                    ),
                  ),
                  SizedBox(height: SizeConfig.size20),

                  // Stoppages
                  Obx(() => Column(
                        children: List.generate(
                          controller.stoppages.length,
                          (stoppageIndex) =>
                              _buildStoppageSection(stoppageIndex, context),
                        ),
                      )),

                  // Add Another Stoppage Button
                  SizedBox(height: SizeConfig.size10),
                  InkWell(
                    onTap: () => controller.addStoppage(),
                    child: Container(
                      width: double.infinity,
                      padding:
                          EdgeInsets.symmetric(vertical: SizeConfig.size12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LocalAssets(
                            imagePath: AppIconAssets.addBlueIcon,
                            imgColor: AppColors.primaryColor,
                          ),
                          SizedBox(width: SizeConfig.size8),
                          CustomText(
                            "Add Another Stoppage",
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.size20),

                  // Transportation Type
                  CustomText(
                    "Start Journey via",
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                  ),
                  SizedBox(height: SizeConfig.size10),
                  _buildTransportationTypeSelector(),
                  SizedBox(height: SizeConfig.size20),

                  // Exact Transportation Information
                  CustomText(
                    "Exact Transportation Information",
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  CommonTextField(
                    textEditController:
                        controller.exactTransportationController,
                    hintText: "E.g., Rajdhani Express",
                    isValidate: false,
                    onChange: (value) => controller.validateForm(),
                  ),
                  SizedBox(height: SizeConfig.size20),

                  // Description
                  CustomText(
                    "Description",
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  CommonTextField(
                    textEditController: controller.descriptionController,
                    hintText: "Type Message...",
                    isValidate: false,
                    maxLine: 4,
                    maxLength: 40,
                    isCounterVisible: false,
                  ),
                  SizedBox(height: SizeConfig.size20),

                  // Submit Button
                  Obx(() => CustomBtn(
                        onTap: controller.isFormValid.value
                            ? () => controller.submitJourneyPlan()
                            : null,
                        title: 'Submit',
                        isValidate: controller.isFormValid.value,
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoppageSection(int stoppageIndex, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          "Stoppage ${stoppageIndex + 1}",
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: SizeConfig.size8),
        InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              RouteHelper.getSearchLocationScreenRoute(),
              arguments: {
                'onPlaceSelected': (double? lat, double? lng, String? address) {
                  if (address != null) {
                    // controller.startFromController.text = address;
                    controller.stoppages[stoppageIndex].city.text = address;
                    controller.stoppages[stoppageIndex].lat.value =
                        lat.toString();
                    controller.stoppages[stoppageIndex].long.value =
                        lng.toString();

                    // controller.stoppages[stoppageIndex].
                    // controller.setStartLocation(lat, lng, address);
                    // controller.validateForm();
                  }
                },
                ApiKeys.fromScreen: RouteConstant.journeyPlanningScreen
              },
            );
          },
          child: CommonTextField(
            textEditController: controller.stoppages[stoppageIndex].city,
            hintText: "E.g., Delhi, Jaipur",
            isValidate: false,
            readOnly: true,
            onChange: (value) => controller.validateForm(),
            sIcon: Icon(Icons.keyboard_arrow_down, color: AppColors.grey9A),
          ),
        ),
        SizedBox(height: SizeConfig.size8),
        Obx(() => Column(
              children: List.generate(
                controller.stoppages[stoppageIndex].attractions.length,
                (attractionIndex) => Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: SizeConfig.size8),
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RouteHelper.getSearchLocationScreenRoute(),
                              arguments: {
                                'onPlaceSelected':
                                    (double? lat, double? lng, String? address) {
                                  if (address != null) {
                                    controller
                                        .stoppages[stoppageIndex]
                                        .attractions[attractionIndex]
                                        .text = address;
                                  }
                                },
                                ApiKeys.fromScreen: RouteConstant.journeyPlanningScreen
                              },
                            );
                          },
                          child: CommonTextField(
                            textEditController: controller
                                .stoppages[stoppageIndex]
                                .attractions[attractionIndex],
                            hintText: "E.g., Qutub Minar, Red Fort",
                            isValidate: false,
                            onChange: (value) => controller.validateForm(),
                          ),
                        ),
                      ),
                    ),
                    if (attractionIndex == controller
                        .stoppages[stoppageIndex]
                        .attractions.length - 1)
                      InkWell(
                        onTap: () => controller.addAttraction(stoppageIndex),
                        child: Container(
                          margin: EdgeInsets.only(left: SizeConfig.size5,bottom: SizeConfig.size5),
                          padding: EdgeInsets.all(SizeConfig.size8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: LocalAssets(
                            imagePath: AppIconAssets.addBlueIcon,
                            imgColor: AppColors.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )),

        SizedBox(height: SizeConfig.size15),
      ],
    );
  }

  Widget _buildTransportationTypeSelector() {
    return Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _transportTypeButton("Car", "Car", AppIconAssets.car),
            _transportTypeButton("Bus", "Bus", AppIconAssets.bus),
            _transportTypeButton("Train", "Train", AppIconAssets.train),
            _transportTypeButton("Plane", "Plane", AppIconAssets.plan),
            _transportTypeButton("Other", "Other", AppIconAssets.other),
          ],
        ));
  }

  Widget _transportTypeButton(String label, String value, String icon) {
    bool isSelected = controller.selectedTransportationType.value == value;

    return InkWell(
      onTap: () => controller.setTransportationType(value),
      child: Container(
        width: SizeConfig.size65,
        padding: EdgeInsets.symmetric(
            vertical: SizeConfig.size15, horizontal: SizeConfig.size10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.greyE5,
            width: 1.5,
          ),
          boxShadow: [AppShadows.textFieldShadow],
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          children: [
            LocalAssets(imagePath: icon),
            SizedBox(height: SizeConfig.size4),
            CustomText(
              label,
              fontSize: SizeConfig.small,
              color: isSelected ? AppColors.primaryColor : AppColors.grey9A,
            ),
          ],
        ),
      ),
    );
  }
}
