import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/help_and_support_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class FaqScreen extends StatelessWidget {
  FaqScreen({super.key});

  final controller = Get.find<HelpAndSupportController>();
  List<String> FAQList = [
    "How can I list my business on the app?",
    "Can I sell physical and digital products on the app?",
    "What are the different ways I can earn through this app?",
    "How does business verification work, and why is it important?",
    "Forem ipsum dolor sit amet, consectetur adipiscing elit.",
    "Forem ipsum dolor sit amet, consectetur adipiscing elit."
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.faq,),
      body: Container(
          padding: EdgeInsets.symmetric(
              vertical: SizeConfig.size4, horizontal: SizeConfig.size4),
          margin: EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListView.builder(
            itemCount: FAQList.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: SizeConfig.size6, horizontal: SizeConfig.size6),
                  child: Column(
                    children: [
                      SizedBox(height: SizeConfig.size8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: CustomText(
                              FAQList[index].toString(),
                              fontSize: SizeConfig.large,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              maxLines: 2,
                            ),
                          ),
                          InkWell(
                            onTap: () {},
                            child: SvgPicture.asset(
                              AppIconAssets.add,
                              height: 18,
                              width: 18,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Divider(
                        thickness: 0.1,
                        color: Colors.grey,
                      ),
                    ],
                  ));
            },
          ))
    );
  }
}
