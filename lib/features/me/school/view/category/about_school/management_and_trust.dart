import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/managment_trust_form_screen.dart';
import 'package:BlueEra/features/me/school/view/widget/add_more_icon_button.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/network_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/api/model/school_about_us_model.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_icon_assets.dart';
import '../../../../../../widgets/common_back_app_bar.dart';
import '../../../../../../widgets/custom_text_cm.dart';
import '../../../../hospital/view/widget/general_medicine.dart';

class ManagementAndTrust extends StatefulWidget {
  ManagementAndTrust({super.key});

  @override
  State<ManagementAndTrust> createState() => _ManagementAndTrustState();
}

class _ManagementAndTrustState extends State<ManagementAndTrust> {
  final schoolAboutUsController = Get.find<SchoolAboutUsController>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    schoolAboutUsController.getSchoolAboutUsController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Management / Trust",
      ),
      body: SafeArea(
        child: Column(
          children: [
            Obx(() {
              if (schoolAboutUsController
                      .aboutUsData?.value.management?.isNotEmpty ??
                  false) {
                return Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: schoolAboutUsController
                            .aboutUsData?.value.management?.length ??
                        0,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      Management? data = schoolAboutUsController
                          .aboutUsData?.value.management?[index];
                      return Material(
                        color: Colors.transparent,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Doctor Image
                              Expanded(child: NetWorkOcToAssets(imgUrl: data?.photo ?? "",height: 140,)),
                              const SizedBox(width: 12),

                              /// Details
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// Name + Menu
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomText(data?.name,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.mainTextColor),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            Get.to(ManagementTrustFormScreen(
                                              isEdit: true,management: data,
                                              editItemIndex: index,
                                            ));
                                          },
                                          child: const Icon(Icons.edit,
                                              size: 20,
                                              color: AppColors.mainTextColor),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: AppColors.greyE5,
                                              width: 1)),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (data?.qualification?.isNotEmpty ??
                                              false)
                                            CustomText(
                                                data?.qualification
                                                    ?.map((e) => e)
                                                    .toList()
                                                    .join(", "),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w400,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                color: AppColors
                                                    .secondaryTextColor),
                                          const SizedBox(height: 6),
                                          CustomText(data?.position,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w400,
                                              color:
                                                  AppColors.secondaryTextColor),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomText(
                                                  "Message: ${data?.bio}",
                                                  fontSize: 10,
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              return CustomText("No Management found yet! ");
            }),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size5, vertical: SizeConfig.size10),
              child: AddMoreIconButton(
                onTapEvent: () {
                  Get.to(ManagementTrustFormScreen(
                    isEdit: false,
                  ));
                },
              ),
            ),
            SizedBox(
              height: SizeConfig.size16,
            )
          ],
        ),
      ),
    );
  }
}
