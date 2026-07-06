import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Dedicated "Website" card for the Me-home Overview tabs.
///
/// Shows the current website (tappable → opens it) or an "Add Website" prompt,
/// with an Edit/Add affordance that opens an inline dialog. The owning screen
/// supplies the current [websiteUrl] and an [onSave] callback that persists the
/// new value (e.g. `controller.updateBusinessProfileDetails({ApiKeys.websiteUrl: url})`).
class WebsiteOverviewCard extends StatelessWidget {
  const WebsiteOverviewCard({
    super.key,
    required this.websiteUrl,
    required this.onSave,
  });

  final String? websiteUrl;

  /// Persists the entered URL. Called with the trimmed value from the dialog.
  final Future<void> Function(String url) onSave;

  bool get _hasUrl => (websiteUrl ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size14),
      // margin: EdgeInsets.only(top: SizeConfig.size10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E8EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14001120),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language_rounded,
                  size: 18, color: AppColors.primaryColor),
              SizedBox(width: SizeConfig.size8),
              Expanded(
                child: CustomText(
                  AppStrings.website.tr,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
              ),
              InkWell(
                onTap: () => _openEditDialog(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size10,
                    vertical: SizeConfig.size4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.3),
                      width: 0.6,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_hasUrl ? Icons.edit_outlined : Icons.add,
                          size: 14, color: AppColors.primaryColor),
                      SizedBox(width: SizeConfig.size4),
                      CustomText(
                        _hasUrl ? AppStrings.edit.tr : AppStrings.add.tr,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          if (_hasUrl)
            InkWell(
              onTap: () => launchURL(websiteUrl!.trim()),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size8,
                  vertical: SizeConfig.size6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded,
                        size: 18, color: AppColors.primaryColor),
                    SizedBox(width: SizeConfig.size6),
                    Expanded(
                      child: CustomText(
                        websiteUrl!.trim(),
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.open_in_new_rounded,
                        size: 14, color: AppColors.secondaryTextColor),
                  ],
                ),
              ),
            )
          else
            CustomText(
              AppStrings.noWebsiteAddedHint.tr,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
            ),
        ],
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context) async {
    final controller = TextEditingController(text: websiteUrl ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(AppStrings.website.tr),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            autofocus: true,
            decoration: InputDecoration(
              hintText: AppStrings.websiteUrlHintExample.tr,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.cancel.tr),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(AppStrings.save.tr),
            ),
          ],
        );
      },
    );
    if (result != null) {
      await onSave(result);
    }
  }
}
