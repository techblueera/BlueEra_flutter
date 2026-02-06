import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_text_cm.dart';
import 'add_achivement_politician.dart';
class PoliticianAchievementsPage extends StatefulWidget {
  const PoliticianAchievementsPage({super.key});

  @override
  State<PoliticianAchievementsPage> createState() => _PoliticianAchievementsPageState();
}

class _PoliticianAchievementsPageState extends State<PoliticianAchievementsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CommonBackAppBar(
          title: "Achievements",
        ),
        body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 10),
            child:SingleChildScrollView(
                child: Column(
                    children: [
                Container(
                decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.white
            ),
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText("Achievements",fontSize: 16,fontWeight: FontWeight.w600,),
                Row(
                  children: [
                    Icon(Icons.add,color: AppColors.primaryColor,),
                    CustomText("Add More",fontSize: 14,color: AppColors.primaryColor,)
                  ],
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size10,),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for(int i=0;i<3;i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Stack(
                          children: [
                            Container(
                              height:302 ,
                              width: 236,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.whiteE5
                              ),
                            ),
                            Positioned(
                                bottom: 0,
                                child: Container(
                                  width: 236,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: AppColors.black.withOpacity(0.5)
                                  ),
                                  padding: EdgeInsets.all(10),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustomText("Certificate Name",fontSize: 18,color: AppColors.white,fontWeight: FontWeight.w600,),
                                      SizedBox(height: 8,),
                                      CustomText("Gorem ipsum dolor sit amet, consectetur adipiscing "
                                          "elit. Nunc vulputate libero et velit interdum....",color: AppColors.white,fontSize: 12,fontWeight: FontWeight.w400,),

                                    ],
                                  ),
                                ))
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ])),
                      SizedBox(height: 10,),
                      Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.white
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    CustomText("Award",fontSize: 16,fontWeight: FontWeight.w600,),
                                    InkWell(
                                      onTap: (){
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                          ),
                                          builder: (_) => const AddAchivementPolitician(),
                                        );

                                      },
                                      child: Row(
                                        children: [
                                          Icon(Icons.add,color: AppColors.primaryColor,),
                                          CustomText("Add More",fontSize: 14,color: AppColors.primaryColor,)
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: SizeConfig.size10,),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      for(int i=0;i<3;i++)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 10.0),
                                          child: Stack(
                                            children: [
                                              Container(
                                                height:302 ,
                                                width: 236,
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(10),
                                                    color: AppColors.whiteE5
                                                ),
                                              ),
                                              Positioned(
                                                  bottom: 0,
                                                  child: Container(
                                                    width: 236,
                                                    decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(10),
                                                        color: AppColors.black.withOpacity(0.5)
                                                    ),
                                                    padding: EdgeInsets.all(10),
                                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        CustomText("Certificate Name",fontSize: 18,color: AppColors.white,fontWeight: FontWeight.w600,),
                                                        SizedBox(height: 8,),
                                                        CustomText("Gorem ipsum dolor sit amet, consectetur adipiscing "
                                                            "elit. Nunc vulputate libero et velit interdum....",color: AppColors.white,fontSize: 12,fontWeight: FontWeight.w400,),

                                                      ],
                                                    ),
                                                  ))
                                            ],
                                          ),
                                        )
                                    ],
                                  ),
                                )
                              ])),
                    ]))));
  }
}
