import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/automotive_service/controller/other_branch_contact_controller.dart';
import 'package:BlueEra/features/me/others/model/business_profile_full_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtherDepartmentOnlyScreen extends StatefulWidget {
  final OtherProfileDepartments? contactInfo;
  final bool? isContactInfoEdit;
  final String? branchId;

  const OtherDepartmentOnlyScreen(
      {super.key, this.isContactInfoEdit, this.contactInfo, this.branchId});

  @override
  _OtherDepartmentOnlyScreenState createState() =>
      _OtherDepartmentOnlyScreenState();
}

class _OtherDepartmentOnlyScreenState extends State<OtherDepartmentOnlyScreen> {
  final schoolAboutUsController = Get.find<AutomotiveBranchContactController>();

  final titleController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState

    if (widget.isContactInfoEdit ?? false) {
      titleController.text = widget.contactInfo?.department ?? "";
      emailController.text = widget.contactInfo?.email ?? "";
      phoneController.text = widget.contactInfo?.phone ?? "";
    }
    super.initState();
  }

// Helper to trigger validation
  void _runValidation() {
    schoolAboutUsController.departmentValidateForm(
      departmentRole: titleController.text,
      departmentEmailAddress: emailController.text,
      departmentPhoneNo: phoneController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.department.tr,
      ),
      body: CommonCardWidget(
        child: SingleChildScrollView(
          // padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonTextField(
                textEditController: titleController,
                hintText: AppStrings.otherHintAdmissionCell.tr,
                title: AppStrings.otherDepartmentRoleTitle.tr,
                onChange: (_) => _runValidation(),
              ),
              SizedBox(height: 12),
              CommonTextField(
                textEditController: emailController,
                hintText: AppStrings.hotelEmailExampleHint.tr,
                title: AppStrings.otherEmailAddressTitle.tr,
                onChange: (_) => _runValidation(),
              ),
              SizedBox(height: 12),
              CommonTextField(
                textEditController: phoneController,
                hintText: AppStrings.hotelPhoneExampleHint.tr,
                title: AppStrings.phoneNumber.tr,
                maxLength: 10,
                onChange: (_) => _runValidation(),
              ),
              SizedBox(height: 12),
              Obx(() {
                return CustomBtn(
                    isValidate: schoolAboutUsController.isFormValid.value,
                    onTap: () async {
                      if (widget.isContactInfoEdit ?? false) {
                        await schoolAboutUsController
                            .updateBranchContactDetailsController(
                                reqBody: {
                              "department": titleController.text,
                              "email": emailController.text,
                              "phone": phoneController.text,
                            },
                                branchID: widget.contactInfo?.id ?? "",
                                contactID: widget.branchId ?? "");
                      } else {
                        await schoolAboutUsController
                            .addBranchDepartmentController(reqBody: {
                          "department": titleController.text,
                          "email": emailController.text,
                          "phone": phoneController.text,
                        }, branchID: widget.branchId ?? "");
                        // addBranchDepartmentController
                      }
                    },
                    title: AppStrings.submit.tr);
              }),
            ],
          ),
        ),
      ),
    );
  }
}
