import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/business_enquiry_model.dart';
import 'package:BlueEra/features/me/others/controller/other_enquiry_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// In-chat card for `message_type: "business_enquiry"` — dedicated
/// finance / "other" business design. Navy + gold palette (banking /
/// insurance / loans feel), a sector ribbon driven by the metadata
/// `category` (LOANS_SECTOR / INSURANCE / BANKING / CAPITAL_MARKET /
/// DATA), and section icons that shift by category. Distinct from the
/// generic [EnquiryMsgCard] and the three vertical cards (hotel /
/// education / healthcare). See
/// `lib/docs/other-enquiry-ui-integration.md` §5 for the wire shape.
class BusinessEnquiryMsgCard extends StatefulWidget {
  final Messages message;
  final String time;

  const BusinessEnquiryMsgCard({
    super.key,
    required this.message,
    required this.time,
  });

  @override
  State<BusinessEnquiryMsgCard> createState() =>
      _BusinessEnquiryMsgCardState();
}

class _BusinessEnquiryMsgCardState extends State<BusinessEnquiryMsgCard> {
  static const Color _navy = Color(0xFF1E3A8A);
  static const Color _navyDeep = Color(0xFF0F172A);
  static const Color _gold = Color(0xFFEAB308);
  static const Color _goldDeep = Color(0xFFB45309);
  static const Color _line = Color(0xFFE2E8F0);
  static const Color _tint = Color(0xFFEFF6FF);

  bool _isUpdating = false;

  BusinessEnquiryModel? get _e => widget.message.metadata?.businessEnquiry;
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

  /// Category-driven header icon. Falls back to a generic briefcase for
  /// listings whose category we don't have a bespoke glyph for.
  IconData get _categoryIcon {
    switch ((_e?.category ?? '').toUpperCase()) {
      case 'LOANS_SECTOR':
        return Icons.request_page_rounded;
      case 'INSURANCE':
        return Icons.shield_rounded;
      case 'BANKING':
        return Icons.account_balance_rounded;
      case 'CAPITAL_MARKET':
        return Icons.trending_up_rounded;
      case 'DATA':
        return Icons.data_object_rounded;
      default:
        return Icons.business_center_rounded;
    }
  }

  /// Per-section icon so common finance groups render with meaningful
  /// glyphs (loan-amount → rupee, sum-assured → savings, etc.).
  IconData _iconFor(String title) {
    switch (title.toLowerCase()) {
      case 'services':
      case 'service':
        return Icons.workspace_premium_rounded;
      case 'purpose':
        return Icons.assignment_rounded;
      case 'loan amount':
      case 'amount':
        return Icons.currency_rupee_rounded;
      case 'policy type':
        return Icons.shield_outlined;
      case 'sum assured':
        return Icons.savings_rounded;
      case 'investment horizon':
      case 'horizon':
        return Icons.timeline_rounded;
      default:
        return Icons.check_rounded;
    }
  }

  /// LOANS_SECTOR → "Loans Sector" — reads much cleaner in the ribbon.
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
            widget.message.metadata?.businessEnquiryId ??
            '')
        .trim();
    if (id.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    setState(() => _isUpdating = true);
    final controller = getOrPut(() => OtherEnquiryController());
    final ok = await controller.updateOtherEnquiryStatus(
      enquiryId: id,
      status: status,
    );
    if (!mounted) return;
    if (ok) widget.message.metadata?.businessEnquiry?.status = status;
    setState(() => _isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    final e = _e;
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
          _navyHeader(),
          _listingSnapshot(e?.listingImage ?? '', e?.listingName ?? '',
              e?.location ?? ''),
          for (final entry in _selections.entries) _sectionRow(entry),
          if ((e?.photos ?? const []).isNotEmpty)
            _photoStrip(e!.photos ?? const []),
          if ((e?.note ?? '').trim().isNotEmpty) _noteRow(e!.note!.trim()),
          _footer(),
        ],
      ),
    );
  }

  Widget _navyHeader() {
    final category = _prettyCategory;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_navyDeep, _navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_goldDeep, _gold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(_categoryIcon, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.businessEnquiryTitle.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (category.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: _gold.withValues(alpha: 0.55), width: 0.8),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _gold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _statusBadge(),
        ],
      ),
    );
  }

  Widget _listingSnapshot(String image, String name, String location) {
    final hasSnapshot = image.trim().isNotEmpty ||
        name.trim().isNotEmpty ||
        location.trim().isNotEmpty;
    if (!hasSnapshot) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              width: 44,
              height: 44,
              child: image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: _tint),
                      errorWidget: (_, __, ___) => Container(
                        color: _tint,
                        alignment: Alignment.center,
                        child: Icon(_categoryIcon,
                            size: 20, color: _navy),
                      ),
                    )
                  : Container(
                      color: _tint,
                      alignment: Alignment.center,
                      child: Icon(_categoryIcon, size: 20, color: _navy),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: _navy),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
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

  Widget _sectionRow(MapEntry<String, List<String>> entry) {
    // ClipRRect + IntrinsicHeight lets the gold accent strip run full-height
    // on the left while keeping rounded corners. A `BoxDecoration.border`
    // with non-uniform side colors would assert at paint time when combined
    // with `borderRadius`.
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Container(
          decoration: BoxDecoration(
            color: _tint,
            border: Border.all(color: _line),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: _gold),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _navy.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Icon(_iconFor(entry.key),
                                  color: _navy, size: 15),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: _navyDeep,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            for (final item in entry.value)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: _navy.withValues(alpha: 0.25),
                                      width: 0.9),
                                ),
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _navyDeep,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoStrip(List<String> photos) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: SizedBox(
        height: 66,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) => ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: CachedNetworkImage(
              imageUrl: photos[i],
              width: 84,
              height: 66,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(width: 84, height: 66, color: _tint),
              errorWidget: (_, __, ___) => Container(
                width: 84,
                height: 66,
                color: _tint,
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

  Widget _noteRow(String note) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.format_quote_rounded, size: 15, color: _navy),
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

  Widget _footer() {
    if (_isAccepted) {
      return _statusBand(
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF16A34A),
        label: AppStrings.enquiryAccepted.tr,
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
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: _isUpdating
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _navy),
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
      color: _gold,
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
      margin: const EdgeInsets.only(top: 10),
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

  Widget _acceptBtn() {
    return InkWell(
      onTap: () => _updateStatus('accepted'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_goldDeep, _gold]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: 0.35),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _navy.withValues(alpha: 0.35)),
        ),
        child: Text(
          AppStrings.declineLabel.tr,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: _navyDeep),
        ),
      ),
    );
  }

  Widget _statusBadge() {
    final (String label, Color color) = _isAccepted
        ? (AppStrings.acceptedStatus.tr, const Color(0xFF16A34A))
        : _isDeclined
            ? (AppStrings.declinedStatus.tr, const Color(0xFFDC2626))
            : (AppStrings.pendingStatus.tr, _gold);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _isPending
            ? _gold.withValues(alpha: 0.18)
            : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 0.8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}
