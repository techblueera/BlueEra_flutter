
import 'package:flutter/material.dart';

class CustomRadioButton extends StatelessWidget {
  final String value;
  final String? groupValue; // Make groupValue nullable
  final ValueChanged<String> onChanged;
  final Color selectedColor;
  final Color unselectedColor;
  final double size;

  const CustomRadioButton({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.grey,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = groupValue != null && value == groupValue;

    return GestureDetector(
      onTap: () {
        onChanged(value); // Notify parent widget of the selection
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? selectedColor : unselectedColor,
            width: 2.0,
          ),
        ),
        child: Center(
          child: Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? selectedColor : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}


class CustomRadioButton2 extends StatelessWidget {
  final String value;
  final String? groupValue; // Make groupValue nullable
  // final ValueChanged<String> onChanged;
  final Color selectedColor;
  final Color unselectedColor;
  final double size;

  const CustomRadioButton2({
    super.key,
    required this.value,
    required this.groupValue,
    // required this.onChanged,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.grey,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = groupValue != null && value == groupValue;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? selectedColor : unselectedColor,
          width: 2.0,
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.6,
          height: size * 0.6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? selectedColor : Colors.transparent,
          ),
        ),
      ),
    );
  }
}
