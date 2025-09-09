import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/widgets/step4_section.dart'; 
import 'package:BlueEra/widgets/common_back_app_bar.dart'; 
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
        backgroundColor: AppColors.appBackgroundColor,
        
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Obx(() => CommonBackAppBar(
            title:  _getTitle(controller.currentStep.value),

            onBackTap: () {
              if (controller.currentStep.value > 1) {
                controller.onBack();
              } else {
                Navigator.of(context).pop();
              }
            },
            showRightTextButton: true,
rightTextButtonText: "Step-${controller.currentStep.value}/${ManualListingScreenController.totalSteps}",
rightTextButtonColor: AppColors.black,
// onRightTextButtonTap: () {}, // Optional callback
            // actionText: "Step-${controller.currentStep.value}/${ManualListingScreenController.totalSteps}",
            // actionTextColor: AppColors.black,
            // actionOnTap: () {
            //   if (controller.currentStep.value < 3) {
            //     controller.currentStep.value += 1;
            //   } else {
            //     controller.createListing();
            //   }
            // },
          )),
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
                          switch (controller.currentStep.value) {
  case 1:
    return Step1Section(controller: controller);
  case 2:
    return Step2Section(controller: controller);
  case 3:
    return Step3Section(controller: controller);
  case 4:
    return Step4Section(controller: controller);
  default:
    return const SizedBox.shrink();
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
  
  String _getTitle(int step) {
  switch (step) {
    case 1:
      return "Product Details";
    case 2:
      return "Product Media";
    case 3:
      return "Add Variant";
    case 4:
      return "Pricing and Warranty";
    default:
      return "Listing Form";
  }
}

 
}
