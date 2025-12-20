import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
class MeMenuCardDesign extends StatelessWidget {
  const MeMenuCardDesign({super.key, required this.title, required this.icon, this.showCount, this.count, this.showToggleButton});
  final String title;
  final String icon;
  final bool? showCount;
  final bool? showToggleButton;
  final String? count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8,vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:AppColors.greyE5
        ),
        color: AppColors.white
      ),
      padding: EdgeInsets.symmetric(horizontal: 14,vertical: 18),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.store, color: AppColors.secondaryTextColor,),
              SizedBox(
                width: SizeConfig.size12,
              ),
              CustomText(
                  "${title}",
                fontSize: 18,
                fontWeight: FontWeight.normal,
                color: AppColors.secondaryTextColor,
          
              )
            ],
          ),
          if(showCount??false)
          CustomText("${count}",
          fontSize: 18,),
          if(showToggleButton??false)
          CustomToggleSwitch()
        ],
      ),
    );
  }
}
class CustomToggleSwitch extends StatefulWidget {
  const CustomToggleSwitch({super.key});

  @override
  State<CustomToggleSwitch> createState() => _CustomToggleSwitchState();
}

class _CustomToggleSwitchState extends State<CustomToggleSwitch> {
  bool isOn = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => isOn = !isOn);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 22,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isOn ? Colors.green : Colors.grey.shade400,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
