import 'package:BlueEra/core/api/model/school_contact_us_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/features/me/school/controller/branch_contact_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BranchOnlyScreen extends StatefulWidget {
  final SchoolContactUsData schoolContactUsData;

  const BranchOnlyScreen({super.key, required this.schoolContactUsData});

  @override
  _BranchOnlyScreenState createState() => _BranchOnlyScreenState();
}

class _BranchOnlyScreenState extends State<BranchOnlyScreen> {
  final schoolAboutUsController = Get.find<BranchContactController>();

  // Main Branch Controllers
  final branchNameController = TextEditingController();
  final websiteController = TextEditingController();
  final addressController = TextEditingController();

  @override
  void initState() {
    schoolAboutUsController.isFormValid.value = false;
    branchNameController.text = widget.schoolContactUsData.branch?.name ?? "";
    addressController.text =
        widget.schoolContactUsData.branch?.location?.name ?? "";
    websiteController.text = widget.schoolContactUsData.branch?.website ?? "";
    // TODO: implement initState
    branchNameController.addListener(_runValidation);
    websiteController.addListener(_runValidation);
    addressController.addListener(_runValidation);

    super.initState();
  }

// Helper to trigger validation
  void _runValidation() {
    schoolAboutUsController.branchValidateForm(
      branchName: branchNameController.text,
      branchWebsiteUrl: websiteController.text,
      branchLocation: addressController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.branch,
      ),
      body: CommonCardWidget(
        child: SingleChildScrollView(
          // padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TOP BRANCH SECTION ---
              CommonTextField(
                textEditController: branchNameController,
                hintText: "E.g. DPS Dehradun",
                title: AppStrings.branchName,
                maxLength: 50,
                onChange: (_) => _runValidation(),
              ),
              SizedBox(height: 12),
              HttpsTextField(
                controller: websiteController,
                hintText: "https://dpsdehradun.com",
                title: AppStrings.website,
                onChange: (_) => _runValidation(),
              ),
              SizedBox(height: 12),

              CommonLocationSearchField(
                controller: addressController,
                title: AppStrings.location,
                isShowLeading: false,
                hintText: AppStrings.egLucknowGomtiNagar,
                onSelected: (placeId, lat, lng, address) async {
                  addressController.text = address;
                  schoolAboutUsController.selectedLat = lat;
                  schoolAboutUsController.selectedLng = lng;
                  _runValidation();
                },
              ),

              SizedBox(height: 24),

              Obx(() {
                return CustomBtn(
                  onTap: schoolAboutUsController.isFormValid.value
                      ? () async {
                          // updateBranchContactController

                          await schoolAboutUsController
                              .updateBranchContactController(reqBody: {
                            "branch": {
                              "name": branchNameController.text,
                              "website": websiteController.text,
                              "location": {
                                "name": addressController.text,
                                "type": "Point",
                                "coordinates": [
                                  schoolAboutUsController.selectedLat,
                                  schoolAboutUsController.selectedLng
                                ]
                              }
                            }
                          }, branchId: widget.schoolContactUsData.id ?? "");
                        }
                      : null,
                  title: AppStrings.submit,
                  isValidate: schoolAboutUsController.isFormValid.value,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
