import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/common/qr_code/model/qr_design_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrDesignCardWidget extends StatelessWidget {
  final QrDesignModel design;
  final String qrData;
  final String userName;
  final bool isSelected;
  final bool isThumbnail;
  final VoidCallback? onTap;

  const QrDesignCardWidget({
    super.key,
    required this.design,
    required this.qrData,
    required this.userName,
    this.isSelected = false,
    this.isThumbnail = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final qrSize = isThumbnail ? 80.0 : 200.0;
    final fontSize = isThumbnail ? 8.0 : 14.0;
    final padding = isThumbnail ? 8.0 : 20.0;
    final logoSize = isThumbnail ? 20.0 : 48.0;
    final logoFontSize = isThumbnail ? 7.0 : 16.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          // border: isSelected
          //     ? Border.all(color: AppColors.primaryColor, width: 2.5)
          //     : Border.all(color: AppColors.whiteE5, width: 1),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (design.showLabel)
              Padding(
                padding: EdgeInsets.only(bottom: isThumbnail ? 4 : 8),
                child: CustomText(
                  isThumbnail ? design.name : userName.isNotEmpty ? userName : design.name,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (design.subtitle != null && !isThumbnail)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.secondaryTextColor, width: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomText(
                    design.subtitle!,
                    fontSize: 11,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ),
            const SizedBox(height: 20),

            _buildQrContainer(qrSize, logoSize, logoFontSize),
            if (design.subtitle != null && isThumbnail)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: CustomText(
                  design.subtitle!,
                  fontSize: 7,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

          ],
        ),
      ),
    );
  }

  Widget _buildQrContainer(double qrSize, double logoSize, double logoFontSize) {
    Widget qrContent = SizedBox(
      width: qrSize,
      height: qrSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: qrSize,
            gapless: true,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: design.qrColor,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: design.qrColor,
            ),
            errorStateBuilder: (context, error) => const Center(
              child: CustomText("QR Error"),
            ),
          ),
          if (design.showBranding)
            Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: design.qrColor, width: isThumbnail ? 1 : 2),
              ),
              alignment: Alignment.center,
              child: CustomText(
                'BE',
                fontSize: logoFontSize,
                fontWeight: FontWeight.w600,
                color: design.qrColor,
                letterSpacing: 1,
                height: 1,
              ),
            ),
        ],
      ),
    );

    switch (design.shape) {
      case QrDesignShape.house:
        return _buildHouseShape(qrContent, qrSize);
      case QrDesignShape.circle:
        return Container(
          padding: EdgeInsets.all(isThumbnail ? 4 : 12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: design.backgroundColor,
            border: Border.all(color: design.borderColor, width: design.borderWidth),
          ),
          child: qrContent,
        );
      case QrDesignShape.rounded:
        return Container(
          padding: EdgeInsets.all(isThumbnail ? 4 : 12),
          decoration: BoxDecoration(
            color: design.backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: design.borderColor, width: design.borderWidth),
          ),
          child: qrContent,
        );
      case QrDesignShape.rectangle:
        return Container(
          padding: EdgeInsets.all(isThumbnail ? 4 : 12),
          decoration: BoxDecoration(
            color: design.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: design.borderColor, width: design.borderWidth),
          ),
          child: qrContent,
        );
    }
  }

  Widget _buildHouseShape(Widget qrContent, double qrSize) {
    final totalWidth = qrSize + (isThumbnail ? 16 : 32);
    return CustomPaint(
      painter: _HouseShapePainter(
        borderColor: design.borderColor,
        backgroundColor: design.backgroundColor,
        borderWidth: design.borderWidth,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: isThumbnail ? 14 : 28,
          left: isThumbnail ? 8 : 16,
          right: isThumbnail ? 8 : 16,
          bottom: isThumbnail ? 8 : 16,
        ),
        child: SizedBox(width: totalWidth - (isThumbnail ? 16 : 32), child: qrContent),
      ),
    );
  }
}

class _HouseShapePainter extends CustomPainter {
  final Color borderColor;
  final Color backgroundColor;
  final double borderWidth;

  _HouseShapePainter({
    required this.borderColor,
    required this.backgroundColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();
    final roofHeight = size.height * 0.15;

    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, roofHeight);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, roofHeight);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
