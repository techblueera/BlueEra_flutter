import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart'; // for formatting date

class NewDatePicker extends StatelessWidget {
  final int? selectedDay;
  final int? selectedMonth;
  final int? selectedYear;
  final Function(int?)? onDayChanged;
  final Function(int?)? onMonthChanged;
  final Function(int?) onYearChanged;
  bool? isMonth;
  bool? isYear;
  bool? isDate;
  bool? isFutureYear;
  bool? isAgeValidation15;

  // Optional constraints populated by API
  final List<int>? allowedDays;
  final List<int>? allowedMonths;
  final List<int>? allowedYears;

  NewDatePicker({
    Key? key,
    this.selectedDay,
    this.selectedMonth,
    this.selectedYear,
    this.onDayChanged,
    this.onMonthChanged,
    required this.onYearChanged,
    this.isMonth = true,
    this.isYear = true,
    this.isDate = true,
    this.isFutureYear = false,
    this.isAgeValidation15,
    this.allowedDays,
    this.allowedMonths,
    this.allowedYears,
  }) : super(key: key);

  List<int> get days => List.generate(31, (index) => index + 1);

  List<String> get months => [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];

  List<int> get years {
    if (isAgeValidation15 ?? false) {
      final currentYear = DateTime.now().year - 10;

      return List.generate(
        100,
        (index) => (currentYear - index),
      );
    } else {
      final currentYear = DateTime.now().year;

      return List.generate(
        100,
        (index) => (isFutureYear ?? false)
            ? (currentYear + index)
            : (currentYear - index),
      );
    }
  }

  Widget _buildDropdown<T>({
    required List<T> items,
    required T? selectedValue,
    required String? isDropDownTypeHint,
    required Function(T?) onChanged,
    required String Function(T) displayValue,
  }) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(
          right: SizeConfig.paddingXSL,
        ),
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXS),
        decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [AppShadows.textFieldShadow],
            border: Border.all(width: 1, color: AppColors.greyE5)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: items.contains(selectedValue) ? selectedValue : null,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down_outlined,
                color: AppColors.grey99),
            dropdownColor: AppColors.white,
            style: const TextStyle(color: Colors.black),
            onChanged: onChanged,
            hint: Padding(
              padding: EdgeInsets.only(left: SizeConfig.size5),
              child: CustomText(
                isDropDownTypeHint,
                color: AppColors.grey9A,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w400,
              ),
            ),
            items: items.map((value) {
              return DropdownMenuItem<T>(
                value: value,
                child: Padding(
                  padding: EdgeInsets.only(left: SizeConfig.size5),
                  child: CustomText(displayValue(value)),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isDate ?? true)
          _buildDropdown<int>(
            isDropDownTypeHint: "DD",
            items: (allowedDays != null && allowedDays!.isNotEmpty)
                ? allowedDays!
                : days,
            selectedValue: selectedDay,
            onChanged: onDayChanged ?? (value) {},
            displayValue: (val) => val.toString().padLeft(2, '0'),
          ),
        if (isMonth ?? true)
          _buildDropdown<int>(
            isDropDownTypeHint: "MM",
            items: (allowedMonths != null && allowedMonths!.isNotEmpty)
                ? allowedMonths!
                : List.generate(12, (index) => index + 1),
            selectedValue: selectedMonth,
            onChanged: onMonthChanged ?? (value) {},
            displayValue: (val) => months[val - 1],
          ),
        _buildDropdown<int>(
          isDropDownTypeHint: "YYYY",
          items: (allowedYears != null && allowedYears!.isNotEmpty)
              ? allowedYears!
              : years,
          selectedValue: selectedYear,
          onChanged: onYearChanged,
          displayValue: (val) => val.toString(),
        ),
      ],
    );
  }
}
