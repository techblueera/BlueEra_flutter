import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/widgets/step4_section.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/date_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'listing_form_screen_controller.dart';
import 'widgets/step1_section.dart';
import 'widgets/step2_section.dart';
import 'widgets/step3_section.dart';

class ListingFormScreen extends StatefulWidget {
  const ListingFormScreen({super.key});

  @override
  State<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends State<ListingFormScreen> {
  ManualListingScreenController controller =
      Get.put(ManualListingScreenController());

  final ScrollController _scrollController = ScrollController();
  late final Worker _stepWorker;

  @override
  void initState() {
    super.initState();
    // Scroll to top whenever step changes
    _stepWorker = ever<int>(controller.currentStep, (_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _stepWorker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // intercept system back
      onPopInvoked: (didPop) {
        if (didPop) return; // route already popped
        if (controller.currentStep.value > 1) {
          controller.onBack();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        bottomNavigationBar:
              Obx(() => Container(
                    padding: EdgeInsets.all(SizeConfig.size16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: CustomBtn(
                      title: controller.currentStep.value ==
                          ManualListingScreenController.totalSteps
                          ? 'Submit'
                          : 'Next',
                      onTap: controller.onNext,
                      bgColor: AppColors.primaryColor,
                      textColor: AppColors.white,
                      height: SizeConfig.size40,
                      radius: 10.0,
                    ),
                  )),

        backgroundColor: AppColors.whiteF3,
        appBar: CommonBackAppBar(
          title: controller.currentStep.value == 3
              ? 'Pricing & Warranty'
              : controller.currentStep.value == 4
              ? 'Add Variant'
              : 'Product Details',
          onBackTap: () {
            if (controller.currentStep.value > 1) {
              controller.onBack();
            } else {
              Navigator.of(context).pop();
            }
          },
          buildCustomWidget: () {
            return Padding(
              padding: EdgeInsets.only(right: SizeConfig.size20),
              child: Obx(()=> CustomText(
                'Steps-${controller.currentStep.value}/${ManualListingScreenController.totalSteps}',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              )),
            );
          }
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  // padding: EdgeInsets.all(SizeConfig.size16),
                  child: Form(
                    key: controller.formKey,
                    child: Obx(() {
                          final step = controller.currentStep.value;
                          if (step == 1) {
                            return Step1Section(controller: controller);
                          } else if (step == 2) {
                            return Step2Section(controller: controller);
                          } else if (step == 3) {
                            return Step3Section(controller: controller);
                          }else{
                            return Step4Section(controller: controller);
                          }
                        }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 
}
