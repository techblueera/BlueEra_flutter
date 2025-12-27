import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/add_documents_screen/add_documents_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/common_document_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widget/aadhar_card_widget.dart';
import '../widget/address_card_widget.dart';
import '../widget/pan_card_widget.dart';

class AddDocumentScreen extends StatelessWidget {
  const AddDocumentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AddDocumentsController>(
        init: AddDocumentsController(),
        builder: (Controller) {
          return Scaffold(
            appBar: CommonBackAppBar(
              title: AppStrings.addDocuments,
              isLeading: true,
            ),
            body: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size8,
                      vertical: SizeConfig.size15),
                  child: CustomFormCard(
                      // padding: EdgeInsets.zero,
                      padding: EdgeInsets.all(SizeConfig.size8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min ,
                        children: [
                          _buildAddButton(
                            title: "Add Bank Cancel Check",
                            status: true,
                            onTap: () {

                            },
                          ),
                          _buildAddButton(
                            title: "Upload Aadhar",
                            status: false,
                            onTap: () {
                              Get.bottomSheet(
                                CommonDocumentBottomSheet(
                                  title: AppStrings.aadharCard,
                                  child: AadharCardWidget(),
                                ),
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                              );
                            },
                          ),
                          _buildAddButton(
                            title: "Upload Pan",
                            status: false,
                            onTap: () {
                              Get.bottomSheet(
                                CommonDocumentBottomSheet(
                                  title: AppStrings.panCard,
                                  child: PanCardWidget(),
                                ),
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                              );
                            },
                          ),
                          _buildAddButton(
                            title: "Upload Address",
                            status: false,
                            onTap: () {
                              Get.bottomSheet(
                                CommonDocumentBottomSheet(
                                  title: AppStrings.addressProof,
                                  child: AddressCardWidget(),
                                ),
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                              );
                            },
                          ),
                        ],
                      )
                  ),
                )
            )

          );
        });
  }

  Widget _buildAddButton({
    required String title,
    required VoidCallback onTap,
    required bool status,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
            child: TextButton(
                onPressed: status ? null : onTap,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.add,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                SizedBox(width: SizeConfig.size8),
                Flexible(
                  child: CustomText(
                    title,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w400,
                    fontSize: SizeConfig.large,
                  ),
                ),
              ],
          ))),

        if (status)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
          child: LocalAssets(imagePath: AppIconAssets.green_tick_icon),
        ),
      ],
    );
  }

}
