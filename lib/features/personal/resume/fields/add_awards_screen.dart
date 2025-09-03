import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/personal/resume/controller/awards_controller.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_document_picker.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/new_common_date_selection_dropdown.dart';

class AddAwardsScreen extends StatefulWidget {
  const AddAwardsScreen({super.key});

  @override
  State<AddAwardsScreen> createState() => _AddAwardsScreenState();
}

class _AddAwardsScreenState extends State<AddAwardsScreen> {
  final AwardsController _controller =
      Get.put(AwardsController()); // Initialize controller
  RxBool validate = false.obs;

  int? _selectedDay;
  int? _selectedMonth;
  int? _selectedYear;
  String? imagePath;

  bool _isValidDate(int? day, int? month, int? year) {
    if (day == null || month == null || year == null) return false;
    try {
      final selectedDate = DateTime(year, month, day);
      return !selectedDate.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (_controller.selectedAward.value != null) {
      _controller.fillFormForEdit(_controller.selectedAward.value!);
      final date = _controller.selectedDate.value;
      if (date != null) {
        _selectedDay = date.day;
        _selectedMonth = date.month;
        _selectedYear = date.year;
      }

      if (_controller.selectedFile != null) {
        imagePath = _controller.selectedFile!.path;
      } else if (_controller.selectedImageUrl != null &&
          _controller.selectedImageUrl!.isNotEmpty) {
        imagePath = _controller.selectedImageUrl;
      } else {
        imagePath = null;
      }
    }

    validateForm();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations.of(context);

    return Scaffold(
      appBar: CommonBackAppBar(
        title: _controller.selectedAward.value != null
            ? "Edit Award"
            : "Add Award",
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(SizeConfig.size15),
            child: Column(
              children: [
                CommonCardWidget(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Organization Name
                      CommonTextField(
                        textEditController: _controller.issuedByController,
                        inputLength: AppConstants.inputCharterLimit100,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        title: "Who Awarded You (Organization Name)",
                        titleColor: AppColors.black1A,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        hintText: "E.g. ABC Wail fare Society",
                        isValidate: true,
                        onChange: (value) => validateForm(),
                      ),

                      SizedBox(height: SizeConfig.size15),

                      /// Award Name
                      CommonTextField(
                        textEditController: _controller.titleController,
                        inputLength: AppConstants.inputCharterLimit100,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        title: "Name of the Award",
                        titleColor: AppColors.black1A,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        hintText: "E.g. Best Employee of Year",
                        isValidate: true,
                        onChange: (value) => validateForm(),
                      ),

                      SizedBox(height: SizeConfig.size15),

                      /// Date
                      CustomText(
                        "Awarded Date",
                        color: AppColors.black1A,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                      ),
                      SizedBox(height: SizeConfig.size10),
                      NewDatePicker(
                        selectedDay: _selectedDay,
                        selectedMonth: _selectedMonth,
                        selectedYear: _selectedYear,
                        onDayChanged: (value) {
                          setState(() {
                            _selectedDay = value;
                            _controller.selectedDate.value =
                                _selectedYear != null &&
                                        _selectedMonth != null &&
                                        _selectedDay != null
                                    ? DateTime(_selectedYear!, _selectedMonth!,
                                        _selectedDay!)
                                    : null;
                          });
                          validateForm();
                        },
                        onMonthChanged: (value) {
                          setState(() {
                            _selectedMonth = value;
                            _controller.selectedDate.value =
                                _selectedYear != null &&
                                        _selectedMonth != null &&
                                        _selectedDay != null
                                    ? DateTime(_selectedYear!, _selectedMonth!,
                                        _selectedDay!)
                                    : null;
                          });
                          validateForm();
                        },
                        onYearChanged: (value) {
                          setState(() {
                            _selectedYear = value;
                            _controller.selectedDate.value =
                                _selectedYear != null &&
                                        _selectedMonth != null &&
                                        _selectedDay != null
                                    ? DateTime(_selectedYear!, _selectedMonth!,
                                        _selectedDay!)
                                    : null;
                          });
                          validateForm();
                        },
                      ),

                      SizedBox(height: SizeConfig.size15),

                      /// Attachment
                      CustomText(
                        "Upload Attachment (Optional)",
                        color: AppColors.black1A,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      CommonDocumentPicker(
                        imagePath: imagePath,
                        onClear: () {
                          _controller.setAttachment(null);
                          setState(() {
                            imagePath = null;
                          });
                          validateForm();
                        },
                        onSelect: (context) async {
                          // final file =
                          //     await SelectProfilePictureDialog.pickFile(
                          //         context);
                          // if (file != null) {
                          //   _controller.setAttachment(file);
                          //   setState(() {
                          //     imagePath = file.path;
                          //   });
                          //   validateForm();
                          // }
                          final selected =
                              await SelectProfilePictureDialog.showLogoDialog(
                            context,
                            AppLocalizations.of(context)!
                                .uploadYourDocumentPhoto,
                          );

                          if (selected?.isNotEmpty ?? false) {
                            _controller.setAttachment(File(selected!));
                            setState(() {
                              imagePath = selected;
                            });
                            validateForm();
                          }
                        },
                      ),

                      SizedBox(height: SizeConfig.size15),

                      /// Description
                      CommonTextField(
                        textEditController: _controller.descriptionController,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        title: "Description",
                        titleColor: AppColors.black1A,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        hintText: "Share Experience....",
                        isValidate: true,
                        maxLine: 4,
                        onChange: (value) => validateForm(),
                      ),

                      SizedBox(height: SizeConfig.size20),

                      /// SAVE BUTTON
                      Obx(() => CustomBtn(
                            onTap: validate.value
                                ? () async {
                                    print("Calling API...");
                                    if (_controller.selectedAward.value !=
                                        null) {
                                      await _controller.updateAwardApi();
                                    } else {
                                      await _controller.addAwardApi();
                                    }
                                    print("API call done");
                                    Get.back();
                                  }
                                : null,
                            title: 'Save',
                            bgColor: validate.value
                                ? AppColors.primaryColor
                                : AppColors.shadowColor,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void validateForm() {
    final isValid = _controller.titleController.text.isNotEmpty &&
        _controller.issuedByController.text.isNotEmpty &&
        _controller.selectedDate.value != null &&
        _isValidDate(_selectedDay, _selectedMonth, _selectedYear) &&
        _controller.descriptionController.text.isNotEmpty;

    validate.value = isValid;
  }
}
