import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class JobFilterDialog extends StatefulWidget {
  @override
  _JobFilterDialogState createState() => _JobFilterDialogState();
}

class _JobFilterDialogState extends State<JobFilterDialog> {
  late TextEditingController _salaryController;
  late TextEditingController _departmentSearchController;
  String selectedCategory = JobFilteredCategory.postedIn.label;

  final Map<String, List<String>> filterValues = {
    JobFilteredCategory.postedIn.label : ['All', 'Last 24 Hours', 'Last 3 Days', 'Last 7 Days'],
    JobFilteredCategory.salary.label : ['₹ 25,000'],
    JobFilteredCategory.workMode.label : ['Work From Home', 'Work From Office'],
    JobFilteredCategory.jobType.label : ['Full Time', 'Part Time', 'Internship', 'Freelance'],
    JobFilteredCategory.workShift.label : ['Day Shift', 'Night Shift', 'Rotational Shift'],
    JobFilteredCategory.department.label : [
                                          'Aviation & Aerospace',
                                          'Admin / Back Office / Computer Operator',
                                          'Advertising / Communication',
                                          'Beauty, Fitness & Personal Care',
                                          'CSR & Social Service',
                                          'Beauty, Fitness & Personal Care',
                                          'Delivery Driver / Logistics',
                                          'Customer Support',
                                          'Consulting'
                                          ],
  };

  final Map<String, List<String>> selectedFilters = {};

  List<String> get activeTags => selectedFilters.values.expand((e) => e).toList();

  void toggleSelection(String category, String value) {
    final isSelected = selectedFilters[category]?.contains(value) ?? false;

    setState(() {
      if (isSelected) {
        selectedFilters[category]?.remove(value);
        if (selectedFilters[category]?.isEmpty ?? true) {
          selectedFilters.remove(category);
        }
      } else {
        selectedFilters.putIfAbsent(category, () => []);
        selectedFilters[category]!.add(value);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _departmentSearchController = TextEditingController();
    _salaryController = TextEditingController(
      text: selectedFilters['Salary']?.first ?? '',
    );

    _salaryController.addListener(() {
      setState(() {
        selectedFilters['Salary'] = [_salaryController.text];
      });
    });
  }

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
      child: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.only(
                bottom: 0,
                // bottom: MediaQuery.of(context).viewInsets.bottom, // push content above keyboard
              ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15, vertical: SizeConfig.size6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText('All Filters', fontSize: SizeConfig.large, fontWeight: FontWeight.w700, color: AppColors.black28),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                CommonHorizontalDivider(
                  color: AppColors.grey9A,
                  height: 0.5,
                ),

                /// Category and Options Section
                Padding(
                    padding: EdgeInsets.all(SizeConfig.size10),
                  child: Container(
                    width: SizeConfig.screenWidth,
                    height: SizeConfig.size290,
                    decoration: BoxDecoration(
                        color: AppColors.whiteF4,
                        borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10, vertical: SizeConfig.size10),
                    child: Row(
                      children: [

                        /// Categories
                        Container(
                          width: SizeConfig.size130,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.white,
                           border: Border.all(
                             color: AppColors.whiteED
                           )
                          ),
                          padding: EdgeInsets.all(SizeConfig.size10),
                          child: ListView(
                            children: filterValues.keys.map((category) {
                              final isSelected = selectedCategory == category;
                              final hasSelection = selectedFilters[category]?.isNotEmpty ?? false;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () => setState(() => selectedCategory = category),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primaryColor : AppColors.fillColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: CustomText(
                                            category,
                                            fontSize: SizeConfig.medium,
                                            color: isSelected ? AppColors.white : AppColors.black30,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (hasSelection)
                                           Container(
                                             height: SizeConfig.size15,
                                             width: SizeConfig.size15,
                                             decoration: BoxDecoration(
                                               shape: BoxShape.circle,
                                               color: isSelected ? AppColors.white : AppColors.primaryColor,
                                             ),
                                             alignment: Alignment.center,
                                             child: CustomText(
                                                 "1",
                                                fontSize: SizeConfig.extraSmall,
                                               fontWeight: FontWeight.w700,
                                               color: isSelected ? AppColors.primaryColor : AppColors.white,
                                             ),
                                           ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        SizedBox(width: SizeConfig.size10),

                        /// Options
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
                            child: Builder(
                              builder: (_) {
                                final options = filterValues[selectedCategory]!;

                                // Radio for "Posted In"
                                if (selectedCategory == JobFilteredCategory.postedIn.label) {
                                  final selected = selectedFilters[selectedCategory]?.first;
                                  return Column(
                                    children: options.map((option) {
                                      return Padding(
                                        padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              selectedFilters[selectedCategory] = [option];
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(6),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: SizeConfig.size16,
                                                height: SizeConfig.size16,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color:  selected == option ? AppColors.primaryColor : AppColors.grey83, width: 1.5),
                                                ),
                                                child: selected == option
                                                    ? Center(
                                                  child: Container(
                                                    width: SizeConfig.size10,
                                                    height: SizeConfig.size10,
                                                    decoration: const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                )
                                                    : null,
                                              ),
                                              SizedBox(width: SizeConfig.size6),
                                              Expanded(
                                                child: CustomText(
                                                  option,
                                                  color: AppColors.grey83,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                }

                                // Salary TextField
                                if (selectedCategory == JobFilteredCategory.salary.label) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustomText(
                                        'Minimum Monthly Salary',
                                        color: AppColors.black28,
                                      ),
                                      SizedBox(height: SizeConfig.size12),
                                      Container(
                                        height: SizeConfig.size40,
                                        child: TextField(
                                          controller: _salaryController,
                                          style: TextStyle(color: AppColors.black28, fontSize: SizeConfig.extraSmall, fontWeight: FontWeight.w400),
                                          decoration: InputDecoration(
                                            hintText: options.first,
                                            hintStyle: const TextStyle(color: Colors.black45),
                                            prefixStyle: const TextStyle(color: Colors.black),
                                            filled: true,
                                            isDense: true,
                                            fillColor: AppColors.whiteF3,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(6.0),
                                              borderSide: const BorderSide(color: AppColors.grey83, width: 0.5),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(6.0),
                                              borderSide: const BorderSide(color: AppColors.grey83, width: 0.5),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(6.0),
                                              borderSide: const BorderSide(color: AppColors.grey83, width: 0.5),
                                            ),
                                            suffixIcon: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                InkWell(
                                                    onTap: () {
                                                      final current = int.tryParse(_salaryController.text.replaceAll(',', '')) ?? 0;
                                                      _salaryController.text = (current + 1000).toString();
                                                    },
                                                    child: Icon(Icons.arrow_drop_up, color: Colors.black87, size: SizeConfig.size14)),
                                                SizedBox(height: SizeConfig.size4),
                                                // IconButton(
                                                //   padding: EdgeInsets.zero,
                                                //   visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                //   constraints: const BoxConstraints(),
                                                //   onPressed: () {
                                                //     final current = int.tryParse(_salaryController.text.replaceAll(',', '')) ?? 0;
                                                //     _salaryController.text = (current + 1000).toString();
                                                //   },
                                                //   icon: const Icon(Icons.arrow_drop_up, color: Colors.black87, size: 20),
                                                // ),

                                                InkWell(
                                                  onTap: () {
                                                    final current = int.tryParse(_salaryController.text.replaceAll(',', '')) ?? 0;
                                                    final newVal = (current - 1000).clamp(0, double.infinity).toInt();
                                                    _salaryController.text = newVal.toString();
                                                  },
                                                  child: Icon(Icons.arrow_drop_down, color: Colors.black87, size: SizeConfig.size14),
                                                )
                                                // IconButton(
                                                //   padding: EdgeInsets.zero,
                                                //   visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                //   constraints: const BoxConstraints(),
                                                //   onPressed: () {
                                                //     final current = int.tryParse(_salaryController.text.replaceAll(',', '')) ?? 0;
                                                //     final newVal = (current - 1000).clamp(0, double.infinity).toInt();
                                                //     _salaryController.text = newVal.toString();
                                                //   },
                                                //   icon: const Icon(Icons.arrow_drop_down, color: Colors.black87, size: 20),
                                                // ),
                                              ],
                                            ),
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                // Checkbox for other categories
                                return Align(
                                  alignment: Alignment.topCenter,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [

                                        if (selectedCategory == JobFilteredCategory.department.label)
                                          Container(
                                            height: SizeConfig.size40,
                                            child: TextField(
                                              controller: _departmentSearchController,
                                              style: TextStyle(color: AppColors.black28, fontSize: SizeConfig.extraSmall, fontWeight: FontWeight.w400),
                                              decoration: InputDecoration(
                                                hintText: "Search here...",
                                                hintStyle: TextStyle(color: AppColors.grey99, fontSize: SizeConfig.size10, fontWeight: FontWeight.w400),
                                                prefixIcon: Padding(
                                                  padding:  EdgeInsets.only(left: 8.0),
                                                  child: Icon(Icons.search, color: AppColors.grey99, size: 18),
                                                ),
                                                prefixIconConstraints: BoxConstraints(
                                                  minWidth: 20,
                                                  minHeight: 20,
                                                ),
                                                filled: true,
                                                isDense: true,
                                                fillColor: AppColors.white,
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(100.0),
                                                  borderSide: const BorderSide(color: AppColors.whiteED, width: 1.0),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(100.0),
                                                  borderSide: const BorderSide(color: AppColors.whiteED, width: 1.0),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(100.0),
                                                  borderSide: const BorderSide(color: AppColors.whiteED, width: 1.0),
                                                ),
                                              ),
                                              keyboardType: TextInputType.text,
                                            ),
                                          ),


                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: options.map((option) {
                                            final isSelected = selectedFilters[selectedCategory]?.contains(option) ?? false;
                                            return Padding(
                                              padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
                                              child: InkWell(
                                                onTap: () => toggleSelection(selectedCategory, option),
                                                borderRadius: BorderRadius.circular(6),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      width: SizeConfig.size16,
                                                      height: SizeConfig.size16,
                                                      margin: EdgeInsets.only(top: SizeConfig.size2),
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(2),
                                                        border: isSelected
                                                            ? null
                                                            : Border.all(color: AppColors.grey83, width: 1),
                                                        color: isSelected ? AppColors.primaryColor : Colors.transparent,
                                                      ),
                                                      child: isSelected
                                                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                                                          : null,
                                                    ),
                                                    SizedBox(width: SizeConfig.size6),
                                                    Expanded(
                                                      child: CustomText(
                                                        option,
                                                        color: AppColors.grey83,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),

                SizedBox(height: SizeConfig.size10),

                /// Selected Filters Chips
                if (activeTags.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.whiteF4,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding: EdgeInsets.all(SizeConfig.size10),
                    child: Wrap(
                      spacing: 10,
                      children: activeTags.map((tag) {
                        return Chip(
                          side: BorderSide.none,
                          padding: const EdgeInsets.all(8.0),
                          label: Text(tag),
                          onDeleted: () {
                            for (var category in selectedFilters.keys) {
                              if (selectedFilters[category]!.remove(tag)) {
                                if (selectedFilters[category]!.isEmpty) {
                                  selectedFilters.remove(category);
                                }
                                setState(() {});
                                break;
                              }
                            }
                          },
                          backgroundColor: AppColors.skyBlueFF,
                          labelStyle: TextStyle(fontSize: SizeConfig.size10, fontWeight: FontWeight.w400, color: AppColors.blackD93),
                          deleteIcon: Icon(Icons.close, size: SizeConfig.size14, color: AppColors.blackD93),
                        );
                      }).toList(),
                    ),
                  ),


                /// Bottom Buttons
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20, vertical: SizeConfig.size10),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomBtn(
                          onTap: () {
                            setState(() => selectedFilters.clear());
                          },
                          title: 'Clear Filters',
                          borderColor: AppColors.primaryColor,
                          bgColor: AppColors.white,
                          textColor: AppColors.primaryColor,
                          radius: 10.0,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size10),
                      Expanded(
                        child: CustomBtn(
                          onTap: () {
                            logs("selectedFilters=== ${selectedFilters}");
                            // Pass selectedFilters if needed
                            Navigator.pop(context, selectedFilters);
                          },
                          title: 'Apply',
                          isValidate: true,
                          radius: 10.0,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
