import 'package:BlueEra/features/me/school/controller/about_us_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DepartmentOnlyScreen extends StatefulWidget {
  @override
  _DepartmentOnlyScreenState createState() => _DepartmentOnlyScreenState();
}

class _DepartmentOnlyScreenState extends State<DepartmentOnlyScreen> {
  final aboutUsController = Get.find<AboutUsController>();

  final titleController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState

    titleController.addListener(_runValidation);
    emailController.addListener(_runValidation);
    phoneController.addListener(_runValidation);
    super.initState();
  }

// Helper to trigger validation
  void _runValidation() {
    aboutUsController.departmentValidateForm(
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
                onChange: (_) => _runValidation(),
              ),
              CustomBtn(onTap: () {}, title: "Submit"),
            ],
          ),
        ),
      ),
    );
  }
}
