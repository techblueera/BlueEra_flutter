import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/education_enquiry_model.dart';
import 'package:BlueEra/features/me/school/controller/education_enquiry_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// In-chat card for a `messageType: "education_enquiry"` message.
///
/// Visually mirrors [ServiceEnquiryMsgCard]: slim header, divider-separated
/// sections (photo / selections / note), and an accept-decline or status
/// footer. The school/owner (receiver) can Accept / Decline while pending;
/// the customer (sender) sees a waiting/decision state.
class EducationEnquiryMsgCard extends StatefulWidget {
  final Messages message;
  final String time;

  const EducationEnquiryMsgCard({
    super.key,
    required this.message,
    required this.time,
  });

  @override
  State<EducationEnquiryMsgCard> createState() =>
      _EducationEnquiryMsgCardState();
}

class _EducationEnquiryMsgCardState extends State<EducationEnquiryMsgCard> {
  bool _isUpdating = false;

  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _line = Color(0xFFF0F2F5);

  EducationEnquiryModel? get _enquiry =>
      widget.message.metadata?.educationEnquiry;

  bool get _isMyMessage => widget.message.myMessage ?? false;

  String get _status => (_enquiry?.status ?? 'pending').toLowerCase();

  bool get _isAccepted => _status == 'accepted';
  bool get _isDeclined => _status == 'declined';

  /// Non-empty selection groups, in display order — each carries its own
  /// tinted icon (mirrors the reference enquiry-details design).
  List<_EnquiryRow> get _rows {
    final e = _enquiry;
    final out = <_EnquiryRow>[];
    (e?.selections ?? const <String, List<String>>{}).forEach((title, values) {
      final items = values.where((s) => s.trim().isNotEmpty).toList();
      if (items.isEmpty) return;
      final (icon, color) = _iconAndColorFor(title);
      out.add(_EnquiryRow(title, items, icon, color));
    });
    return out;
  }

  /// Map a selection group's title to a themed icon + tint. Falls back to a
  /// neutral school icon so unknown groups still render on-brand.
  (IconData, Color) _iconAndColorFor(String title) {
    switch (title.toLowerCase()) {
      case 'course':
      case 'courses':
      case 'program':
      case 'programs':
        return (Icons.menu_book_rounded, const Color(0xFF3B82F6));
      case 'admission for':
      case 'admission':
      case 'level':
      case 'grade':
        return (Icons.school_rounded, const Color(0xFF8B5CF6));
      case 'subjects':
      case 'subject':
      case 'requirements':
      case 'requirement':
        return (Icons.subject_rounded, const Color(0xFF22C55E));
      case 'mode':
      case 'mode of study':
        return (Icons.laptop_rounded, const Color(0xFF0EA5E9));
      case 'timeline':
      case 'duration':
        return (Icons.schedule_rounded, const Color(0xFFF59E0B));
      default:
        return (Icons.school_outlined, const Color(0xFF0EA5E9));
    }
  }

  int get _totalCount {
    var n = 0;
    (_enquiry?.selections ?? const <String, List<String>>{}).forEach((_, v) {
      n += v.where((s) => s.trim().isNotEmpty).length;
    });
    return n;
  }

  List<String> get _photos => _enquiry?.photos ?? const [];

  String get _note => _enquiry?.note ?? '';

  String get _subtitle {
    final parts = <String>[];
    if (_totalCount > 0) {
      parts.add(
          '$_totalCount ${_totalCount == 1 ? AppStrings.itemLabel.tr : AppStrings.itemsLabel.tr}');
    }
    if (_photos.isNotEmpty) {
      parts.add(
          '${_photos.length} ${_photos.length == 1 ? AppStrings.photoLabel.tr : AppStrings.photosLabel.tr}');
    }
    return parts.isEmpty ? AppStrings.customRequest.tr : parts.join(' · ');
  }

  Future<void> _updateStatus(String status) async {
    final id = (_enquiry?.enquiryId ??
            widget.message.metadata?.educationEnquiryId ??
            '')
        .trim();
    if (id.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    setState(() => _isUpdating = true);
    final controller = getOrPut(() => EducationEnquiryController());
    final ok = await controller.updateEducationEnquiryStatus(
      enquiryId: id,
      status: status,
    );
    if (!mounted) return;
    if (ok) widget.message.metadata?.educationEnquiry?.status = status;
    setState(() => _isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      width: SizeConfig.screenWidth * 0.72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line, width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F001120), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          if (_photos.isNotEmpty) ...[_divider(), _photoSection()],
          for (final row in _rows) ...[_divider(), _enquiryRow(row)],
          if (_note.trim().isNotEmpty) ...[_divider(), _noteSection()],
          _divider(),
          _footer(),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 1, color: _line);

  // ── Slim header — small tinted icon + title/subtitle + status pill ──
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.school_rounded, color: _accent, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.educationEnquiryTitle.tr,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                CustomText(
                  _subtitle,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  // ── Full-width photo(s) — compact strip ─────────────────────────────
  Widget _photoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        children: [
          for (int i = 0; i < _photos.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: double.infinity,
                height: 130,
                child: CachedNetworkImage(
                  imageUrl: _photos[i],
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: AppColors.whiteE5),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.whiteE5,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined,
                        size: 20, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── One enquiry row — tinted icon badge + eyebrow + value(s) ────────
  // A single value renders as plain text; multiple values render as a
  // bullet list (mirrors the reference enquiry-details card).
  Widget _enquiryRow(_EnquiryRow row) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: row.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(row.icon, color: row.color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eyebrow(row.title),
                const SizedBox(height: 3),
                if (row.items.length == 1)
                  CustomText(
                    row.items.first,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    height: 1.3,
                  )
                else
                  for (final item in row.items)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7, right: 7),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.mainTextColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Expanded(
                            child: CustomText(
                              item,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mainTextColor,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Note — tinted icon badge + eyebrow + text (row style) ───────────
  Widget _noteSection() {
    const color = Color(0xFF64748B);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.sticky_note_2_outlined,
                color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eyebrow(AppStrings.noteLabel.tr),
                const SizedBox(height: 3),
                CustomText(
                  _note,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainTextColor,
                  height: 1.35,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eyebrow(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
        color: AppColors.secondaryTextColor,
      ),
    );
  }

  // ── Footer — status band (waiting / accepted / declined) or, for the
  // receiver while pending, the Accept / Decline actions. ──────────────
  Widget _footer() {
    if (_isAccepted) {
      return _statusBand(
        icon: Icons.check_circle_rounded,
        color: Colors.green,
        label: AppStrings.enquiryAccepted.tr,
      );
    }
    if (_isDeclined) {
      return _statusBand(
        icon: Icons.cancel_rounded,
        color: Colors.red,
        label: AppStrings.enquiryDeclined.tr,
      );
    }

    // Pending — receiver gets Accept / Decline + timestamp.
    if (!_isMyMessage) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _isUpdating
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _accent),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(child: _declineBtn()),
                      const SizedBox(width: 8),
                      Expanded(child: _acceptBtn()),
                    ],
                  ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: CustomText(
                widget.time,
                fontSize: SizeConfig.size10,
                fontWeight: FontWeight.w400,
                color: AppColors.grayText,
              ),
            ),
          ],
        ),
      );
    }

    // Pending — customer (sender) waits for the school's response.
    return _statusBand(
      icon: Icons.access_time_rounded,
      color: Colors.orange,
      label: AppStrings.waitingForResponse.tr,
    );
  }

  // Full-width tinted band: status icon + label, with the message time on
  // the right (matches the reference card's footer).
  Widget _statusBand({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      color: color.withValues(alpha: 0.10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: CustomText(
              label,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          CustomText(
            widget.time,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _acceptBtn() {
    return InkWell(
      onTap: () => _updateStatus('accepted'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_accentDeep, _accent]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_rounded, size: 15, color: Colors.white),
            const SizedBox(width: 5),
            Text(AppStrings.acceptLabel.tr,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _declineBtn() {
    return InkWell(
      onTap: () => _updateStatus('declined'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: Colors.red.withValues(alpha: 0.55), width: 1.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.close_rounded, size: 15, color: Colors.red),
            const SizedBox(width: 5),
            Text(AppStrings.declineLabel.tr,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final (String label, Color color) = _isAccepted
        ? (AppStrings.acceptedStatus.tr, Colors.green)
        : _isDeclined
            ? (AppStrings.declinedStatus.tr, Colors.red)
            : (AppStrings.pendingStatus.tr, Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// One enquiry detail row's data — label, value(s), and its tinted icon.
class _EnquiryRow {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  const _EnquiryRow(this.title, this.items, this.icon, this.color);
}
