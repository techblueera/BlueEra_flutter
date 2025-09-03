import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart'; // for colors and styling


class RestrictedDatePicker extends StatelessWidget {
  final int? selectedDay;
  final int? selectedMonth;
  final int? selectedYear;

  final Function(int?)? onDayChanged;
  final Function(int?)? onMonthChanged;
  final Function(int?) onYearChanged;

  final bool isMonth;
  final bool isYear;
  final bool isDate;

  final bool isFutureYear; // Whether allowing future years (default false)

  final DateTime maxDate;

  RestrictedDatePicker({
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
    DateTime? maxDate, // Optional max date to restrict selection
  })  : maxDate = maxDate ?? DateTime.now(),
        super(key: key);

  // Month names for display
  static const List<String> monthsNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  // Years list limited to maxDate year, descending or ascending depending on isFutureYear
  List<int> get years {
    final currentYear = maxDate.year;
    if (isFutureYear) {
      // Allow future years up to 100 years ahead
      return List.generate(100, (index) => currentYear + index);
    } else {
      // Allow years from currentYear down 100 years
      return List.generate(100, (index) => currentYear - index)
          .where((year) => year <= maxDate.year)
          .toList();
    }
  }

  // Months filtered based on selectedYear and maxDate
  List<int> get months {
    final allMonths = List.generate(12, (i) => i + 1);

    if (selectedYear == null) {
      return allMonths;
    }

    if (selectedYear! < maxDate.year) {
      return allMonths;
    } else if (selectedYear == maxDate.year) {
      return allMonths.where((month) => month <= maxDate.month).toList();
    } else {
      return [];
    }
  }

  // Days filtered based on selectedYear, selectedMonth, and maxDate
  List<int> get days {
    if (selectedYear == null || selectedMonth == null) {
      return List.generate(31, (i) => i + 1);
    }

    int daysInMonth;
    try {
      // Last day of the month trick
      daysInMonth = DateTime(selectedYear!, selectedMonth! + 1, 0).day;
    } catch (e) {
      daysInMonth = 31; // fallback
    }

    final allDays = List.generate(daysInMonth, (i) => i + 1);

    if (selectedYear! < maxDate.year) {
      return allDays;
    } else if (selectedYear == maxDate.year) {
      if (selectedMonth! < maxDate.month) {
        return allDays;
      } else if (selectedMonth == maxDate.month) {
        return allDays.where((day) => day <= maxDate.day).toList();
      } else {
        return [];
      }
    } else {
      return [];
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
        margin: EdgeInsets.only(right: SizeConfig.paddingXSL),
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXS),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [AppShadows.textFieldShadow],
          border: Border.all(
            width: 1,
            color: AppColors.greyE5,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: items.contains(selectedValue) ? selectedValue : null,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_outlined,
              color: AppColors.grey99,
            ),
            dropdownColor: AppColors.white,
            style: const TextStyle(color: Colors.black),
            onChanged: onChanged,
            hint: Padding(
              padding: EdgeInsets.only(left: SizeConfig.size5),
              child: CustomText(
                isDropDownTypeHint ?? '',
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
        if (isDate)
          _buildDropdown<int>(
            isDropDownTypeHint: "DD",
            items: days,
            selectedValue: selectedDay,
            onChanged: onDayChanged ?? (_) {},
            displayValue: (val) => val.toString().padLeft(2, '0'),
          ),
        if (isMonth)
          _buildDropdown<int>(
            isDropDownTypeHint: "MM",
            items: months,
            selectedValue: selectedMonth,
            onChanged: onMonthChanged ?? (_) {},
            displayValue: (val) => monthsNames[val - 1],
          ),
        if (isYear)
          _buildDropdown<int>(
            isDropDownTypeHint: "YYYY",
            items: years,
            selectedValue: selectedYear,
            onChanged: onYearChanged,
            displayValue: (val) => val.toString(),
          ),
      ],
    );
  }
}
