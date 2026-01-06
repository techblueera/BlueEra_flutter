import 'dart:io';
import 'package:BlueEra/core/api/model/get_faculty_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/school/controller/faculty_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class FacultyFormScreen extends StatefulWidget {
  final bool isEdit;
  final FacultyData? facultyData;

  const FacultyFormScreen({super.key, this.isEdit = false, this.facultyData});

  @override
  _FacultyFormScreenState createState() => _FacultyFormScreenState();
}

class _FacultyFormScreenState extends State<FacultyFormScreen> {
  final controller = Get.find<FacultyController>();

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
      profile: controller.facultyProfile.value,
    );
  }

  @override
  void initState() {
    super.initState();
    controller.facultyProfile.value = "";
    controller.facultyProfileImageFile.value = null;
    controller.qualifications.clear();
    // If editing, populate the controllers with existing data
    if (widget.isEdit && widget.facultyData != null) {
      final data = widget.facultyData!;

      nameController.text = data.name ?? "";
      posController.text = data.position ?? "";
      emailController.text = data.email ?? "";
      phoneController.text = data.phone ?? "";
      bioController.text = data.bio ?? "";
      expYearsController.text = data.experience?.years.toString() ?? "";
      expDetailsController.text = data.experience?.details ?? "";

      // Set existing qualifications in GetX controller
      controller.qualifications.assignAll(data.qualifications ?? []);

      // Set the existing photo URL (for validation purposes)
      controller.facultyProfile.value = data.photo ?? "";

      // Set bio length counter
      controller.faculty_short_bio_text.value = data.bio ?? "";
    }

    // Run validation once to set initial button state
    _triggerValidation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: "Add Faculty"),
      body: SafeArea(
        child: CommonCardWidget(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Basic Information"),
                Center(child: _buildImageSection()),
                SizedBox(height: 12),

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
                  hintText: "+9834567890",
                  onChange: (_) => _triggerValidation(),
                  keyBoardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                SizedBox(height: 12),

                _buildSectionTitle("Qualifications"),
                _buildListInput(
                  hint: "Add Qualification (e.g. PhD)",
                  onAdd: (val) => controller.addQualification(val),
                  items: controller.qualifications,
                ),
                SizedBox(height: 12),

                _buildSectionTitle("Experience"),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: CommonTextField(
                        textEditController: expYearsController,
                        title: "Years",
                        hintText: "10",keyBoardType: TextInputType.number,
                        onChange: (_) => _triggerValidation(),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
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
                SizedBox(height: 12),

                _buildSectionTitle("Bio"),

                /// Apply Button
                CommonTextField(
                  textEditController: bioController,
                  title: "Short Bio",
                  hintText: "Experienced professor with expertise in AI...",
                  maxLine: 5,
                  maxLength: 500,
                  isValidate: false,
                  keyBoardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChange: (value) {
                    String newVal = value.replaceAll(RegExp(r'\n{3,}'), '\n\n');
                    controller.faculty_short_bio_text.value = newVal;
                    _triggerValidation();
                  },
                ),
                SizedBox(height: SizeConfig.size10),

                Align(
                  alignment: Alignment.centerRight,
                  child: Obx(() => CustomText(
                        "${controller.faculty_short_bio_text.value.length}/500",
                        color: Colors.grey,
                        fontSize: 12,
                      )),
                ),
                SizedBox(height: SizeConfig.size30),

                Obx(() => CustomBtn(
                      isLoading: controller.isLoading.value,
                      onTap: controller.isFormValid.value ? _submit : null,
                      title: "Submit Faculty Profile",
                      isValidate: controller.isFormValid.value,
                    )),
                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    logs("widget.facultyData?.photo === ${widget.facultyData?.photo}");
    // If user picked a NEW local file
    if (controller.facultyProfileImageFile.value != null) {
      return CommonProfileImageUpload(
        imageFile: controller.facultyProfileImageFile,
        imgUrl: widget.facultyData?.photo ?? "",
        onImageRemove: () {
          controller.facultyProfileImageFile.value = null;
          controller.facultyProfile.value = "";

          _triggerValidation();
        },
        title: '',
        context: context,
      );
    }

    // If no local file but we have a NETWORK image from API
    // Default: Show Upload Placeholder
    return CommonProfileImageUpload(
      title: "Upload Photo",
      context: context,
      imgUrl: widget.facultyData?.photo ?? "",
      onImageSelected: () async {
        final path = await CommonProfileImageUpload.pickImage(context: context);
        if (path != null) {
          controller.facultyProfile.value = path;
          controller.isImageUpdated.value = true;
          controller.facultyProfileImageFile.value = File(path);
          _triggerValidation();
        }
      },
      imageFile: controller.facultyProfileImageFile,
    );
  }

  void _submit() {
    if (widget.isEdit) {
      controller.submitFacultyData(
          name: nameController.text,
          position: posController.text,
          bio: bioController.text,
          email: emailController.text,
          phone: phoneController.text,
          expYears: int.tryParse(expYearsController.text) ?? 0,
          expDetails: expDetailsController.text,
          isEdit: true,
          docId: widget.facultyData?.id,
          isImageEdit: controller.isImageUpdated.value);
    } else {
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
  }

  // --- UI Reusable Parts ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 10),
      child: CustomText(title,
          fontWeight: FontWeight.bold, fontSize: SizeConfig.large),
    );
  }

  Widget _buildListInput(
      {required String hint,
      required Function(String) onAdd,
      required RxList<String> items}) {
    return Column(
      children: [
        CommonTextField(
          textEditController: addItemController,
          hintText: hint,
          isValidate: false,
        ),
        SizedBox(height: SizeConfig.size10,),
        Align(
          alignment: Alignment.centerRight,
          child: InkWell(
              onTap: () {
                if (addItemController.text.isNotEmpty) {
                  onAdd(addItemController.text);
                  addItemController.clear();
                  _triggerValidation();
                }
              },
              child: CustomText(
                "Add More",
                color: AppColors.primaryColor,
                decorationColor: AppColors.primaryColor,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.bold,
              )),
        ),
        Obx(() => Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
                spacing: 8,
                alignment: WrapAlignment.start,
                children: items
                    .map((item) => Chip(
                          label: CustomText(item),
                          onDeleted: () => items.remove(item),
                          deleteIcon: Icon(Icons.close, size: 14),
                        ))
                    .toList(),
              ),
        ))
      ],
    );
  }
}
