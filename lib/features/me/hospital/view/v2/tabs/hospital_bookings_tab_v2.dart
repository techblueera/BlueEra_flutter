import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical/controller/hospital_appointment_controller.dart';
import 'package:BlueEra/features/me/medical/model/hospital_appointment_item.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Owner-side bookings tab — renders the doctor cards returned by
/// `GET /hospital-appointments/owner/me` (see
/// `lib/docs/healthcare-appointment-ui-integration.md` §3).
///
/// Layout goals:
///   • Doctor identity first (avatar + name + department + fees), because
///     the owner scans the list to spot which doctor a request landed on.
///   • Appointment slot (date + hours in 24-hour) rendered as two big
///     tiles side-by-side so scanning down the list surfaces "when" at a
///     glance without reading a paragraph.
///   • Patient / note footer only when there's something to show, so
///     lean requests stay compact.
///
/// Accept / Decline still happens on the in-chat `healthcare_booking`
/// card — this tab is a read-only inbox.
class HospitalBookingsTabV2 extends StatefulWidget {
  const HospitalBookingsTabV2({super.key});

  @override
  State<HospitalBookingsTabV2> createState() => _HospitalBookingsTabV2State();
}

class _HospitalBookingsTabV2State extends State<HospitalBookingsTabV2> {
  final _controller = getOrPut(() => HospitalAppointmentController());

  @override
  void initState() {
    super.initState();
    // Hydrate on first paint; the parent RefreshIndicator re-fetches on pull.
    if (_controller.ownerAppointments.isEmpty) {
      _controller.fetchOwnerAppointments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = _controller.isLoadingOwnerAppointments.value;
      final items = _controller.ownerAppointments;

      if (isLoading && items.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size32),
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      if (items.isEmpty) {
        return const _EmptyState();
      }

      // Pending first — that's what the owner needs to act on. Terminal
      // statuses (accepted / declined / cancelled) fall to the bottom so
      // the actionable requests are always visible without scrolling.
      final sorted = _sortedByStatus(items);

      return Padding(
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size12,
          SizeConfig.size12,
          SizeConfig.size12,
          SizeConfig.size12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ListHeader(total: items.length),
            SizedBox(height: SizeConfig.size12),
            for (int i = 0; i < sorted.length; i++) ...[
              if (i > 0) SizedBox(height: SizeConfig.size12),
              _BookingDoctorCard(item: sorted[i]),
            ],
          ],
        ),
      );
    });
  }

  List<HospitalAppointmentItem> _sortedByStatus(
      List<HospitalAppointmentItem> items) {
    int rank(HospitalAppointmentItem e) {
      switch (e.status.toLowerCase()) {
        case 'pending':
          return 0;
        case 'accepted':
          return 1;
        case 'declined':
          return 2;
        case 'cancelled':
          return 3;
        default:
          return 4;
      }
    }

    final copy = List<HospitalAppointmentItem>.from(items);
    copy.sort((a, b) => rank(a).compareTo(rank(b)));
    return copy;
  }
}

/// "Booking Requests · N" strip that sits above the list so the owner
/// sees the inbox depth without counting cards.
class _ListHeader extends StatelessWidget {
  final int total;

  const _ListHeader({required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        CustomText(
          'Booking Requests',
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
        ),
        SizedBox(width: SizeConfig.size8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: CustomText(
            '$total',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size24,
        vertical: SizeConfig.size48,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_note_rounded,
              size: 36,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: SizeConfig.size14),
          CustomText(
            'No booking requests yet',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            "New appointment requests on your hospital's doctors will appear here.",
            fontSize: 12.5,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A single booking row. Three zones separated by dividers:
///   • Doctor header  — avatar (64) + name + dept + fees + status pill
///   • Slot           — Date tile | Time tile (both prominent)
///   • Footer         — patient chip + optional note (only when present)
class _BookingDoctorCard extends StatelessWidget {
  final HospitalAppointmentItem item;

  const _BookingDoctorCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E8EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F001120),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _doctorHeader(),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFEEF1F6),
          ),
          _slotBlock(),
          if (_hasFooter) ...[
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFEEF1F6),
            ),
            _footer(),
          ],
        ],
      ),
    );
  }

  // ─── Doctor header ──────────────────────────────────────────────────

  Widget _doctorHeader() {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.size14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _doctorAvatar(),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        item.doctorName.isEmpty ? 'Doctor' : item.doctorName,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size8),
                    _StatusPill(status: item.status),
                  ],
                ),
                if ((item.department ?? '').isNotEmpty) ...[
                  SizedBox(height: SizeConfig.size2),
                  CustomText(
                    item.department!,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.fees != null) ...[
                  SizedBox(height: SizeConfig.size4),
                  Row(
                    children: [
                      Icon(
                        Icons.currency_rupee_rounded,
                        size: 13,
                        color: AppColors.secondaryTextColor,
                      ),
                      SizedBox(width: 2),
                      CustomText(
                        'Consultation fees · ₹${item.fees}',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _doctorAvatar() {
    final url = item.doctorImage ?? '';
    final placeholder = Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.medical_services_rounded,
        color: AppColors.primaryColor,
        size: 28,
      ),
    );
    if (url.isEmpty) return placeholder;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }

  // ─── Slot block ─────────────────────────────────────────────────────

  Widget _slotBlock() {
    final hasDate = item.appointmentDate != null;
    final hasTime = (item.preferredTime ?? '').isNotEmpty;
    if (!hasDate && !hasTime) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14,
          vertical: SizeConfig.size10,
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 14,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              'No time provided',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size14,
        SizeConfig.size12,
        SizeConfig.size14,
        SizeConfig.size12,
      ),
      child: Row(
        children: [
          if (hasDate)
            Expanded(
              child: _SlotTile(
                icon: Icons.calendar_month_rounded,
                label: 'Appointment Date',
                primary: _formatDate(item.appointmentDate!),
                secondary: _formatWeekday(item.appointmentDate!),
              ),
            ),
          if (hasDate && hasTime) SizedBox(width: SizeConfig.size10),
          if (hasTime)
            Expanded(
              child: _SlotTile(
                icon: Icons.schedule_rounded,
                label: 'Time (24h)',
                primary: _to24h(item.preferredTime!),
                secondary: 'Hours',
              ),
            ),
        ],
      ),
    );
  }

  // ─── Footer (patient + note) ────────────────────────────────────────

  bool get _hasFooter =>
      (item.patientName ?? '').isNotEmpty || (item.note ?? '').isNotEmpty;

  Widget _footer() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size14,
        SizeConfig.size10,
        SizeConfig.size14,
        SizeConfig.size12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((item.patientName ?? '').isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 14,
                  color: AppColors.secondaryTextColor,
                ),
                SizedBox(width: SizeConfig.size6),
                Expanded(
                  child: CustomText(
                    'Patient · ${item.patientName!}',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if ((item.patientName ?? '').isNotEmpty &&
              (item.note ?? '').isNotEmpty)
            SizedBox(height: SizeConfig.size6),
          if ((item.note ?? '').isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.sticky_note_2_outlined,
                  size: 14,
                  color: AppColors.secondaryTextColor,
                ),
                SizedBox(width: SizeConfig.size6),
                Expanded(
                  child: CustomText(
                    item.note!,
                    fontSize: 12,
                    color: AppColors.secondaryTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatWeekday(DateTime d) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    // DateTime.weekday is 1..7 where 1 = Monday
    return days[(d.weekday - 1).clamp(0, 6)];
  }

  /// Best-effort normalization of the free-text `preferredTime` field to
  /// 24-hour `HH:mm`. The sheet now always writes 24-hour, but legacy /
  /// third-party payloads can still arrive as `10:00 AM` — this parser
  /// covers that case so the list is visually consistent.
  ///
  /// Handles single times and ranges (`10:00 – 11:00 AM`,
  /// `10:00 AM – 11:00 AM`, `10:00-11:00`). Falls back to the raw string
  /// if nothing matches, so we never silently blank out a value.
  String _to24h(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    // Split on en-dash, em-dash, or hyphen.
    final parts = trimmed.split(RegExp(r'\s*[–—-]\s*'));
    if (parts.length == 1) {
      return _one24h(parts[0]) ?? trimmed;
    }
    if (parts.length == 2) {
      final endMeridiem = _detectMeridiem(parts[1]);
      final start = _one24h(parts[0], fallbackMeridiem: endMeridiem);
      final end = _one24h(parts[1]);
      if (start != null && end != null) return '$start – $end';
    }
    return trimmed;
  }

  /// Detects a trailing AM/PM on the given token, if any.
  String? _detectMeridiem(String token) {
    final upper = token.toUpperCase();
    if (upper.contains('AM')) return 'AM';
    if (upper.contains('PM')) return 'PM';
    return null;
  }

  /// Normalizes a single `10:00`, `10:00 AM`, `10 PM` etc. to `HH:mm`.
  String? _one24h(String token, {String? fallbackMeridiem}) {
    final raw = token.trim();
    if (raw.isEmpty) return null;
    final upper = raw.toUpperCase();
    final match = RegExp(
      r'^(\d{1,2})(?::(\d{1,2}))?\s*(AM|PM)?$',
    ).firstMatch(upper);
    if (match == null) return null;
    int h = int.parse(match.group(1)!);
    final m = int.tryParse(match.group(2) ?? '0') ?? 0;
    final mer = match.group(3) ?? fallbackMeridiem;
    if (mer != null) {
      if (mer == 'AM' && h == 12) h = 0;
      if (mer == 'PM' && h != 12) h += 12;
    }
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

/// Tinted slot tile — used for both the date and the time cells so
/// they read as siblings in the "when" block.
class _SlotTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String primary;
  final String secondary;

  const _SlotTile({
    required this.icon,
    required this.label,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primaryColor),
              SizedBox(width: SizeConfig.size6),
              CustomText(
                label,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryColor,
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            primary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2),
          CustomText(
            secondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final (Color bg, Color fg, String label, IconData icon) = switch (normalized) {
      'accepted' => (
          AppColors.green00.withValues(alpha: 0.14),
          AppColors.green00,
          'Accepted',
          Icons.check_circle_rounded,
        ),
      'declined' => (
          AppColors.red.withValues(alpha: 0.14),
          AppColors.red,
          'Declined',
          Icons.cancel_rounded,
        ),
      'cancelled' => (
          AppColors.secondaryTextColor.withValues(alpha: 0.14),
          AppColors.secondaryTextColor,
          'Cancelled',
          Icons.do_not_disturb_on_rounded,
        ),
      _ => (
          AppColors.primaryColor.withValues(alpha: 0.14),
          AppColors.primaryColor,
          'Pending',
          Icons.hourglass_bottom_rounded,
        ),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          SizedBox(width: 4),
          CustomText(
            label,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ],
      ),
    );
  }
}
