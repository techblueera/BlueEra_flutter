import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/get_hotel_contact_us_res_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_branch_contact_controller.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_contact_us/hotel_branch_details_form_screen.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_contact_us/hotel_department_only_screen.dart';
import 'package:BlueEra/features/me/school/view/widget/add_more_icon_button.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../widgets/custom_text_cm.dart';

class HotelContactUs extends StatefulWidget {
  const HotelContactUs({super.key});

  @override
  State<HotelContactUs> createState() => _HotelContactUsState();
}

class _HotelContactUsState extends State<HotelContactUs> {
  final controller = Get.put(HotelBranchContactController());

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
        isShadowShow: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (controller.getHotelContactUsResponse.value.status ==
                    Status.COMPLETE) {
                  // if (controller.schoolContactUsData==null) {
                  //   return Center(child: CustomText("No Contact Us Found "));
                  // }
                  GetHotelContactUsResModel dataHotel =
                      controller.hotelContactUsData.value;

                  return CommonCardWidget(
                    child: Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            HotelContactUsData contactData =
                                dataHotel.data?[index] ?? HotelContactUsData();
                            return Container(
                              padding: EdgeInsets.all(8),
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.whiteE5)),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: iconTextRow(
                                            iconName: AppIconAssets.principal,
                                            value: contactData.email ?? ""),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          Get.to(HotelDepartmentOnlyScreen(
                                            contactInfo: contactData,
                                            isContactInfoEdit: true,
                                            branchId: contactData.id,
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
                                          if (dataHotel.data?.length == 1) {
                                            commonSnackBar(
                                                message: AppStrings
                                                    .minOneBranchRequired);
                                          } else {
                                            await showCommonDialog(
                                                context: context,
                                                text: AppStrings
                                                    .deleteBranchConfirm.tr,
                                                confirmCallback: () async {
                                                  await controller
                                                      .deleteHotelBranchDepartmentController(
                                                    departmentId:
                                                        contactData.id ?? "",
                                                  );
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
                                  SizedBox(
                                    height: SizeConfig.size5,
                                  ),
                                  if ((contactData.website ?? "").isNotEmpty)
                                    iconTextRow(
                                        iconName: AppIconAssets.website_click,
                                        value: contactData.website ?? "",
                                        isPrimary: true),
                                  if ((contactData.website ?? "").isNotEmpty)
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
                          itemCount: dataHotel.data?.length,
                        ),
                      ],
                    ),
                  );
                }
                if (controller.getHotelContactUsResponse.value.status ==
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
            // if (controller.schoolContactUsData?.value == null)
            AddMoreIconButton(
              onTapEvent: () {
                Get.to(HotelBranchDetailsFormScreen());
              },
              buttonName: AppStrings.addAnotherBranch.tr,
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
