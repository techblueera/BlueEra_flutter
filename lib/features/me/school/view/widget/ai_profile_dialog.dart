
import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AIProfileDialog extends StatefulWidget {
  AIProfileDialog({super.key});

  @override
  State<AIProfileDialog> createState() => _AIProfileDialogState();
}

class _AIProfileDialogState extends State<AIProfileDialog> {
  final controller = Get.find<SchoolController>();

  @override
  Widget build(BuildContext context) {
    // Inject the controller
    return StatefulBuilder(builder: (context, setstate) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.extraLarge22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText("Create Your Profile Via AI",
                  fontSize: SizeConfig.size20, fontWeight: FontWeight.bold),

              SizedBox(height: SizeConfig.size20),
              CommonLocationSearchField(
                controller: controller.searchController,
                hintText: "E.g. Bharati Public School...",
                isShowLeading: false,
                title: "Search Your Profile On Google",
                onSelected: (placeId, lat, lng, address) async {

                  controller.searchController.text = address;

                  // Fetch and auto-fill details
                  try {
                    final detailsResponse = await PlaceRepo().getCompletePlaceDetails(placeId: placeId);
                    final detailsData = detailsResponse.response?.data;
                    final placeDetails = PlaceDetailsResponse.fromJson(detailsData);
                    controller.lat.value=placeDetails.result?.geometry?.location?.lat??0.0;
                    controller.lng.value=placeDetails.result?.geometry?.location?.lng??0.0;
                    controller.websiteController.text=placeDetails.result?.website??"";
                  } catch (e) {
                    print("Error fetching place details: $e");
                  }
                  validateAiSchoolForm();

                  setstate(() {});
                },
              ),

              SizedBox(height: SizeConfig.size20),
              HttpsTextField(
                title: "Organization Website or Social Media link",
                controller: controller.websiteController,
                hintText: "E.g. https://bhartipublic.com",
                // onChange: (_) {
                //   // validateAiSchoolForm();
                //   // setstate(() {});
                // },
              ),

              SizedBox(height: SizeConfig.size30),
              // Buttons Row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomBtn(
                      title: AppStrings.generate,
                      isValidate: isFormValid,
                      onTap: isFormValid
                          ? controller.aiInstitutionFetchDetailsController
                          : null,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    flex: 1,
                    child: CustomBtn(
                      onTap: () {
                        Get.back();
                      },
                      title: AppStrings.skip,
                      bgColor: AppColors.greyLite,
                      textColor: AppColors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  bool isFormValid = false;

  void validateAiSchoolForm() {
    // Check if all fields are not empty
    isFormValid = controller.searchController.text.trim().isNotEmpty ;

  }
}
