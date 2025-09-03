import 'package:flutter/material.dart';

import '../../../../../../core/constants/size_config.dart';
import '../../../../../../widgets/custom_text_cm.dart';

class CommonPopupButton extends StatelessWidget {
  final Function(String)? onSelected;
  final List<PopupMenuEntry<String>> menuItems;
  final String title;

  const CommonPopupButton({
    Key? key,
    required this.menuItems,
    this.onSelected,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) => menuItems,
      child: Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size10),
        border: Border.all(
          color: Colors.blue, // 🔵 Border color
                // 🧱 Border width
        ),
      ),
      child: Center(
          child:
          Row(
            mainAxisSize: MainAxisSize.min,
            children:  [

              CustomText(
                title,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
              SizedBox(width: SizeConfig.size4),
              Icon(Icons.keyboard_arrow_down, color: Colors.blue),

            ],
          )

      ),
    ),

    );
  }
}
