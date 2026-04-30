import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/referral/view/referral_history_screen.dart';
import 'package:BlueEra/features/common/referral/widgets/referral_points_chart.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/amount_withdraw_screen.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/dashed_border_container.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../business/auth/controller/view_business_details_controller.dart';
import '../../../personal/auth/controller/view_personal_details_controller.dart';
import '../controller/referral_controller.dart';

class BdmDocumentVerifiedPage extends StatefulWidget {
  const BdmDocumentVerifiedPage({
    super.key,
  });

  @override
  State<BdmDocumentVerifiedPage> createState() => _BdmDocumentVerifiedPageState();
}

class _BdmDocumentVerifiedPageState extends State<BdmDocumentVerifiedPage> {
  final controller = getOrPut(()=> ReferralController());
  final viewProfileController = getOrPut(() => ViewPersonalDetailsController());
  final viewBusinessProfileController =  getOrPut(() =>ViewBusinessDetailsController(), permanent: true);

  @override
  initState() {
    super.initState();
    // controller.getWalletReferralStatsApi();
  }


  @override
  Widget build(BuildContext context) {
    return Obx((){
      // if(controller.walletReferralStatsResponse.value.status == Status.INITIAL){
      //   return Center(
      //       child: CircularProgressIndicator()
      //   );
      // }

      // if(controller.referralBdmDetailsResponse.value.status == Status.ERROR){
      //   return Center(
      //       child: CustomText(
      //         'Oops Something went wrong.. Unable to fetch referral stats',
      //         fontSize: SizeConfig.extraLarge,
      //         color: AppColors.secondaryTextColor,
      //         fontWeight: FontWeight.w400,
      //       )
      //   );
      // }

      var _stats = controller.referralStatsData.value;

      return SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8,
            vertical: SizeConfig.size15
        ),
        child: Column(
          children: [
            CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  children: [
                    // 1. Header
                    Row(
                      children: [
                        LocalAssets(
                          imagePath: AppIconAssets.multiPersonsIcon,
                          imgColor: AppColors.secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        CustomText(
                          "Share Your Referral Code",
                          fontSize: SizeConfig.large,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400,
                        )
                      ],
                    ),

                    SizedBox(height: SizeConfig.paddingXSL),

                    DashedBorderContainer(
                      borderColor: AppColors.primaryColor,
                      strokeWidth: 1,
                      dashLength: 2,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: SizeConfig.size5,
                          bottom: SizeConfig.size5,
                          left: SizeConfig.size15,
                          right: SizeConfig.size5,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: CustomText(
                                _stats.referralCode??'',
                                color: AppColors.secondaryTextColor,
                                fontSize: SizeConfig.extraLarge,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: SizeConfig.size8),
                            InkWell(
                              onTap: (){
                                copyToClipboard(context, _stats.referralCode??'');
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.primaryColor,
                                    width: 0.5,
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primaryColor.withValues(alpha: 0.06),
                                      AppColors.primaryColor.withValues(alpha: 0.02),
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(10.0),
                                child: Icon(
                                  Icons.copy,
                                  color: AppColors.primaryColor,
                                  size: SizeConfig.size20,
                                ),
                              ),
                            ),
                            SizedBox(width: SizeConfig.paddingXSL),
                            GestureDetector(
                              onTap: () async {
                                await Share.share(
                                  _stats.referralCode??'',
                                  subject: "Amazing App",
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.whiteE5,
                                    width: 1.0,
                                  ),
                                ),
                                padding: const EdgeInsets.all(10.0),
                                child: LocalAssets(
                                  imagePath: AppIconAssets.reelShare,
                                  imgColor: AppColors.secondaryTextColor,
                                  height: SizeConfig.size20,
                                  width: SizeConfig.size20,
                                ),
                              ),
                            )

                          ],
                        ),
                      ),
                    )


                  ],
                )
            ),

            SizedBox(height: SizeConfig.paddingXSL),

            CustomFormCard(
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 6,
                  ),
                  FittedBox(
                    child: SizedBox(
                     width: SizeConfig.screenWidth,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SizedBox(
                            width: SizeConfig.size20,
                          ),
                          Column(
                            children: [
                              CustomText(
                                "Balance",
                                fontSize: SizeConfig.large,
                                color: AppColors.secondaryTextColor,
                              ),
                              SizedBox(
                                height: SizeConfig.paddingM,
                              ),
                              CustomText("₹ ${_stats.balance??00}",fontSize: SizeConfig.extraLarge,
                                color: AppColors.secondaryTextColor,

                                fontWeight: FontWeight.w800,)
                            ],
                          ),
                          SizedBox(
                            width: SizeConfig.size20,
                          ),
                          Container(
                            height: 70,
                            width: 1,
                            color: AppColors.whiteE5,
                          ),
                          SizedBox(
                            width: SizeConfig.size20,
                          ),
                          Column(
                            children: [
                              CustomText("Total Earn", fontSize: SizeConfig.large,
                                color: AppColors.secondaryTextColor,
                              ),
                              SizedBox(
                                height: SizeConfig.paddingM,
                              ),
                              CustomText("₹ ${_stats.totalIncome??00}", fontSize: SizeConfig.extraLarge,
                                color: AppColors.secondaryTextColor,
                                fontWeight: FontWeight.w800,
                              )
                            ],
                          ),
                          SizedBox(
                            width: SizeConfig.size20,
                          ),
                          Container(
                            height: 70,
                            width: 1,
                            color: AppColors.whiteE5,
                          ),
                          SizedBox(
                            width: SizeConfig.size20,
                          ),
                          Column(
                            children: [
                              CustomText("Estd. Earning", fontSize: SizeConfig.large,
                                color: AppColors.secondaryTextColor,
                              ),
                              SizedBox(
                                height: SizeConfig.paddingM,
                              ),
                              CustomText("₹ ${_stats.estimatedEarning??00}",  fontSize: SizeConfig.extraLarge,
                                color: AppColors.secondaryTextColor,
                                fontWeight: FontWeight.w800,
                              )
                            ],
                          ),

                          SizedBox(
                            width: SizeConfig.size20,
                          ),


                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: SizeConfig.paddingM,
                  ),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.greyPlaceHolder,
                        boxShadow: [AppShadows.textFieldShadow]
                    ),
                    padding: EdgeInsets.all(10),
                    child: Center(
                      child: CustomText(
                        "${_stats.breakdown?.subscribed??00} Subscription Out of ${_stats.totalReferralCount??00} Referral",
                        fontSize: SizeConfig.medium,fontWeight: FontWeight.w600,
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
                          onTap: (){
                            Get.to(()=> ReferralHistoryScreen());
                          }, title: "History",
                          textColor: AppColors.primaryColor,),
                      ),
                      SizedBox(width: SizeConfig.paddingXSL),
                      Expanded(
                        child: CustomBtn(
                            radius: 10,
                            height: 34,
                            isValidate: true,
                            onTap: (){
                              Get.to(() => AmountWithdrawScreen());
                            },
                            title: "Withdraw"
                        ),
                      ),
                    ],
                  )

                ],
              ),
            ),

            SizedBox(height: SizeConfig.paddingXSL),

            CustomFormCard(
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                children: [
                  ReferralPointsChart(
                    subscribe: _stats.breakdown?.subscribed ?? 0,
                    unSubscribe: _stats.breakdown?.nonSubscribed ?? 0,
                    expired: _stats.breakdown?.expired ?? 0,
                    pending: _stats.breakdown?.pending ?? 0,
                  )
                ],
              ),
            )

          ],
        ),
      );

    });

  }

}
