import 'package:flutter/material.dart';

class CircularCheckbox extends StatelessWidget {
  final bool isChecked;
  final VoidCallback onChanged;
  final Color activeColor;
  final Color borderColor;
  final double size;

  const CircularCheckbox({
    Key? key,
    required this.isChecked,
    required this.onChanged,
    this.activeColor = Colors.blue,
    this.borderColor = Colors.grey,
    this.size = 20.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(

          color: isChecked ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(

            color: isChecked ? activeColor : borderColor,
            width: 0.5,
          ),
        ),
        child: isChecked
            ? Center(
          child: Icon(
            Icons.check,
            size: size * 0.6,
            color: Colors.white,
          ),
        )
            : null,
      ),
    );
  }
}
