import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/qr_code/model/qr_design_model.dart';
import 'package:BlueEra/features/common/qr_code/view/qr_design_card_widget.dart';
import 'package:BlueEra/features/common/qr_code/view/qr_fullscreen_view.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class QrDesignOptionsWidget extends StatelessWidget {
  final String userName;

  const QrDesignOptionsWidget({super.key, required this.userName});

  String get _qrData => 'https://emergency.blueera.ai/$userId';

  @override
  Widget build(BuildContext context) {
    final designs = QrDesignModel.designs;
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const CustomText(
                  'QR Sticker Designs',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                const Spacer(),
                CustomText(
                  '${designs.length} designs',
                  fontSize: 12,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: CustomText(
              'Tap any design to view full screen',
              fontSize: 12,
              color: AppColors.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: designs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final design = designs[index];
                return SizedBox(
                  width: 140,
                  child: QrDesignCardWidget(
                    design: design,
                    qrData: _qrData,
                    userName: userName,
                    isThumbnail: true,
                    onTap: () => _openFullScreen(context, design),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreen(BuildContext context, QrDesignModel design) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrFullScreenView(
          design: design,
          userName: userName,
        ),
      ),
    );
  }
}
