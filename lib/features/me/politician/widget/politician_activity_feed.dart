import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/common_back_app_bar.dart';
class PoliticianActivityFeed extends StatefulWidget {
  const PoliticianActivityFeed({super.key});

  @override
  State<PoliticianActivityFeed> createState() => _PoliticianActivityFeedState();
}

class _PoliticianActivityFeedState extends State<PoliticianActivityFeed> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CommonBackAppBar(
          isCreateEventBtn:true,
          title: "Activity Feed",
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
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText("Activity Videos",fontSize: 16,fontWeight: FontWeight.w600,),
                          Row(
                            children: [
                              Icon(Icons.add,color: AppColors.primaryColor,),
                              CustomText("Add More",fontSize: 14,color: AppColors.primaryColor,)
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size6,),
                      Container(
                        height: 194,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.whiteE5
                        ),
                      ),
                      SizedBox(height: SizeConfig.size18,),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText("Activity Title",fontSize: 16,fontWeight: FontWeight.w600,),
                          Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: AppColors.whiteE5.withOpacity(0.3),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6
                              ),
                              child: CustomText("20 April,2025",fontSize: 10,fontWeight: FontWeight.w600,)),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size6,),
                      CustomText("Gorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum....",
                      fontSize: 12,color: AppColors.grayText,)


                    ],
                  ),),
                  SizedBox(height: SizeConfig.size10,),
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
                          CustomText("Activity Folder",fontSize: 16,fontWeight: FontWeight.w600,),
                          Row(
                            children: [
                              Icon(Icons.add,color: AppColors.primaryColor,),
                              CustomText("Add More",fontSize: 14,color: AppColors.primaryColor,)
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size10,),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.whiteE5
                          )
                        ),
                        padding: EdgeInsets.all(10),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.whiteE5
                              ),
                            ),
                            SizedBox(width: 10,),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start,mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      CustomText("Activity Title",fontSize: 16,fontWeight: FontWeight.w600,),
                                      LocalAssets(imagePath: AppIconAssets.info_more,imgColor: AppColors.grayText,)
                                    ],
                                  ),
                                  SizedBox(
                                    height: SizeConfig.size6,
                                  ),
                                  Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: AppColors.whiteE5.withOpacity(0.3),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6
                                      ),
                                      child: CustomText("20 April,2025",fontSize: 10,fontWeight: FontWeight.w600,)),
                                  SizedBox(
                                    height: SizeConfig.size6,
                                  ),
                                  CustomText(
                                      maxLines: 3,
                                      "Gorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum....")
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.size10,),
                      Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.whiteE5
                          )
                      ),
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText("Activity Folder",fontSize: 16,fontWeight: FontWeight.w600,),
                              Row(
                                children: [
                                  Icon(Icons.add,color: AppColors.primaryColor,),
                                  CustomText("Add More",fontSize: 14,color: AppColors.primaryColor,)
                                ],
                              ),
                            ],
                          ),
                          SizedBox(
                            height: SizeConfig.size10,
                          ),
                         Row(
                           children: [
                             Column(
                               children: [
                                 Container(
                                   height: 120,
                                   width: 120,
                                   decoration: BoxDecoration(
                                     borderRadius: BorderRadius.circular(10),
                                     color: AppColors.whiteE5
                                   ),
                                 ),
                                 SizedBox(
                                   height: 10,
                                 ),
                                 Container(
                                   height: 120,
                                   width: 120,
                                   decoration: BoxDecoration(
                                       borderRadius: BorderRadius.circular(10),
                                       color: AppColors.whiteE5
                                   ),
                                 ),
                               ],
                             ),
                             SizedBox(width: 10,),
                             Expanded(child:
                             Container(
                               height: 250,
                               width: 224,
                               decoration: BoxDecoration(
                                   borderRadius: BorderRadius.circular(10),
                                   color: AppColors.whiteE5
                               ),
                             ),)
                           ],
                         )
                         // Container(
                         //   child: Center(
                         //     child:CustomText("Upload Images"),
                         //   ),
                         // )
                        ],
                      ),)

                    ],
                  ),),
                  SizedBox(height: SizeConfig.size10,),
                ],
              ),
            ) )
    );
  }
}
