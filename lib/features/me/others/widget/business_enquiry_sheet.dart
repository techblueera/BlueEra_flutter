import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/me/others/controller/other_enquiry_controller.dart';
import 'package:BlueEra/features/me/others/model/predefined_enquiry_group.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One selection group on the "other" business enquiry form.
///
/// [title] is what the user (and the in-chat card) sees as the section
/// label; the same string is sent back to the server as the
/// selections-map key so the card can render it verbatim.
///
/// [multiSelect] mirrors the server catalog contract from
/// `lib/docs/predefined-enquiry-ui-integration.md` §2:
///   • `true`  → toggle chips (0..n selectable) — default.
///   • `false` → radio chips (0..1 selectable per group).
class BusinessEnquiryGroup {
  final String title;
  final List<String> options;
  final bool multiSelect;

  const BusinessEnquiryGroup({
    required this.title,
    required this.options,
    this.multiSelect = true,
  });

  factory BusinessEnquiryGroup.fromPredefined(PredefinedEnquiryGroup g) =>
      BusinessEnquiryGroup(
        title: g.title,
        options: g.options,
        multiSelect: g.multiSelect,
      );
}

/// Snapshot of the listing being enquired about. Denormalised into the
/// form (and onto the eventual chat card) so the customer / owner sees a
/// header without an extra fetch.
class BusinessEnquiryListing {
  final String listingId;
  final String ownerId;
  final String ownerName;
  final String listingName;
  final String? listingImage;
  final String? location;

  const BusinessEnquiryListing({
    required this.listingId,
    required this.ownerId,
    required this.ownerName,
    required this.listingName,
    this.listingImage,
    this.location,
  });
}

/// Customer-side enquiry sheet for the **"other" business flow** — the
/// non-hospital, non-healthcare, non-hotel, non-education, non-vehicle
/// vertical. One parameterized sheet covers every category — the only
/// thing that varies per category is the [groups] list, which by default
/// is fetched **server-side** via
/// `GET other-service/predefined-enquiry/{category}` (see
/// `lib/docs/predefined-enquiry-ui-integration.md` §1).
///
/// Supported categories are seeded on the backend and can be extended
/// without an app release. Current catalog:
///
/// **Finance (4)**
///   • LOANS_SECTOR
///   • BANKING_SECTOR
///   • INSURANCE_SECTOR
///   • FINANCIAL_SERVICES
///
/// **Find Services (8)**
///   • CONSULTING_BUSINESS_SERVICES
///   • BEAUTY_FITNESS_PERSONAL_CARE
///   • REPAIR_ESSENTIAL_SERVICES
///   • HOME_SERVICES_CONTRACTORS
///   • IT_DIGITAL_SERVICES
///   • MEDIA_NEWS_CREATIVE
///   • TRAVEL_HOSPITALITY
///   • REAL_ESTATE_PROPERTY
///
/// **Automotive (3)**
///   • VEHICLE_SERVICE
///   • VEHICLE_SUPPORT
///   • TRANSPORT_LOGISTICS_PARKING
///
/// The sheet drives [OtherEnquiryController], then opens the business
/// chat with the owner — the backend posts the `business_enquiry` card
/// into that conversation, so we never seed any chat text.
class BusinessEnquirySheet {
  BusinessEnquirySheet._();

  /// Open the enquiry sheet.
  ///
  /// [category] is the canonical category string snapshot from the
  /// listing (LOANS_SECTOR / CONSULTING_BUSINESS_SERVICES /
  /// VEHICLE_SERVICE / …). Case-insensitive — normalised to uppercase
  /// before hitting the catalog endpoint.
  ///
  /// Group source, in priority order (per doc §1–§2):
  ///   1. Explicit [groups] arg (caller-controlled override).
  ///   2. Server catalog `GET /predefined-enquiry/{category}`, cached
  ///      per-category on [OtherEnquiryController].
  ///   3. Empty — sheet renders note+photo only (§2 fallback).
  ///
  /// **No static per-category defaults** live in the app anymore — the
  /// backend is the source of truth so new categories and option edits
  /// ship without a release. See §5 checklist item 1.
  static Future<void> open(
    BuildContext context, {
    required String category,
    required BusinessEnquiryListing listing,
    List<BusinessEnquiryGroup>? groups,
  }) async {
    if (listing.ownerId.isEmpty || listing.listingId.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return;
    }

    final effectiveGroups = groups ?? await _resolveGroups(context, category);
    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BusinessEnquireForm(
        listing: listing,
        groups: effectiveGroups,
        category: category,
        onSubmit: (selections, note, photoPaths) =>
            _submit(listing, selections, note, photoPaths),
      ),
    );
  }

  /// Resolve the group list for [category] using cache → server. Only
  /// blocks the UI when we've never fetched this category before —
  /// second-time opens are instant from the controller's in-memory
  /// cache.
  static Future<List<BusinessEnquiryGroup>> _resolveGroups(
      BuildContext context, String category) async {
    final slug = category.trim();
    if (slug.isEmpty) return const [];

    final controller = getOrPut(() => OtherEnquiryController());
    final cached = controller.cachedPredefinedEnquiryOptions(slug);
    if (cached != null) {
      return cached.map(BusinessEnquiryGroup.fromPredefined).toList();
    }

    // First-time fetch — block briefly so the sheet doesn't open with
    // just a note field when the server *does* have a catalog for this
    // category. Errors resolve to `[]` inside the controller (§1 error
    // table → note-only fallback).
    AppLoader.show();
    try {
      final fetched = await controller.loadPredefinedEnquiryOptions(slug);
      return fetched.map(BusinessEnquiryGroup.fromPredefined).toList();
    } finally {
      AppLoader.hide();
    }
  }

  static Future<void> _submit(
    BusinessEnquiryListing listing,
    Map<String, List<String>> selections,
    String note,
    List<String> photoPaths,
  ) async {
    // Enquiry POST FIRST. Gating navigation on the POST result means
    // (1) failures keep the customer on the detail screen with a
    // snackbar instead of stranded on an empty chat; (2) `AppLoader`
    // blocks the detail screen, not the chat; (3) by the time we
    // navigate the backend has already accepted the enquiry, so the
    // real `business_enquiry` card lands over the socket
    // (`newBusinessEnquiryReceived`) shortly after — see
    // `lib/docs/other-enquiry-ui-integration.md` §5 + §8.
    final controller = getOrPut(() => OtherEnquiryController());
    final enquiryId = await controller.submitOtherEnquiry(
      businessId: listing.listingId,
      selections: selections,
      note: note,
      photoPaths: photoPaths,
    );
    if (enquiryId == null) return;

    final chatViewController = getOrPut(() => ChatViewController());
    await chatViewController.checkChatConnectionAndOpenChat(
      userId: listing.ownerId,
      name: listing.listingName.isNotEmpty
          ? listing.listingName
          : listing.ownerName,
      profile: listing.listingImage,
      route: AppConstants.route_discover,
    );
  }
}

class _BusinessEnquireForm extends StatefulWidget {
  final BusinessEnquiryListing listing;
  final List<BusinessEnquiryGroup> groups;
  final String category;
  final void Function(
    Map<String, List<String>> selections,
    String note,
    List<String> photoPaths,
  ) onSubmit;

  const _BusinessEnquireForm({
    required this.listing,
    required this.groups,
    required this.category,
    required this.onSubmit,
  });

  @override
  State<_BusinessEnquireForm> createState() => _BusinessEnquireFormState();
}

class _BusinessEnquireFormState extends State<_BusinessEnquireForm> {
  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _surface = Color(0xFFF4F6FA);

  /// Server caps photos at 5 (see §2 "Rules" in the integration guide).
  static const int _maxPhotos = 5;

  // Selection state keyed by the group's display title (which is also the
  // selections-map key sent to the server).
  final Map<String, Set<String>> _selected = {};
  final List<String> _photos = [];
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// Multi-select toggles the value; single-select (radio) replaces the
  /// existing selection for that group. A repeat tap on the current
  /// radio choice clears it (matching the doc §2 rule that every group
  /// is optional).
  void _toggle(BusinessEnquiryGroup group, String value) {
    setState(() {
      final set = _selected.putIfAbsent(group.title, () => <String>{});
      if (group.multiSelect) {
        if (!set.add(value)) set.remove(value);
      } else {
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

  /// `LOANS_SECTOR` → `Loans Sector`, `CONSULTING_BUSINESS_SERVICES` →
  /// `Consulting Business Services`. Same pretty-print used by the
  /// finance sheet so the header reads consistently across verticals.
  String get _prettyCategory {
    final raw = widget.category.trim();
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
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_accentDeep, _accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.business_center_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.businessEnquiryTitle.tr,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  AppStrings.tellListingAboutEnquiry.tr
                      .replaceAll('{listing}', widget.listing.ownerName),
                  fontSize: 12.5,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                  maxLines: 2,
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
    // radio → filled/outlined circle glyphs so the group visually reads
    // as single-select; otherwise fall back to the check/add glyphs used
    // by the other Discover sheets for multi-select toggles.
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
