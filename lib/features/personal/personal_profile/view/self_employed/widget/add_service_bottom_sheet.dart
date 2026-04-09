import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AddServiceBottomSheet extends StatefulWidget {
  final Function(List<String>) onUpload;

  const AddServiceBottomSheet({super.key, required this.onUpload});

  @override
  State<AddServiceBottomSheet> createState() => _AddServiceBottomSheetState();
}

class _AddServiceBottomSheetState extends State<AddServiceBottomSheet> {
  late List<TextEditingController> _controllers;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controllers = [TextEditingController()];
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addNewField() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removeField(int index) {
    if (_controllers.length > 1) {
      setState(() {
        // Dispose the specific controller we are removing
        _controllers[index].dispose();
        _controllers.removeAt(index);
      });
    }
  }

  void _handleUpload() {
    if(!_formKey.currentState!.validate()) return;

    final validTexts = _controllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (validTexts.isNotEmpty) {
      widget.onUpload(validTexts);
      Navigator.pop(context);
    }
  }

  String? serviceNameValidation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter service details';
    }

    if (value.trim().length < 3) {
      return "Validation Error, Name must be at least 3 characters";
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate padding for keyboard
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: SizeConfig.size12,
          right: SizeConfig.size12,
          top: SizeConfig.size10,
          bottom: SizeConfig.size40,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Drag Handle ---
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryTextColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // --- Header ---
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      AppStrings.addService,
                      // "Add More Services",
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.large,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              SizedBox(height: SizeConfig.size8),

              // --- Dynamic Fields ---
              ...List.generate(_controllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CommonTextField(
                          textEditController: _controllers[index],
                          hintText: "E.g. Short-circuit & power failure repair....",

                          validator: serviceNameValidation,
                          maxLength: 30,
                        ),
                      ),
                      if (_controllers.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 12),
                          child: InkWell(
                            onTap: () => _removeField(index),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 24),
                          ),
                        ),
                    ],
                  ),
                );
              }),

              // --- Add More Button ---
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _addNewField,
                  icon: Icon(
                      CupertinoIcons.add,
                      color: AppColors.primaryColor,
                      size: 20
                  ),
                  label: CustomText(
                   AppStrings.addMore,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),

              SizedBox(height: SizeConfig.paddingM),

              // --- Upload Button ---
              CustomBtn(
                title:AppStrings.upload,
                onTap: _handleUpload,
                bgColor: AppColors.primaryColor,
                radius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}