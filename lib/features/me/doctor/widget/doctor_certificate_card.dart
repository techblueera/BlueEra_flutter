import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/doctor/model/doctor_certificate_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Certificate tile — full-bleed image with the title and description over a
/// bottom gradient, as in the Overview carousel.
class DoctorCertificateCard extends StatelessWidget {
  final DoctorCertificate certificate;
  final VoidCallback? onTap;

  /// The Overview carousel uses a fixed width; the grid passes null and lets
  /// the parent size it.
  final double? width;

  const DoctorCertificateCard({
    super.key,
    required this.certificate,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final image = certificate.imageUrl ?? '';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.whiteE5),
          color: AppColors.white,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image.isNotEmpty)
              CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[200]),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            else
              _placeholder(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.all(SizeConfig.size10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                    stops: const [0.35, 0.6, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      certificate.title ?? '',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: SizeConfig.medium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((certificate.description ?? '').isNotEmpty) ...[
                      SizedBox(height: SizeConfig.size4),
                      CustomText(
                        certificate.description!,
                        color: AppColors.whiteE5,
                        fontSize: SizeConfig.small,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF7FAFC),
      child: Center(
        child: Icon(
          Icons.workspace_premium_outlined,
          size: 40,
          color: AppColors.primaryColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
