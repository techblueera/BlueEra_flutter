import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/model/doctor_discover_summary.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Discover card for one standalone doctor — laid out to `docs/drcard_new.png`:
/// square photo with a rating pill, name + overflow menu, specialization pill,
/// experience and degree rows behind soft grey icon tiles, a tag chip strip
/// capped at three with a red "+N More", an expandable availability bar, and a
/// fee + "Book Now" footer.
///
/// Sizes and colours below are MEASURED off that reference rather than guessed.
/// The mock renders a ~412dp-wide screen, and this card is `screen − 24` (the
/// list's own padding, see [DoctorDiscoverListScreen]), so each pixel value in
/// the file was converted at that card width — hence the odd-looking exact
/// numbers (130 photo, 24 tiles) instead of round ones.
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
/// Card corner, and therefore the footer's bottom corners too — the footer
/// paints its own fill, so the two radii have to stay in step.
const double _kCardRadius = 12;

/// Hairline round the specialization pill and the tag chips. Cooler than
/// [AppColors.greyE5]; the reference draws every outline in this blue-grey.
const Color _kHairline = Color(0xFFE5E9F2);

/// Slightly darker hairline for the availability box, which is a container
/// rather than a chip and reads a step heavier in the reference.
const Color _kAvailBorder = Color(0xFFDDE2EE);

/// The reference's red — a pink-leaning one used for "+N More" and for the
/// closing time / "Closed today". NOT [Colors.red], which is duller and warmer.
const Color _kAccentRed = Color(0xFFFF2C55);

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

  /// Wash behind the small leading icon tiles. Sampled off the reference as
  /// the SAME pale grey the footer uses (#F5F7FD ≈ [AppColors.geryFC]), not the
  /// blue tint this card carried before — only the glyph inside is blue.
  static const Color _iconTileBg = AppColors.geryFC;

  static const int _maxChips = 3;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: CustomFormCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(_kCardRadius),
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
                      doctor.name.isNotEmpty
                          ? doctor.name
                          : AppStrings.doctorDiscoverFallbackName.tr,
                      fontSize: SizeConfig.large18,
                      fontWeight: FontWeight.w800,
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
              // Composed here rather than read off `doctor.experienceLabel`,
              // which hardcodes the English "Years" — the whole line has to
              // come from one translated pattern so languages that put the
              // count elsewhere can move it.
              if (_experienceYears > 0) ...[
                SizedBox(height: SizeConfig.size12),
                _iconLine(
                  icon: _experienceGlyph(),
                  child: CustomText(
                    _experienceText,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (doctor.degreeLabel.isNotEmpty) ...[
                SizedBox(height: SizeConfig.size10),
                _iconLine(
                  // Filled mortarboard, as in the reference — the outlined
                  // school glyph disappears at 15px inside the tile.
                  icon: const Icon(Icons.school,
                      size: 15, color: AppColors.primaryColor),
                  child: CustomText(
                    doctor.degreeLabel,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    color: AppColors.grey7E,
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

  /// `0` and `null` are treated alike — both mean "not filled in" rather than
  /// "no experience", so the row hides itself either way.
  int get _experienceYears => doctor.experienceYears ?? 0;

  String get _experienceText => (_experienceYears == 1
          ? AppStrings.doctorDiscoverExperienceYearFmt
          : AppStrings.doctorDiscoverExperienceYearsFmt)
      .trParams({'count': '$_experienceYears'});

  /// Square portrait with the rating pill floating over its top-left corner.
  ///
  /// 130 rather than the 110 this card used to draw: in the reference the photo
  /// is ~36% of the card, which is what makes the degree line wrap to the two
  /// ellipsized rows shown there instead of running long.
  Widget _photo() {
    final image = doctor.logo.isNotEmpty ? doctor.logo : doctor.coverPicture;
    return SizedBox(
      width: SizeConfig.size130,
      height: SizeConfig.size130,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: SizeConfig.size130,
              height: SizeConfig.size130,
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
        // The reference's scrim measures ~20% black, which only works because
        // its mock photo is a mid-grey studio backdrop — over a light portrait
        // that leaves white text on near-white. 0.40 is the lightest value that
        // still holds the reference's airy look on any photo.
        color: Colors.black.withValues(alpha: 0.40),
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
        child: Icon(Icons.more_vert, size: 20, color: AppColors.grey7E),
      );
    }
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      splashRadius: 18,
      constraints: const BoxConstraints(minWidth: 140),
      icon: Icon(Icons.more_vert, size: 20, color: AppColors.grey7E),
      onSelected: (value) {
        if (value == 'profile') {
          widget.onTap();
        } else {
          ShareService.instance.openShareSheet(
            text: AppStrings.doctorDiscoverShareFmt
                .trParams({'name': doctor.name}),
            subject: doctor.name,
          );
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'profile',
          child:
              CustomText(AppStrings.viewProfile.tr, fontSize: SizeConfig.small),
        ),
        PopupMenuItem(
          value: 'share',
          child: CustomText(AppStrings.share.tr, fontSize: SizeConfig.small),
        ),
      ],
    );
  }

  /// Hugging outlined pill — the reference sizes it to the text, so a long
  /// specialization stretches it and a short one leaves the row bare.
  Widget _specializationPill() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kHairline),
      ),
      child: CustomText(
        doctor.headline,
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w500,
        color: AppColors.grey7E,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// The experience glyph: a person outline wearing a small star, which is one
  /// icon in the reference's own set and none in Material's. Stacked here — the
  /// star sits in a tile-coloured disc so the two outlines don't run together
  /// at this size — rather than shipped as a new asset for a single card.
  Widget _experienceGlyph() {
    return SizedBox(
      width: 16,
      height: 16,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            top: 0,
            left: 0,
            child: Icon(Icons.person_outline,
                size: 14, color: AppColors.primaryColor),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: _iconTileBg,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(0.5),
              child: const Icon(Icons.star,
                  size: 8, color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  /// One "pale tile + text" line, used for experience and degree. The tile is
  /// 24 square in the reference — small enough that the degree's second line
  /// clears it, which is what keeps that row's text block centred against it.
  Widget _iconLine({required Widget icon, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: SizeConfig.size24,
          height: SizeConfig.size24,
          decoration: BoxDecoration(
            color: _iconTileBg,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: icon,
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

    // ONE strip, never two: three chips sharing the row with "+N More" pinned
    // at its end, exactly as the reference draws it. A [Wrap] was the obvious
    // choice and the wrong one — three chips of real tag text plus the counter
    // overrun the row by a few points on most phones, and the counter drops to
    // a second line, which is the one thing the reference never shows.
    //
    // Each chip is [Flexible], so a long tag ellipsizes inside its share of the
    // row instead of pushing the counter off the end.
    return Row(
      children: [
        for (int i = 0; i < visible.length; i++) ...[
          if (i > 0) SizedBox(width: SizeConfig.size5),
          Flexible(child: _chip(visible[i])),
        ],
        // "+N More" repeats the card tap rather than expanding in place — the
        // full list lives on the profile, which is one tap away anyway. Left
        // unflexed so it always keeps its full width.
        if (more > 0) ...[
          SizedBox(width: SizeConfig.size5),
          _chip(
            AppStrings.doctorDiscoverMoreFmt.trParams({'count': '$more'}),
            accent: true,
          ),
        ],
      ],
    );
  }

  Widget _chip(String label, {bool accent = false}) {
    final color = accent ? _kAccentRed : AppColors.grey7E;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent ? _kAccentRed : _kHairline),
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
        border: Border.all(color: _kAvailBorder),
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
                horizontal: SizeConfig.size12,
                vertical: SizeConfig.size10,
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined,
                      size: 16, color: AppColors.primaryColor),
                  SizedBox(width: SizeConfig.size6),
                  CustomText(
                    AppStrings.doctorDiscoverAvailability.tr,
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
                      color: AppColors.grey7E,
                    ),
                ],
              ),
            ),
          ),
          if (_availabilityExpanded && canExpand) ...[
            Container(height: 0.5, color: _kAvailBorder),
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
        AppStrings.doctorDiscoverTimingNotSet.tr,
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
        AppStrings.doctorDiscoverClosedToday.tr,
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w600,
        color: _kAccentRed,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final day = _dayLabel(doctor.todayDayLabel);
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
                  color: AppColors.grey7E,
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
                color: AppColors.grey7E,
              ),
            ),
            TextSpan(
              text: close,
              style: TextStyle(
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: _kAccentRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The server sends weekday names in English (`timing.today.day` and each
  /// `timing.schedule[].day`). Only the visible text is translated — anything
  /// that keys off the day still uses the raw value. Unknown input falls
  /// through untouched rather than rendering blank.
  static String _dayLabel(String day) {
    switch (day) {
      case 'Monday':
        return AppStrings.monday.tr;
      case 'Tuesday':
        return AppStrings.tuesday.tr;
      case 'Wednesday':
        return AppStrings.wednesday.tr;
      case 'Thursday':
        return AppStrings.thursday.tr;
      case 'Friday':
        return AppStrings.friday.tr;
      case 'Saturday':
        return AppStrings.saturday.tr;
      case 'Sunday':
        return AppStrings.sunday.tr;
    }
    return day;
  }

  Widget _weeklyRow(Map row) {
    final day = _dayLabel(row['day']?.toString() ?? '');
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
              color: AppColors.grey7E,
            ),
          ),
          CustomText(
            hasWindow ? '$open – $close' : AppStrings.closed.tr,
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
        vertical: SizeConfig.size14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.geryFC,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(_kCardRadius),
          bottomRight: Radius.circular(_kCardRadius),
        ),
      ),
      child: Row(
        children: [
          // Fee block only when the doctor actually set one. With no fee the
          // CTA simply takes the full width — no "₹0", no "N/A".
          //
          // The split is even rather than "fee takes what it needs": in the
          // reference the button is ~47% of the card, which a hugging button
          // never reaches — it would sit at roughly 40% and leave the footer
          // looking lopsided next to the mock.
          if (doctor.hasFee) ...[
            Expanded(child: _feeBlock()),
            SizedBox(width: SizeConfig.size10),
            Expanded(child: _bookNowButton()),
          ] else
            Expanded(child: _bookNowButton()),
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
          AppStrings.doctorConsultationFee.tr,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w400,
          color: AppColors.grey7E,
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
                    fontSize: SizeConfig.large18,
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

  /// Fills whatever slot the footer gives it — the footer owns the width.
  Widget _bookNowButton() {
    return GestureDetector(
      onTap: widget.onBookNow ?? widget.onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size10,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Flexible + FittedBox: at `large` the label is the widest thing in
            // the footer, and on a narrow phone (or with a long fee) it would
            // otherwise overflow its half of the row rather than shrink.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: CustomText(
                  AppStrings.bookNow.tr,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
            SizedBox(width: SizeConfig.size8),
            const Icon(Icons.arrow_forward, size: 18, color: AppColors.white),
          ],
        ),
      ),
    );
  }
}
