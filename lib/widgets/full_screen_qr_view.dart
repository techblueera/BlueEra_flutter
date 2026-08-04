import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Opens [data] as a full-screen QR code.
///
/// Every QR in this app exists to be scanned **off this screen by a second
/// phone**, usually at arm's length, often in sunlight and sometimes through a
/// cracked screen. Inline, a QR is 100px of decoration; the customer's camera
/// needs it big, which is what this is for.
///
/// Pass the same [heroTag] used on the inline code so it grows out of the card
/// instead of cutting to a new page.
Future<void> showFullScreenQr({
  required BuildContext context,
  required String data,
  required String heroTag,
  String? caption,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (_, __, ___) => FullScreenQrView(
        data: data,
        heroTag: heroTag,
        caption: caption,
      ),
    ),
  );
}

/// The blown-up QR. White card on a dimmed backdrop, sized to the narrower
/// screen edge so it fills the display in either orientation without ever being
/// clipped.
class FullScreenQrView extends StatelessWidget {
  final String data;
  final String heroTag;

  /// Optional line under the code — a UPI id, a name — so whoever is scanning
  /// can check they are paying the right person before they do.
  final String? caption;

  const FullScreenQrView({
    super.key,
    required this.data,
    required this.heroTag,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final side = (size.shortestSide * 0.8).clamp(200.0, 420.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        // Anywhere, not just the code — this is dismissed one-handed while
        // handing the phone back.
        onTap: () => Navigator.of(context).maybePop(),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Hero(
            tag: heroTag,
            child: Container(
              padding: EdgeInsets.all(SizeConfig.size16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QrImageView(
                    data: data,
                    version: QrVersions.auto,
                    size: side,
                    padding: EdgeInsets.zero,
                    // Scanned off a screen, often in sunlight.
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    gapless: true,
                  ),
                  if (caption != null && caption!.trim().isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size12),
                    CustomText(
                      caption!,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
