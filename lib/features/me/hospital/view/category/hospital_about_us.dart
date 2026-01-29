import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../../widgets/expandable_text.dart';
import '../../../../../widgets/local_assets.dart';
import '../../../widget/no_product_profile.dart';
import '../../controller/hospital_model_controller.dart';
import '../widget/add_contact_us_details.dart';


class HospitalAboutUs extends StatefulWidget {
  const HospitalAboutUs(
      {super.key, required this.categoryId, required this.title, required this.type});
  final String categoryId;
  final String title;
  final String type;

  @override
  State<HospitalAboutUs> createState() => _HospitalAboutUsState();
}

class _HospitalAboutUsState extends State<HospitalAboutUs> {
  final controller = getOrPut(() => HospitalModelController());
  @override
  void initState() {
    // TODO: implement initState
      controller.getAboutUs();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: widget.title,
        isShadowShow: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Obx(() {
            if (controller.getHospitalAboutUsResponse.value.status ==
                Status.COMPLETE) {
              final details =controller.hospitalAboutUsModel.value;
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      SizedBox(height: SizeConfig.size20,),
                     if(details.visionMission!="")
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.blue.shade300,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.45),
                                blurRadius: 12,
                                spreadRadius: -6,
                              ),
                            ],
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  LocalAssets(height: 25,
                                      width: 25,
                                      imagePath: AppIconAssets
                                          .hospitalVisionIcon),
                                  SizedBox(width: SizeConfig.size10,),
                                  CustomText(
                                    "Vision & Mission", fontSize: 18,
                                    fontWeight: FontWeight.w600,),
                                ],
                              ),
                              //
                              SizedBox(height: 10,),
                              Container(
                                height: 1,
                                color: AppColors.whiteE5,
                              ),
                              SizedBox(height: 10,),
                              ExpandableText(
                                text: details.visionMission??'',
                                trimLines: 6,
                                isReadMoreNewLine: false,
                                expandMode: ExpandMode.dialog,
                                style: TextStyle(
                                  color: AppColors.secondaryTextColor,
                                  fontSize: SizeConfig.large,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: AppConstants.OpenSans,
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: SizeConfig.size20,),
                      if(details.history!="")
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.blue.shade300,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.45),
                                blurRadius: 12,
                                spreadRadius: -6,
                              ),
                            ],
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  LocalAssets(height: 25,
                                      width: 25,
                                      imagePath: AppIconAssets
                                          .hospitalHistoryIcon),
                                  SizedBox(width: SizeConfig.size10,),
                                  CustomText("History", fontSize: 18,
                                    fontWeight: FontWeight.w600,),
                                ],
                              ),
                              SizedBox(height: 10,),
                              Container(
                                height: 1,
                                color: AppColors.whiteE5,
                              ),
                              SizedBox(height: 10,),
                              ExpandableText(
                                text:details.history??'',
                                trimLines: 6,
                                isReadMoreNewLine: false,
                                expandMode: ExpandMode.dialog,
                                style: TextStyle(
                                  color: AppColors.secondaryTextColor,
                                  fontSize: SizeConfig.large,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: AppConstants.OpenSans,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      if(details.visionMission==""&&details.history=="")
                        Padding(
                          padding: const EdgeInsets.only(top: 30.0),
                          child: NoProfileDetailsFound(
                              content: "No Details Found Under ${widget.title}"),
                        ),
                      SizedBox(height: SizeConfig.size20,),
                      InkWell(
                        onTap: () {
                         if ((details.visionMission==""&&details.history=="")){
                           AddContactUsDetailsDialog.addAboutUsDetailsPage(
                               context: context,

                           );
                         }else{
                           AddContactUsDetailsDialog.addAboutUsDetailsPage(
                               context: context,
                               preVision:details.visionMission??'',
                               preHistory:details.history,
                           );
                         }

                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 0),
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
                              ((details.visionMission==""&&details.history==""))?Icon(Icons.add_circle_outline,
                                color: AppColors.primaryColor,):
                              LocalAssets(imagePath: AppIconAssets.pen_line
                                , height: 16, width: 16,imgColor: AppColors.primaryColor,),
                              SizedBox(width: SizeConfig.size10,),
                              CustomText(
                                ((details.visionMission==""&&details.history==""))? "Add More ${widget.title}":"Edit About Us",
                                fontSize: 14,
                                textAlign: TextAlign.center,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: SizeConfig.size50,),
                    ],
                  ),
                ),
              );
            } else if (controller.getHospitalAboutUsResponse.value.status ==
                Status.INITIAL) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              return Center(
                child: CustomText("Please try sometime"),
              );
            }
          }),
        ),
      ),
    );
  }
}
