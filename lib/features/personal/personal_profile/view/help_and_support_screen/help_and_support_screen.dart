import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/faq_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/help_and_support__form_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/queries_card_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../chat/auth/controller/chat_view_controller.dart';
import '../../../../chat/view/ai_chat/view/ai_chat_screen.dart';
import '../../controller/help_and_support_controller.dart';

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
                  AppIconAssets.helpIcon,
                  AppStrings.customerSupport,
                  () {
                    // Get.to(CustomerSupportScreen());
                    final chat =ChatViewController.personalAiChatModule;
                    Get.to(()=> AiChatScreen(
                      profileImage: chat?.sender?.profileImage,
                      name: chat?.sender?.name,
                      contactNo: chat?.sender?.contactNo,
                      conversationId: '',
                      userId: '',
                      businessId: '',
                      type: chat?.sender?.accountType,
                      isInitialMessage: false,));
                  },
                ),
                SizedBox(height: SizeConfig.size10),
                _helpServiceCard(
                  AppIconAssets.mailIcon,
                  AppStrings.mailUs,
                  () {
                    Get.to(HelpAndSupportFormScreen());
                  },
                ),
                SizedBox(height: SizeConfig.size10),
                _helpServiceCard(
                  AppIconAssets.queriIcon,
                  AppStrings.queries,
                  () {
                    Get.to(QueriesCard());
                  },
                ),
                SizedBox(height: SizeConfig.size10),
                _helpServiceCard(
                  AppIconAssets.queriIcon,
                  "Complaint",
                  () {
                   // Get.to(QueriesCard());
                  },
                ),
                SizedBox(height: SizeConfig.size10),
                _helpServiceCard(
                  AppIconAssets.FAQIcon,
                  AppStrings.faq,
                  () {
                    Get.to(FaqScreen());
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
          vertical: SizeConfig.size16, horizontal: SizeConfig.size16),
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
              Container(
                padding: EdgeInsets.all(SizeConfig.size16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: AppColors.primaryColor.withValues(alpha: 0.2),
                ),
                child: SvgPicture.asset(
                  value1,
                  height: 24,
                  width: 24,
                ),
              ),
              SizedBox(width: SizeConfig.size16),
              CustomText(
                value2,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size10),
            child: InkWell(
              onTap: onTap,
              child: SvgPicture.asset(
                AppIconAssets.frontArrow,
                height: 18,
                width: 18,
                color: Colors.black,
              ),
            ),
          )
        ],
      ),
    ),
  );
}
