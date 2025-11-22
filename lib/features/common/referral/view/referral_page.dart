import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../../../widgets/custom_text_cm.dart';


class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Referral",
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _referralSummaryCard(),
            SizedBox(height: SizeConfig.size20),
            CustomText(
            "Referred Persons",
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: SizeConfig.size12),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) => _referredUserCard(),
              ),
            )
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
           "Your Referral Code",
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: SizeConfig.size4),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomText(
                "REK003612",
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: SizeConfig.size8,),
              GestureDetector(
                onTap: () {
                  commonSnackBar(
                      message: "Referral Code Copied");

                  Clipboard.setData(ClipboardData(text: "REK003612"));
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
              _subSummary("Referral Points", "120"),
              _subSummary("Referral Count", "12"),
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
