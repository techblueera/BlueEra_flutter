import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/faq_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/help_and_support__mail_us.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/queries_card_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../chat/auth/controller/chat_view_controller.dart';
import '../../../../chat/view/ai_chat/view/ai_chat_screen.dart';
import '../../controller/help_and_support_controller.dart';
import '../complaint/complaint_main_page.dart';

class HelpAndSupportScreen extends StatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HelpAndSupportController>(
      init: HelpAndSupportController(),
      builder: (helpController) {
        return Scaffold(

          appBar: CommonBackAppBar(
            onBackTap: () {

              Navigator.pop(context);
            },
            isShadowShow: false,
            title: AppStrings.helpAndSupport,

            isLeading: true,
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8,),
            child: Column(
              children: [
                SizedBox(height: SizeConfig.size20),
                _helpServiceCard(
                  'assets/images/customer.png',
                  AppStrings.customerSupport,
                  () {
                    // Get.to(() => CustomerSupportScreen());
                    final chat =ChatViewController.personalAiChatModule;
                    Get.to(()=> AiChatScreen(
                      profileImage: chat?.sender?.profileImage,
                      name: chat?.sender?.name,
                      type: chat?.sender?.accountType,
                      ));
                  },
                ),
                SizedBox(height: SizeConfig.size10),
                _helpServiceCard(
                  'assets/images/mail.png',
                  AppStrings.mailUs,
                  () {
                    Get.to(() => HelpAndSupportFormScreen());
                  },
                ),
                SizedBox(height: SizeConfig.size10),
                _helpServiceCard(
                 'assets/images/qury.png',
                  AppStrings.queries,
                  () {
                    Get.to(() => QueriesCard());
                  },
                ),
                SizedBox(height: SizeConfig.size10),
                _helpServiceCard(
                  'assets/images/complaint.png',

                  "Complaint",
                  () {
                   Get.to(() => ComplaintMainPage());
                  },
                ),
                SizedBox(height: SizeConfig.size10),
                _helpServiceCard(
                  'assets/images/faq.png',
                  AppStrings.faq,
                  () {
                    Get.to(() => FaqScreen());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _helpServiceCard(String value1, value2, GestureTapCallback? onTap) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(
          vertical: SizeConfig.size20, horizontal: SizeConfig.size16),
      margin: EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              LocalAssets(
                height: 20,
                width: 20,
                imagePath: value1,
                imgColor: AppColors.secondaryTextColor,

              ),
              SizedBox(width: SizeConfig.size16),
              CustomText(
                value2,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
          if(value2==AppStrings.customerSupport)
          LocalAssets(imagePath: AppImageAssets.chat_with_ai_bot),
          if(value2==AppStrings.mailUs)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.whiteE5.withValues(alpha: 0.4)
            ),
            padding: EdgeInsets.symmetric(vertical: 4,horizontal: 8),
            child: Center(
              child: CustomText(
                "mailusbluecs@gmail.com",fontSize: 14,
              color: AppColors.secondaryTextColor,),
            ),
          )
        ],
      ),
    ),
  );
}
