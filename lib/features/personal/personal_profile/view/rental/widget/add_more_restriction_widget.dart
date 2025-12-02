import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddMoreRestrictionsWidget extends StatefulWidget {
  /// Initial highlights (can be empty)
  final List<String> initialRestriction;

  /// Callback when user presses Save
  final ValueChanged<List<String>> onSave;

  const AddMoreRestrictionsWidget({
    super.key,
    this.initialRestriction = const [],
    required this.onSave,
  });

  @override
  State<AddMoreRestrictionsWidget> createState() => _AddMoreRestrictionsWidgetState();
}

class _AddMoreRestrictionsWidgetState extends State<AddMoreRestrictionsWidget> {
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();

    // If highlights exist, create controllers for them
    if (widget.initialRestriction.isNotEmpty) {
      for (final text in widget.initialRestriction) {
        _controllers.add(TextEditingController(text: text));
      }
    }else{
      // Ensure there are always 4 controllers minimum
      while(_controllers.length < 2) {
        _controllers.add(TextEditingController());
      }
    }
  }

  void _addController() {
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removeController(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  void _onSavePressed() {
    final restrictions = _controllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (restrictions.length > 10) {
      Get.snackbar(
        AppStrings.limitExceeded.tr,
        AppStrings.restrictionsLimitMessage.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
      );
      return;
    }

    widget.onSave(restrictions);
    Get.back();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: SizeConfig.size15,
            right: SizeConfig.size15,
            top: SizeConfig.size15,
            bottom: SizeConfig.size40,
          ),
          child: CustomFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.addRestrictionsTitle,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size8),
                ListView.builder(
                  itemCount: _controllers.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: SizeConfig.size10),
                      child: Row(
                        children: [
                          Expanded(
                            child: CommonTextField(
                              textEditController: _controllers[index],
                              hintText: AppStrings.hintRestrictionsExample,
                              isValidate: true,
                            ),
                          ),
                          if (_controllers.length > 1)
                            IconButton(
                              onPressed: () => _removeController(index),
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.red),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _addController,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const LocalAssets(
                        imagePath: AppIconAssets.addBlueIcon,
                        imgColor: AppColors.primaryColor,
                      ),
                      SizedBox(width: SizeConfig.size5),
                      CustomText(
                        AppStrings.addMoreTitle,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w400,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.paddingL),
                CustomBtn(
                  onTap: _onSavePressed,
                  title: AppStrings.save,
                  bgColor: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
