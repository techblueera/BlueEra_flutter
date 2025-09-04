import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/hide_confirmation_dialog.dart';
import 'package:flutter/material.dart';

class ReportDialog extends StatefulWidget {
  const ReportDialog(
      {super.key,
      required this.reportReasons,
      required this.reportType,
      required this.contentId,
      required this.reportTo,
      required this.postModelIndex,
      this.backgroundColor = AppColors.primaryColor,
      this.textColor = AppColors.black,
      this.iconColor = AppColors.black
      });

  final Map<String, bool> reportReasons;
  final String reportType;
  final int contentId;
  final int reportTo;
  final int postModelIndex;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;

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
                              setState(() {
                                currentReportReasons[key] = value!;
                                _updateValidation();
                              });
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
              CommonTextField(
                maxLine: 5,
                textEditController: reportController,
                keyBoardType: TextInputType.text,
                // regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                // hintText: appLocalizations?.enterGSTNumber,
                isValidate: true,

                onChange: (value) {
                  setState(() {
                    _reportText = value;
                    _updateValidation();
                  });
                },
                hintText: AppLocalizations.of(context)!.provideDetails,

                validator: (value) {
                  if (_reportText == null ||
                      (_reportText != null && _reportText!.isEmpty)) {
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
                      if (_formKey.currentState!.validate()) {
                        reportCase.clear();
                        for (int i = 0;
                        i < currentReportReasons.length;
                        i++) {
                          if (currentReportReasons.values.elementAt(i) ==
                              true) {
                            reportCase
                                .add(currentReportReasons.keys.elementAt(i));
                          }
                        }

                        if(widget.reportType == 'POST'){

                          Navigator.pop(context);

                          commonSnackBar(message: "Reported Successfully", isFromHomeScreen: true);

                          showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: Material(
                                  color: Colors.transparent,
                                  child: CustomSuccessSheet(
                                    buttonText: AppLocalizations.of(context)!.gotIt,
                                    title: AppLocalizations.of(context)!.youHaveReportedThisPost,
                                    subTitle: AppLocalizations.of(context)!.reportSuccessMessage,
                                    onPress: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ));


                          // context.read<FeedBloc>().add(PostReportEvent(
                          //     description: _reportText!,
                          //     reportCase: reportCase.isNotEmpty ? reportCase : null,
                          //     reportType: widget.reportType,
                          //     contentId: widget.contentId,
                          //     reportedTo: widget.reportTo));
                        }
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

  void reportUpdate(BuildContext context, int postModelIndex) {
    // switch (pageName) {
    //   case "GetSearchDataPage":
    //     context.read<GetSearchModelProvider>().reportUpdate(postModelIndex);
    //     break;
    //   case "JobPostScreen":
    //     context.read<JobPostModelProvider>().reportUpdate(postModelIndex);
    //     break;
    //
    //   case 'HomeScreen':
    //     context.read<PostModelProvider>().reportUpdate(postModelIndex);
    //     break;
    //   default:
    //     break;
    // }

    /// do work for hiding the post because its reported
  }
}
