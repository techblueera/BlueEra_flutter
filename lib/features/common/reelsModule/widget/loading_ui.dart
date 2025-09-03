import 'package:flutter/material.dart';

class LoadingUi extends StatelessWidget {
  const LoadingUi({super.key, this.color, this.size});

  final Color? color;

  final double? size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}
class CustomFormatNumber {
  static String convert(int number) {
    if (number >= 10000000) {
      double millions = number / 1000000;
      return '${millions.toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      double thousands = number / 1000;
      return '${thousands.toStringAsFixed(1)}k';
    } else {
      return number.toString();
    }
  }
}
