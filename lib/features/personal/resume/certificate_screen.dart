import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_document_picker.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../widgets/new_common_date_selection_dropdown.dart';
import 'controller/certifications_controller.dart';
import 'model/certification_model.dart';

class CertificateScreen extends StatefulWidget {
  final bool isEdit;
  final String? certificationId;
  final Certification? existingData;

  const CertificateScreen({
    super.key,
    this.isEdit = false,
    this.certificationId,
    this.existingData,
  });

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final _formKey = GlobalKey<FormState>();

  String? imagePath;

  // bool validate = false;
  final RxBool validate = false.obs;

  int? _selectedDay, _selectedMonth, _selectedYear;
  final CertificationsController certificationsController =
      Get.find<CertificationsController>();

  bool isValidDate(int? day, int? month, int? year) {
    if (day == null || month == null || year == null) return false;
    try {
      final date = DateTime(year, month, day);
      final today = DateTime.now();
      if (date.isAfter(DateTime(today.year, today.month, today.day)))
        return false;
      return date.year == year && date.month == month && date.day == day;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.certificationId != null) {
      setState(() {
        _selectedDay = certificationsController.selectedDay;
        _selectedMonth = certificationsController.selectedMonth;
        _selectedYear = certificationsController.selectedYear;
        imagePath = certificationsController.selectedAttachment.value?.path;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => validateForm());
    } else {
      certificationsController.clearForm();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CommonBackAppBar(
        title: widget.isEdit
            ? AppStrings.editCertification
            : AppStrings.addCertification,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size15),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: CommonCardWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ///Course Name....
                    CommonTextField(
                      textEditController:
                          certificationsController.titleController,
                      inputLength: AppConstants.inputCharterLimit50,
                      keyBoardType: TextInputType.text,
                      regularExpression:
                          RegularExpressionUtils.alphabetSpacePattern,
                      title: AppStrings.certificateName,
                      titleColor: AppColors.black1A,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      hintText: AppStrings.certificateNameHint,
                      isValidate: true,
                      onChange: (value) => validateForm(),
                    ),

                    SizedBox(
                      height: SizeConfig.size15,
                    ),

                    CommonTextField(
                      textEditController:
                          certificationsController.issuingOrgController,
                      inputLength: AppConstants.inputCharterLimit50,
                      keyBoardType: TextInputType.text,
                      regularExpression:
                          RegularExpressionUtils.alphabetSpacePattern,
                      title: AppStrings.certificateIssuedBy,
                      titleColor: AppColors.black1A,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      hintText: AppStrings.certificateIssuedByHint,
                      isValidate: true,
                      onChange: (value) => validateForm(),
                    ),

                    SizedBox(
                      height: SizeConfig.size15,
                    ),

                    ///START DATE...
                    CustomText(
                      AppStrings.certifiedDate,
                      color: AppColors.black1A,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                    ),
                    SizedBox(
                      height: SizeConfig.size10,
                    ),
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

                    SizedBox(
                      height: SizeConfig.size15,
                    ),

                    /// Certifications photo...
                    CustomText(
                      AppStrings.certifications,
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
                        certificationsController.setAttachment(null);
                        validateForm();
                      },
                      onSelect: (context) {
                        selectImage(context);
                      },
                    ),

                    SizedBox(
                      height: SizeConfig.size20,
                    ),

                    /// Save button
                    Obx(() => CustomBtn(
                          onTap: validate.value &&
                                  !certificationsController.isLoading.value
                              ? () async {
                                  final Map<String, dynamic> inputParams = {
                                    'title': certificationsController
                                        .titleController.text
                                        .trim(),
                                    'issuingOrg': certificationsController
                                        .issuingOrgController.text
                                        .trim(),
                                    'certificateDate[date]':
                                        _selectedDay.toString(),
                                    'certificateDate[month]':
                                        _selectedMonth.toString(),
                                    'certificateDate[year]':
                                        _selectedYear.toString(),
                                  };

                                  if (widget.isEdit &&
                                      widget.certificationId != null) {
                                    await certificationsController
                                        .updateCertification(
                                      widget.certificationId!,
                                      inputParams,
                                      photoPath: imagePath,
                                    );
                                  } else {
                                    await certificationsController
                                        .addCertification(
                                      inputParams,
                                      photoPath: imagePath,
                                    );
                                  }

                                  if (!certificationsController
                                      .isLoading.value) {
                                    Navigator.pop(context, true);
                                  }
                                }
                              : null,
                          title: widget.isEdit
                              ? AppStrings.update
                              : AppStrings.save,
                          isValidate: validate.value &&
                              !certificationsController.isLoading.value,
                        ))
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void validateForm() {
    final isValid = certificationsController.titleController.text
            .trim()
            .isNotEmpty &&
        certificationsController.issuingOrgController.text.trim().isNotEmpty &&
        isValidDate(_selectedDay, _selectedMonth, _selectedYear) &&
        (imagePath?.isNotEmpty ?? false);

    validate.value = isValid;
  }

  selectImage(BuildContext context) async {

    imagePath = await SelectProfilePictureDialog.showLogoDialog(
        context, AppStrings.uploadDocumentPhoto);
    if (imagePath?.isNotEmpty ?? false) {
      final file = File(imagePath!);
      certificationsController.setAttachment(file);
      setState(() {});
      validateForm();
    }
  }
}
