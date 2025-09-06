import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportDialog extends StatefulWidget {
  const ReportDialog({
    super.key,
    required this.reportReasons,
    required this.reportCallback,
    required this.reportType,
    required this.contentId,
    required this.otherUserId,
    this.backgroundColor = AppColors.primaryColor,
    this.textColor = AppColors.black,
    this.iconColor = AppColors.black,
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
    isValidate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> reportCase = [];

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
              /// Header
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
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.close,
                      color: widget.iconColor ?? AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size10),

              /// Label
              Text(
                AppLocalizations.of(context)!.stateReason,
                style: TextStyle(
                  fontSize: SizeConfig.screenWidth * .036,
                  fontWeight: FontWeight.w500,
                  color: widget.textColor,
                ),
              ),
              SizedBox(height: SizeConfig.size10),

              /// Reason List
              ...currentReportReasons.keys.map((String key) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: SizeConfig.screenHeight * .007,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: Checkbox(
                          value: currentReportReasons[key],
                          onChanged: (bool? value) {
                            final selectedCount = currentReportReasons.values
                                .where((v) => v == true)
                                .length;

                            if (value == true && selectedCount >= 3) {
                              commonSnackBar(
                                message:
                                'You can choose up to three reasons only',
                              );
                              return;
                            }

                            setState(() {
                              currentReportReasons[key] = value ?? false;
                              _updateValidation();
                            });
                          },
                          activeColor: AppColors.primaryColor,
                          checkColor: AppColors.white,
                          side: currentReportReasons[key] == true
                              ? BorderSide.none
                              : const BorderSide(
                            color: Colors.black,
                            width: 1.0,
                          ),
                          materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size20),
                      Expanded(
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: SizeConfig.screenWidth * .036,
                            fontWeight: FontWeight.w500,
                            color: widget.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              SizedBox(height: SizeConfig.size10),

              /// Extra description
              if (currentReportReasons.containsValue(true))
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
                      return AppLocalizations.of(context)!
                          .pleaseEnterDescription;
                    }
                    return null;
                  },
                ),

              SizedBox(height: SizeConfig.size20),

              /// Learn More Link
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    // open bottom sheet / web page
                    showModalBottomSheet(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (ctx) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "Here you can explain why reports matter, "
                                "how they are handled, and what happens next.",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.secondaryTextColor,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: InkWell(
                    onTap: () => _launchURL('https://bluecs.in/privacypolicy'),
                    child: Text(
                      "Learn more",
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: SizeConfig.size20),

              /// Submit button
              ValueListenableBuilder<bool>(
                valueListenable: isValidate,
                builder: (context, value, child) {
                  return CustomBtn(
                    title: widget.reportType == 'POST'
                        ? AppLocalizations.of(context)!.reportPost
                        : widget.reportType == 'COMMENT'
                        ? AppLocalizations.of(context)!.reportComment
                        : AppLocalizations.of(context)!.reportAndBlockUser,
                    width: SizeConfig.screenWidth,
                    isValidate: value,
                    onTap: () {
                      if (_formKey.currentState!.validate()) {
                        final selectedReasons = currentReportReasons.entries
                            .where((e) => e.value)
                            .map((e) => e.key)
                            .toList();

                        if (selectedReasons.isEmpty) {
                          commonSnackBar(message: "Please select a reason");
                          return;
                        }

                        Map<String, dynamic> params = {
                          ApiKeys.reportType: widget.reportType,
                          ApiKeys.description: _reportText,
                          ApiKeys.reportCase: selectedReasons,
                          ApiKeys.contentId: widget.contentId,
                          ApiKeys.reportedTo: widget.otherUserId,
                        };


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

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
