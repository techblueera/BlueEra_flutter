import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn_with_icon.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class LoadErrorWidget extends StatelessWidget {
  const LoadErrorWidget({
    Key? key,
    required this.onRetry,
    this.errorMessage = 'Failed to load videos',
  }) : super(key: key);

  /// Callback invoked when the user presses the “Try Again” button.
  final VoidCallback onRetry;

  /// Optional override for the text under the icon.
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            SizedBox(height: SizeConfig.size16),
            CustomText(
              errorMessage,
              color: AppColors.mainTextColor,
              fontSize: SizeConfig.large18,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size12),
            CommonIconContainerButton(
              width: SizeConfig.size120,
              icon: Icon(Icons.refresh, color: AppColors.white),
              onTap: onRetry,
              label: 'Try Again',
              textColor: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }
}