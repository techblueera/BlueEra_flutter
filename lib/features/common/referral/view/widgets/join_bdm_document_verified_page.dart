import 'package:BlueEra/features/common/referral/view/widgets/referral_points_chart.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../business/auth/controller/view_business_details_controller.dart';
import '../../../../personal/auth/controller/view_personal_details_controller.dart';
import '../../controller/referral_controller.dart';
import '../referral_page.dart';


class JoinBdmDocumentVerifiedPage extends StatefulWidget {
  const JoinBdmDocumentVerifiedPage({super.key, required this.referralCode, required this.isEditable});
  final String referralCode;
  final bool isEditable;

  @override
  State<JoinBdmDocumentVerifiedPage> createState() => _JoinBdmDocumentVerifiedPageState();
}

class _JoinBdmDocumentVerifiedPageState extends State<JoinBdmDocumentVerifiedPage> {
  final controller = getOrPut(()=>ReferralController());
  final viewProfileController = getOrPut(() => ViewPersonalDetailsController());
  final viewBusinessProfileController =  getOrPut(() =>ViewBusinessDetailsController());


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              SizedBox(height: 10,),
              GenerateReferralCodeCard(
                isEditable: widget.isEditable,
                referralCode: '${widget.referralCode}',),
              SizedBox(height: 10,),
              SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.white
                ),
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 6,
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            CustomText("Balance",fontSize: 16,
                              color: AppColors.secondaryTextColor,
                            ),
                            SizedBox(
                              height: 16,
                            ),
                            CustomText("₹ 10,000",fontSize: 20,
                              color: AppColors.secondaryTextColor,

                              fontWeight: FontWeight.w800,)
                          ],
                        ),
                        SizedBox(
                          width: 46,
                        ),
                        Container(
                          height: 70,
                          width: 1,
                          color: AppColors.whiteE5,
                        ),
                        SizedBox(
                          width: 46,
                        ),
                        Column(
                          children: [
                            CustomText("Balance",fontSize: 16,
                              color: AppColors.secondaryTextColor,
                            ),
                            SizedBox(
                              height: 16,
                            ),
                            CustomText("₹ 10,000",fontSize: 20,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w800,
                            )
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: AppColors.greyPlaceHolder
                      ),
                      padding: EdgeInsets.all(10),
                      child: Center(
                        child: CustomText(
                          "20 Subscription Out of 400 Referral",
                          fontSize: 14,fontWeight: FontWeight.w600,
                          color: AppColors.grayText,),
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CustomBtn(
                            height: 34,
                            radius: 10,
                            borderColor: AppColors.primaryColor,
                            bgColor: Colors.transparent,
                            onTap: (){}, title: "History",
                            textColor: AppColors.primaryColor,),
                        ),
                        SizedBox(width: 10,),
                        Expanded(
                          child: CustomBtn(
                              radius: 10,
                              height: 34,
                              isValidate: true,
                              onTap: (){}, title: "Withdraw"),
                        ),
                      ],
                    )

                  ],
                ),
              ),
              SizedBox(height: 10,),
              Container(

                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.white
                ),
                padding: EdgeInsets.all(10),
                child:    Column(
                  children: [
                    ReferralPointsChart(subscribe: 100, unSubscribe: 30, expired: 10,)
                  ],
                ),
              )

            ],
          ),
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
