import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../widgets/new_common_date_selection_dropdown.dart';
import '../controller/publications_controller.dart';

class AddPublishingScreen extends StatefulWidget {
  final Map<String, dynamic>? publicationData; // For edit mode

  const AddPublishingScreen({
    super.key,
    this.publicationData,
  });

  @override
  State<AddPublishingScreen> createState() => _AddPublishingScreenState();
}

class _AddPublishingScreenState extends State<AddPublishingScreen> {
  final PublicationsController controller = Get.find<PublicationsController>();

  bool _isValidDate(int? day, int? month, int? year) {
    if (day == null || month == null || year == null) return false;
    try {
      return true;
    } catch (e) {
      return false;
    }
  }

  DateTime? _getDate(int? day, int? month, int? year) {
    if (!_isValidDate(day, month, year)) return null;
    return DateTime(year!, month!, day!);
  }

  bool _areDatesValid() {
    final selectedDate = _getDate(_selectedDay, _selectedMonth, _selectedYear);
    if (selectedDate == null) return false;

    // Optionally, check date is not in the future
    final now = DateTime.now();
    if (selectedDate.isAfter(DateTime(now.year, now.month, now.day))) {
      return false;
    }

    return true;
  }

  bool validate = false;
  int? _selectedDay, _selectedMonth, _selectedYear;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.publicationData != null) {
      controller.fillFormForEdit(widget.publicationData!);

      if (controller.dateController.text.isNotEmpty) {
        _selectedDay = int.tryParse(controller.dateController.text);
      }
      if (controller.monthController.text.isNotEmpty) {
        _selectedMonth = int.tryParse(controller.monthController.text);
      }
      if (controller.yearController.text.isNotEmpty) {
        _selectedYear = int.tryParse(controller.yearController.text);
      }
    } else {
      controller.clearForm();
    }

    _validateForm();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations.of(context);

    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.publicationData != null
            ? "Edit Publication"
            : "Add Publication",
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
                      /// Title
                      CommonTextField(
                        textEditController: controller.titleController,
                        inputLength: AppConstants.inputCharterLimit100,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        title: "Title",
                        titleColor: AppColors.black1A,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        hintText: "E.g. paper/Book Publication.....",
                        isValidate: true,
                        onChange: (value) => _validateForm(),
                      ),

                      SizedBox(height: SizeConfig.size15),

                      /// URL
                      CommonTextField(
                        textEditController: controller.linkController,
                        inputLength: AppConstants.inputCharterLimit100,
                        keyBoardType: TextInputType.url,
                        title: "URL",
                        titleColor: AppColors.black1A,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        hintText: "E.g. https://loremipsumdolor.com",
                        isValidate: true,
                        onChange: (value) => _validateForm(),
                      ),

                      SizedBox(height: SizeConfig.size15),

                      /// Date
                      CustomText(
                        "Date",
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
                            controller.dateController.text = value.toString();
                          });
                          _validateForm();
                        },
                        onMonthChanged: (value) {
                          setState(() {
                            _selectedMonth = value;
                            controller.monthController.text = value.toString();
                          });
                          _validateForm();
                        },
                        onYearChanged: (value) {
                          setState(() {
                            _selectedYear = value;
                            controller.yearController.text = value.toString();
                          });
                          _validateForm();
                        },
                      ),

                      SizedBox(height: SizeConfig.size15),

                      /// Description
                      CommonTextField(
                        textEditController: controller.descriptionController,
                        keyBoardType: TextInputType.multiline,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        title: "Description",
                        titleColor: AppColors.black1A,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        hintText: "Type here...",
                        isValidate: true,
                        maxLine: 4,
                        onChange: (value) => _validateForm(),
                      ),

                      SizedBox(height: SizeConfig.size20),

                      /// Save Button
                      Obx(() => CustomBtn(
                            onTap: validate && !controller.isLoading.value
                                ? _handleSave
                                : null,
                            title: controller.isLoading.value
                                ? "Saving..."
                                : (widget.publicationData != null
                                    ? "Update"
                                    : "Save"),
                            isValidate: validate && !controller.isLoading.value,
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

  /// Validate Form
  bool _validateForm() {
    final titleNotEmpty = controller.titleController.text.trim().isNotEmpty;
    final linkNotEmpty = controller.linkController.text.trim().isNotEmpty;
    final descriptionNotEmpty =
        controller.descriptionController.text.trim().isNotEmpty;
    final isDateValid = _areDatesValid();

    final isValid =
        titleNotEmpty && linkNotEmpty && descriptionNotEmpty && isDateValid;

    setState(() {
      validate = isValid;
    });

    return isValid;
  }

  Future<void> _handleSave() async {
    if (!_validateForm()) return;

    if (widget.publicationData != null) {
      await controller.updatePublicationApi();
    } else {
      await controller.addPublicationApi();
    }

    if (!controller.isLoading.value) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
