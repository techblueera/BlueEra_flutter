import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ClickableLinkText extends StatelessWidget {
  final String url;
  final double? topPadding;

  const ClickableLinkText({
    Key? key,
    required this.url,
    this.topPadding,
  }) : super(key: key);

  Future<void> _launchURL(String link) async {
    final Uri uri = Uri.parse(link.startsWith('http') ? link : 'https://$link');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $link');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _launchURL(url),
      child: CustomText(
        url.replaceAll(RegExp(r'^@'), ''), // Removes @ if present
        color: Colors.blue,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
