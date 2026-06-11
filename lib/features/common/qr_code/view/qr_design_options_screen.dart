import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/Emergency/view/emergency_profileScreen.dart';
import 'package:BlueEra/features/common/qr_code/model/qr_design_model.dart';
import 'package:BlueEra/features/common/qr_code/view/qr_design_card_widget.dart';
import 'package:BlueEra/features/common/qr_code/view/qr_fullscreen_view.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class QrDesignOptionsScreen extends StatelessWidget {
  final String userName;

  const QrDesignOptionsScreen({super.key, required this.userName});

  String get _qrData => 'https://emergency.beapp.in/$userId';

  @override
  Widget build(BuildContext context) {
    final designs = QrDesignModel.designs;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        title: AppStrings.qrStickerDesigns.tr,
        buildCustomActionWidget: () => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: InkWell(
            onTap: () => Get.to(() => EmergencyProfileScreen1()),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline,
                      size: 16, color: AppColors.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.viewProfile.tr,
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.61,
            // childAspectRatio: 0.85,
          ),
          itemCount: designs.length,
          itemBuilder: (context, index) {
            final design = designs[index];
            return QrDesignCardWidget(
              design: design,
              qrData: _qrData,
              userName: userName,
              isThumbnail: true,
              onTap: () => _openFullScreen(context, design),
            );
          },
        ),
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
