import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_success_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReportDialog extends StatefulWidget {
  const ReportDialog(
      {super.key,
        required this.reportReasons,
        required this.reportCallback,
        required this.reportType,
        required this.contentId,
        required this.otherUserId,
        this.backgroundColor = AppColors.primaryColor,
        this.textColor = AppColors.black,
        this.iconColor = AppColors.black
      });

  final Map<String, bool> reportReasons;
  final String reportType;
  final String contentId;
  final String otherUserId;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final Function(Map<String, dynamic>) reportCallback;

  @override
  _ReportDialogState createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  late Map<String, bool> currentReportReasons;
  final _formKey = GlobalKey<FormState>();
  String? _reportText;
  List<String> reportCase = [];
  final TextEditingController reportController = TextEditingController();
  final ValueNotifier<bool> isValidate = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    currentReportReasons = Map<String, bool>.from(widget.reportReasons);
  }

  @override
  void dispose() {
    reportController.dispose();
    isValidate.dispose(); // ✅ Dispose ValueNotifier
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    widget.reportType == 'POST'
                        ? AppLocalizations.of(context)!.reportPost
                        : widget.reportType == 'COMMENT'
                        ? AppLocalizations.of(context)!.reportComment
                        : AppLocalizations.of(context)!.reportUser,
                    fontSize: SizeConfig.screenWidth * .05,
                    fontWeight: FontWeight.bold,
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Icon(
                      Icons.close,
                      color: widget.iconColor ?? AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size10),
              Text(
                AppLocalizations.of(context)!.stateReason,
                style: TextStyle(
                    fontSize: SizeConfig.screenWidth * .036,
                    fontWeight: FontWeight.w500,
                    color: widget.textColor),
              ),
              SizedBox(height: SizeConfig.size10),
              ...currentReportReasons.keys.map(
                    (String key) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.screenHeight * .007),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: Checkbox(
                            value: currentReportReasons[key],
                            onChanged: (bool? value) {
                              for (int i = 0; i < currentReportReasons.length; i++) {
                                if (currentReportReasons.values.elementAt(i) == true) {
                                  reportCase.add(currentReportReasons.keys.elementAt(i));
                                }
                              }
                              if(reportCase.length <= 3) {
                                setState(() {
                                  currentReportReasons[key] = value!;
                                  _updateValidation();
                                });
                              }else{
                                commonSnackBar(message: 'You can choose upto three reason');
                              }
                            },
                            // checkColor: Colors.yellowAccent,  // color of tick Mark
                            activeColor: AppColors.primaryColor,
                            checkColor: AppColors.white,
                            side: currentReportReasons[key] == true
                                ? BorderSide.none               // ✅ hide border when checked
                                : const BorderSide(             // 🟥 show border when unchecked
                              color: Colors.black,
                              width: 1.0,
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduces tap target size
                          ),
                        ),
                        SizedBox(width: SizeConfig.size20),
                        Expanded(
                          child: Text(
                            key,
                            style: TextStyle(
                                fontSize: SizeConfig.screenWidth * .036,
                                fontWeight: FontWeight.w500,
                                color: widget.textColor),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: SizeConfig.size10),

              if(currentReportReasons.containsValue(true))
              CommonTextField(
                maxLine: 5,
                textEditController: reportController,
                keyBoardType: TextInputType.text,
                isValidate: true,
                onChange: (value) {
                  setState(() {
                    _reportText = value;
                    _updateValidation();
                  });
                },
                hintText: AppLocalizations.of(context)!.provideDetails,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.pleaseEnterDescription;
                  }
                  return null;
                },
              ),

              SizedBox(height: SizeConfig.size30),
              ValueListenableBuilder<bool>(
                valueListenable: isValidate,
                builder: (context, value, child) {
                  return CustomBtn(
                    title: widget.reportType == 'POST'
                        ? AppLocalizations.of(context)!.reportPost
                        : widget.reportType == 'COMMENT'
                        ? AppLocalizations.of(context)!.reportComment
                        : AppLocalizations.of(context)!
                        .reportAndBlockUser,
                    width: SizeConfig.screenWidth,
                    isValidate: value,
                    onTap: () {
                      if(reportCase.length < 1){
                        return;
                      }
                      if (_formKey.currentState!.validate()) {
                        // reportCase.clear();
                        // for (int i = 0; i < currentReportReasons.length; i++) {
                        //   if (currentReportReasons.values.elementAt(i) == true) {
                        //     reportCase.add(currentReportReasons.keys.elementAt(i));
                        //   }
                        // }

                        Map<String, dynamic> params = {
                          ApiKeys.reportType: widget.reportType,
                          ApiKeys.description: _reportText,
                          ApiKeys.reportCase: reportCase,
                          ApiKeys.contentId: widget.contentId,
                          ApiKeys.reportedTo: widget.otherUserId,
                        };

                        Navigator.pop(context);

                        widget.reportCallback(params);

                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateValidation() {
    final hasChecked = currentReportReasons.containsValue(true);
    final hasText = _reportText != null && _reportText!.trim().isNotEmpty;

    isValidate.value = hasChecked && hasText;
  }

}
