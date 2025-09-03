import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
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

class EducationResumeScreen extends StatefulWidget {

  const EducationResumeScreen({super.key});

  @override
  State<EducationResumeScreen> createState() => _EducationResumeScreenState();
}

class _EducationResumeScreenState extends State<EducationResumeScreen> {
  bool isCurrentlyStudy = false;
  final _formKey = GlobalKey<FormState>();
  bool isCurrentlyStudying = false;
  TextEditingController educationCtrl = TextEditingController();
  TextEditingController enterGradingController = TextEditingController();
  TextEditingController courseCtrl = TextEditingController();
  TextEditingController institutionCtrl = TextEditingController();
  int? _selectedYear;
  String? selectedStartYear;
  String? selectedEndYear;
  late List<String> yearsList;
  int tempIndex = -1;
  EducationType? _educationType;
  String? selectedGradingSystem;

  bool validate = false;

  @override
  void initState() {
    yearsList = generateList(1970, DateTime.now().year);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppLocalizations.of(context)!.education,
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.all(SizeConfig.size15),
              child: Column(
                children: [
                    CommonCardWidget(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                              AppLocalizations.of(context)!.education,
                              color: AppColors.black1A,
                            ),
                          SizedBox(height: SizeConfig.size8),
                          CommonDropdown<EducationType>(
                            items: EducationType.values,
                            selectedValue: _educationType,
                            hintText: AppConstants.selectProfession,
                            displayValue: (_educationType) => _educationType.label,
                            onChanged: (value) {
                              setState(() {
                                _educationType = value;
                                validateForm();
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return appLocalizations?.selectYourEducation;
                              }
                              return null;
                            },
                          )
                        ],
                      )
                  ),
      
                    CommonCardWidget(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            "Graduation details/ Post graduation details",
                            color: AppColors.black1A,
                            fontSize: SizeConfig.large,
                            fontWeight: FontWeight.w700,
                          ),
                          SizedBox(
                            height: SizeConfig.size20,
                          ),
      
                          /// Course Name
                          CommonTextField(
                            textEditController: courseCtrl,
                            inputLength: AppConstants.inputCharterLimit100,
                            keyBoardType: TextInputType.text,
                            regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                            title: "Course Name",
                            titleColor: AppColors.black1A,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            hintText: "Eg., Bachelor of Science",
                            isValidate: true,
                            onChange: (value) => validateForm(),
                          ),
                          SizedBox(
                            height: SizeConfig.size15,
                          ),
      
                          /// Collage
                          CommonTextField(
                            textEditController: institutionCtrl,
                            inputLength: AppConstants.inputCharterLimit50,
                            keyBoardType: TextInputType.text,
                            regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                            titleColor: AppColors.black1A,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            title: "Collage",
                            hintText: "Eg.., TDB Collage",
                            onChange: (value) => validateForm(),
                          ),
                          SizedBox(
                            height: SizeConfig.size15,
                          ),
      
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      'Start Year',
                                      color: AppColors.black1A,
                                      fontSize: SizeConfig.small,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    SizedBox(
                                      height: SizeConfig.size10,
                                    ),
                                    NewDatePicker(
                                      selectedYear: _selectedYear,
                                      onYearChanged: (value) {
                                        setState(() {
                                          _selectedYear = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: SizeConfig.size15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      'End Year',
                                      color: AppColors.black1A,
                                      fontSize: SizeConfig.small,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    SizedBox(
                                      height: SizeConfig.size10,
                                    ),
                                    NewDatePicker(
                                      selectedYear: _selectedYear,
                                      onYearChanged: (value) {
                                        setState(() {
                                          _selectedYear = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
      
                          SizedBox(
                            height: SizeConfig.size15,
                          ),
      
      
                          /// Grading System
                          CustomText(
                            appLocalizations?.gradingSystem,
                            color: AppColors.black1A,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                          ),
                          SizedBox(
                            height: SizeConfig.size10,
                          ),
                          CommonDropdown<String>(
                            items: gradingOptions,
                            selectedValue: selectedGradingSystem,
                            hintText: AppConstants.selectProfession,
                            displayValue: (grad) => grad,
                            onChanged: (value) {
                              setState(() {
                                selectedGradingSystem = value;
                                validateForm();
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return appLocalizations?.pleaseSelectAGradingSystem;
                              }
                              return null;
                            },
                          ),
      
                          /// Institution
                          if (selectedGradingSystem != null)
                            Padding(
                              padding: EdgeInsets.only(
                                top: SizeConfig.size15,
                              ),
                              child: CommonTextField(
                                textEditController: enterGradingController,
                                inputLength: AppConstants.inputCharterLimit10,
                                keyBoardType: TextInputType.number,
                                regularExpression: RegularExpressionUtils.digitsPattern,
                                title: "Enter ${selectedGradingSystem}",
                                titleColor: AppColors.black1A,
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400,
                                hintText: selectedGradingSystem,
                                isValidate: false,
                                onChange: (value) => validateForm(),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ///VALIDATE FORM...
  void validateForm() {
    final educationType = _educationType!=null;
    final courseNotEmpty = courseCtrl.text.isNotEmpty;
    final institutionNotEmpty = institutionCtrl.text.isNotEmpty;
    final isStartYearSelected = selectedStartYear?.isNotEmpty ?? false;
    final isEndYearSelected = selectedEndYear?.isNotEmpty ?? false;
    final enterGradingNotEmpty = enterGradingController.text.isNotEmpty;
    final isSelectedGradingSystemEmpty = selectedGradingSystem?.isNotEmpty ?? false;

    if(!educationType ||
        !courseNotEmpty ||
        !institutionNotEmpty ||
        !isStartYearSelected ||
        !isEndYearSelected ||
        !isSelectedGradingSystemEmpty ||
        !enterGradingNotEmpty
       ){
      validate = false;
      setState(() {});

      return;
    }

    validate = true;
    setState(() {});
  }
}
