import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/qr_code/model/qr_design_model.dart';
import 'package:BlueEra/features/common/qr_code/view/qr_design_card_widget.dart';
import 'package:BlueEra/features/common/qr_code/view/qr_fullscreen_view.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class QrDesignOptionsScreen extends StatelessWidget {
  final String userName;

  const QrDesignOptionsScreen({super.key, required this.userName});

  String get _qrData => 'https://emergency.blueera.ai/$userId';

  @override
  Widget build(BuildContext context) {
    final designs = QrDesignModel.designs;
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
appBar: CommonBackAppBar(title:  'QR Sticker Designs',),
      // appBar: AppBar(
      //   backgroundColor: AppColors.white,
      //   elevation: 0,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back, color: AppColors.black),
      //     onPressed: () => Navigator.pop(context),
      //   ),
      //   title: const CustomText(
      //     'QR Sticker Designs',
      //     fontSize: 16,
      //     fontWeight: FontWeight.w600,
      //     color: AppColors.mainTextColor,
      //   ),
      //   centerTitle: false,
      // ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
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
