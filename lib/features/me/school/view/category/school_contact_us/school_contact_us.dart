import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/school_contact_us_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/category/school_contact_us/branch_details_form_screen.dart';
import 'package:BlueEra/features/me/school/view/category/school_contact_us/branch_only_screen.dart';
import 'package:BlueEra/features/me/school/view/category/school_contact_us/department_only_screen.dart';
import 'package:BlueEra/features/me/school/view/widget/add_more_icon_button.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../widgets/custom_text_cm.dart';

class SchoolContactUs extends StatefulWidget {
  const SchoolContactUs({super.key});

  @override
  State<SchoolContactUs> createState() => _SchoolContactUsState();
}

class _SchoolContactUsState extends State<SchoolContactUs> {
  final schoolAboutUsController = Get.find<SchoolAboutUsController>();

  @override
  void initState() {
    // TODO: implement initState
    schoolAboutUsController.getBranchDetailsController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Contact Us",
        isShadowShow: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Obx(() {
              if (schoolAboutUsController
                      .getSchoolContactUsResponse.value.status ==
                  Status.COMPLETE) {
                return Expanded(
                  child: SingleChildScrollView(
                    child: CommonCardWidget(
                      child: Column(
                        children: [
                          /// Course Card
                          Row(
                            children: [
                              CustomText(
                                "Branch: ",
                                color: AppColors.secondaryTextColor,
                                fontSize: SizeConfig.large,
                              ),
                              Expanded(
                                  child: CustomText(
                                "${schoolAboutUsController.schoolContactUsData?.value.branch}",
                                color: AppColors.secondaryTextColor,
                                fontSize: SizeConfig.large,
                                fontWeight: FontWeight.w600,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
                              InkWell(
                                onTap: () {
                                  Get.to(BranchOnlyScreen());
                                },
                                child: LocalAssets(
                                  imagePath: AppIconAssets.editIcon,
                                  imgColor: AppColors.black,
                                ),
                              )
                            ],
                          ),
                          iconTextRow(
                              iconName: AppIconAssets.website_click,
                              isPrimary: true,
                              value:
                                  '${schoolAboutUsController.schoolContactUsData?.value.website}'),
                          SizedBox(
                            height: SizeConfig.size5,
                          ),

                          iconTextRow(
                              iconName: AppIconAssets.location_new,
                              value:
                                  '${schoolAboutUsController.schoolContactUsData?.value.address}'),
                          const SizedBox(height: 20),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              ContactInfo data = schoolAboutUsController
                                      .schoolContactUsData
                                      ?.value
                                      .contactInfo?[index] ??
                                  ContactInfo();
                              return Container(
                                padding: EdgeInsets.all(8),
                                margin: EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: AppColors.whiteE5)),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: iconTextRow(
                                              iconName: AppIconAssets.principal,
                                              value: data.title ?? ""),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            Get.to(DepartmentOnlyScreen());
                                          },
                                          child: LocalAssets(
                                            imagePath: AppIconAssets.editIcon,
                                            imgColor: AppColors.black,
                                          ),
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                      height: SizeConfig.size5,
                                    ),
                                    iconTextRow(
                                        iconName: AppIconAssets.email,
                                        value: data.email ?? ""),
                                    SizedBox(
                                      height: SizeConfig.size5,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: iconTextRow(
                                              iconName: AppIconAssets.call,
                                              value: data.phone ?? ""),
                                        ),
                                        LocalAssets(
                                          imagePath: AppIconAssets.chat,
                                          imgColor: AppColors.black,
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                            itemCount: schoolAboutUsController
                                .schoolContactUsData?.value.contactInfo?.length,
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: Icon(
                                Icons.add,
                                color: AppColors.primaryColor,
                              ),
                              label: CustomText(
                                "Add More Department",
                                color: AppColors.primaryColor,
                              ),
                              onPressed: () {
                                Get.to(DepartmentOnlyScreen());
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }
              if (schoolAboutUsController
                      .getSchoolContactUsResponse.value.status ==
                  Status.ERROR) {
                return CustomText(AppStrings.somethingWentWrong);
              }
              return SizedBox();
            }),
            SizedBox(
              height: SizeConfig.size10,
            ),

            /// Add More Course Button
            AddMoreIconButton(
              onTapEvent: () {
                Get.to(BranchDetailsFormScreen());
              },
              buttonName: "Add Another Branch",
            ),
            SizedBox(
              height: SizeConfig.size25,
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable Row Widget
  Widget iconTextRow(
      {required String iconName,
      required String value,
      bool? isPrimary = false}) {
    return Row(
      children: [
        LocalAssets(
          imagePath: iconName,
          imgColor:
              (isPrimary ?? false) ? AppColors.primaryColor : AppColors.black,
        ),
        SizedBox(
          width: SizeConfig.size10,
        ),
        Expanded(
            child: CustomText(
          value,
          color: (isPrimary ?? false)
              ? AppColors.primaryColor
              : AppColors.secondaryTextColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )),
      ],
    );
  }
}
