import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SelectCompanyVerificationScreen extends StatefulWidget {
  const SelectCompanyVerificationScreen({super.key});

  @override
  State<SelectCompanyVerificationScreen> createState() =>
      _SelectCompanyVerificationScreenState();
}

class _SelectCompanyVerificationScreenState extends State<SelectCompanyVerificationScreen> {
  VerificationType? verificationType;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: true,
        title: appLocalizations?.businessVerification
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: SizeConfig.size20),
                SvgPicture.asset(
                  AppIconAssets.phoneSecurity,
                ),
                SizedBox(height: SizeConfig.size45),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CustomText(
                    appLocalizations?.chooseWhatYouWantToVerify,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: SizeConfig.size15),

                _buildVerificationCard(
                    onTap: () {
                      setState(() {
                        verificationType = VerificationType.business;
                      });
                    },
                    isSelected: (verificationType == VerificationType.business) ? true : false,
                    title: appLocalizations!.businessVerification,
                    heading: appLocalizations.verifyYourBusinessDetailsUsingGst,
                    descriptionOne: appLocalizations.confirmsYourBusinessIsRegistered,
                    descriptionTwo: appLocalizations.requiredGstOrLicenseCertificate
                ),
                SizedBox(height: SizeConfig.size12),
                _buildVerificationCard(
                    onTap: () {
                      setState(() {
                        verificationType = VerificationType.ownership;
                      });
                    },
                    isSelected: (verificationType == VerificationType.ownership) ? true : false,
                    title: appLocalizations.ownershipVerification,
                    heading: appLocalizations.verifyThatYouAreTheOwnerOfTheBusiness,
                    descriptionOne: appLocalizations.confirmsYourIdentityAsTheBusinessOwner,
                    descriptionTwo: appLocalizations.requiredAadhaarVoterIdOrSimilar
                ),
                SizedBox(height: SizeConfig.size20),

                CustomBtn(
                    onTap: () {
                      if (verificationType != null) {
                        if(verificationType == VerificationType.business){
                          Navigator.pushNamed(
                              context, RouteHelper.getBusinessVerificationScreenRoute());
                        }else{
                          Navigator.pushNamed(
                              context, RouteHelper.getOwnershipVerificationScreenRoute());
                        }
                      }
                    },
                    title: appLocalizations.verifyNow,
                    isValidate: (verificationType != null) ? true : false
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationCard({required VoidCallback onTap, required bool isSelected,required String title, required String heading, required String descriptionOne, required String descriptionTwo}){
    return InkWell(
      onTap: onTap,
      child: Container(
          width: SizeConfig.screenWidth,
          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: AppColors.black28,
            border: Border.all(
              color: (isSelected) ? AppColors.primaryColor : Colors.transparent
            )
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                title,
                fontSize: SizeConfig.extraLarge22,
                fontWeight: FontWeight.w700,
                color: AppColors.yellow,
              ),
              SizedBox(height: SizeConfig.size4),
              CustomText(
                heading,
                fontSize: SizeConfig.extraSmall
              ),
              SizedBox(height: SizeConfig.size8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: CustomText(
                  descriptionOne,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: SizeConfig.size4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: CustomText(
                  descriptionTwo,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
      ),
    );
  }

}