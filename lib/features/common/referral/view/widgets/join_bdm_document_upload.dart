import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/constants/shared_preference_utils.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../business/auth/controller/view_business_details_controller.dart';
import '../../../../personal/auth/controller/view_personal_details_controller.dart';
import '../../controller/referral_controller.dart';



class JoinBdmDocumentUpload extends StatefulWidget {
  const JoinBdmDocumentUpload({super.key});

  @override
  State<JoinBdmDocumentUpload> createState() => _JoinBdmDocumentUploadState();
}

class _JoinBdmDocumentUploadState extends State<JoinBdmDocumentUpload> {
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
   // await controller.getBdmDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Refer & Earn (Become BlueEra Assistant)",
        isShadowShow: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: SizeConfig.size230,
              width: double.infinity,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),

                  color: AppColors.white
              ),
              padding:EdgeInsets.all(14) ,
              child: Column(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.whiteE5
                    ),
                    child: Center(
                      child: Container(
                        height: SizeConfig.size50,
                        width: SizeConfig.size50,
                        decoration: BoxDecoration(
                          color: AppColors.black65,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.play_arrow,
                            color: AppColors.white,
                            size: SizeConfig.size30),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  SizedBox(height: 10,),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.white
                    ),
                    padding: EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.add,color: AppColors.primaryColor,),
                            SizedBox(width: 10,),
                            CustomText("Personal Details",color: AppColors.primaryColor,fontSize: 16,fontWeight: FontWeight.w600,)
                          ],
                        ),
                        SizedBox(height: 16,),
                        Row(
                          children: [
                            Icon(Icons.add,color: AppColors.primaryColor,),
                            SizedBox(width: 10,),
                            CustomText("Upload Aadhar Card",color: AppColors.primaryColor,fontSize: 16,fontWeight: FontWeight.w600,)
                          ],
                        ),
                        SizedBox(height: 16,),
                        Row(
                          children: [
                            Icon(Icons.add,color: AppColors.primaryColor,),
                            SizedBox(width: 10,),
                            CustomText("Upload Pan Card",color: AppColors.primaryColor,fontSize: 16,fontWeight: FontWeight.w600,)
                          ],
                        ),
                        SizedBox(height: 16,),
                        Row(
                          children: [
                            Icon(Icons.add,color: AppColors.primaryColor,),
                            SizedBox(width: 10,),
                            CustomText("Upload Address Proof",color: AppColors.primaryColor,fontSize: 16,fontWeight: FontWeight.w600,)
                          ],
                        ),
                        SizedBox(height: 16,),
                        Row(
                          children: [
                            Icon(Icons.add,color: AppColors.primaryColor,),
                            SizedBox(width: 10,),
                            CustomText("Upload Bank Details",color: AppColors.primaryColor,fontSize: 16,fontWeight: FontWeight.w600,)
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10,),
                  GenerateReferralCodeCard(referralCode: '${referralCode()}',),
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
                          height: 2,
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

                                  fontWeight: FontWeight.w800,)
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 6,
                        ),


                      ],
                    ),
                  ),

                ],
              ),
            ),


          ],
        ),
      ),
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
class GenerateReferralCodeCard extends StatelessWidget {
  const GenerateReferralCodeCard({super.key, required this.referralCode});
  final String referralCode;

  @override
  Widget build(BuildContext context) {
    return        Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.white
      ),
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LocalAssets(imagePath: AppIconAssets.multiPersonsIcon,
                imgColor:  AppColors.secondaryTextColor,),
              SizedBox(width: 6,),
              CustomText("Generate Your Referral Code",fontSize: 16,
                color: AppColors.secondaryTextColor,
              )
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.2)
                )
            ),
            padding: EdgeInsets.all(4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Row(
                    children: [
                      CustomText("${referralCode}",
                          color: AppColors.secondaryTextColor,
                          fontWeight:  FontWeight.w600,fontSize:20),
                      SizedBox(width: 16,),
                      LocalAssets(imagePath: AppIconAssets.editIcon,
                        imgColor:  AppColors.secondaryTextColor,)
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryColor,
                      width: 1.5,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8), // slightly smaller than outer
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryColor.withOpacity(0.06),
                          AppColors.primaryColor.withOpacity(0.02),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Center(
                        child: Row(
                          children: [
                            Icon(Icons.copy,color: AppColors.primaryColor,),
                            SizedBox(width: 6,),
                            CustomText("Copy",
                              color: AppColors.primaryColor,fontSize: 14,fontWeight: FontWeight.w600,)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              ],
            ),
          )

        ],
      ),
    );
  }
}
