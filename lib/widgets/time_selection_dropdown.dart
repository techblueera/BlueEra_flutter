import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class TimeSelectionDropdown extends StatelessWidget {
  final int? selectedHour;
  final int? selectedMinute;
  final String? selectedPeriod;
  final Function(int?) onHourChanged;
  final Function(int?) onMinuteChanged;
  final Function(String?) onPeriodChanged;

  const TimeSelectionDropdown({
    Key? key,
    this.selectedHour,
    this.selectedMinute,
    this.selectedPeriod,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.onPeriodChanged,
  }) : super(key: key);

  List<int> get hours => List.generate(12, (index) => index + 1);
  List<int> get minutes => [0, 15, 30, 45]; // 15-minute intervals
  List<String> get periods => ['AM', 'PM'];

  Widget _buildDropdown<T>({
    required List<T> items,
    required T? selectedValue,
    required String? hintText,
    required Function(T?) onChanged,
    required String Function(T) displayValue,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXS),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 1, color: AppColors.greyE5),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: items.contains(selectedValue) ? selectedValue : null,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down_outlined, color: AppColors.grey99),
            dropdownColor: AppColors.white,
            style: const TextStyle(color: Colors.black),
            onChanged: onChanged,
            hint: Padding(
              padding: EdgeInsets.only(left: SizeConfig.size5),
              child: CustomText(
                hintText,
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
        _buildDropdown<int>(
          hintText: "Hour",
          items: hours,
          selectedValue: selectedHour,
          onChanged: onHourChanged,
          displayValue: (val) => val.toString().padLeft(2, '0'),
        ),
        SizedBox(width: 8),
        _buildDropdown<int>(
          hintText: "Min",
          items: minutes,
          selectedValue: selectedMinute,
          onChanged: onMinuteChanged,
          displayValue: (val) => val.toString().padLeft(2, '0'),
        ),
        SizedBox(width: 8),
        _buildDropdown<String>(
          hintText: "AM/PM",
          items: periods,
          selectedValue: selectedPeriod,
          onChanged: onPeriodChanged,
          displayValue: (val) => val,
        ),
      ],
    );
  }
}