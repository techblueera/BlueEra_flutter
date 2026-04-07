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
    // Captioned card has its own self-contained layout (the entire card is
    // the design), so it short-circuits the generic Column wrapper used by
    // legacy shapes.
    //
    // Thumbnails: render the *full-size* card and let FittedBox scale it
    // uniformly into whatever box the carousel gives us. That way the
    // preview looks identical to the full-screen version (just smaller)
    // and we don't need a separate set of "small" sizes that risk
    // overflowing the 180px-tall picker tile.
    if (design.shape == QrDesignShape.captionedCard) {
      final card = _buildCaptionedCard();
      return GestureDetector(
        onTap: onTap,
        child: isThumbnail
            ? FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: card,
              )
            : card,
      );
    }

    final qrSize = isThumbnail ? 80.0 : 200.0;
    final fontSize = isThumbnail ? 8.0 : 14.0;
    final logoSize = isThumbnail ? 20.0 : 48.0;
    final logoFontSize = isThumbnail ? 7.0 : 16.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
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
                  isThumbnail
                      ? design.name
                      : userName.isNotEmpty
                          ? userName
                          : design.name,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColors.secondaryTextColor, width: 0.5),
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

  // ───────────────────────────────────────────────────────────────────────
  // CAPTIONED CARD — the new, attractive design (matches the dummy mock).
  // ───────────────────────────────────────────────────────────────────────

  Widget _buildCaptionedCard() {
    final accent = design.accentColor ?? design.borderColor;
    final headline = design.headlineColor ?? const Color(0xFF1A1A2E);
    final captionColor = design.captionColor ?? const Color(0xFF3D3A1F);

    // Always render at the full-size dimensions. Thumbnail rendering is
    // handled by an outer FittedBox in build() which uniformly scales the
    // entire card down to fit the carousel tile — keeping the preview a
    // perfect miniature of the full-screen version.
    const cardPadding = 18.0;
    const cardRadius = 22.0;
    const qrSize = 200.0;
    const qrPadding = 10.0;
    const headerTitleSize = 16.0;
    const headerSubSize = 10.0;
    const captionSize = 14.0;
    const chipSize = 10.0;
    const taglineSize = 10.0;
    const logoSize = 44.0;
    const logoFontSize = 14.0;

    final cardDecoration = BoxDecoration(
      gradient: design.backgroundGradient,
      color: design.backgroundGradient == null ? design.backgroundColor : null,
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(
        color: accent,
        width: design.borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.18),
          blurRadius: 18,
          spreadRadius: 1,
          offset: const Offset(0, 6),
        ),
      ],
    );

    return Container(
      width: 280, // fixed natural width — FittedBox scales for thumbnails
      padding: const EdgeInsets.all(cardPadding),
      decoration: cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header pill: title + subtitle ──
          if ((design.headerTitle ?? '').isNotEmpty)
            _buildHeaderPill(
              accent: accent,
              headline: headline,
              titleSize: headerTitleSize,
              subSize: headerSubSize,
            ),

          const SizedBox(height: 12),

          // ── Caption above QR ──
          if ((design.captionText ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: CustomText(
                design.captionText!,
                fontSize: captionSize,
                fontWeight: FontWeight.w700,
                color: captionColor,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          const SizedBox(height: 10),

          // ── QR code with rounded white plate ──
          Container(
            padding: const EdgeInsets.all(qrPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent, width: 1.5),
            ),
            child: SizedBox(
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
                    errorStateBuilder: (context, error) =>
                        const Center(child: CustomText('QR Error')),
                  ),
                  if (design.showBranding)
                    Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: design.qrColor, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: CustomText(
                        'BE',
                        fontSize: logoFontSize,
                        fontWeight: FontWeight.w700,
                        color: design.qrColor,
                        letterSpacing: 1,
                        height: 1,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Feature chips row (Parking issue • Emergency • Vehicle alert) ──
          if (design.featureChips.isNotEmpty)
            _buildFeatureChips(
              accent: accent,
              fontSize: chipSize,
              textColor: captionColor,
            ),

          const SizedBox(height: 10),

          // ── Footer tagline ──
          if ((design.footerTagline ?? '').isNotEmpty)
            CustomText(
              design.footerTagline!,
              fontSize: taglineSize,
              fontWeight: FontWeight.w500,
              color: captionColor,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 10),

          // ── BlueEra logo strip + short code ──
          _buildBrandingFooter(
            accent: accent,
            headline: headline,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPill({
    required Color accent,
    required Color headline,
    required double titleSize,
    required double subSize,
  }) {
    final pillBg = design.backgroundGradient != null
        ? Colors.white.withValues(alpha: 0.25)
        : accent.withValues(alpha: 0.12);
    final pillBorder = design.backgroundGradient != null
        ? Colors.white.withValues(alpha: 0.6)
        : accent.withValues(alpha: 0.6);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pillBorder, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: headline,
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: 14,
                  color: design.backgroundGradient != null
                      ? design.qrColor
                      : (design.backgroundColor),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: CustomText(
                  design.headerTitle!,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  color: headline,
                  letterSpacing: 0.2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if ((design.headerSubtitle ?? '').isNotEmpty) ...[
            const SizedBox(height: 3),
            CustomText(
              design.headerSubtitle!,
              fontSize: subSize,
              fontWeight: FontWeight.w500,
              color: headline.withValues(alpha: 0.75),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureChips({
    required Color accent,
    required double fontSize,
    required Color textColor,
  }) {
    final chips = design.featureChips;
    final separator = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: accent,
          shape: BoxShape.circle,
        ),
      ),
    );

    final children = <Widget>[];
    for (var i = 0; i < chips.length; i++) {
      children.add(
        Flexible(
          child: CustomText(
            chips[i],
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: textColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
      if (i != chips.length - 1) children.add(separator);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }

  Widget _buildBrandingFooter({
    required Color accent,
    required Color headline,
  }) {
    final boxColor = design.backgroundGradient != null
        ? Colors.white.withValues(alpha: 0.18)
        : accent.withValues(alpha: 0.10);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: headline,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: CustomText(
                  'B',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: design.backgroundGradient != null
                      ? design.qrColor
                      : design.backgroundColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              CustomText(
                'BlueEra',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: headline,
                letterSpacing: 0.4,
              ),
            ],
          ),
          CustomText(
            _shortCode(),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: headline.withValues(alpha: 0.75),
            letterSpacing: 0.5,
          ),
        ],
      ),
    );
  }

  String _shortCode() {
    // Last 6 alphanum chars from the qrData → shows like "QR_X8M9KL".
    final cleaned = qrData.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (cleaned.length <= 6) return 'QR_${cleaned.toUpperCase()}';
    return 'QR_${cleaned.substring(cleaned.length - 6).toUpperCase()}';
  }

  // ───────────────────────────────────────────────────────────────────────
  // LEGACY SHAPES — preserved exactly as before.
  // ───────────────────────────────────────────────────────────────────────

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
                border: Border.all(
                    color: design.qrColor, width: isThumbnail ? 1 : 2),
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
            border: Border.all(
                color: design.borderColor, width: design.borderWidth),
          ),
          child: qrContent,
        );
      case QrDesignShape.rounded:
        return Container(
          padding: EdgeInsets.all(isThumbnail ? 4 : 12),
          decoration: BoxDecoration(
            color: design.backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: design.borderColor, width: design.borderWidth),
          ),
          child: qrContent,
        );
      case QrDesignShape.rectangle:
        return Container(
          padding: EdgeInsets.all(isThumbnail ? 4 : 12),
          decoration: BoxDecoration(
            color: design.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: design.borderColor, width: design.borderWidth),
          ),
          child: qrContent,
        );
      case QrDesignShape.captionedCard:
        // Should not be reached — handled in build().
        return _buildCaptionedCard();
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
        child: SizedBox(
            width: totalWidth - (isThumbnail ? 16 : 32), child: qrContent),
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
