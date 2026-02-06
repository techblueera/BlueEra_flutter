import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/help_and_support_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/api/apiService/api_response.dart';
class FaqScreen extends StatefulWidget {
  FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final controller = Get.find<HelpAndSupportController>();

  @override
  void initState() {
    controller.getFaqsForHelp();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.faq),
      body: Obx(() {
        if (controller.getFAQResponse.value.status ==
            Status.COMPLETE) {
          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10,vertical: SizeConfig.size10),
            itemCount: controller.faqDetailsList.length,
            itemBuilder: (context, index) {
              final details = controller.faqDetailsList[index];

              return Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent, // 🚫 removes top & bottom borders
                ),
                child: Card(
                  elevation: 0, // 🚫 shadow remove
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide.none, // 🚫 card border remove
                  ),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size6,
                      vertical: SizeConfig.size4,
                    ),
                    childrenPadding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size6,
                      vertical: SizeConfig.size4,
                    ),
                    title: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: CustomText(
                        details.question ?? '',
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        maxLines: 2,
                      ),
                    ),
                    trailing: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: LocalAssets(
                        imagePath: AppIconAssets.qa_ask_questionOutlinedIcon,
                      ),
                    ),
                    children: [
                      Divider(
                        color: AppColors.whiteE5,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: CustomText(
                          details.answer ?? '',
                          fontSize: SizeConfig.medium,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: SizeConfig.size4),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return const Center(child: Center(child: CustomText('No Faq Found'),));
        }
      }),
    );
  }
}