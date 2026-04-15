import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Reusable website card for earn-service home pages.
///
/// Mirrors the business [WebsiteTab] layout:
/// - Empty: centered globe + "Add Website" CTA.
/// - Filled: URL bar with Update button + inline webview of the URL.
class EarnServiceWebsiteCard extends StatelessWidget {
  final EarnProfileController controller;
  final double webViewHeight;

  const EarnServiceWebsiteCard({
    super.key,
    required this.controller,
    this.webViewHeight = 320,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final url = controller.earnProfile.value?.website ?? '';
      final hasUrl = url.isNotEmpty;

      return CustomFormCard(
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(top: 10),
        child: hasUrl
            ? _buildFilled(context, url)
            : _buildEmpty(context),
      );
    });
  }

  Widget _buildFilled(BuildContext context, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppColors.white,
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12,
            vertical: SizeConfig.size8,
          ),
          child: Row(
            children: [
              const Icon(Icons.language_rounded,
                  size: 18, color: AppColors.primaryColor),
              SizedBox(width: SizeConfig.size8),
              Expanded(
                child: InkWell(
                  onTap: () => launchURL(url),
                  child: CustomText(
                    url,
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.size8),
              GestureDetector(
                onTap: () => _openUpdateSheet(context),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size10,
                    vertical: SizeConfig.size4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryColor),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: CustomText(
                    'Update',
                    fontSize: SizeConfig.extraSmall,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.greyE5),
        SizedBox(
          height: webViewHeight,
          child: CommonWebView(
            urlLink: url,
            urlTitle: '',
            hideAppBar: true,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size24),
      child: Center(
        child: GestureDetector(
          onTap: () => _openUpdateSheet(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language_rounded,
                size: 64,
                color: AppColors.greyE5,
              ),
              SizedBox(height: SizeConfig.size15),
              CustomText(
                'Add Website',
                fontSize: SizeConfig.large,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openUpdateSheet(BuildContext context) {
    final websiteCtrl = TextEditingController(
      text: controller.earnProfile.value?.website ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (ctx) => GestureDetector(
        onTap: () => FocusScope.of(ctx).unfocus(),
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16,
              vertical: SizeConfig.size16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    CustomText('Update Website',
                        fontSize: 18, fontWeight: FontWeight.w600),
                    CloseButton(),
                  ],
                ),
                const SizedBox(height: 20),
                HttpsTextField(
                  controller: websiteCtrl,
                  title: 'Website URL',
                  hintText: 'e.g. https://www.example.com',
                  isUrlValidate: true,
                ),
                const SizedBox(height: 24),
                CustomBtn(
                  radius: 10,
                  bgColor: AppColors.primaryColor,
                  title: AppStrings.save,
                  onTap: () async {
                    final error = ValidationMethod.urlValidation(
                        websiteCtrl.text.trim());
                    if (error != null) {
                      commonSnackBar(message: error);
                      return;
                    }
                    final ok = await controller.patchEarnProfile({
                      'website': websiteCtrl.text.trim(),
                    });
                    if (ok && ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
