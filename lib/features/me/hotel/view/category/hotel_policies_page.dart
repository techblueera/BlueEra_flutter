import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/common_box_shadow.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';
class HotelPoliciesPage extends StatefulWidget {
  const HotelPoliciesPage({super.key});

  @override
  State<HotelPoliciesPage> createState() => _HotelPoliciesPageState();
}
class _HotelPoliciesPageState extends State<HotelPoliciesPage> {

final List<String> contentList=[
  "Early Check In Allowed ?",
  "Late Check Out Allowed ?",
  "Are You Allow Un-Married Couple",
  "Are You Allow Bachelor or Student",
  "Free Cancelation",
  "Local ID Allowed?",
  "Aadhar Mandatory As ID?",
  "Smoking & Drinking Allowed?",
];
final List<String> value=[
  "All",
  "Vegetarian",
  "Non-Vegetarian"
];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "hotel Policies",
        isShadowShow: false,
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              padding: EdgeInsets.symmetric(horizontal: 16,vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.white
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 CustomText("Check In/Check Out",
                 fontSize: 12,
                 fontWeight: FontWeight.w400,
                 color: AppColors.mainTextColor,),
                  SizedBox(
                    height: SizeConfig.size8,
                  ),
                  Row(
                    children: [
                      Expanded(child: CommonTextField(
                        hintText: "Check In - 10:00",
                      )),
                     SizedBox(width: SizeConfig.size8,),
                      Expanded(child: CommonTextField(
                        hintText: "Check Out - 23:00",
                      )),
                    ],
                  ),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),
                  for(int i=0;i<contentList.length;i++)...[
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.whiteFE,
                      border: Border.all(
                        color: AppColors.greyE5
                      ),
                      boxShadow: [AppShadows.textFieldShadow],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12,vertical: 12),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText("${contentList[i]}",fontSize: 14,color: AppColors.mainTextColor,),
                        CustomToggleSwitch()
                      ],
                    ),
                  )
            ],
                  SizedBox(
                    height: SizeConfig.size10,
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.whiteFE,
                        border: Border.all(
                            color: AppColors.greyE5
                        ),
                      boxShadow: [AppShadows.textFieldShadow],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12,vertical: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText("Any Food Habit Restrictions",fontSize: 14,color: AppColors.mainTextColor,),
                            CustomToggleSwitch()
                          ],
                        ),
                        SizedBox(
                          height: SizeConfig.size10,
                        ),
                        CustomText("Kindly indicate which food habits you allow.",fontSize: 12,color: AppColors.mainTextColor,),
                        SizedBox(
                          height: SizeConfig.size10,
                        ),
                        for(int i=0;i<value.length;i++)...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Row(
                              children: [
                                Container(
                                  height: 12,
                                  width: 12,
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppColors.secondaryTextColor
                                      )
                                  ),
                                ),
                                SizedBox(
                                  width: 6,
                                ),
                                CustomText("${value[i]}",fontSize: 12,)
                              ],
                            ),
                          )
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    height: SizeConfig.size22,
                  ),
                  CustomText("+ Add More Restrictions",fontSize: 16,color: AppColors.primaryColor,),
                  SizedBox(
                    height: SizeConfig.size22,
                  ),
                  CustomBtn(onTap: (){}, title: "Submit",isValidate: true,),
                ],
              ),
            ),
            SizedBox(
              height: SizeConfig.size42,
            ),

          ],
        ),
      ),
    );
  }
}
