import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/getx_utils.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import '../../../controller/help_and_support_controller.dart';

class CreateSupportQueryPage extends StatefulWidget {
  const CreateSupportQueryPage({super.key});

  @override
  State<CreateSupportQueryPage> createState() =>
      _CreateSupportQueryPageState();
}

class _CreateSupportQueryPageState extends State<CreateSupportQueryPage> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final controller = getOrPut(() => HelpAndSupportController());
  String? priority; // 🔑 nullable for validation

  bool isValidate = false;

  /// ---------------- IMAGE PICK ----------------
  Future<void> pickImage() async {
    if (controller.pickedQueriesImages.length >= 3) {
      Get.snackbar('Limit reached', 'You can upload max 3 images');
      return;
    }

    final String? image =
    await PhotoPickerService.pickSinglePhoto(
        context, "Choose Image");

    if (image != null) {
      setState(() {
        controller.pickedQueriesImages.add(image);
      });
    }
  }

  void removeImage(int index) {
    setState(() {
      controller.pickedQueriesImages.removeAt(index);
    });
  }

  /// ---------------- VALIDATION ----------------
  bool validateForm() {
    if (_subjectController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Subject is required');
      return false;
    }

    if (_messageController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Message is required');
      return false;
    }

    if (priority == null) {
      Get.snackbar('Error', 'Please choose priority');
      return false;
    }

    return true;
  }

  /// ---------------- SUBMIT ----------------
  void onSubmit() {
    if (!validateForm()) return;

    setState(() {
      isValidate = true;
    });

    final payload = {
      ApiKeys.type: "query",
       ApiKeys.subject: _subjectController.text.trim(),
       ApiKeys.message: _messageController.text.trim(),
       ApiKeys.priority: priority,

    };
    controller.addQuery(payload);


    // 👉 call controller.addQuery(payload) later
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Create Support Query",
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.white),
          margin: const EdgeInsets.all(10),
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              CommonTextField(
                textEditController: _subjectController,
                hintText: 'Enter subject',
                title: "Subject",
              ),
              const SizedBox(height: 16),

              CommonTextField(
                textEditController: _messageController,
                hintText: 'Describe your issue',
                title: "Message",
              ),
              const SizedBox(height: 16),

              /// Priority
              const CustomText('Priority'),
              const SizedBox(height: 6),
              CommonDropdown(
                items: const ["Low", "Medium", "High"],
                selectedValue: priority,
                hintText: "Choose Priority",
                onChanged: (value) {
                  setState(() {
                    priority = value?.toLowerCase();
                  });
                },
                displayValue: (value) => value,
              ),

              const SizedBox(height: 16),

              /// Attachments
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CustomText(
                    'Attachments (max 3)',
                    fontWeight: FontWeight.w600,
                  ),
                  IconButton(
                    onPressed: pickImage,
                    icon: const Icon(Icons.add_photo_alternate),
                  )
                ],
              ),

              const SizedBox(height: 10),

              /// Image Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.pickedQueriesImages.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(controller.pickedQueriesImages[index]),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => removeImage(index),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              /// Submit Button
              CustomBtn(
                isLoading: controller.isLoading.value,
                isValidate: true,
                onTap: onSubmit,
                title: "Submit",
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}