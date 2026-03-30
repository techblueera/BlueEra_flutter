import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';


class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(

      child: Center(child: CustomText("Coming soon...")),
    );
  }
}
