import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/journey/controller/journey_update_planning_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/common_edit_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class UpdateJourneyScreen extends StatefulWidget {
  const UpdateJourneyScreen({super.key, required this.journeyId});

  final String journeyId;

  @override
  State<UpdateJourneyScreen> createState() => _UpdateJourneyScreenState();
}

class _UpdateJourneyScreenState extends State<UpdateJourneyScreen> {
  final JourneyUpdatePlanningController controller =
      Get.put(JourneyUpdatePlanningController());

  void clearAllSocialLinks() {
    for (var field in controller.travelSocialLink) {
      field.linkController.clear();
    }
  }

  @override
  void initState() {
    // controller.addStoppage();
    // controller.addStoppage();
    // TODO: implement initState
    clearAllSocialLinks();

    getJourneyDetails();
    super.initState();
  }

  getJourneyDetails() async {
    await controller.getJourneyDetails(journeyId: widget.journeyId);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    Get.delete<JourneyUpdatePlanningController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: CommonBackAppBar(
          title: "Start Journey",
          isEndJourney: true,
          onEndJourneyTap: () {
            commonConformationDialog(
                context: context,
                text: "Are you sure you want to end your journey?",
                confirmCallback: () async {
                  controller.endTravelController(journeyId: widget.journeyId);
                },
                cancelCallback: () {
                  Navigator.of(context).pop(); // Close the dialog
                });
          },
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(SizeConfig.size15),
            child: CommonCardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stoppages
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        "Choose Stoppage",
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w500,
                      ),
                      CommonEditWidget(
                        voidCallback: () {
                          // Edit functionality for stoppages
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size8),

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

                  // Add Media (Photo Upload)
                  CustomText(
                    "Add Media",
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  _buildPhotoUploadSection(),
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

                  // Stay Information
                  CustomText(
                    "Stay Information",
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  CommonTextField(
                    textEditController: controller.stayInfoController,
                    hintText: "Type Message...",
                    isValidate: false,
                    maxLine: 3,
                  ),
                  SizedBox(height: SizeConfig.size20),

                  // Food Information
                  CustomText(
                    "Food Information",
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  CommonTextField(
                    textEditController: controller.foodInfoController,
                    hintText: "Write here...",
                    isValidate: false,
                    maxLine: 3,
                  ),
                  SizedBox(height: SizeConfig.size20),

                  // Add Other Information Button
                  InkWell(
                    onTap: () {
                      // Add other information functionality
                    },
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
                            "Add Other Information",
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.size20),

                  _buildSocialMediaLinks(),
                  SizedBox(height: SizeConfig.size20),
                  // Submit Button
                  Obx(() => CustomBtn(
                        onTap: controller.isFormValid.value
                            ? () => controller.submitJourneyPlan(
                                journeyId: widget.journeyId)
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

// Photo upload section widget
  Widget _buildPhotoUploadSection() {
    return Column(
      children: [
        // Photo grid view
        Obx(
          () => controller.selectedPhotos.isEmpty
              ? InkWell(
                  onTap: () => controller.addPhotos(),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LocalAssets(
                          imagePath: AppIconAssets.uploadIcon,
                          height: 40,
                          width: 40,
                        ),
                        SizedBox(height: SizeConfig.size8),
                        CustomText(
                          "Upload Media",
                          fontSize: SizeConfig.medium,
                          color: AppColors.grey9A,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: controller.selectedPhotos.length + 1,
                      // +1 for add button
                      itemBuilder: (context, index) {
                        if (index == controller.selectedPhotos.length) {
                          // Add more photos button
                          return InkWell(
                            onTap: () => controller.addPhotos(),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.add,
                                  color: AppColors.primaryColor,
                                  size: 30,
                                ),
                              ),
                            ),
                          );
                        }

                        // Photo preview with delete option
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: FileImage(
                                      File(controller.selectedPhotos[index])),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: InkWell(
                                onTap: () => controller.removePhoto(index),
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
        ),
      ],
    );
  }

// Social media links section
  Widget _buildSocialMediaLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Links Section
        CustomText(
          "Add Links",
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: SizeConfig.size10),
        ...controller.travelSocialLink.map(
          (field) => Padding(
            padding: EdgeInsets.only(bottom: SizeConfig.size14),
            child: HttpsTextField(
              controller: field.linkController,
              pIcon: Container(
                width: 40,
                child: Center(
                  child: SvgPicture.asset(
                    field.icon,
                    height: SizeConfig.size24,
                    width: SizeConfig.size24,
                    fit: BoxFit.fitHeight,
                  ),
                ),
              ),
              hintText: "Your ${field.name} URL here",
              isUrlValidate: false,
            ),
          ),
        ),
      ],
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
                ApiKeys.fromScreen: RouteConstant.UpdateJourneyScreen
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
                                'onPlaceSelected': (double? lat, double? lng,
                                    String? address) {
                                  if (address != null) {
                                    controller
                                        .stoppages[stoppageIndex]
                                        .attractions[attractionIndex]
                                        .text = address;
                                  }
                                },
                                ApiKeys.fromScreen: RouteConstant.UpdateJourneyScreen
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
                    if (attractionIndex ==
                        controller.stoppages[stoppageIndex].attractions.length -
                            1)
                      InkWell(
                        onTap: () => controller.addAttraction(stoppageIndex),
                        child: Container(
                          margin: EdgeInsets.only(
                              left: SizeConfig.size5, bottom: SizeConfig.size5),
                          padding: EdgeInsets.all(SizeConfig.size8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
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
