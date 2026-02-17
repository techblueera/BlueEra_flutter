import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AIHospitalProfileDialog extends StatefulWidget {
  AIHospitalProfileDialog({super.key});

  @override
  State<AIHospitalProfileDialog> createState() => _AIHospitalProfileDialogState();
}

class _AIHospitalProfileDialogState extends State<AIHospitalProfileDialog> {
  final controller = Get.find<HospitalServiceAiController>();

  @override
  Widget build(BuildContext context) {
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
              CustomText("Create Your Hospital Profile Via AI",
                  fontSize: SizeConfig.size20, fontWeight: FontWeight.bold),

              SizedBox(height: SizeConfig.size20),
              CommonLocationSearchField(
                controller: controller.searchController,
                hintText: "E.g. Veer Hospital...",
                isShowLeading: false,
                title: "Search Your Profile On Google",
                onSelected: (placeId, lat, lng, address) async {
                  controller.searchController.text = address;

                  try {
                    final detailsResponse = await PlaceRepo()
                        .getCompletePlaceDetails(placeId: placeId);
                    final detailsData = detailsResponse.response?.data;
                    final placeDetails =
                        PlaceDetailsResponse.fromJson(detailsData);
                    // controller.lat.value=placeDetails.result?.geometry?.location?.lat??0.0;
                    // controller.lng.value=placeDetails.result?.geometry?.location?.lng??0.0;
                    logs(
                        "placeDetails.result?.website ${placeDetails.result?.website}");
                    controller.websiteController.text =
                        placeDetails.result?.website ?? "";
                  } catch (e) {
                    print("Error fetching place details: $e");
                  }

                  validateAiSchoolForm();
                  setstate(() {});
                },
              ),

              SizedBox(height: SizeConfig.size20),
              HttpsTextField(
                title: "Hospital Website",
                controller: controller.websiteController,
                hintText: "E.g. https://veeraboratory.com",
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
                          ? controller.aiHospitalFetchDetailsController
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
    isFormValid = controller.searchController.text.trim().isNotEmpty;
  }
}
