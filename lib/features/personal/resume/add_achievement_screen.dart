import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_document_picker.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../widgets/new_common_date_selection_dropdown.dart';
import '../../../core/constants/snackbar_helper.dart';
import 'controller/achievements_controller.dart';

class AddAchievementScreen extends StatefulWidget {
  final String? achievementId;
  final bool isEdit;
  const AddAchievementScreen({
    super.key,
    this.achievementId,
    this.isEdit = false,
  });

  @override
  State<AddAchievementScreen> createState() => _AddAchievementScreenState();
}

class _AddAchievementScreenState extends State<AddAchievementScreen> {
  TextEditingController achievementCtrl = TextEditingController();
  TextEditingController courseCtrl = TextEditingController();
  TextEditingController achievementDetailsCtrl = TextEditingController();

  final AchievementsController _controller = Get.find<AchievementsController>();

  int? _selectedDay, _selectedMonth, _selectedYear;
  String? imagePath;
  bool validate = false;
  bool isLoading = false;

  bool _isValidDate(int? day, int? month, int? year) {
    if (day == null || month == null || year == null) return false;
    try {
      final selectedDate = DateTime(year, month, day);
      final today = DateTime.now();
      // For basic validation: date cannot be in the future
      return !selectedDate.isAfter(today);
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.isEdit && widget.achievementId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // await _controller.getAchievementById(widget.achievementId!);

        achievementCtrl.text = _controller.titleController.text;
        achievementDetailsCtrl.text = _controller.descriptionController.text;
        courseCtrl.text = _controller.courseController.text;

        final selectedDate = _controller.selectedDate.value;
        if (selectedDate != null) {
          setState(() {
            _selectedDay = selectedDate.day;
            _selectedMonth = selectedDate.month;
            _selectedYear = selectedDate.year;
          });
        }

        setState(() {
          if (_controller.selectedFile != null) {
            imagePath = _controller.selectedFile!.path;
          } else if (_controller.selectedImageUrl != null &&
              _controller.selectedImageUrl!.isNotEmpty) {
            imagePath = _controller.selectedImageUrl;
          } else {
            imagePath = null;
          }
        });

        validateForm();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.isEdit ? "Edit Achievement" : "Add Achievement",
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
                      CommonTextField(
                        textEditController: achievementCtrl,
                        inputLength: AppConstants.inputCharterLimit100,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        title: "Title",
                        titleColor: AppColors.black1A,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        hintText: "Eg., Employee of the month",
                        isValidate: true,
                        onChange: (value) => validateForm(),
                      ),
                      SizedBox(height: SizeConfig.size15),
                      CustomText(
                        "Date Awarded",
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
                          });
                          validateForm();
                        },
                        onMonthChanged: (value) {
                          setState(() {
                            _selectedMonth = value;
                          });
                          validateForm();
                        },
                        onYearChanged: (value) {
                          setState(() {
                            _selectedYear = value;
                          });
                          validateForm();
                        },
                      ),
                      SizedBox(height: SizeConfig.size15),
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
                          setState(() {
                            imagePath = null;
                          });
                          validateForm();
                        },
                        onSelect: (context) {
                          selectImage(context);
                        },
                      ),
                      SizedBox(height: SizeConfig.size15),
                      CommonTextField(
                        textEditController: achievementDetailsCtrl,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        title: "Description",
                        titleColor: AppColors.black1A,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        hintText: "Share experience...",
                        isValidate: true,
                        maxLine: 4,
                        onChange: (value) => validateForm(),
                      ),
                      SizedBox(height: SizeConfig.size20),
                      CustomBtn(
                        title: isLoading
                            ? (widget.isEdit ? "Updating..." : "Saving...")
                            : (widget.isEdit ? "Update" : "Save"),
                        isValidate: validate && !isLoading,
                        onTap: validate && !isLoading
                            ? () async {
                                setState(() {
                                  isLoading = true;
                                });

                                // Assign UI inputs to controller fields correctly
                                _controller.titleController.text =
                                    achievementCtrl.text.trim();
                                _controller.descriptionController.text =
                                    achievementDetailsCtrl.text.trim();
                                _controller.courseController.text =
                                    courseCtrl.text.trim();

                                // Assign selected date if available
                                if (_selectedYear != null &&
                                    _selectedMonth != null &&
                                    _selectedDay != null) {
                                  _controller.selectedDate.value = DateTime(
                                    _selectedYear!,
                                    _selectedMonth!,
                                    _selectedDay!,
                                  );
                                }

                                // Handle image - distinguish between local file path and remote URL
                                if (imagePath != null &&
                                    imagePath!.isNotEmpty) {
                                  if (imagePath!.startsWith('http://') ||
                                      imagePath!.startsWith('https://')) {
                                    _controller.selectedFile = null;
                                    _controller.selectedImageUrl = imagePath;
                                  } else {
                                    _controller.selectedFile = File(imagePath!);
                                    _controller.selectedImageUrl = null;
                                  }
                                } else {
                                  _controller.selectedFile = null;
                                  _controller.selectedImageUrl = null;
                                }

                                try {
                                  if (widget.isEdit &&
                                      widget.achievementId != null) {
                                    await _controller.updateAchievement(
                                        widget.achievementId!);
                                    commonSnackBar(
                                        message:
                                            "Achievement updated successfully!");
                                  } else {
                                    final res =
                                        await _controller.addAchievement();
                                    if (res.isSuccess) {
                                      commonSnackBar(
                                          message:
                                              "Achievement added successfully!");
                                    } else {
                                      commonSnackBar(
                                          message: res.message ??
                                              "Failed to add achievement");
                                      return;
                                    }
                                  }
                                  _controller.clearForm();
                                  Navigator.pop(context);
                                } catch (e) {
                                  commonSnackBar(
                                      message:
                                          "An error occurred. Please try again.");
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void validateForm() {
    final isTitleFilled = achievementCtrl.text.trim().isNotEmpty;
    final isDescriptionFilled = achievementDetailsCtrl.text.trim().isNotEmpty;
    final isDateSelected =
        _selectedDay != null && _selectedMonth != null && _selectedYear != null;
    final isDateValid =
        _isValidDate(_selectedDay, _selectedMonth, _selectedYear);
    validate =
        isTitleFilled && isDescriptionFilled && isDateSelected && isDateValid;

    setState(() {});
  }

  selectImage(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context);
    final selected = await SelectProfilePictureDialog.showLogoDialog(
      context,
      appLocalizations!.uploadYourDocumentPhoto,
    );
    if (selected?.isNotEmpty ?? false) {
      setState(() {
        imagePath = selected;
      });
      validateForm();
    }
  }

  @override
  void dispose() {
    achievementCtrl.dispose();
    courseCtrl.dispose();
    achievementDetailsCtrl.dispose();
    super.dispose();
  }
}
