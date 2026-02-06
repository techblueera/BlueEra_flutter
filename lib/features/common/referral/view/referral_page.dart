import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../business/auth/controller/view_business_details_controller.dart';
import '../../../personal/auth/controller/view_personal_details_controller.dart';
import '../controller/referral_controller.dart';


class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  final controller = getOrPut(()=>ReferralController());
  final viewProfileController = getOrPut(() => ViewPersonalDetailsController());
  final viewBusinessProfileController =  getOrPut(() =>ViewBusinessDetailsController());
  String referralCode(){
    if (accountTypeGlobal != "BUSINESS") {
      return viewProfileController
          .personalProfileDetails.value.user?.referral_code??'';
    }else{
      return
        viewBusinessProfileController.businessProfileDetails?.data?.referral_code??"";
    }
  }  String referralPoint(){
    if (accountTypeGlobal != "BUSINESS") {
      return viewProfileController
          .personalProfileDetails.value.user?.referral_points??'';
    }else{
      return
        viewBusinessProfileController.businessProfileDetails?.data?.referral_points??"";
    }
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
   // loadDetails();
  }
  void loadDetails()async{
   // await controller.fetchMyReferralId();
   await controller.getMyReferralHistoryApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.referral,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _referralSummaryCard(),
            SizedBox(height: SizeConfig.size20),
            CustomText(
              AppStrings.referredPersons,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: SizeConfig.size12),
            Center(
              child: CustomText("No Referral Record Found"),
            )
            // Expanded(
            //   child: ListView.builder(
            //     itemCount: 5,
            //     itemBuilder: (context, index) => _referredUserCard(),
            //   ),
            // )
          ],
        ),
      ),
    );
  }

  Widget _referralSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          CustomText(
            AppStrings.yourReferralCode,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: SizeConfig.size4),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomText(
                "${referralCode()}",
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: SizeConfig.size8,),
              GestureDetector(
                onTap: () {
                  commonSnackBar(
                      message: AppStrings.referralCodeCopied);

                  Clipboard.setData(ClipboardData(text: "${referralCode()}"));
                },
                child: Icon(
                  Icons.copy,
                  size: 20,
                  color: AppColors.primaryColor,
                ),
              )
            ],
          ),
          SizedBox(height: SizeConfig.size20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _subSummary(AppStrings.referralPoints, "${referralPoint()}"),
              _subSummary(AppStrings.referralCount, "0"),
            ],
          )
        ],
      ),
    );
  }

  Widget _subSummary(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.grayText,
        ),
        SizedBox(height: SizeConfig.size4),
        CustomText(
           value,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor,
        ),
      ],
    );
  }

  Widget _referredUserCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, size: 28),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                   "User Name",
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: SizeConfig.size4),
                CustomText(
                   "Referred on 12 Nov 2025",
                  fontSize: 12,
                  color: AppColors.grayText,
                ),
              ],
            ),
          ),
          CustomText(
          "+10 pts",
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryColor,
          )
        ],
      ),
    );
  }
}
