import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/customer_support_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/faq_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/help_and_support__form_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/queries_card_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/api/model/support_model.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../widgets/common_search_bar.dart';
import '../../../../../widgets/horizontal_tab_selector.dart';
import 'help_and_support_controller.dart';

class HelpAndSupportScreen extends StatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {
  List<SupportCase> allList = [];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HelpAndSupportController>(
      init: HelpAndSupportController(),
      builder: (helpController) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: CommonBackAppBar(
            onBackTap: () {
              Navigator.pop(context);
            },
            title: AppStrings.helpAndSupport,
            isLeading: true,
          ),
          body: Padding(
            padding: EdgeInsets.all(SizeConfig.size16),
            child: Column(
              children: [
                SizedBox(height: SizeConfig.size20),
                _helpServiceCard(
                  AppIconAssets.helpIcon,
                  AppStrings.customerSupport,
                  () {
                    Get.to(CustomerSupportScreen());
                  },
                ),
                SizedBox(height: SizeConfig.size20),
                _helpServiceCard(
                  AppIconAssets.mailIcon,
                  AppStrings.mailUs,
                  () {
                    Get.to(HelpAndSupportFormScreen());
                  },
                ),
                SizedBox(height: SizeConfig.size20),
                _helpServiceCard(
                  AppIconAssets.queriIcon,
                  AppStrings.queries,
                  () {
                    Get.to(QueriesCard());
                  },
                ),
                SizedBox(height: SizeConfig.size20),
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
          vertical: SizeConfig.size4, horizontal: SizeConfig.size4),
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
                margin: EdgeInsets.all(SizeConfig.size10),
                padding: EdgeInsets.all(SizeConfig.size10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                ),
                child: SvgPicture.asset(
                  value1,
                  height: 18,
                  width: 18,
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              CustomText(
                value2,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
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
