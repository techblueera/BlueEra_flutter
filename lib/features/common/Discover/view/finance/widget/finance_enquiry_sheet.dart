import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/Discover/model/finance_search_res_model.dart';
import 'package:BlueEra/features/me/others/controller/other_enquiry_controller.dart';
import 'package:BlueEra/features/me/others/model/predefined_enquiry_group.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One selection group on the finance enquiry form. Kept separate from
/// [BusinessEnquiryGroup] per the "duplicate sheets per category" pattern
/// used across Discover verticals — the wire contract to
/// `POST /other-enquiries` is identical (see
/// `lib/docs/other-enquiry-ui-integration.md` §2), but the form UX is
/// finance-specific.
///
/// [multiSelect] mirrors the server catalog contract from
/// `lib/docs/predefined-enquiry-ui-integration.md` §2: `true` → toggle
/// chips (default), `false` → radio (0..1 selected per group). Static
/// defaults keep the older shape (all multi-select) — the server catalog
/// overrides them per category.
class FinanceEnquiryGroup {
  final String title;
  final List<String> options;
  final bool multiSelect;

  const FinanceEnquiryGroup({
    required this.title,
    required this.options,
    this.multiSelect = true,
  });

  factory FinanceEnquiryGroup.fromPredefined(PredefinedEnquiryGroup g) =>
      FinanceEnquiryGroup(
        title: g.title,
        options: g.options,
        multiSelect: g.multiSelect,
      );
}

/// Customer-side enquiry sheet for finance listings served from Discover
/// (banking / insurance / loans / capital-market / data). Feeds the same
/// `/other-enquiries` endpoint as `BusinessEnquirySheet` — same
/// [OtherEnquiryController], same `business_enquiry` chat card — but
/// tailored to the finance flow: takes a [FinanceBusinessItem] directly
/// (no listing-adapter mapping), renders a category chip in the header,
/// and ships finance-specific group defaults.
class FinanceEnquirySheet {
  FinanceEnquirySheet._();

  /// Default group catalogs per finance category. Keys are matched
  /// case-insensitively against `FinanceBusinessItem.category`.
  static const Map<String, List<FinanceEnquiryGroup>> _defaultGroups = {
    'LOANS_SECTOR': [
      FinanceEnquiryGroup(title: 'Services', options: [
        'Home Loan',
        'Personal Loan',
        'Business Loan',
        'Vehicle Loan',
        'Education Loan',
        'Gold Loan',
        'Loan Against Property',
      ]),
      FinanceEnquiryGroup(title: 'Loan Amount', options: [
        'Under ₹1 L',
        '₹1 L – ₹5 L',
        '₹5 L – ₹25 L',
        '₹25 L – ₹1 Cr',
        'Above ₹1 Cr',
      ]),
      FinanceEnquiryGroup(title: 'Purpose', options: [
        'Compare rates',
        'Check eligibility',
        'Apply now',
        'Documentation help',
      ]),
    ],
    'INSURANCE': [
      FinanceEnquiryGroup(title: 'Policy Type', options: [
        'Life Insurance',
        'Health Insurance',
        'Motor Insurance',
        'Home Insurance',
        'Travel Insurance',
        'Business Insurance',
      ]),
      FinanceEnquiryGroup(title: 'Sum Assured', options: [
        'Up to ₹5 L',
        '₹5 L – ₹25 L',
        '₹25 L – ₹1 Cr',
        'Above ₹1 Cr',
      ]),
      FinanceEnquiryGroup(title: 'Purpose', options: [
        'Compare plans',
        'New policy',
        'Renew existing',
        'Claim assistance',
      ]),
    ],
    'BANKING': [
      FinanceEnquiryGroup(title: 'Services', options: [
        'Savings Account',
        'Current Account',
        'Fixed Deposit',
        'Recurring Deposit',
        'Credit Card',
        'Locker',
        'Forex / Remittance',
      ]),
      FinanceEnquiryGroup(title: 'Purpose', options: [
        'Open account',
        'Rate enquiry',
        'Documentation help',
        'Branch visit',
      ]),
    ],
    'CAPITAL_MARKET': [
      FinanceEnquiryGroup(title: 'Services', options: [
        'Stocks / Equity',
        'Mutual Funds',
        'IPO',
        'Bonds',
        'Portfolio Management',
        'Demat Account',
      ]),
      FinanceEnquiryGroup(title: 'Investment Horizon', options: [
        'Short term (< 1 yr)',
        'Medium term (1–5 yrs)',
        'Long term (> 5 yrs)',
      ]),
      FinanceEnquiryGroup(title: 'Purpose', options: [
        'Advice',
        'Open account',
        'Compare plans',
        'Documentation help',
      ]),
    ],
    'DATA': [
      FinanceEnquiryGroup(title: 'Services', options: [
        'Data Analysis',
        'Reports',
        'Consulting',
        'Subscription',
      ]),
      FinanceEnquiryGroup(title: 'Purpose', options: [
        'Trial / Demo',
        'Pricing',
        'Custom quote',
      ]),
    ],
  };

  /// Lookup default groups for [category]. Returns an empty list for
  /// unknown categories so the sheet still opens (caller likely passed
  /// [groups] explicitly in that case).
  static List<FinanceEnquiryGroup> defaultGroupsFor(String category) =>
      _defaultGroups[category.toUpperCase()] ?? const [];

  /// Open the finance enquiry sheet for [data].
  ///
  /// Group source, in priority order (see
  /// `lib/docs/predefined-enquiry-ui-integration.md` §1–§2):
  ///   1. Explicit [groups] arg (caller-controlled override).
  ///   2. Server-driven catalog `GET /predefined-enquiry/{category}`,
  ///      cached per-category via [OtherEnquiryController]. Prefetched
  ///      results open the sheet instantly; a first-time miss shows a
  ///      brief loader while the fetch runs.
  ///   3. Static per-category defaults ([defaultGroupsFor]) — only used
  ///      when the server returned no groups (404 / error) so the sheet
  ///      still has something to render. If both server and defaults are
  ///      empty, the sheet renders note+photo only (§2 fallback).
  static Future<void> open(
    BuildContext context, {
    required FinanceBusinessItem data,
    List<FinanceEnquiryGroup>? groups,
  }) async {
    final listingId = (data.id ?? '').trim();
    final ownerId = (data.userId ?? '').trim();
    if (listingId.isEmpty || ownerId.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return;
    }

    final effectiveGroups =
        groups ?? await _resolveGroups(context, data.category ?? '');
    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FinanceEnquireForm(
        data: data,
        groups: effectiveGroups,
        onSubmit: (selections, note, photoPaths) =>
            _submit(data, selections, note, photoPaths),
      ),
    );
  }

  /// Resolve the group list for [category] using cache → server → static
  /// defaults. Only shows a loader when we have no cached entry AND no
  /// static default — otherwise the sheet opens instantly on whatever we
  /// have and the server catalog just wasn't seeded for this category.
  static Future<List<FinanceEnquiryGroup>> _resolveGroups(
      BuildContext context, String category) async {
    final controller = getOrPut(() => OtherEnquiryController());
    final cached = controller.cachedPredefinedEnquiryOptions(category);
    if (cached != null) {
      if (cached.isNotEmpty) {
        return cached.map(FinanceEnquiryGroup.fromPredefined).toList();
      }
      // Server said "no seeded catalog" — fall through to static defaults.
      return defaultGroupsFor(category);
    }

    final defaults = defaultGroupsFor(category);
    if (defaults.isNotEmpty) {
      // Kick the fetch in the background; the sheet opens now with
      // defaults so the customer isn't blocked. Next open in the same
      // session will pick up the server catalog from cache.
      // ignore: unawaited_futures
      controller.loadPredefinedEnquiryOptions(category);
      return defaults;
    }

    // No cache, no defaults — worth blocking briefly so the sheet doesn't
    // open with just a note field when the server *does* have groups.
    AppLoader.show();
    try {
      final fetched =
          await controller.loadPredefinedEnquiryOptions(category);
      return fetched.map(FinanceEnquiryGroup.fromPredefined).toList();
    } finally {
      AppLoader.hide();
    }
  }

  static Future<void> _submit(
    FinanceBusinessItem data,
    Map<String, List<String>> selections,
    String note,
    List<String> photoPaths,
  ) async {
    final listingId = (data.id ?? '').trim();
    final ownerId = (data.userId ?? '').trim();

    // Enquiry POST FIRST. Gating navigation on the POST result means:
    //   1. If it fails, the customer stays on the detail screen with a
    //      snackbar — not stranded on an empty chat wondering why no
    //      card ever appears.
    //   2. `AppLoader` blocks the current screen (the sheet has already
    //      dismissed itself), not the chat.
    //   3. By the time we navigate, the backend has already accepted
    //      the enquiry and either created the card or is about to; the
    //      socket delivers it shortly after we land on the chat.
    // Per `lib/docs/other-enquiry-ui-integration.md` §5 + §8 the real
    // `business_enquiry` card arrives via `newBusinessEnquiryReceived`
    // and renders through `case "business_enquiry":` in MessageCard.
    final controller = getOrPut(() => OtherEnquiryController());
    final enquiryId = await controller.submitOtherEnquiry(
      businessId: listingId,
      selections: selections,
      note: note,
      photoPaths: photoPaths,
    );
    if (enquiryId == null) return;

    final chatViewController = getOrPut(() => ChatViewController());
    await chatViewController.checkChatConnectionAndOpenChat(
      userId: ownerId,
      name: (data.profileName ?? '').trim(),
      profile: data.logoUrl,
      route: AppConstants.route_discover,
    );
  }
}

class _FinanceEnquireForm extends StatefulWidget {
  final FinanceBusinessItem data;
  final List<FinanceEnquiryGroup> groups;
  final void Function(
    Map<String, List<String>> selections,
    String note,
    List<String> photoPaths,
  ) onSubmit;

  const _FinanceEnquireForm({
    required this.data,
    required this.groups,
    required this.onSubmit,
  });

  @override
  State<_FinanceEnquireForm> createState() => _FinanceEnquireFormState();
}

class _FinanceEnquireFormState extends State<_FinanceEnquireForm> {
  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _surface = Color(0xFFF4F6FA);

  /// Server caps photos at 5 (see §2 "Rules" in the integration guide).
  static const int _maxPhotos = 5;

  final Map<String, Set<String>> _selected = {};
  final List<String> _photos = [];
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toggle(FinanceEnquiryGroup group, String value) {
    setState(() {
      final set = _selected.putIfAbsent(group.title, () => <String>{});
      if (group.multiSelect) {
        // Toggle: add if absent, remove if present (0..n selectable).
        if (!set.add(value)) set.remove(value);
      } else {
        // Radio: at most one selected per group — a repeat tap clears it.
        // See lib/docs/predefined-enquiry-ui-integration.md §2.
        if (set.contains(value)) {
          set.remove(value);
        } else {
          set
            ..clear()
            ..add(value);
        }
      }
    });
  }

  bool _isOn(String groupTitle, String value) =>
      _selected[groupTitle]?.contains(value) ?? false;

  int _countFor(String groupTitle) => _selected[groupTitle]?.length ?? 0;

  bool get _hasSelection => _selected.values.any((s) => s.isNotEmpty);

  bool get _canSubmit =>
      _hasSelection ||
      _noteController.text.trim().isNotEmpty ||
      _photos.isNotEmpty;

  Future<void> _pickPhoto() async {
    if (_photos.length >= _maxPhotos) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return;
    }
    final path = await PhotoPickerService.pickSinglePhoto(
      context,
      AppStrings.photoLabel.tr,
      isOnlyCamera: true,
      isGallery: true,
    );
    if (path == null || path.isEmpty || !mounted) return;
    setState(() => _photos.add(path));
  }

  void _removePhoto(String path) => setState(() => _photos.remove(path));

  void _submit() {
    final selections = <String, List<String>>{};
    _selected.forEach((title, set) {
      if (set.isNotEmpty) selections[title] = set.toList();
    });
    final note = _noteController.text.trim();
    Navigator.of(context).pop();
    widget.onSubmit(selections, note, List<String>.from(_photos));
  }

  /// Pretty-print the raw category code (`LOANS_SECTOR` → `Loans Sector`).
  String get _prettyCategory {
    final raw = (widget.data.category ?? '').trim();
    if (raw.isEmpty) return '';
    return raw.replaceAll('_', ' ').toLowerCase().split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  decoration: BoxDecoration(
                    color: AppColors.greyE5,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _header(),
              Flexible(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _eyebrow(
                          '${AppStrings.photoLabel.tr.toUpperCase()} · ${AppStrings.optionalLabel.tr}',
                          _photos.length),
                      const SizedBox(height: 12),
                      _photoSection(),
                      const SizedBox(height: 22),
                      for (final group in widget.groups) ...[
                        _eyebrow(group.title, _countFor(group.title)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: group.options
                              .map((s) => _checkChip(
                                    label: s,
                                    on: _isOn(group.title, s),
                                    radio: !group.multiSelect,
                                    onTap: () => _toggle(group, s),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      _eyebrow(
                          '${AppStrings.noteLabel.tr.toUpperCase()} · ${AppStrings.optionalLabel.tr}',
                          0),
                      const SizedBox(height: 10),
                      _noteField(),
                    ],
                  ),
                ),
              ),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final category = _prettyCategory;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_accentDeep, _accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.account_balance_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.financeEnquiryTitle.tr,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  (widget.data.profileName ?? '').trim().isEmpty
                      ? AppStrings.financeService.tr
                      : widget.data.profileName!.trim(),
                  fontSize: 12.5,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (category.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: CustomText(
                      category,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded,
                  size: 18, color: AppColors.secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eyebrow(String label, int count) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: AppConstants.OpenSans,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppColors.secondaryTextColor,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: CustomText(
              '$count',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _accent,
            ),
          ),
        ],
      ],
    );
  }

  Widget _checkChip({
    required String label,
    required bool on,
    required VoidCallback onTap,
    bool radio = false,
  }) {
    // radio → filled/outlined circle glyphs so the group visually reads as
    // single-select; otherwise fall back to the check/add glyphs used by
    // the other Discover sheets for multi-select toggles.
    final IconData icon = radio
        ? (on
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded)
        : (on
            ? Icons.check_circle_rounded
            : Icons.add_circle_outline_rounded);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: on ? _accent.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: on ? _accent : AppColors.greyE5,
            width: on ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: on ? _accent : AppColors.greyCA,
            ),
            const SizedBox(width: 6),
            CustomText(
              label,
              fontSize: 12.5,
              fontWeight: on ? FontWeight.w700 : FontWeight.w600,
              color: on ? _accent : AppColors.mainTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_photos.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final path in _photos) _photoThumb(path),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (_photos.length < _maxPhotos) _addPhotoButton(),
      ],
    );
  }

  Widget _photoThumb(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Image.file(
            File(path),
            width: 92,
            height: 92,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => _removePhoto(path),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addPhotoButton() {
    return InkWell(
      onTap: _pickPhoto,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 110,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: _accent.withValues(alpha: 0.35), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 28, color: _accent),
            const SizedBox(height: 6),
            CustomText(AppStrings.photoLabel.tr,
                fontSize: 13, fontWeight: FontWeight.w800, color: _accent),
          ],
        ),
      ),
    );
  }

  Widget _noteField() {
    return CommonTextField(
      textEditController: _noteController,
      hintText: AppStrings.noteLabel.tr,
      maxLine: 4,
      minLines: 2,
      isValidate: false,
      onChange: (_) => setState(() {}),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.greyE5, width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: InkWell(
          onTap: _canSubmit ? _submit : null,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: _canSubmit
                  ? const LinearGradient(colors: [_accentDeep, _accent])
                  : null,
              color: _canSubmit ? null : AppColors.greyE5,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _canSubmit
                  ? [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.32),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_rounded,
                    size: 18,
                    color: _canSubmit ? Colors.white : AppColors.greyCA),
                const SizedBox(width: 8),
                CustomText(
                  AppStrings.sendEnquiryLabel.tr,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _canSubmit ? Colors.white : AppColors.greyCA,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
