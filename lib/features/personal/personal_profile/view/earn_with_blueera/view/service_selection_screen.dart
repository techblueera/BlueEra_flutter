import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/self_work_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/add_service_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ServiceSelectionScreen extends StatefulWidget {
  final SelfWorkServiceController controller;
  final String designation;
  final String pageTitle;
  final String selectedCategoryKey;
  final List<String> preSelectedOptions;
  final bool isDataUpdate;

  const ServiceSelectionScreen({
    super.key,
    required this.controller,
    required this.designation,
    required this.pageTitle,
    required this.selectedCategoryKey,
    required this.preSelectedOptions,
    this.isDataUpdate = false,
  });

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  late List<String> _tempSelectedOptions;
  late SelfWorkServiceController _controller;
  late String _selectedCategoryKey;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _selectedCategoryKey = widget.selectedCategoryKey;
    _tempSelectedOptions = List.from(widget.preSelectedOptions);

    final currentList = _controller.allCategoryMap[_selectedCategoryKey];

    if (currentList == null || currentList.isEmpty) {
      _controller.fetchServiceSelectionOptions(
          designation: widget.designation,
          selectedServiceKey: _selectedCategoryKey
      );
    } else {
      print("Data for $_selectedCategoryKey already exists. Skipping API call.");
    }
  }

  void _toggleSelection(String option) {
    setState(() {
      if (_tempSelectedOptions.contains(option)) {
        _tempSelectedOptions.remove(option);
      } else {
        _tempSelectedOptions.add(option);
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    final Widget contentBody = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Wrap the List in Obx to listen for API updates
        Obx(() {
          // Show Loader
          if (_controller.isServiceSelectionLoading.value) {
            return const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final allOptions = _controller.allCategoryMap[_selectedCategoryKey] ?? <String>[].obs;

          return ListView.builder(
            // Add +1 for the "Add More" button
            itemCount: allOptions.length + 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Important inside SingleChildScrollView
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {

              // --- Case 1: "Add More Services" Button (Last Item) ---
              if (index == allOptions.length) {
                return TextButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddServiceBottomSheet(
                      onUpload: (List<String> newServices) {
                        // A. Update the Controller's Main List (Source of Truth)
                        final RxList<String>? mainList = _controller.allCategoryMap[_selectedCategoryKey];
                        if (mainList != null) {
                          mainList.addAll(newServices);
                        }

                        setState(() {
                          _tempSelectedOptions.addAll(newServices);
                        });
                      },
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.add, color: AppColors.primaryColor, size: 20),
                      SizedBox(width: SizeConfig.size8),
                      CustomText(
                          "Add More Services",
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w400,
                          color: AppColors.primaryColor
                      ),
                    ],
                  ),
                );
              }

              // --- Case 2: Standard Option Item ---
              final option = allOptions[index];
              final isSelected = _tempSelectedOptions.contains(option);

              return Theme(
                data: ThemeData(unselectedWidgetColor: Colors.grey.shade300),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
                  dense: true,
                  activeColor: AppColors.primaryColor,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: CustomText(
                      option,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor
                  ),
                  value: isSelected,
                  onChanged: (val) => _toggleSelection(option),
                ),
              );
            },
          );
        }),

        // --- SAVE BUTTON ---
        Padding(
          padding: EdgeInsets.only(
            left: SizeConfig.size10,
            top: SizeConfig.size10,
            right: SizeConfig.size10,
          ),
          child: CustomBtn(
            title: AppStrings.save,
            onTap: () {
              _controller.updateSelection(
                  _selectedCategoryKey,
                  _tempSelectedOptions
              );
              _tempSelectedOptions.clear();
              Get.back();
            },
            bgColor: AppColors.primaryColor,
          ),
        ),
      ],
    );

    if (!widget.isDataUpdate) {
      return Scaffold(
        backgroundColor: AppColors.whiteF3,
        appBar: CommonBackAppBar(title: widget.pageTitle),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              vertical: SizeConfig.size15,
              horizontal: SizeConfig.size8
          ),
          child: CustomFormCard(
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size15),
            child: contentBody, // <--- Reusing content here
          ),
        ),
      );
    } else {
      // Bottom Sheet view
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: contentBody, // <--- Reusing content here
      );
    }
  }
}