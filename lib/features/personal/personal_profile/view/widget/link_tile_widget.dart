import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkTile extends StatelessWidget {
  final String label;
  final String url;

  const LinkTile({required this.label, required this.url});


  Future<void> _launchURL(String rawUrl) async {
    final cleanUrl = rawUrl.startsWith("http") ? rawUrl : "https://$rawUrl";
    final Uri? uri = Uri.tryParse(cleanUrl);

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $cleanUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _launchURL(url),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Color.fromRGBO(245, 245, 245, 1)),
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12, vertical: SizeConfig.size4),
        margin: EdgeInsets.only(bottom: SizeConfig.size12),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
          child: RichText(
            text: TextSpan(
      
              style:
                  TextStyle(fontSize: SizeConfig.medium, color: Colors.black87,fontFamily: AppConstants.OpenSans),
              children: [
                TextSpan(
                    text: "$label: ",
                    style: TextStyle(
      
                        fontSize: SizeConfig.medium, color: Colors.black)),
                TextSpan(
                  text: url,
                  style: TextStyle(
                      fontSize: SizeConfig.medium, color: AppColors.primaryColor),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
