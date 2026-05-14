import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_branch_contact_controller.dart';
import 'package:BlueEra/features/me/others/model/business_profile_full_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalDepartmentOnlyScreen extends StatefulWidget {
  final OtherProfileDepartments? contactInfo;
  final bool? isContactInfoEdit;
  final String? branchId;

  const HospitalDepartmentOnlyScreen({
    super.key,
    this.isContactInfoEdit,
    this.contactInfo,
    this.branchId,
  });

  @override
  State<HospitalDepartmentOnlyScreen> createState() =>
      _HospitalDepartmentOnlyScreenState();
}

class _HospitalDepartmentOnlyScreenState
    extends State<HospitalDepartmentOnlyScreen> {
  final branchController = Get.find<HospitalBranchContactController>();

  final titleController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  bool get _isEdit => widget.isContactInfoEdit ?? false;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      titleController.text = widget.contactInfo?.department ?? "";
      emailController.text = widget.contactInfo?.email ?? "";
      phoneController.text = widget.contactInfo?.phone ?? "";
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _runValidation() {
    branchController.departmentValidateForm(
      departmentRole: titleController.text,
      departmentEmailAddress: emailController.text,
      departmentPhoneNo: phoneController.text,
    );
  }

  Future<void> _handleSubmit() async {
    final body = {
      "department": titleController.text,
      "email": emailController.text,
      "phone": phoneController.text,
    };
    if (_isEdit) {
      // NOTE: branchID/contactID names look swapped here vs. the param
      // semantics — preserved as-is to avoid changing the outbound request.
      await branchController.updateBranchContactDetailsController(
        reqBody: body,
        branchID: widget.contactInfo?.id ?? "",
        contactID: widget.branchId ?? "",
      );
    } else {
      await branchController.addBranchDepartmentController(
        reqBody: body,
        branchID: widget.branchId ?? "",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.department),
      body: CommonCardWidget(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonTextField(
                textEditController: titleController,
                hintText: "E.g.Admission Cell",
                title: AppStrings.department,
                onChange: (_) => _runValidation(),
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: emailController,
                hintText: "dpsdehradun@gmail.com",
                title: AppStrings.enterEmailAddress,
                onChange: (_) => _runValidation(),
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: phoneController,
                hintText: "+91 1234567890",
                title: AppStrings.phoneNumber,
                maxLength: 10,
                onChange: (_) => _runValidation(),
              ),
              const SizedBox(height: 12),
              Obx(() {
                return CustomBtn(
                  isValidate: branchController.isFormValid.value,
                  onTap: _handleSubmit,
                  title: AppStrings.submit,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
