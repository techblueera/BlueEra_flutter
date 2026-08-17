import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/fallback_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The redesigned doctor listing card from `docs/newdrcard.png`.
///
/// Built as a plain, data-in widget (no controller, no fetch) so the same
/// layout can back both the owner-side preview inside
/// `DoctorRequiredDetailsForm` and, later, the patient-facing listing.
///
/// Every value it renders is a field the dashboard collects up-front — see
/// [DoctorProfile.cardRequiredKeys]. Placeholders are therefore shown for
/// empty values rather than the row being dropped: in the preview the point is
/// to make the still-missing pieces obvious.
class DoctorProfileCardPreview extends StatelessWidget {
  /// Photo url — the business logo. Falls back to a local placeholder.
  final String? photoUrl;

  final String name;

  /// Rating shown in the pill over the photo. Hidden when null or 0 — a fresh
  /// listing has no ratings and a "0.0" badge reads worse than no badge.
  final double? rating;

  /// `specialization[0]` — the chip under the name.
  final String specialization;

  /// Years of experience. Null/0 renders the placeholder.
  final int? experienceYears;

  /// Joined `degree` list, e.g. "MBBS, MD (General Medicine)".
  final String degree;

  /// `expertise` — the checklist inside the blue panel.
  final List<String> services;

  /// Preformatted fee, e.g. "₹1000/Visit". Empty renders the placeholder.
  final String feeLabel;

  /// Null in the preview: the button is drawn exactly as the design shows it
  /// but does nothing, because the owner is looking at their own card.
  final VoidCallback? onBookNow;

  const DoctorProfileCardPreview({
    super.key,
    this.photoUrl,
    required this.name,
    this.rating,
    required this.specialization,
    required this.experienceYears,
    required this.degree,
    required this.services,
    required this.feeLabel,
    this.onBookNow,
  });

  /// Services beyond this are collapsed into the "+N more services" cell.
  static const int _visibleServices = 5;

  static const Color _cardBg = Color(0xFFF4F9FD);
  static const Color _panelBg = Color(0xFFE8F3FA);
  static const Color _iconBoxBg = Color(0xFFE1F0FF);
  static const Color _ratingPillBg = Color(0xFF243447);
  static const Color _tick = Color(0xFF2BA84A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE7F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _photo(),
              SizedBox(width: SizeConfig.size12),
              Expanded(child: _identity()),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          _servicesPanel(),
          SizedBox(height: SizeConfig.size12),
          _feeRow(),
        ],
      ),
    );
  }

  // ── Photo + rating pill ───────────────────────────────────────────────

  Widget _photo() {
    return SizedBox(
      width: 108,
      height: 128,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FallbackNetworkImage(urls: [photoUrl]),
            ),
          ),
          if ((rating ?? 0) > 0)
            Positioned(
              top: SizeConfig.size6,
              left: SizeConfig.size6,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size8,
                  vertical: SizeConfig.size4,
                ),
                decoration: BoxDecoration(
                  color: _ratingPillBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 13, color: Color(0xFFFFC107)),
                    SizedBox(width: SizeConfig.size4),
                    CustomText(
                      rating!.toStringAsFixed(1),
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Name · specialization · experience · degree ───────────────────────

  Widget _identity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          name.isEmpty ? AppStrings.doctorCardNamePlaceholder.tr : name,
          fontSize: SizeConfig.large18,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: SizeConfig.size8),
        _specializationChip(),
        SizedBox(height: SizeConfig.size10),
        _iconLine(
          icon: Icons.person_outline,
          child: CustomText(
            experienceYears == null || experienceYears! <= 0
                ? AppStrings.doctorCardExperiencePlaceholder.tr
                : '$experienceYears ${AppStrings.doctorYears.tr} '
                    '${AppStrings.doctorExperience.tr}',
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w700,
            color: _valueColor(experienceYears != null && experienceYears! > 0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: SizeConfig.size8),
        _iconLine(
          icon: Icons.school_outlined,
          child: CustomText(
            degree.isEmpty
                ? AppStrings.doctorCardDegreePlaceholder.tr
                : degree,
            fontSize: SizeConfig.medium,
            color: _valueColor(degree.isNotEmpty),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _specializationChip() {
    final filled = specialization.isNotEmpty;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size6,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4DEE7)),
      ),
      child: CustomText(
        filled
            ? specialization
            : AppStrings.doctorCardSpecializationPlaceholder.tr,
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w600,
        color: _valueColor(filled),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _iconLine({required IconData icon, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _iconBoxBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primaryColor),
        ),
        SizedBox(width: SizeConfig.size8),
        Expanded(child: child),
      ],
    );
  }

  // ── Services checklist ────────────────────────────────────────────────

  Widget _servicesPanel() {
    final shown = services.take(_visibleServices).toList();
    final extra = services.length - shown.length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size10,
      ),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: shown.isEmpty
          ? CustomText(
              AppStrings.doctorCardServicesPlaceholder.tr,
              fontSize: SizeConfig.small,
              color: AppColors.grey99,
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                // Two columns, as in the design. The gutter is split off the
                // available width first so a long service name wraps inside
                // its own column instead of pushing the row over.
                final columnWidth =
                    (constraints.maxWidth - SizeConfig.size10) / 2;
                return Wrap(
                  spacing: SizeConfig.size10,
                  runSpacing: SizeConfig.size8,
                  children: [
                    for (final service in shown)
                      SizedBox(
                        width: columnWidth,
                        child: _serviceRow(service),
                      ),
                    if (extra > 0)
                      SizedBox(
                        width: columnWidth,
                        child: CustomText(
                          '+$extra ${AppStrings.doctorCardMoreServices.tr}',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _serviceRow(String service) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.check_circle_outline, size: 15, color: _tick),
        ),
        SizedBox(width: SizeConfig.size6),
        Expanded(
          child: CustomText(
            service,
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Fee + Book Now ────────────────────────────────────────────────────

  Widget _feeRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                AppStrings.doctorConsultationFee.tr,
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
              ),
              SizedBox(height: SizeConfig.size2),
              CustomText(
                feeLabel.isEmpty
                    ? AppStrings.doctorCardFeePlaceholder.tr
                    : feeLabel,
                fontSize: SizeConfig.large18,
                fontWeight: FontWeight.w800,
                color: _valueColor(feeLabel.isNotEmpty),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        // Drawn even in the preview so the owner sees the card exactly as a
        // patient will; `onBookNow` is null there, which makes it inert.
        InkWell(
          onTap: onBookNow,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16,
              vertical: SizeConfig.size12,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  AppStrings.bookNow.tr,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
                SizedBox(width: SizeConfig.size6),
                const Icon(Icons.arrow_forward,
                    size: 16, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Filled values read as content; placeholders read as "still to do".
  Color _valueColor(bool filled) =>
      filled ? AppColors.mainTextColor : AppColors.grey99;
}
