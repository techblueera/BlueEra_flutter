import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/local_assets.dart';
import '../../controller/hospital_model_controller.dart';
import '../../model/get_contact_us_details_model.dart';
import '../widget/add_contact_us_details.dart';

class ContactUsDetailsPage extends StatefulWidget {
  const ContactUsDetailsPage({super.key,});


  @override
  State<ContactUsDetailsPage> createState() => _ContactUsDetailsPageState();
}

class _ContactUsDetailsPageState extends State<ContactUsDetailsPage> {
  final controller = getOrPut(() => HospitalModelController());

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller.getContactUsDetails();
 }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Contact Us",
      ),
      body: Obx(() {
        if(controller.getContactUsResponse.value.status==Status.COMPLETE){
          final details =controller.getContactUsResponse.value.data as HospitalContactUsDetailsModel;
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child:
                          CustomText("${details.hospitalName}",fontSize: 16,fontWeight: FontWeight.w600,)
                          ),
                          InkWell(
                            onTap: (){
                              AddContactUsDetailsDialog.showHospitalNameEdit(context: context, preName: details.hospitalName??'');
                            },
                            child: LocalAssets(imagePath: AppIconAssets.pen_line
                              , height: 16, width: 16,),
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size8,),
                      Row(
                        children: [
                          LocalAssets(imagePath: AppIconAssets.link_pref_profile
                            , height: 16, width: 16,),
                          SizedBox(
                            width: SizeConfig.size6,
                          ),
                          Expanded(child:
                          CustomText(
                            "${details.website}",
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          color: AppColors.primaryColor,
                          )),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size8,),
                      Row(
                        children: [
                          LocalAssets(
                            imagePath: AppIconAssets.location_new
                            , height: 16, width: 16,),
                          SizedBox(
                            width: SizeConfig.size6,
                          ),
                          Expanded(child:
                          CustomText(
                            "${details.address}",
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.black,
                          )),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size8,),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.whiteE5)
                        ),
                        padding: EdgeInsets.all(10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText("Admission Cell Number ",fontSize: 14,fontWeight: FontWeight.w600,),
                            SizedBox(height: SizeConfig.size8,),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    LocalAssets(
                                      imagePath: AppIconAssets.chat_call
                                      , height: 16, width: 16,),
                                    SizedBox(
                                      width: SizeConfig.size6,
                                    ),
                                    CustomText(
                                      "${details.admissionPhone}",
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.black,
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: (){
                                 AddContactUsDetailsDialog.showHospitalAdmissionEdit(context: context,preName: details.admissionPhone??'');
                                  },
                                  child: LocalAssets(imagePath: AppIconAssets.pen_line
                                    , height: 16, width: 16,),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.size10,),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.whiteE5)
                        ),
                        padding: EdgeInsets.all(10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText("Principal Number ",fontSize: 14,fontWeight: FontWeight.w600,),
                            SizedBox(height: SizeConfig.size8,),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    LocalAssets(
                                      imagePath: AppIconAssets.chat_call
                                      , height: 16, width: 16,),
                                    SizedBox(
                                      width: SizeConfig.size6,
                                    ),
                                    CustomText(
                                      "${details.principalPhone}",
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.black,
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: (){
                                 AddContactUsDetailsDialog.showHospitalPrincipalEdit(
                                   context: context,
                                   preName: details.principalPhone??''
                                 );
                                  },
                                  child: LocalAssets(imagePath: AppIconAssets.pen_line
                                    , height: 16, width: 16,),
                                ),
                              ],
                            ),
                            SizedBox(height: SizeConfig.size10,),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    LocalAssets(
                                      imagePath: AppIconAssets.mail_new
                                      , height: 16, width: 16,),
                                    SizedBox(
                                      width: SizeConfig.size6,
                                    ),
                                    CustomText(
                                      "${details.email}",
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.black,
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: (){
                                    AddContactUsDetailsDialog.showHospitalEmailEdit(
                                        context: context,
                                        preName: details.email??''
                                    );
                                  },
                                  child: LocalAssets(imagePath: AppIconAssets.pen_line
                                    , height: 16, width: 16,),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.size20,),
                if(details.id==null)
                InkWell(
                  onTap: () {
                    AddContactUsDetailsDialog.showAddContactUs(context: context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryColor),
                      color: AppColors.primaryColor.withOpacity(0.1),
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: 14, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline,
                          color: AppColors.primaryColor,),
                        SizedBox(width: SizeConfig.size6,),
                        CustomText(
                          "Add More Details",
                          fontSize: 14,
                          textAlign: TextAlign.center,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }else if(controller.getContactUsResponse.value.status==Status.ERROR){

          return Center(
            child: CustomText("${controller.getContactUsResponse.value.message}"),
          );
        }else{
          return Center(
            child: CircularProgressIndicator(),
          );
        }

      }),
    );
  }

  /// 🔥 Converts `emergencyPhone` → `Emergency Phone`
  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAllMapped(
      RegExp(r'[A-Z]'),
          (match) => ' ${match.group(0)}',
    )
        .split(' ')
        .map((e) =>
    e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1))
        .join(' ')
        .trim();
  }
}
