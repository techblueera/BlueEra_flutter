import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/new_common_date_selection_dropdown.dart';

class RecruiterAccountScreen extends StatefulWidget {
  RecruiterAccountScreen({super.key});

  @override
  State<RecruiterAccountScreen> createState() => _RecruiterAccountState();
}

class _RecruiterAccountState extends State<RecruiterAccountScreen> {
  final companyOrgNameTextController = TextEditingController();
  final nameTextController = TextEditingController();
  final referralCodeController = TextEditingController();
  final designationTextController = TextEditingController();
  bool referralCodeEnable = false, validate = false;
  int? _selectedDay, _selectedMonth, _selectedYear;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: SizeConfig.size20,
              ),
              CustomText(
                appLocalizations?.recruiterDetails,
                fontSize: SizeConfig.extraLarge,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(
                height: SizeConfig.size20,
              ),

              ///ENTER ORG/COMPANY NAME...
              CommonTextField(
                textEditController: companyOrgNameTextController,
                inputLength: AppConstants.inputCharterLimit50,
                keyBoardType: TextInputType.text,
                regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                title: appLocalizations?.companyOrgName,
                hintText: "Eg. Wipro,TCS",
                isValidate: false,
                onChange: (value) => validateForm(),
              ),

              SizedBox(
                height: SizeConfig.size20,
              ),

              ///DOB selection
              CustomText(
                appLocalizations?.dateOfIncorporation,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
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

              SizedBox(
                height: SizeConfig.size20,
              ),

              ///ENTER  NAME...
              CommonTextField(
                textEditController: nameTextController,
                inputLength: AppConstants.inputCharterLimit50,
                keyBoardType: TextInputType.text,
                regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                title: appLocalizations?.yourName,
                hintText: "Eg. Rahul Sharma",
                isValidate: false,
                onChange: (value) => validateForm(),
              ),
              SizedBox(
                height: SizeConfig.size20,
              ),

              /// Designation
              CommonTextField(
                textEditController: designationTextController,
                inputLength: AppConstants.inputCharterLimit50,
                keyBoardType: TextInputType.text,
                regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                title: appLocalizations?.yourDesignation,
                hintText: "Eg. HR Manager",
                isValidate: false,
                onChange: (value) => validateForm(),
              ),
              SizedBox(
                height: SizeConfig.size20,
              ),
              referralCodeEnable
                  ? CommonTextField(
                      textEditController: referralCodeController,
                      inputLength: AppConstants.inputCharterLimit10,
                      keyBoardType: TextInputType.text,
                      regularExpression: RegularExpressionUtils.alphanumericPattern,
                      title: appLocalizations?.referralCode,
                      hintText: appLocalizations?.enterReferralCode,
                      isValidate: false,
                    )
                  : Center(
                      child: InkWell(
                        onTap: () => setState(() => referralCodeEnable = true),
                        child: CustomText(
                          appLocalizations?.youHaveReferCode,
                          color: AppColors.primaryColor,
                          decoration: TextDecoration.underline,
                          fontSize: SizeConfig.medium,
                          decorationColor: AppColors.primaryColor,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
          child: Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15, vertical: SizeConfig.size15),
        child: CustomBtn(
          onTap: () async {
            Navigator.pushNamedAndRemoveUntil(
                context,
                RouteHelper.getBottomNavigationBarScreenRoute(),
                arguments: {},
                (Route<dynamic> route) => false);
          },
          title: appLocalizations?.submit,
          isValidate: validate,
        ),
      )),
    );
  }

  ///VALIDATE FORM...
  void validateForm() {
    final nameNotEmpty = nameTextController.text.isNotEmpty;
    final companyNameNotEmpty = companyOrgNameTextController.text.isNotEmpty;
    final designationNotEmpty = designationTextController.text.isNotEmpty;
    final isYearSelected = _selectedYear!=null;
    final isMonthSelected = _selectedMonth!=null;
    final isDaySelected = _selectedDay!=null;
    if (!nameNotEmpty ||
        !companyNameNotEmpty ||
        !designationNotEmpty ||
        !isYearSelected ||
        !isMonthSelected ||
        !isDaySelected) {
      validate = false;
      setState(() {});
      return;
    } else {
      validate = true;
    }
    setState(() {});
  }
}
