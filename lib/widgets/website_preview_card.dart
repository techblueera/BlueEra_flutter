import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class WebsitePreviewCard extends StatelessWidget {
  final String url;

  const WebsitePreviewCard({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: SizeConfig.paddingXSmall,
      ),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.language,
                    color: AppColors.primaryColor, size: SizeConfig.size20),
                SizedBox(width: SizeConfig.paddingXS),
                ServiceHomeTitleWidget(title: AppStrings.website.tr),
              ],
            ),
            SizedBox(height: SizeConfig.paddingS),
            InkWell(
              onTap: () => launchUrl(
                Uri.parse(url.startsWith('http') ? url : 'https://$url'),
                mode: LaunchMode.externalApplication,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 300,
                  child: IgnorePointer(
                    child: CommonWebView(
                      urlLink: url,
                      urlTitle: '',
                      hideAppBar: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}