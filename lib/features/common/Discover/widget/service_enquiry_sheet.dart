import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared service-enquiry flow used by BOTH the Discover self-profession list
/// card and the provider detail screen. Opens the "What do you need?" sheet
/// (grouped option checkboxes + optional note + optional photo), submits to the
/// service-enquiry API, then opens the provider's business chat where the
/// backend posts the enquiry card.
class ServiceEnquirySheet {
  ServiceEnquirySheet._();

  /// Generic intent options always offered (in addition to the profession's
  /// fetched options), so the form has a structured choice even when the
  /// predefined catalog returns nothing for a profession.
  static const List<String> _standardRequestOptions = [
    'Installation',
    'Repair',
    'Maintenance',
    'Visit & Quote',
    'Urgent / Same-day',
  ];

  /// Entry point — opens the enquiry sheet for [service]. The selectable
  /// options are fetched dynamically from the predefined-category API based on
  /// the provider's profession ([ServiceData.category]).
  static void open(BuildContext context, ServiceData service) {
    final targetUserId = service.id ?? '';
    if (targetUserId.isEmpty) return;
    final category = (service.category?.trim().isNotEmpty ?? false)
        ? service.category!.trim()
        : ((service.designation?.trim().isNotEmpty ?? false)
            ? service.designation!.trim()
            : (service.profession ?? '').trim());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EnquireSheet(
        providerName: (service.name?.trim().isNotEmpty ?? false)
            ? service.name!.trim()
            : AppStrings.unknownUser.tr,
        category: category,
        onSubmit: (selections, note, photoPaths) =>
            _submit(service, selections, note, photoPaths),
      ),
    );
  }

  /// Submits the enquiry then opens the provider's business chat. The backend
  /// posts the enquiry card into that conversation — it IS the enquiry, so we
  /// don't seed any chat text.
  static Future<void> _submit(
    ServiceData service,
    Map<String, List<String>> selections,
    String note,
    List<String> photoPaths,
  ) async {
    final targetUserId = service.id ?? '';
    if (targetUserId.isEmpty) return;

    final controller = getOrPut(() => DiscoverController());
    final ok = await controller.submitServiceEnquiry(
      providerId: targetUserId,
      selections: selections,
      note: note,
      photoPaths: photoPaths,
    );
    if (!ok) return;

    final chatViewController = getOrPut(() => ChatViewController());
    chatViewController.checkChatConnectionAndOpenChat(
      userId: targetUserId,
      route: AppConstants.route_discover,
    );
  }

  /// Generic entry point — opens the SAME enquiry sheet for any provider by
  /// raw fields (not tied to a [ServiceData]). Used by the home-service detail
  /// screen. [category] drives the fetched option chips (the provider's
  /// profession / service category); [chatName] / [chatProfile] seed the
  /// business chat opened after a successful submit.
  static void openForProvider(
    BuildContext context, {
    required String userId,
    required String providerName,
    String? category,
    String? chatName,
    String? chatProfile,
  }) {
    final uid = userId.trim();
    if (uid.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EnquireSheet(
        providerName: providerName.trim().isNotEmpty
            ? providerName.trim()
            : AppStrings.unknownUser.tr,
        category: (category ?? '').trim(),
        onSubmit: (selections, note, photoPaths) => _submitForProvider(
          userId: uid,
          selections: selections,
          note: note,
          photoPaths: photoPaths,
          chatName: chatName,
          chatProfile: chatProfile,
        ),
      ),
    );
  }

  /// Submit for the generic entry point — same enquiry API, then opens the
  /// provider's business chat (seeded with the given name/profile).
  static Future<void> _submitForProvider({
    required String userId,
    required Map<String, List<String>> selections,
    required String note,
    required List<String> photoPaths,
    String? chatName,
    String? chatProfile,
  }) async {
    if (userId.isEmpty) return;
    final controller = getOrPut(() => DiscoverController());
    final ok = await controller.submitServiceEnquiry(
      providerId: userId,
      selections: selections,
      note: note,
      photoPaths: photoPaths,
    );
    if (!ok) return;
    final chatViewController = getOrPut(() => ChatViewController());
    chatViewController.checkChatConnectionAndOpenChat(
      userId: userId,
      name: chatName,
      profile: chatProfile,
      route: AppConstants.route_discover,
    );
  }
}

/// One selectable group on the enquiry form — mirrors a provider-profile
/// field (Service Type / Type of Work / …) or the generic Request Type group.
/// [apiKey] is the request-body / metadata key the selected values are sent under.
class _EnquiryGroup {
  final String apiKey;
  final String title;
  final List<String> options;

  const _EnquiryGroup({
    required this.apiKey,
    required this.title,
    required this.options,
  });
}

/// Bottom-sheet enquiry form. Renders the provider's [groups] as tick-able
/// chips, an optional note, and an optional photo ("show the problem"), then
/// hands everything back via [onSubmit]; the sheet pops itself.
class _EnquireSheet extends StatefulWidget {
  final String providerName;
  final String category;
  final void Function(
    Map<String, List<String>> selections,
    String note,
    List<String> photoPaths,
  ) onSubmit;

  const _EnquireSheet({
    required this.providerName,
    required this.category,
    required this.onSubmit,
  });

  @override
  State<_EnquireSheet> createState() => _EnquireSheetState();
}

class _EnquireSheetState extends State<_EnquireSheet> {
  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _surface = Color(0xFFF4F6FA);
  static const int _maxPhotos = 1;

  /// Fetched option groups we intentionally don't surface in the enquiry form.
  static const Set<String> _hiddenApiKeys = {'typesOfWork', 'workCategories'};

  final Map<String, Set<String>> _selected = {};
  final List<String> _photos = [];
  final _noteController = TextEditingController();

  // Groups fetched from the predefined-category API for the provider's
  // profession, plus the always-on generic "Request Type" group.
  List<_EnquiryGroup> _groups = [];
  bool _loadingOptions = true;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final ctrl = getOrPut(() => DiscoverController());
    final fetched = await ctrl.fetchEnquiryOptions(widget.category);
    if (!mounted) return;
    setState(() {
      _groups = [
        for (final g in fetched)
          if (!_hiddenApiKeys.contains(g['apiKey'] as String))
            _EnquiryGroup(
              apiKey: g['apiKey'] as String,
              title: g['title'] as String,
              options: List<String>.from(g['options'] as List),
            ),
        const _EnquiryGroup(
          apiKey: 'requestType',
          title: 'Request Type',
          options: ServiceEnquirySheet._standardRequestOptions,
        ),
      ];
      _loadingOptions = false;
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toggle(String apiKey, String s) {
    setState(() {
      final set = _selected.putIfAbsent(apiKey, () => <String>{});
      if (!set.add(s)) set.remove(s);
    });
  }

  bool _isOn(String apiKey, String s) =>
      _selected[apiKey]?.contains(s) ?? false;

  int _countFor(String apiKey) => _selected[apiKey]?.length ?? 0;

  bool get _hasSelection => _selected.values.any((s) => s.isNotEmpty);

  bool get _canSubmit =>
      _hasSelection ||
      _noteController.text.trim().isNotEmpty ||
      _photos.isNotEmpty;

  Future<void> _pickPhotos() async {
    // Standard app picker: camera/gallery chooser → crop → compress.
    final path = await PhotoPickerService.pickSinglePhoto(
      context,
      'Add a photo',
      isOnlyCamera: true,
      isGallery: true,
    );
    if (path == null || path.isEmpty || !mounted) return;
    setState(() {
      _photos
        ..clear()
        ..add(path);
    });
  }

  void _removePhoto(String path) => setState(() => _photos.remove(path));

  void _submit() {
    final selections = <String, List<String>>{};
    _selected.forEach((apiKey, set) {
      if (set.isNotEmpty) selections[apiKey] = set.toList();
    });
    final note = _noteController.text.trim();
    Navigator.of(context).pop();
    widget.onSubmit(selections, note, List<String>.from(_photos));
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
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo first — full-width preview.
                      _eyebrow('Photo · optional', _photos.length),
                      const SizedBox(height: 4),
                      CustomText(
                        'Show the problem or the item you need help with.',
                        fontSize: 12,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 12),
                      _photoSection(),
                      const SizedBox(height: 22),
                      // Selectable groups — fetched per provider profession.
                      if (_loadingOptions)
                        _optionsLoader()
                      else
                        for (final group in _groups) ...[
                          _eyebrow(group.title, _countFor(group.apiKey)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: group.options
                                .map((s) => _checkChip(
                                      label: s,
                                      on: _isOn(group.apiKey, s),
                                      onTap: () => _toggle(group.apiKey, s),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                      // Note.
                      _eyebrow('Note · optional', 0),
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
            child: const Icon(Icons.handyman_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'What do you need?',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  'Tell ${widget.providerName} what you’re looking for',
                  fontSize: 12.5,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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

  Widget _optionsLoader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: _accent),
          ),
          const SizedBox(width: 10),
          CustomText(
            'Loading options…',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
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
  }) {
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
              on
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
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
        for (final path in _photos) ...[
          _fullWidthThumb(path),
          const SizedBox(height: 10),
        ],
        if (_photos.length < _maxPhotos) _addPhotoButton(),
      ],
    );
  }

  Widget _fullWidthThumb(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Image.file(
            File(path),
            width: double.infinity,
            height: 190,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: () => _removePhoto(path),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addPhotoButton() {
    return InkWell(
      onTap: _pickPhotos,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 132,
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
            Icon(Icons.add_a_photo_outlined, size: 30, color: _accent),
            const SizedBox(height: 8),
            CustomText('Add a photo',
                fontSize: 14, fontWeight: FontWeight.w800, color: _accent),
            const SizedBox(height: 2),
            CustomText('Tap to upload from gallery',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor),
          ],
        ),
      ),
    );
  }

  Widget _noteField() {
    return CommonTextField(
      textEditController: _noteController,
      hintText: 'Describe the issue, timing, budget…',
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
                  'Send Enquiry',
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
