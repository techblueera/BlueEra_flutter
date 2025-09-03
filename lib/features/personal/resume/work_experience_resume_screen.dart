import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/new_common_date_selection_dropdown.dart';

class WorkExperienceResumeScreen extends StatefulWidget {

  const WorkExperienceResumeScreen({super.key});

  @override
  State<WorkExperienceResumeScreen> createState() => _WorkExperienceResumeScreenState();
}

class _WorkExperienceResumeScreenState extends State<WorkExperienceResumeScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isCurrentlyWorking = false;
  TextEditingController companyCtrl = TextEditingController();
  TextEditingController designationCtrl = TextEditingController();
  TextEditingController locationCtrl = TextEditingController();

  String? selectedStartDay, selectedStartYear, selectedStartMonth;
  String? selectedEndDay, selectedEndMonth ,selectedEndYear;
  bool validate = false;
  WorkType? _workType;
  WorkMode? _workMode;
  int? _selectedDay, _selectedMonth, _selectedYear;
  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CommonBackAppBar(
        title: "Work Experience",
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
      
                    ///Company Name....
                    CommonTextField(
                      textEditController: companyCtrl,
                      inputLength: AppConstants.inputCharterLimit100,
                      keyBoardType: TextInputType.text,
                      regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                      title: "Company Name",
                      titleColor: AppColors.black1A,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      hintText: "Eg., BlueCS Limited",
                      isValidate: true,
                      onChange: (value) => validateForm(),
                    ),
      
                    SizedBox(
                      height: SizeConfig.size15,
                    ),
      
                    ///DESIGNATION....
                    CommonTextField(
                      textEditController: designationCtrl,
                      inputLength: AppConstants.inputCharterLimit100,
                      keyBoardType: TextInputType.text,
                      regularExpression:
                      RegularExpressionUtils.alphabetSpacePattern,
                      title: appLocalizations?.designation,
                      titleColor: AppColors.black1A,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      hintText: "Eg., Software Engineer",
                      isValidate: true,
                      onChange: (value) => validateForm(),
                    ),
      
                    SizedBox(
                      height: SizeConfig.size15,
                    ),
      
                    /// Work Type...
                    CustomText(
                      "Work Type",
                      color: AppColors.black1A,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CommonDropdown<WorkType>(
                      items: WorkType.values,
                      selectedValue: _workType,
                      hintText: "Eg., Full Time",
                      displayValue: (_workType) => _workType.label,
                      onChanged: (value) {
                        setState(() {
                          _workType = value;
                          validateForm();
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                           return appLocalizations?.selectYourWorkType;
                        }
                        return null;
                      },
                    ),
      
                    SizedBox(
                      height: SizeConfig.size15,
                    ),
      
                    /// Job mod...
                    CustomText(
                      "Work Mode",
                      color: AppColors.black1A,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CommonDropdown<WorkMode>(
                      items: WorkMode.values,
                      selectedValue: _workMode,
                      hintText: "Eg., Remote",
                      displayValue: (_workMode) => _workMode.label,
                      onChanged: (value) {
                        setState(() {
                          _workMode = value;
                          validateForm();
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                           return appLocalizations?.selectYourWorkMode;
                        }
                        return null;
                      },
                    ),
      
                    SizedBox(
                      height: SizeConfig.size15,
                    ),
      
                    ///Location....
                    CommonTextField(
                      textEditController: locationCtrl,
                      inputLength: AppConstants.inputCharterLimit100,
                      keyBoardType: TextInputType.text,
                      regularExpression:
                      RegularExpressionUtils.alphabetSpacePattern,
                      title: "Location",
                      titleColor: AppColors.black1A,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      hintText: "Eg.,West Bengal",
                      isValidate: true,
                      onChange: (value) => validateForm(),
                    ),
      
                    SizedBox(
                      height: SizeConfig.size15,
                    ),
      
                    ///START DATE...
                    CustomText(
                      "Start Date",
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
                      },
                      onMonthChanged: (value) {
                        setState(() {
                          _selectedMonth = value;
                        });
                      },
                      onYearChanged: (value) {
                        setState(() {
                          _selectedYear = value;
                        });
                      },
                    ),
      
                    ///END DATE....
                    if (!isCurrentlyWorking) ...[
                      SizedBox(
                        height: SizeConfig.size15,
                      ),
                      CustomText(
                        "End Date",
                        color: AppColors.black1A,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                      ),
                      SizedBox(
                        height: SizeConfig.size5,
                      ),
                      NewDatePicker(
                        selectedDay: _selectedDay,
                        selectedMonth: _selectedMonth,
                        selectedYear: _selectedYear,
                        onDayChanged: (value) {
                          setState(() {
                            _selectedDay = value;
                          });
                        },
                        onMonthChanged: (value) {
                          setState(() {
                            _selectedMonth = value;
                          });
                        },
                        onYearChanged: (value) {
                          setState(() {
                            _selectedYear = value;
                          });
                        },
                      ),
                    ],
      
                    SizedBox(
                      height: SizeConfig.size8,
                    ),
      
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4), // your custom padding
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Theme(
                            data: Theme.of(context).copyWith(
                              checkboxTheme: CheckboxThemeData(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: const BorderSide(color: AppColors.grey99),
                                visualDensity: VisualDensity.compact, // less internal space
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // reduce tap area
                              ),
                            ),
                            child: Checkbox(
                              value: isCurrentlyWorking,
                              activeColor: AppColors.primaryColor,
                              checkColor: AppColors.white,
                              onChanged: (newValue) {
                                setState(() {
                                  isCurrentlyWorking = newValue!;
                                  if (isCurrentlyWorking) {
                                    selectedEndDay = null;
                                    selectedEndMonth = null;
                                    selectedEndYear = null;
                                  }
                                });
                                validateForm();
                              },
                            ),
                          ),
                          SizedBox(width: SizeConfig.size4),
                          Expanded(
                            child: CustomText(
                              "Currently working here",
                              color: AppColors.black,
                              fontSize: SizeConfig.medium,
                            ),
                          ),
                        ],
                      ),
                    ),
      
      
                    SizedBox(
                      height: SizeConfig.size20,
                    ),
      
                    ///SAVE BUTTON....
                    CustomBtn(
                      onTap: (validate) ? (){
                           Navigator.pop(context);
                        } : null,
                      title: "Save",
                      isValidate: validate,
                    )
      
      
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ///VALIDATE FORM...
  void validateForm() {
    final companyCtrlNotEmpty = companyCtrl.text.isNotEmpty;
    final designationCtrlNotEmpty = designationCtrl.text.isNotEmpty;
    final locationCtrlNotEmpty = locationCtrl.text.isNotEmpty;

    final workMode = _workMode!=null;
    final workType = _workType!=null;

    final isStartDaySelected = selectedStartDay?.isNotEmpty ?? false;
    final isStartMonthSelected = selectedStartMonth?.isNotEmpty ?? false;
    final isStartYearSelected = selectedStartYear?.isNotEmpty ?? false;

    final isEndDaySelected = selectedEndDay?.isNotEmpty ?? false;
    final isEndMonthSelected = selectedEndMonth?.isNotEmpty ?? false;
    final isEndYearSelected = selectedEndYear?.isNotEmpty ?? false;

    if (!companyCtrlNotEmpty ||
        !designationCtrlNotEmpty ||
        !locationCtrlNotEmpty ||
        !workMode ||
        !workType ||
        !isStartDaySelected ||
        !isStartMonthSelected ||
        !isStartYearSelected
       ) {
      validate = false;
      setState(() {});

      return;
    }

    if (!isCurrentlyWorking){
        if(!isEndDaySelected || !isEndMonthSelected || !isEndYearSelected){
          validate = false;
          setState(() {});

          return;
        }
    }

    validate = true;
    setState(() {});
  }

}
