
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class StatBlock extends StatelessWidget {
  final String count;
  final String label;
  final VoidCallback? callback;

  const StatBlock({required this.count, required this.label, this.callback});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){
        if(callback!=null) callback!();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            count,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
          CustomText(
            label,
            color: Color.fromRGBO(107, 124, 147, 1),
            fontWeight: FontWeight.w400,
          ),
        ],
      ),
    );
  }
}