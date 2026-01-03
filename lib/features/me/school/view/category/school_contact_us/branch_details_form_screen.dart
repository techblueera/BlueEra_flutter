import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BranchDetailsFormScreen extends StatefulWidget {
  @override
  _BranchDetailsFormScreenState createState() => _BranchDetailsFormScreenState();
}

class _BranchDetailsFormScreenState extends State<BranchDetailsFormScreen> {
  final aboutUsController = Get.find<SchoolController>();
  final branchNameController = TextEditingController();
  final websiteController = TextEditingController();
  final addressController = TextEditingController();
  final titleController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    branchNameController.addListener(_runValidation);
    websiteController.addListener(_runValidation);
    addressController.addListener(_runValidation);
    titleController.addListener(_runValidation);
    emailController.addListener(_runValidation);
    phoneController.addListener(_runValidation);
    super.initState();
  }

// Helper to trigger validation
  void _runValidation() {
    aboutUsController.contactUsValidateForm(
      branchName: branchNameController.text,
      branchWebsiteUrl: websiteController.text,
      branchLocation: addressController.text,
      departmentRole: titleController.text,
      departmentEmailAddress: emailController.text,
      departmentPhoneNo: phoneController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Contact Us",
      ),
      body: CommonCardWidget(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CustomText(
                  'Branch',
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
              ),
              SizedBox(height: 15),

              // --- TOP BRANCH SECTION ---
              CommonTextField(
                textEditController: branchNameController,
                hintText: "E.g. DPS Dehradun",
                title: "Branch Name",
                maxLength: 50,
                onChange: (_) => _runValidation(),
              ),
              SizedBox(height: 12),
              HttpsTextField(
                controller: websiteController,
                hintText: "https://dpsdehradun.com",
                title: "Website URL",
                onChange: (_) => _runValidation(),
              ),
              SizedBox(height: 12),
              CommonLocationSearchField(
                controller: addressController,
                title: AppStrings.location,
                isShowLeading: false,
                hintText: AppStrings.egLucknowGomtiNagar,
                onSelected: (placeId, lat, lng, address) async {
                  print("PlaceId: $placeId Selected: $address → ($lat, $lng)");
                  addressController.text = address;
                  _runValidation();
                },
              ),

              SizedBox(height: 24),

              // --- CONTACT CARDS SECTION ---
              Align(
                alignment: Alignment.centerLeft,
                child: CustomText(
                  'Department',
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
              ),
              SizedBox(height: 15),
              CommonTextField(
                textEditController: titleController,
                hintText: "E.g.Admission Cell",
                title: "Department/Role",
                onChange: (_) => _runValidation(),
              ),
              SizedBox(height: 12),
              CommonTextField(
                textEditController: emailController,
                hintText: "dpsdehradun@gmail.com",
                title: "Email Address",
                onChange: (_) => _runValidation(),
              ),
              SizedBox(height: 12),
              CommonTextField(
                textEditController: phoneController,
                hintText: "+91 1234567890",
                title: "Phone Number",
                onChange: (_) => _runValidation(),
              ),              SizedBox(height: 24),

              CustomBtn(onTap: () {}, title: "Submit"),
            ],
          ),
        ),
      ),
    );
  }

}
