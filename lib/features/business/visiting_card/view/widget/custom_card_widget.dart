import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CustomCardWidget extends StatelessWidget {
  final Widget child;
  const CustomCardWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.0),
     decoration: BoxDecoration(
       color: AppColors.white,
       borderRadius: BorderRadius.circular(10.0),
     ),
      child: child,
    );
  }
}
