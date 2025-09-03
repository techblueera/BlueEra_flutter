import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class ProfileBioWidget extends StatelessWidget {

  final String? bioText;

  const ProfileBioWidget({super.key,required this.bioText});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(SizeConfig.size16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomText(
                    "Bio",
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size8),
              CustomText(
                  "${bioText}"),
            ],
          ),
        ),
        SizedBox(height: SizeConfig.size16),
      ],
    );
  }
}
