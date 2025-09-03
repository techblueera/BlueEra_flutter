import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/global_message_service.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class AnimatedMessageBox extends StatefulWidget {
  final GlobalMessageService controller;

  const AnimatedMessageBox({required this.controller});

  @override
  State<AnimatedMessageBox> createState() => _AnimatedMessageBoxState();
}

class _AnimatedMessageBoxState extends State<AnimatedMessageBox> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // ⏱️ Adjust duration as needed
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.controller.hide();
      }
    });

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_progressController);
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(10.0),
      color: AppColors.white,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.black25,
              blurRadius: 11.0,
              offset: Offset(-1, 0)
            )
          ]
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20, vertical: SizeConfig.size12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LocalAssets(imagePath: AppIconAssets.rightCircleOutlineBlue),
                  SizedBox(width: SizeConfig.size5),
                  Flexible(
                    child: CustomText(
                       widget.controller.message,
                      textAlign: TextAlign.center,
                      color: AppColors.black30,
                      fontSize: SizeConfig.large,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final animatedWidth = _animation.value * SizeConfig.screenWidth;

                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 4,
                      width: animatedWidth,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
