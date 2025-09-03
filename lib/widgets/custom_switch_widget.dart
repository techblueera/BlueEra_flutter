
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CustomSwitch extends StatefulWidget {
  final bool value;
  final double? containerHeight;
  final double? containerWidth;
  final double? circleSize;
  final ValueChanged<bool> onChanged;

  const CustomSwitch({Key? key, required this.value, required this.onChanged, this.containerHeight, this.containerWidth, this.circleSize}) : super(key: key);

  @override
  State<CustomSwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: widget.containerWidth ?? 60,
        height: widget.containerHeight ?? 30,
        padding: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: widget.value ? AppColors.primaryColor : Colors.grey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Align(
          alignment:
          widget.value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: widget.circleSize ?? 22,
            height: widget.circleSize ?? 22,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
