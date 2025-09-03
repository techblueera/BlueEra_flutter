import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/portfolio_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_chip.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PortfolioLinkScreen extends StatefulWidget {
  const PortfolioLinkScreen({Key? key}) : super(key: key);

  @override
  State<PortfolioLinkScreen> createState() => _PortfolioLinkScreenState();
}

class _PortfolioLinkScreenState extends State<PortfolioLinkScreen> {
  final controller = Get.put(PortfolioController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonBackAppBar(title: "Add Portfolio / Work Samples"),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size20),
          child: SingleChildScrollView(
            child: CommonCardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Portfolio / Work Samples",
                    color: AppColors.black1A,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                  ),
                  SizedBox(height: SizeConfig.size8),

                  // Input + Add Button
                  Row(
                    children: [
                      Expanded(
                        child: HttpsTextField(
                          controller: controller.portfolioController,
                          hintText: "Share Your Portfolio link",
                          isUrlValidate: false,
                          onChange: (value) {
                            controller.validateForm();
                          },
                        ),
                      ),
                      SizedBox(width: SizeConfig.size8),
                      Obx(() => CustomBtn(
                            width: SizeConfig.size70,
                            height: SizeConfig.size40,
                            onTap: controller.isAddPortfolioValidate.value
                                ? () {
                                    controller.addPortfolioLink(controller
                                        .portfolioController.text
                                        .trim());
                                  }
                                : null,
                            title: 'Add',
                            isValidate: controller.isAddPortfolioValidate.value,
                          )),
                    ],
                  ),

                  SizedBox(height: SizeConfig.size15),

                  // Display Chips
                  Obx(() => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.portfolioLinks.map((link) {
                          return CommonChip(
                            label: link,
                            onDeleted: () {
                              controller.removePortfolioLink(link);
                            },
                          );
                        }).toList(),
                      )),

                  SizedBox(height: SizeConfig.size20),

                  // Save Button
                  Obx(() => CustomBtn(
                        onTap: controller.isValidate.value
                            ? () {
                                controller.savePortfolio(context);
                              }
                            : null,
                        title: "Save",
                        isValidate: controller.isValidate.value,
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
