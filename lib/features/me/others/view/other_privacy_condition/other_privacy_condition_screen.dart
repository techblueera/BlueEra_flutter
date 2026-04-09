import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/others/controller/other_privacy_condition_controller.dart';
import 'package:BlueEra/features/me/others/model/otherTNC_model.dart';
import 'package:BlueEra/features/me/others/view/other_privacy_condition/other_privacy_condition_form_screen.dart';
import 'package:BlueEra/features/me/school/view/widget/add_more_icon_button.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtherPrivacyConditionScreen extends StatelessWidget {
  OtherPrivacyConditionScreen({super.key});

  final controller = Get.put(OtherPrivacyConditionController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.otherPrivacyTncTitle.tr,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Expanded(
              child: (controller.aboutList.isNotEmpty)
                  ? ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: controller.aboutList.length,
                      itemBuilder: (context, index) {
                        final item = controller.aboutList[index];
                        return _buildItemCard(context, item);
                      },
                    )
                  : Center(
                      child: CustomText(
                          AppStrings.otherNoPrivacyTncFound.tr)),
            ),
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                child: AddMoreIconButton(onTapEvent: () {
                  Get.to(OtherPrivacyConditionFormScreen());
                }),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildItemCard(BuildContext context, OtherTNCData item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.whiteE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomText(
                  item.title ?? "",
                  fontSize: 16,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const LocalAssets(
                      imagePath: AppIconAssets.editIcon,
                      imgColor: AppColors.black,
                    ),
                    onPressed: () => Get.to(OtherPrivacyConditionFormScreen(
                      item: item,
                    )),
                  ),
                  IconButton(
                    icon: const LocalAssets(
                      imagePath: AppIconAssets.deleteIcon,
                      imgColor: AppColors.black,
                    ),
                    onPressed: () async {
                      await showCommonDialog(
                          context: context,
                          text:
                              AppStrings.otherConfirmDeletePrivacyTnc.tr,
                          confirmCallback: () async {
                            Get.back();
                            await controller
                                .deleteOtherTNCController(item.sId!);
                          },
                          cancelCallback: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          confirmText: AppStrings.yes,
                          cancelText: AppStrings.no);
                    },
                    // controller.deleteAboutOrganisation(item.sId!),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 4),
          ExpandableText(
            text: item.description ?? "",
            trimLines: 2,
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
    );
  }
}
