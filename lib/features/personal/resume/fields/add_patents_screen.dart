import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/personal/resume/controller/add_more_controller.dart';
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

class AddPatentsScreen extends StatefulWidget {
  final bool isEdit;
  final String? experienceId;
  const AddPatentsScreen({Key? key, this.isEdit = false, this.experienceId})
      : super(key: key);

  @override
  State<AddPatentsScreen> createState() => _AddPatentsScreenState();
}

class _AddPatentsScreenState extends State<AddPatentsScreen> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  int? _selectedDay, _selectedMonth, _selectedYear;
  String? imagePath;
  bool validate = false;
  bool isValidDate(int? day, int? month, int? year) {
  if (day == null || month == null || year == null) return false;
  try {
    final date = DateTime(year, month, day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return !date.isAfter(todayOnly);
  } catch (e) {
    return false;
  }
}


  final EntityController patentController =
      Get.find<EntityController>(tag: "patent");

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.experienceId != null) {
      final existing = patentController.entityList
          .firstWhereOrNull((e) => e['_id'] == widget.experienceId);
      if (existing != null) {
        titleCtrl.text = existing['title'] ?? '';
        descCtrl.text = existing['subtitle2'] ?? '';
        final dateString = existing['subtitle1'] ?? '';
        final dateParts = dateString.split('/');
        if (dateParts.length == 3) {
          _selectedDay = int.tryParse(dateParts[0]);
          _selectedMonth = int.tryParse(dateParts[1]);
          _selectedYear = int.tryParse(dateParts[2]);
        }
        final docs = (existing['document'] as List<dynamic>?)?.cast<String>();
        if (docs != null && docs.isNotEmpty) imagePath = docs.first;
      }
    }

    validateForm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CommonBackAppBar(
            title: widget.isEdit ? "Edit Patent" : "Add Patent"),
        body: SingleChildScrollView(
            child: SafeArea(
                child: Padding(
                    padding: EdgeInsets.all(SizeConfig.size15),
                    child: Column(children: [
                      CommonCardWidget(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            CommonTextField(
                              textEditController: titleCtrl,
                              inputLength: AppConstants.inputCharterLimit100,
                              keyBoardType: TextInputType.text,
                              regularExpression:
                                  RegularExpressionUtils.alphabetSpacePattern,
                              title: "Title",
                              titleColor: AppColors.black1A,
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              hintText: "E.g. Lorem Ipsum Dolor",
                              isValidate: true,
                              onChange: (value) => validateForm(),
                            ),
                            SizedBox(height: SizeConfig.size15),
                            CustomText("Patent Issued Date",
                                color: AppColors.black1A,
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400),
                            SizedBox(height: SizeConfig.size10),
                            NewDatePicker(
                                selectedDay: _selectedDay,
                                selectedMonth: _selectedMonth,
                                selectedYear: _selectedYear,
                                onDayChanged: (val) {
                                  setState(() {
                                    _selectedDay = val;
                                  });
                                  validateForm();
                                },
                                onMonthChanged: (val) {
                                  setState(() {
                                    _selectedMonth = val;
                                  });
                                  validateForm();
                                },
                                onYearChanged: (val) {
                                  setState(() {
                                    _selectedYear = val;
                                  });
                                  validateForm();
                                }),
                            SizedBox(height: SizeConfig.size15),
                            CustomText("Upload Patent Certificate",
                                color: AppColors.black1A,
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400),
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
                              textEditController: descCtrl,
                              keyBoardType: TextInputType.text,
                              regularExpression:
                                  RegularExpressionUtils.alphabetSpacePattern,
                              title: "Description",
                              titleColor: AppColors.black1A,
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              hintText: "Describe Your Patent.... ",
                              isValidate: true,
                              maxLine: 4,
                              onChange: (value) => validateForm(),
                            ),
                            SizedBox(height: SizeConfig.size20),
                            CustomBtn(
                              onTap: validate
                                  ? () async {
                                 
                                      final params = {
                                        'title': titleCtrl.text.trim(),
                                        'description': descCtrl.text.trim(),
                                        'issuedDate[date]': _selectedDay,
                                        'issuedDate[month]': _selectedMonth,
                                        'issuedDate[year]': _selectedYear,
                                      };

                                      if (widget.isEdit &&
                                          widget.experienceId != null) {
                                        await patentController.updateEntity(
                                            widget.experienceId!, params,
                                            imagePath: imagePath);
                                      } else {
                                        await patentController.addEntity(params,
                                            imagePath: imagePath);
                                      }
                                      Navigator.pop(context);
                                    }
                                  : null,
                              title: widget.isEdit ? "Update" : "Save",
                              isValidate: validate,
                            )
                          ]))
                    ])))));
  }


  void validateForm() {
  final valid = titleCtrl.text.isNotEmpty &&
      descCtrl.text.isNotEmpty &&
      _selectedDay != null &&
      _selectedMonth != null &&
      _selectedYear != null &&
      isValidDate(_selectedDay, _selectedMonth, _selectedYear) &&
      (imagePath?.isNotEmpty ?? false);

  setState(() {
    validate = valid;
  });
}


  void selectImage(BuildContext context) async {
    final locale = AppLocalizations.of(context);
    imagePath = await SelectProfilePictureDialog.showLogoDialog(
        context, locale!.uploadYourDocumentPhoto);
    if (imagePath?.isNotEmpty ?? false) {
      validateForm();
    }
  }
}
