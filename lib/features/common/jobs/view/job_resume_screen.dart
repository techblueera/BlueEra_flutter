import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class JobResumeScreen extends StatelessWidget {
  const JobResumeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: CommonBackAppBar(
        isCancelButton: true,
        onCancelTap: (){},
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header (logo, job title, subtitle)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    color: AppColors.white,
                    border: const Border(
                      bottom: BorderSide(
                        color: AppColors.white12,
                        width: 0.5,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.black25,
                          blurRadius: 6
                      )
                    ]
                ),
      
                child: Column(
                  children: [
                    CommonHorizontalDivider(),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15, vertical: SizeConfig.size18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: SizeConfig.size50,
                            width: SizeConfig.size50,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: SizedBox(
                              height: SizeConfig.size20,
                              width: SizeConfig.size20,
                              child: LocalAssets(
                                imagePath: AppIconAssets.scriptIcon,
                                height: SizeConfig.size25,
                                width: SizeConfig.size25,
                              ),
                            ),
                          ),
                          SizedBox(width: SizeConfig.size10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                "Wordpress Developer",
                                fontWeight: FontWeight.bold,
                                fontSize: SizeConfig.large,
                                color: AppColors.black28,
                              ),
                              SizedBox(height: SizeConfig.size4),
                              CustomText(
                                "OMM Digital Solution Opc",
                                color: AppColors.black28,
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w400,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size10),
        
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.small),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      color: AppColors.white,
                      border: Border.all(color: AppColors.white12, width: 0.5),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.black25,
                            blurRadius: 6
                        )
                      ]
                  ),
                  padding: EdgeInsets.all(SizeConfig.size12),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            color: AppColors.whiteCC,
                            border: Border.all(color: AppColors.white12, width: 0.5),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.black25,
                                  blurRadius: 6
                              )
                            ]
                        ),
                        padding: EdgeInsets.all(SizeConfig.size15),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(SizeConfig.size8),
                              child: LocalAssets(
                                imagePath: AppIconAssets.pdfIcon,
                                height: SizeConfig.size35,
                                width: SizeConfig.size35,
                              ),
                            ),
                            SizedBox(width: SizeConfig.size15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    "Sujoy Ghosh - CV - UI/UX Designer",
                                    color: AppColors.black28,
                                    fontWeight: FontWeight.bold,
                                    fontSize: SizeConfig.medium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: SizeConfig.size4),
                                  CustomText(
                                    "867 Kb · 14 Feb 2022 at 11:30 am",
                                    color: AppColors.blackA3,
                                    fontSize: SizeConfig.small,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.size12),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.0),
                            color: AppColors.whiteCC,
                            border: Border.all(color: AppColors.white12, width: 0.5),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.black25,
                                  blurRadius: 6
                              )
                            ]
                        ),
                        child: Column(
                          children: [
                            // Profile Section
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(12)),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: SizeConfig.size20,
                                horizontal: SizeConfig.size20,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    height: SizeConfig.size80,
                                    width: SizeConfig.size80,
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.white,
                                        width: 2,
                                        // adjust thickness
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: LocalAssets(imagePath: AppImageAssets.profileImage),
                                    ),
                                  ),
                                  SizedBox(height: SizeConfig.size10),
                                  CustomText(
                                    "Sujoy Ghosh",
                                    fontWeight: FontWeight.bold,
                                    fontSize: SizeConfig.medium,
                                    color: AppColors.white,
                                  ),
                                  SizedBox(height: SizeConfig.size4),
                                  CustomText(
                                    "UI/UX Designer",
                                    color: AppColors.white,
                                    fontSize: SizeConfig.medium,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                              color: AppColors.whiteCC,
      
                                borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(12)),
                              ),
                              padding: EdgeInsets.all(SizeConfig.size15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    "Basic Details",
                                    fontWeight: FontWeight.bold,
                                    fontSize: SizeConfig.large,
                                    color: AppColors.black28,
                                  ),
                                  SizedBox(height: SizeConfig.size15),
                                  _infoRow("Location:", "West Bengal"),
                                  _infoRow("D.O.B:", "01/01/1990"),
                                  _infoRow("Phone:", "1234567890"),
                                  _infoRow("Email:", "sujoyghosh.cv@gmail.com"),
        
                                  // Divider
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: SizeConfig.size15),
                                    child: Divider(
                                      color: AppColors.grey9A,
                                      thickness: 1,
                                      height: 1,
                                    ),
                                  ),
        
                                  CustomText(
                                    "About me:",
                                    fontWeight: FontWeight.bold,
                                    fontSize: SizeConfig.large,
                                    color: AppColors.black28,
                                  ),
                                  SizedBox(height: SizeConfig.size15),
                                  CustomText(
                                    "Jorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis.",
                                    color: AppColors.blackA3,
                                    fontSize: SizeConfig.medium,
                                  ),
        
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: SizeConfig.size15),
                                    child: Divider(
                                      color: AppColors.grey9A,
                                      thickness: 1,
                                      height: 1,
                                    ),
                                  ),
        
                                  CustomText(
                                    "Declaration:",
                                    fontWeight: FontWeight.bold,
                                    fontSize: SizeConfig.large,
                                    color: AppColors.black28,
                                  ),
                                  SizedBox(height: SizeConfig.size15),
                                  CustomText(
                                    "I certify that all information provided above is complete and correct to the best of my knowledge & belief",
                                    color: AppColors.blackA3,
                                    fontSize: SizeConfig.medium,
                                  ),
                                  SizedBox(height: SizeConfig.size4),
                                  CustomText(
                                    "Date created: 11 May 2025",
                                    color: AppColors.grey9A,
                                    fontSize: SizeConfig.small,
                                  ),
        
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size15),
                                    child: Divider(
                                      color: AppColors.grey9A,
                                      thickness: 1,
                                      height: 1,
                                    ),
                                  ),
        
                                  CustomText(
                                    "Education:",
                                    fontWeight: FontWeight.bold,
                                    fontSize: SizeConfig.large,
                                    color: AppColors.black28,
                                  ),
                                  SizedBox(height: SizeConfig.size15),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _eduExpEntry(
                                        "School of Design and Media",
                                        "Professional diploma in design and digital business (2022-2024)",
                                      ),
                                      SizedBox(height: SizeConfig.size8),
                                      _eduExpEntry(
                                        "School of Design and Media",
                                        "Professional diploma in design and digital business (2022-2024)",
                                      ),
                                    ],
                                  ),
        
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: SizeConfig.size15),
                                    child: Divider(
                                      color: AppColors.grey9A,
                                      thickness: 1,
                                      height: 1,
                                    ),
                                  ),
        
                                  CustomText(
                                    "Experience:",
                                    fontWeight: FontWeight.bold,
                                    fontSize: SizeConfig.large,
                                    color: AppColors.black28,
                                  ),
                                  SizedBox(height: SizeConfig.size15),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _eduExpEntry(
                                        "BlueCS Limited",
                                        "UI/UX Designer  (2024–2025)",
                                      ),
                                      SizedBox(height: SizeConfig.size8),
                                      _eduExpEntry(
                                        "BlueCS Limited",
                                        "UI/UX Designer  (2024–2025)",
                                      ),
                                    ],
                                  ),
        
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: SizeConfig.size15),
                                    child: Divider(
                                      color: AppColors.grey9A,
                                      thickness: 1,
                                      height: 1,
                                    ),
                                  ),
        
                                  CustomText(
                                    "Key Skills:",
                                    fontWeight: FontWeight.bold,
                                    fontSize: SizeConfig.large,
                                    color: AppColors.black28,
                                  ),
                                  SizedBox(height: SizeConfig.size15),
                                  Column(
                                    children: [
                                      _skillsRow("UI/UX Design", "Logo Design"),
                                      SizedBox(height: SizeConfig.size8),
                                      _skillsRow(
                                          "Product Design", "Graphic Design"),
                                      SizedBox(height: SizeConfig.size8),
                                      _skillsRow("Web Design", "UX Research"),
                                      SizedBox(height: SizeConfig.size8),
                                      _skillsRow("App Design", "Banner Design"),
                                    ],
                                  ),
        
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: SizeConfig.size15),
                                    child: Divider(
                                      color: AppColors.grey9A,
                                      thickness: 1,
                                      height: 1,
                                    ),
                                  ),
        
                                  CustomText(
                                    "Language:",
                                    fontWeight: FontWeight.bold,
                                    fontSize: SizeConfig.large,
                                    color: AppColors.black28,
                                  ),
                                  SizedBox(height: SizeConfig.size8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustomText("Hindi",
                                          color: AppColors.blackA3,
                                          fontSize: SizeConfig.medium),
                                      SizedBox(height: SizeConfig.size8),
                                      CustomText("Bengali",
                                          color: AppColors.blackA3,
                                          fontSize: SizeConfig.medium),
                                      SizedBox(height: SizeConfig.size8),
                                      CustomText("English",
                                          color: AppColors.blackA3,
                                          fontSize: SizeConfig.medium),
                                      SizedBox(height: SizeConfig.size8),
                                    ],
                                  ),
        
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: SizeConfig.size15),
                                    child: Divider(
                                      color: AppColors.grey9A,
                                      thickness: 1,
                                      height: 1,
                                    ),
                                  ),
        
                                  CustomText(
                                    "Portfolio Links:",
                                    fontWeight: FontWeight.bold,
                                    fontSize: SizeConfig.large,
                                    color: AppColors.black28,
                                  ),
                                  SizedBox(height: SizeConfig.size15),
                                  _linkRow("Behance:",
                                      "http://www.annoyingpopups.com/"),
                                  SizedBox(height: SizeConfig.size8),
                                  _linkRow("Instagram:",
                                      "http://www.annoyingpopups.com/"),
                                  SizedBox(height: SizeConfig.size8),
                                  _linkRow("Facebook:",
                                      "http://www.annoyingpopups.com/"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        
              SizedBox(height: SizeConfig.size25),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomBtn(
                        onTap: () {
                          Navigator.pushNamed(
                            context, RouteHelper.getJobQnaScreenRoute(),
                          );
                        },
                        title: "Continue",
                        isValidate: true,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size12),
                    Expanded(
                      child: CustomBtn(
                        onTap: () {},
                        title: "Edit",
                        isValidate: false,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size30),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widgets
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: SizeConfig.size120,
            child: CustomText(
              label,
              fontWeight: FontWeight.w600,
              color: AppColors.black28,
              fontSize: SizeConfig.medium,
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              value,
              color: AppColors.blackA3,
              fontSize: SizeConfig.medium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkRow(String label, String url) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size4),
      child: Row(
        children: [
          SizedBox(
            width: SizeConfig.size100,
            child: CustomText(
              label,
              color: AppColors.black28,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              url,
              color: AppColors.primaryColor,
              fontSize: SizeConfig.medium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eduExpEntry(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title,
          fontWeight: FontWeight.w600,
          color: AppColors.black28,
          fontSize: SizeConfig.medium,
        ),
        SizedBox(height: SizeConfig.size2),
        CustomText(
          subtitle,
          color: AppColors.blackA3,
          fontSize: SizeConfig.small,
        ),
      ],
    );
  }

  Widget _skillsRow(String left, String right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomText(
            left,
            color: AppColors.black28,
            fontSize: SizeConfig.medium,
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: CustomText(
            right,
            color: AppColors.blackA3,
            fontSize: SizeConfig.medium,
          ),
        ),
      ],
    );
  }
}
