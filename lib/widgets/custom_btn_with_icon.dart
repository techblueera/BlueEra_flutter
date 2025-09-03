import 'package:flutter/material.dart';

class CommonIconContainerButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final double width;
  final double height;
  final double fontSize;
  final double iconWidth;
  final double iconHeight;

  const CommonIconContainerButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.label,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.black,
    this.borderRadius = 10,
    this.width = 90,
    this.height = 36,
    this.fontSize = 12,
    this.iconWidth = 16,
    this.iconHeight = 16,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: iconWidth,
              height: iconHeight,
              child: FittedBox(child: icon),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
