import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/healthcare_enquiry_model.dart';
import 'package:BlueEra/features/me/medical/controller/healthcare_enquiry_controller.dart';
import 'package:BlueEra/features/me/medical/widget/hospital_appointment_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// In-chat card for `message_type: "healthcare_enquiry"`.
///
/// Shares its visual language with the other enquiry/booking cards
/// (hotel / vehicle / education) — hero-banner layout + amber accent
/// so all four verticals render identically in the chat stream. Only
/// the healthcare-specific data (category ribbon, medical section icons)
/// differs from the hotel/vehicle/education implementations.
class HealthcareEnquiryMsgCard extends StatefulWidget {
  final Messages message;
  final String time;

  const HealthcareEnquiryMsgCard({
    super.key,
    required this.message,
    required this.time,
  });

  @override
  State<HealthcareEnquiryMsgCard> createState() =>
      _HealthcareEnquiryMsgCardState();
}

class _HealthcareEnquiryMsgCardState extends State<HealthcareEnquiryMsgCard> {
  static const Color _accent = Color(0xFFF59E0B); // warm amber
  static const Color _accentDeep = Color(0xFFD97706);
  static const Color _line = Color(0xFFF3E7CE);
  static const Color _noteBg = Color(0xFFFFF8EC);

  bool _isUpdating = false;

  HealthcareEnquiryModel? get _e =>
      widget.message.metadata?.healthcareEnquiry;
  bool get _isMyMessage => widget.message.myMessage ?? false;
  String get _status => (_e?.status ?? 'pending').toLowerCase();
  bool get _isAccepted => _status == 'accepted';
  bool get _isDeclined => _status == 'declined';
  bool get _isPending => !_isAccepted && !_isDeclined;

  Map<String, List<String>> get _selections {
    final out = <String, List<String>>{};
    (_e?.selections ?? const <String, List<String>>{}).forEach((k, v) {
      final items = v.where((s) => s.trim().isNotEmpty).toList();
      if (items.isNotEmpty) out[k] = items;
    });
    return out;
  }

  IconData _iconFor(String title) {
    switch (title.toLowerCase()) {
      case 'departments':
      case 'department':
      case 'specialization':
        return Icons.medical_services_outlined;
      case 'test types':
      case 'tests':
        return Icons.biotech_outlined;
      case 'product type':
      case 'products':
        return Icons.medication_outlined;
      case 'purpose':
        return Icons.assignment_outlined;
      case 'timeline':
        return Icons.access_time_rounded;
      default:
        return Icons.local_hospital_outlined;
    }
  }

  /// Pretty-print HOSPITAL / DOCTOR / LAB → "Hospital" / "Doctor" / "Lab"
  /// for the category chip in the hero title.
  String get _prettyCategory {
    final raw = (_e?.category ?? '').trim();
    if (raw.isEmpty) return '';
    return raw.replaceAll('_', ' ').toLowerCase().split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  Future<void> _updateStatus(String status) async {
    final id = (_e?.enquiryId ??
            widget.message.metadata?.healthcareEnquiryId ??
            '')
        .trim();
    if (id.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    setState(() => _isUpdating = true);
    final controller = getOrPut(() => HealthcareEnquiryController());
    final ok = await controller.updateHealthcareEnquiryStatus(
      enquiryId: id,
      category: _e?.category ?? '',
      status: status,
    );
    if (!mounted) return;
    if (ok) widget.message.metadata?.healthcareEnquiry?.status = status;
    setState(() => _isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    final e = _e;
    final photos = e?.photos ?? const <String>[];
    final coverImage = (e?.listingImage ?? '').trim();
    final firstPhoto = photos.isNotEmpty ? photos.first : '';
    final heroImage = coverImage.isNotEmpty ? coverImage : firstPhoto;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      width: SizeConfig.screenWidth * 0.74,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line, width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroBanner(heroImage, e?.listingName ?? '', e?.location ?? ''),
          for (final entry in _selections.entries) _selectionRow(entry),
          if ((e?.note ?? '').trim().isNotEmpty) _noteRow(e!.note!.trim()),
          if (photos.length > 1) _photoStrip(photos.skip(1).toList()),
          _footer(),
        ],
      ),
    );
  }

  Widget _heroBanner(String image, String name, String location) {
    final category = _prettyCategory;
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 140,
          child: image.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: image,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: _line),
                  errorWidget: (_, __, ___) => Container(
                    color: _line,
                    alignment: Alignment.center,
                    child: const Icon(Icons.local_hospital_rounded,
                        color: Colors.white, size: 32),
                  ),
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accentDeep, _accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.local_hospital_rounded,
                      color: Colors.white, size: 32),
                ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_hospital_rounded,
                            size: 12, color: _accentDeep),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.healthcareEnquiry.tr.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: _accentDeep,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _statusBadge(),
                ],
              ),
              const SizedBox(height: 6),
              if (name.trim().isNotEmpty)
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              if (location.trim().isNotEmpty || category.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (location.trim().isNotEmpty) ...[
                      const Icon(Icons.place_rounded,
                          size: 11, color: Colors.white70),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    if (category.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _selectionRow(MapEntry<String, List<String>> entry) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFor(entry.key), color: _accentDeep, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    for (final item in entry.value)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _accent.withValues(alpha: 0.25),
                              width: 0.8),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _accentDeep,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteRow(String note) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: _noteBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _line, width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                size: 14, color: _accentDeep),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                note,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainTextColor,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoStrip(List<String> photos) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: SizedBox(
        height: 60,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: photos[i],
              width: 80,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(width: 80, height: 60, color: _line),
              errorWidget: (_, __, ___) => Container(
                width: 80,
                height: 60,
                color: _line,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined,
                    size: 16, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    if (_isAccepted) {
      // Hospital enquiry-first flow (doc
      // `healthcare-appointment-ui-integration.md` §0): once the owner
      // accepts, the customer gets a "Book Appointment" CTA that opens
      // the appointment sheet with `enquiry_id` pre-filled. Only for
      // HOSPITAL category; other healthcare categories don't have an
      // appointment endpoint. Owner side just sees the accepted band.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _statusBand(
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF16A34A),
            label: AppStrings.enquiryAccepted.tr,
          ),
          if (_isMyMessage && _canOpenAppointmentSheet) _bookAppointmentRow(),
        ],
      );
    }
    if (_isDeclined) {
      return _statusBand(
        icon: Icons.cancel_rounded,
        color: const Color(0xFFDC2626),
        label: AppStrings.enquiryDeclined.tr,
      );
    }
    if (_isPending && !_isMyMessage) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: _isUpdating
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _accentDeep),
                ),
              )
            : Row(
                children: [
                  Expanded(child: _declineBtn()),
                  const SizedBox(width: 8),
                  Expanded(child: _acceptBtn()),
                ],
              ),
      );
    }
    return _statusBand(
      icon: Icons.access_time_rounded,
      color: _accentDeep,
      label: AppStrings.waitingForResponse.tr,
    );
  }

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

  /// Enquiry-first hook: only wire the CTA when
  ///  1. the enquiry is on a HOSPITAL listing (appointment endpoint is
  ///     hospital-only),
  ///  2. we have a hospital id + owner id + enquiry id to send.
  /// Any missing → hide the button rather than opening a broken sheet.
  bool get _canOpenAppointmentSheet {
    final e = _e;
    if (e == null) return false;
    if ((e.category ?? '').toUpperCase() != 'HOSPITAL') return false;
    return (e.listingId ?? '').trim().isNotEmpty &&
        (e.ownerId ?? '').trim().isNotEmpty &&
        (e.enquiryId ?? '').trim().isNotEmpty;
  }

  void _openAppointmentSheet() {
    final e = _e!;
    HospitalAppointmentSheet.open(
      context,
      listing: HospitalAppointmentListing(
        hospitalId: (e.listingId ?? '').trim(),
        ownerId: (e.ownerId ?? '').trim(),
        // The enquiry card doesn't carry a separate ownerName — the
        // sheet header falls back to hospitalName when ownerName is
        // empty, so an empty string is fine here.
        ownerName: '',
        hospitalName: (e.listingName ?? '').trim(),
        coverImage: (e.listingImage ?? '').trim(),
        location: (e.location ?? '').trim(),
      ),
      enquiryId: (e.enquiryId ?? '').trim(),
    );
  }

  Widget _bookAppointmentRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: InkWell(
        onTap: _openAppointmentSheet,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_accentDeep, _accent]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_available_rounded,
                  size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                'Book Appointment',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _acceptBtn() {
    return InkWell(
      onTap: () => _updateStatus('accepted'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_accentDeep, _accent]),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_rounded, size: 15, color: Colors.white),
            const SizedBox(width: 5),
            Text(AppStrings.acceptLabel.tr,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _accentDeep.withValues(alpha: 0.35)),
        ),
        child: Text(
          AppStrings.declineLabel.tr,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: _accentDeep),
        ),
      ),
    );
  }

  Widget _statusBadge() {
    final (String label, Color color) = _isAccepted
        ? (AppStrings.acceptedStatus.tr, const Color(0xFF16A34A))
        : _isDeclined
            ? (AppStrings.declinedStatus.tr, const Color(0xFFDC2626))
            : (AppStrings.pendingStatus.tr, Colors.white);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _isPending ? Colors.white.withValues(alpha: 0.28) : color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}
