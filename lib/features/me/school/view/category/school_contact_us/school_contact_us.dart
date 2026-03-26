import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/school_contact_us_res_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/others/model/business_profile_full_model.dart';
import 'package:BlueEra/features/me/school/controller/branch_contact_controller.dart';
import 'package:BlueEra/features/me/school/view/category/school_contact_us/branch_details_form_screen.dart';
import 'package:BlueEra/features/me/school/view/category/school_contact_us/branch_only_screen.dart';
import 'package:BlueEra/features/me/school/view/category/school_contact_us/department_only_screen.dart';
import 'package:BlueEra/features/me/school/view/widget/add_more_icon_button.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
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
  final controller = Get.put(BranchContactController());

  @override
  void initState() {
    // TODO: implement initState
    controller.getBranchDetailsController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.contactUs,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (controller.getSchoolContactUsResponse.value.status ==
                    Status.COMPLETE) {
                  if (controller.schoolContactUsData?.isEmpty ?? false) {
                    return Center(child: CustomText(AppStrings.noContactsFound));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      SchoolContactUsData data =
                          controller.schoolContactUsData?[index] ??
                              SchoolContactUsData();

                      return CommonCardWidget(
                        child: Column(
                          children: [
                            /// Course Card
                            Row(
                              children: [
                                CustomText(
                                  "${AppStrings.branchName.tr}: ",
                                  color: AppColors.secondaryTextColor,
                                  fontSize: SizeConfig.large,
                                ),
                                Expanded(
                                    child: CustomText(
                                  "${data.branch?.name}",
                                  color: AppColors.secondaryTextColor,
                                  fontSize: SizeConfig.large,
                                  fontWeight: FontWeight.w600,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )),
                                InkWell(
                                  onTap: () {
                                    Get.to(BranchOnlyScreen(schoolContactUsData: data,));
                                  },
                                  child: LocalAssets(
                                    imagePath: AppIconAssets.editIcon,
                                    imgColor: AppColors.black,
                                  ),
                                ),
                                SizedBox(
                                  width: SizeConfig.size10,
                                ),
                                InkWell(
                                  onTap: () async {
                                    if (controller
                                            .schoolContactUsData?.length ==
                                        1) {
                                      commonSnackBar(
                                          message:
                                          AppStrings.minOneBranchRequired);
                                    } else {
                                      await showCommonDialog(
                                          context: context,
                                          text:
                                          AppStrings.deleteBranchConfirm,
                                          confirmCallback: () async {
                                            await controller
                                                .deleteSchoolBranchController(
                                                    contactId: data.id ?? "");
                                          },
                                          cancelCallback: () {
                                            Navigator.of(context)
                                                .pop(); // Close the dialog
                                          },
                                          confirmText: AppStrings.yes,
                                          cancelText: AppStrings.no);
                                    }
                                  },
                                  child: LocalAssets(
                                    imagePath: AppIconAssets.deleteIcon,
                                    imgColor: AppColors.red00,
                                  ),
                                ),
                              ],
                            ),
                            iconTextRow(
                                iconName: AppIconAssets.website_click,
                                isPrimary: true,
                                value: '${data.branch?.website}'),
                            SizedBox(
                              height: SizeConfig.size5,
                            ),

                            iconTextRow(
                                iconName: AppIconAssets.location_new,
                                value: '${data.branch?.location?.name}'),
                            const SizedBox(height: 20),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                OtherProfileDepartments contactData =
                                    data.departments?[index] ?? OtherProfileDepartments();
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
                                                iconName:
                                                    AppIconAssets.principal,
                                                value: contactData.department ??
                                                    ""),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              Get.to(DepartmentOnlyScreen(
                                                contactInfo: contactData,
                                                isContactInfoEdit: true,
                                                branchId: data.id,
                                              ));
                                            },
                                            child: LocalAssets(
                                              imagePath: AppIconAssets.editIcon,
                                              imgColor: AppColors.black,
                                            ),
                                          ),
                                          SizedBox(
                                            width: SizeConfig.size10,
                                          ),
                                          InkWell(
                                            onTap: () async {
                                              if (data.departments?.length ==
                                                  1) {
                                                commonSnackBar(
                                                    message:
                                                    AppStrings.minOneDeptRequired);
                                              } else {
                                                await showCommonDialog(
                                                    context: context,
                                                    text:
                                                    AppStrings. deleteDeptConfirm,
                                                    confirmCallback: () async {
                                                      await controller
                                                          .deleteSchoolBranchDepartmentController(
                                                              departmentId:
                                                                  contactData
                                                                          .id ??
                                                                      "",
                                                              contactId:
                                                                  data.id ??
                                                                      "");
                                                    },
                                                    cancelCallback: () {
                                                      Navigator.of(context)
                                                          .pop(); // Close the dialog
                                                    },
                                                    confirmText: AppStrings.yes,
                                                    cancelText: AppStrings.no);
                                              }
                                            },
                                            child: LocalAssets(
                                              imagePath:
                                                  AppIconAssets.deleteIcon,
                                              imgColor: AppColors.red00,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: SizeConfig.size5,
                                      ),
                                      iconTextRow(
                                          iconName: AppIconAssets.email,
                                          value: contactData.email ?? ""),
                                      SizedBox(
                                        height: SizeConfig.size5,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: iconTextRow(
                                                iconName: AppIconAssets.call,
                                                value: contactData.phone ?? ""),
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
                              itemCount: data.departments?.length,
                            ),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: Icon(
                                  Icons.add,
                                  color: AppColors.primaryColor,
                                ),
                                label: CustomText(
                                  AppStrings.addMoreDepartment,
                                  color: AppColors.primaryColor,
                                ),
                                onPressed: () {
                                  Get.to(DepartmentOnlyScreen(
                                    branchId: data.id,
                                  ));
                                },
                              ),
                            )
                          ],
                        ),
                      );
                    },
                    itemCount: controller.schoolContactUsData?.length,
                  );
                }
                if (controller.getSchoolContactUsResponse.value.status ==
                    Status.ERROR) {
                  return CustomText(AppStrings.somethingWentWrong);
                }
                return SizedBox();
              }),
            ),
            SizedBox(
              height: SizeConfig.size10,
            ),

            /// Add More Course Button
            AddMoreIconButton(
              onTapEvent: () {
                Get.to(BranchDetailsFormScreen());
              },
              buttonName: AppStrings.addAnotherBranch
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
