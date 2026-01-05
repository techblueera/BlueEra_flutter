import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/faculty_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FacultyFormScreen extends StatefulWidget {
  @override
  _FacultyFormScreenState createState() => _FacultyFormScreenState();
}

class _FacultyFormScreenState extends State<FacultyFormScreen> {
  final controller = Get.put(FacultyController());

  // Controllers for TextFields
  final nameController = TextEditingController();
  final posController = TextEditingController();
  final bioController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final expYearsController = TextEditingController();
  final expDetailsController = TextEditingController();

  // Temporary controller for adding list items
  final addItemController = TextEditingController();

  void _triggerValidation() {
    controller.validateFacultyForm(
      name: nameController.text,
      email: emailController.text,
      phone: phoneController.text,
      posController: posController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: "Add Faculty"),
      body: CommonCardWidget(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Basic Information"),
              CommonTextField(
                textEditController: nameController,
                title: "Full Name",
                hintText: "Dr. John Smith",
                onChange: (_) => _triggerValidation(),
              ),
              SizedBox(height: 12),
              CommonTextField(
                textEditController: posController,
                title: "Position",
                hintText: "Manager",
                onChange: (_) => _triggerValidation(),
              ),
              SizedBox(height: 12),
              CommonTextField(
                textEditController: emailController,
                title: "Email Address",
                hintText: "john.smith@university.edu",
                onChange: (_) => _triggerValidation(),
              ),
              SizedBox(height: 12),
              CommonTextField(
                textEditController: phoneController,
                title: "Phone Number",
                hintText: "+1234567890",
                onChange: (_) => _triggerValidation(),
              ),

              _buildSectionTitle("Qualifications"),
              _buildListInput(
                hint: "Add Qualification (e.g. PhD)",
                onAdd: (val) => controller.addQualification(val),
                items: controller.qualifications,
              ),

              _buildSectionTitle("Experience"),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: CommonTextField(
                      textEditController: expYearsController,
                      title: "Years",
                      hintText: "10",
                      onChange: (_) => _triggerValidation(),

                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: CommonTextField(
                      textEditController: expDetailsController,
                      title: "Experience Details",
                      hintText: "Details about research...",
                      onChange: (_) => _triggerValidation(),

                    ),
                  ),
                ],
              ),

              _buildSectionTitle("Bio"),
              CommonTextField(
                textEditController: bioController,
                title: "Short Bio",
                hintText: "Experienced professor with expertise in AI...",
                maxLength: 200,
                onChange: (_) => _triggerValidation(),

              ),

              SizedBox(height: 30),
              Obx(() => CustomBtn(
                isLoading: controller.isLoading.value,
                onTap: controller.isFormValid.value ? _submit : null,
                title: "Save Faculty Profile",
                isValidate: controller.isFormValid.value ,
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    controller.submitFacultyData(
      name: nameController.text,
      position: posController.text,
      bio: bioController.text,
      email: emailController.text,
      phone: phoneController.text,
      expYears: int.tryParse(expYearsController.text) ?? 0,
      expDetails: expDetailsController.text,
    );
  }

  // --- UI Reusable Parts ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: CustomText(title, fontWeight: FontWeight.bold, fontSize: SizeConfig.large),
    );
  }

  Widget _buildListInput({required String hint, required Function(String) onAdd, required RxList<String> items}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CommonTextField(
                textEditController: addItemController,
                hintText: hint,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: AppColors.primaryColor, size: 30),
              onPressed: () {
                if (addItemController.text.isNotEmpty) {
                  onAdd(addItemController.text);
                  addItemController.clear();
                  _triggerValidation();
                }
              },
            )
          ],
        ),
        Obx(() => Wrap(
          spacing: 8,
          children: items.map((item) => Chip(
            label: Text(item),
            onDeleted: () => items.remove(item),
            deleteIcon: Icon(Icons.close, size: 14),
          )).toList(),
        ))
      ],
    );
  }
}