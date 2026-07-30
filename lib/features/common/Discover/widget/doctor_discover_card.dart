import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/model/doctor_discover_summary.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Discover card for one standalone doctor — laid out to `docs/drcard.png`:
/// square photo with a rating pill, name + overflow menu, specialization pill,
/// experience and degree rows behind soft blue icon tiles, a tag chip strip
/// capped at three with a red "+N More", an expandable availability bar, and a
/// fee + "Book Now" footer.
///
/// Every line is driven by the doctor enrichment on the business listing
/// (guide §14). Two rules the card must honour:
///
/// 1. `consultationFee == null` means "not set" — the fee block is hidden
///    entirely rather than rendered as `₹0`.
/// 2. Every other field is optional too. The backend returns the listing with
///    empty arrays, zero counts and `timing: null` when the doctor service is
///    briefly unavailable, so each row hides itself (or says "Timing not set")
///    instead of printing a placeholder.
class DoctorDiscoverCard extends StatefulWidget {
  final DoctorDiscoverSummary doctor;
  final VoidCallback onTap;

  /// Footer CTA. Defaults to opening the profile — same destination as the
  /// card body — so the button is never a dead end.
  final VoidCallback? onBookNow;

  /// Overflow (⋮) menu. When null the card shows its own menu with
  /// "View Profile" and "Share".
  final VoidCallback? onMenuTap;

  const DoctorDiscoverCard({
    super.key,
    required this.doctor,
    required this.onTap,
    this.onBookNow,
    this.onMenuTap,
  });

  @override
  State<DoctorDiscoverCard> createState() => _DoctorDiscoverCardState();
}

class _DoctorDiscoverCardState extends State<DoctorDiscoverCard> {
  /// Availability chevron state. Collapsed shows today only; expanded lists
  /// the saved weekly hours.
  bool _availabilityExpanded = false;

  DoctorDiscoverSummary get doctor => widget.doctor;

  /// Soft blue wash behind the small leading icon tiles.
  static Color get _iconTileBg =>
      AppColors.primaryColor.withValues(alpha: 0.10);

  static const int _maxChips = 3;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: CustomFormCard(
        padding: EdgeInsets.zero,
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(SizeConfig.size12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerRow(),
                  if (_chips.isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size12),
                    _chipsRow(),
                  ],
                  SizedBox(height: SizeConfig.size12),
                  _availabilityBlock(),
                ],
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  // ── Header: photo + name + specialization + experience + degree ─────
  Widget _headerRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _photo(),
        SizedBox(width: SizeConfig.size12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomText(
                      doctor.name.isNotEmpty ? doctor.name : 'Doctor',
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _overflowMenu(),
                ],
              ),
              if (doctor.headline.isNotEmpty) ...[
                SizedBox(height: SizeConfig.size6),
                _specializationPill(),
              ],
              if (doctor.experienceLabel.isNotEmpty) ...[
                SizedBox(height: SizeConfig.size10),
                _iconLine(
                  icon: Icons.person_outline,
                  child: CustomText(
                    '${doctor.experienceLabel} Experience',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (doctor.degreeLabel.isNotEmpty) ...[
                SizedBox(height: SizeConfig.size8),
                _iconLine(
                  icon: Icons.school_outlined,
                  child: CustomText(
                    doctor.degreeLabel,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Square portrait with the rating pill floating over its top-left corner.
  Widget _photo() {
    final image = doctor.logo.isNotEmpty ? doctor.logo : doctor.coverPicture;
    return SizedBox(
      width: SizeConfig.size110,
      height: SizeConfig.size110,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: SizeConfig.size110,
              height: SizeConfig.size110,
              child: image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.greyE5),
                      errorWidget: (_, __, ___) => _photoFallback(),
                    )
                  : _photoFallback(),
            ),
          ),
          // Hidden entirely when the doctor has no ratings yet — a "0.0 ★" pill
          // reads as a bad score rather than as "not rated".
          if (doctor.rating > 0)
            Positioned(top: 6, left: 6, child: _ratingPill()),
        ],
      ),
    );
  }

  Widget _photoFallback() => Container(
        color: AppColors.greyE5,
        alignment: Alignment.center,
        child: Icon(
          Icons.medical_services_outlined,
          size: 34,
          color: Colors.grey.shade500,
        ),
      );

  Widget _ratingPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 12, color: AppColors.yellow),
          const SizedBox(width: 4),
          CustomText(
            doctor.rating.toStringAsFixed(1),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ],
      ),
    );
  }

  Widget _overflowMenu() {
    if (widget.onMenuTap != null) {
      return GestureDetector(
        onTap: widget.onMenuTap,
        child: Icon(Icons.more_vert,
            size: 20, color: AppColors.secondaryTextColor),
      );
    }
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      splashRadius: 18,
      constraints: const BoxConstraints(minWidth: 140),
      icon: Icon(Icons.more_vert,
          size: 20, color: AppColors.secondaryTextColor),
      onSelected: (value) {
        if (value == 'profile') {
          widget.onTap();
        } else {
          ShareService.instance.openShareSheet(
            text: 'Check out ${doctor.name} on BlueEra',
            subject: doctor.name,
          );
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'profile',
          child: CustomText('View Profile', fontSize: SizeConfig.small),
        ),
        PopupMenuItem(
          value: 'share',
          child: CustomText('Share', fontSize: SizeConfig.small),
        ),
      ],
    );
  }

  Widget _specializationPill() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: CustomText(
        doctor.headline,
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w500,
        color: AppColors.secondaryTextColor,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// One "soft blue tile + text" line, used for experience and degree.
  Widget _iconLine({required IconData icon, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: SizeConfig.size30,
          height: SizeConfig.size30,
          decoration: BoxDecoration(
            color: _iconTileBg,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: AppColors.primaryColor),
        ),
        SizedBox(width: SizeConfig.size8),
        Expanded(child: child),
      ],
    );
  }

  // ── Tag chips ───────────────────────────────────────────────────────
  List<String> get _chips => doctor.tagChips;

  Widget _chipsRow() {
    final chips = _chips;
    final visible = chips.take(_maxChips).toList();
    final more = chips.length - visible.length;

    return Wrap(
      spacing: SizeConfig.size8,
      runSpacing: SizeConfig.size8,
      children: [
        ...visible.map((label) => _chip(label)),
        // "+N More" repeats the card tap rather than expanding in place — the
        // full list lives on the profile, which is one tap away anyway.
        if (more > 0) _chip('+$more More', accent: true),
      ],
    );
  }

  Widget _chip(String label, {bool accent = false}) {
    final color = accent ? AppColors.red : AppColors.secondaryTextColor;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent ? AppColors.red : AppColors.greyE5),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: SizeConfig.screenWidth * 0.38),
        child: CustomText(
          label,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w500,
          color: color,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // ── Availability ────────────────────────────────────────────────────
  Widget _availabilityBlock() {
    final weekly = doctor.weeklyTiming;
    final canExpand = weekly.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: canExpand
                ? () => setState(
                    () => _availabilityExpanded = !_availabilityExpanded)
                : null,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size10,
                vertical: SizeConfig.size10,
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined,
                      size: 18, color: AppColors.primaryColor),
                  SizedBox(width: SizeConfig.size8),
                  CustomText(
                    'Availability',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(width: SizeConfig.size8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _todayLabel(),
                    ),
                  ),
                  if (canExpand)
                    Icon(
                      _availabilityExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: AppColors.secondaryTextColor,
                    ),
                ],
              ),
            ),
          ),
          if (_availabilityExpanded && canExpand) ...[
            Container(height: 0.5, color: AppColors.greyE5),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size10,
                vertical: SizeConfig.size8,
              ),
              child: Column(
                children: weekly.map(_weeklyRow).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Collapsed summary: `Monday: 9:00 AM – 6:00 PM`. Three states, because
  /// `timing` is null for any doctor who never set visiting hours — inventing a
  /// default window here would advertise hours the doctor never agreed to.
  Widget _todayLabel() {
    if (!doctor.hasTiming) {
      return CustomText(
        'Timing not set',
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w400,
        color: AppColors.grey7E,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final open = doctor.todayOpenLabel;
    final close = doctor.todayCloseLabel;
    if (!doctor.isOpenToday || (open.isEmpty && close.isEmpty)) {
      return CustomText(
        'Closed today',
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w600,
        color: AppColors.red,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final day = doctor.todayDayLabel;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: RichText(
        maxLines: 1,
        text: TextSpan(
          children: [
            if (day.isNotEmpty)
              TextSpan(
                text: '$day: ',
                style: TextStyle(
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            TextSpan(
              text: open,
              style: TextStyle(
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.greenShade,
              ),
            ),
            TextSpan(
              text: ' – ',
              style: TextStyle(
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
              ),
            ),
            TextSpan(
              text: close,
              style: TextStyle(
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weeklyRow(Map row) {
    final day = row['day']?.toString() ?? '';
    final isOpen = row['isOpen'] == true;
    final open = DoctorDiscoverSummary.formatClock(row['shopOpenTime']);
    final close = DoctorDiscoverSummary.formatClock(row['shopCloseTime']);
    final hasWindow = isOpen && (open.isNotEmpty || close.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              day,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
            ),
          ),
          CustomText(
            hasWindow ? '$open – $close' : 'Closed',
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            color: hasWindow ? AppColors.mainTextColor : AppColors.grey7E,
          ),
        ],
      ),
    );
  }

  // ── Footer: consultation fee + Book Now ─────────────────────────────
  Widget _footer() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.geryFC,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          // Fee block only when the doctor actually set one. With no fee the
          // CTA simply takes the full width — no "₹0", no "N/A".
          if (doctor.hasFee) ...[
            Expanded(child: _feeBlock()),
            SizedBox(width: SizeConfig.size10),
            _bookNowButton(),
          ] else
            Expanded(child: _bookNowButton(fullWidth: true)),
        ],
      ),
    );
  }

  Widget _feeBlock() {
    // `feeLabel` is "₹600/Visit" — split on the slash so the amount can carry
    // the emphasis while the unit stays small, as in the reference.
    final label = doctor.feeLabel;
    final slash = label.indexOf('/');
    final amount = slash == -1 ? label : label.substring(0, slash);
    final unit = slash == -1 ? '' : label.substring(slash);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          'Consultation Fee',
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w400,
          color: AppColors.secondaryTextColor,
        ),
        SizedBox(height: SizeConfig.size2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: RichText(
            maxLines: 1,
            text: TextSpan(
              children: [
                TextSpan(
                  text: amount,
                  style: TextStyle(
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryColor,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: TextStyle(
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mainTextColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bookNowButton({bool fullWidth = false}) {
    return GestureDetector(
      onTap: widget.onBookNow ?? widget.onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: fullWidth ? SizeConfig.size12 : SizeConfig.size24,
          vertical: SizeConfig.size12,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(
              'Book Now',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
            SizedBox(width: SizeConfig.size8),
            const Icon(Icons.arrow_forward, size: 18, color: AppColors.white),
          ],
        ),
      ),
    );
  }
}
