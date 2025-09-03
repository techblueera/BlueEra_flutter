import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/model/create_account_model.dart';
import 'package:BlueEra/core/common_singleton_class/user_session.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class CreateAccountScreen extends StatefulWidget {
  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  int? _selectedIndex;
  String? _imagePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;
    final List<AccountOption> accountOptions = getCreateAccountType();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // onWillPop(context);
        if (!isGuestUser()) {
          commonConformationDialog(
              context: context,
              text: "Are you sure you want to exit the app?",
              confirmCallback: () async {
                await SharedPreferenceUtils.clearPreference();
                Navigator.of(context).pushNamedAndRemoveUntil(
                    RouteHelper.getMobileNumberLoginRoute(),
                    (Route<dynamic> route) => false);
              },
              cancelCallback: () {
                Navigator.of(context).pop(); // Close the dialog
              });
        } else {
          Navigator.of(context).pop(); // Close the dialog
        }
      },
      child: Scaffold(
        appBar: CommonBackAppBar(
          isLeading: true,
          appBarColor: Colors.white,
          onBackTap: () {
            if (!isGuestUser()) {
              commonConformationDialog(
                  context: context,
                  text: "Are you sure you want to exit the app?",
                  confirmCallback: () async {
                    await SharedPreferenceUtils.clearPreference();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        RouteHelper.getMobileNumberLoginRoute(),
                        (Route<dynamic> route) => false);
                  },
                  cancelCallback: () {
                    Navigator.of(context).pop(); // Close the dialog
                  });
            } else {
              Navigator.of(context).pop(); // Close the dialog
            }
          },
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size30, vertical: SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        SizedBox(height: SizeConfig.paddingM),
                        CustomText(
                          appLocalizations.chooseAccountType,
                          color: Colors.black,
                          fontSize: SizeConfig.extraLarge22,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: SizeConfig.paddingXSmall),
                        CustomText(
                          appLocalizations.chooseShopSellHire,
                          textAlign: TextAlign.center,
                          fontSize: SizeConfig.small,
                        ),
                        SizedBox(height: SizeConfig.size30),
                        InkWell(
                          onTap: () => _selectImage(context),
                          child: Container(
                            padding: EdgeInsets.all(SizeConfig.size2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primaryColor, width: 1.6),
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.whiteF3,
                              child: _imagePath?.isNotEmpty == true
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(40),
                                      child: Image(
                                          image: FileImage(File(_imagePath!))
                                            ..evict()),
                                    )
                                  : LocalAssets(
                                      imagePath: AppIconAssets.user_out_line),
                            ),
                          ),
                        ),
                        SizedBox(height: SizeConfig.size8),
                        InkWell(
                          onTap: () => _selectImage(context),
                          child: CustomText(
                            appLocalizations.uploadYourPhotoOrLogo,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // SizedBox(height: SizeConfig.size22),
                      ],
                    ),
                  ),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: accountOptions.length,
                    itemBuilder: (context, index) {
                      final option = accountOptions[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedIndex = index);
                        },
                        child: Container(
                          margin:
                              EdgeInsets.symmetric(vertical: SizeConfig.size12),
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.medium),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (_selectedIndex == index)
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                height: SizeConfig.size90,
                                width: SizeConfig.size100,
                                child: LocalAssets(
                                    imagePath: option.iconPath,
                                    boxFix: BoxFit.fitHeight),
                              ),
                              SizedBox(width: SizeConfig.size15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: SizeConfig.paddingS),
                                    CustomText(
                                      option.title,
                                      color: AppColors.navy,
                                      fontWeight: FontWeight.bold,
                                      fontSize: SizeConfig.large,
                                    ),
                                    CustomText(option.subtitle,
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.bold),
                                    CustomText(
                                      option.description,
                                      fontSize: SizeConfig.small,
                                      color: AppColors.black28,
                                    ),
                                    SizedBox(height: SizeConfig.paddingXL),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // SizedBox(height: SizeConfig.size10),
                  PositiveCustomBtn(
                    onTap: _onGetStartedPressed,
                    title: appLocalizations.submit,
                    radius: SizeConfig.size8,
                  ),
                  SizedBox(
                    height: kToolbarHeight,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectImage(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final String? selected = await SelectProfilePictureDialog.showLogoDialog(
      context,
      loc.uploadProfilePicture,
    );

    if (selected?.isNotEmpty ?? false) {
      _imagePath = selected;
      UserSession().imagePath = selected;
      setState(() {});
      if (_selectedIndex != null) _navigateToCreateAccount();
    }
  }

  void _onGetStartedPressed() {
    if (_imagePath?.isEmpty ?? true) {
      _selectImage(context);
      return;
    }
    _navigateToCreateAccount();
  }

  void _navigateToCreateAccount() {
    if (_selectedIndex == null) {
      commonSnackBar(message: AppLocalizations.of(context)!.selectAccountType);
      return;
    }
    final accountType =
        _selectedIndex == 0 ? AppConstants.individual : AppConstants.business;
    UserSession().userType = accountType;
    // SharedPreferenceUtils.setSecureValue(
    //     SharedPreferenceUtils.accountType, accountType);
    Navigator.pushNamed(
      context,
      RouteHelper.getCreateUserAccountRoute(),
      arguments: {ApiKeys.argAccountType: accountType},
    );
  }
}
