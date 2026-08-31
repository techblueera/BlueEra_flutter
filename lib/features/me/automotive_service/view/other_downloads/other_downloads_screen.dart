import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/automotive_service/controller/other_downloads_controller.dart';
import 'package:BlueEra/features/me/others/model/other_downloads_model.dart';
import 'package:BlueEra/features/me/automotive_service/view/other_downloads/other_downloads_form_screen.dart';
import 'package:BlueEra/features/me/school/view/widget/add_more_icon_button.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtherDownloadsScreen extends StatelessWidget {
  OtherDownloadsScreen({super.key});

  final controller = Get.find<OtherDownloadsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.otherDownloadsTitle.tr,
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
                      child: CustomText(AppStrings.otherNoDownloadsFound.tr)),
            ),
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                child: AddMoreIconButton(onTapEvent: () {
                  Get.to(() => OtherDownloadsFormScreen());
                }),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildItemCard(BuildContext context, OtherDownloadsData item) {
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
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            InkWell(
              onTap: () {
                navigatePushTo(
                  context,
                  ImageViewScreen(
                    subTitle: item.description,
                    appBarTitle: AppStrings.imageViewer,
                    imageUrls: [item.imageUrl ?? ""],
                    initialIndex: 0,
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          const SizedBox(height: 8),
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
                    onPressed: () => Get.to(() => OtherDownloadsFormScreen(
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
                          text: AppStrings.otherConfirmDeleteDownload.tr,
                          confirmCallback: () async {
                            Get.back();
                            await controller
                                .deleteDownloadsController(item.sId!);
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
