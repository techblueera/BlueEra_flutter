import 'package:BlueEra/core/api/model/school_contact_us_model.dart';
import 'package:BlueEra/core/api/model/school_contact_us_new_res_model.dart';
import 'package:BlueEra/features/me/school/controller/branch_contact_controller.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/api/model/school_contact_us_res_model.dart';

class DepartmentOnlyScreen extends StatefulWidget {
  final Departments? contactInfo;
  final bool? isContactInfoEdit;
  final String? branchId;

  const DepartmentOnlyScreen(
      {super.key, this.isContactInfoEdit, this.contactInfo, this.branchId});

  @override
  _DepartmentOnlyScreenState createState() => _DepartmentOnlyScreenState();
}

class _DepartmentOnlyScreenState extends State<DepartmentOnlyScreen> {
  final schoolAboutUsController = Get.find<BranchContactController>();

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
        title: "Department",
      ),
      body: CommonCardWidget(
        child: SingleChildScrollView(
          // padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      }
                      else{
                        await schoolAboutUsController
                            .addBranchDepartmentController(
                            reqBody: {
                              "department": titleController.text,
                              "email": emailController.text,
                              "phone": phoneController.text,
                            },
                            branchID:
                            widget.branchId ?? "");
                        // addBranchDepartmentController
                      }
                    },
                    title: "Submit");
              }),
            ],
          ),
        ),
      ),
    );
  }
}
