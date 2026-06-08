import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/Discover/model/emergency_contact_model.dart';
import 'package:BlueEra/features/common/Discover/repo/emergency_contacts_repo.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class TrustedContact {
  /// Server-issued id when the contact has been persisted via
  /// `rider-service/emergency-contacts`. Null for newly-added or
  /// device-picked entries that haven't been saved yet.
  final String? id;
  final String name;
  final String phone;

  const TrustedContact({this.id, required this.name, required this.phone});

  TrustedContact copyWith({String? id, String? name, String? phone}) =>
      TrustedContact(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
      );

  factory TrustedContact.fromEmergencyModel(EmergencyContactModel m) =>
      TrustedContact(
        id: m.id,
        name: m.name,
        phone: m.displayPhone,
      );

  @override
  bool operator ==(Object other) =>
      other is TrustedContact && other.phone == phone;

  @override
  int get hashCode => phone.hashCode;
}

const int kMaxTrustedContacts = 3;

/// Trusted Contacts entry — info banner up top, list of currently-saved
/// contacts with a per-row delete, and a primary "Add Contact" button that
/// opens a sheet offering "Choose from contacts" or "Add manually".
class TrustedContactsScreen extends StatefulWidget {
  final List<TrustedContact> initial;

  const TrustedContactsScreen({super.key, this.initial = const []});

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  late final List<TrustedContact> _contacts = [...widget.initial];
  final _repo = EmergencyContactsRepo();
  bool _isLoading = false;
  bool _isSubmitting = false;

  bool get _atLimit => _contacts.length >= kMaxTrustedContacts;

  @override
  void initState() {
    super.initState();
    _refreshFromServer();
  }

  Future<void> _refreshFromServer() async {
    setState(() => _isLoading = true);
    try {
      final res = await _repo.list();
      if (!mounted) return;
      if (res.isSuccess) {
        final raw = res.response?.data;
        final list = (raw is Map ? raw['contacts'] as List? : null) ?? const [];
        final fetched = list
            .map((e) => EmergencyContactModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .map(TrustedContact.fromEmergencyModel)
            .toList();
        setState(() {
          _contacts
            ..clear()
            ..addAll(fetched);
        });
      }
    } catch (_) {
      // Silent — screen still works with locally added entries.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Server expects the Indian phone form `^(?:\+91|91)?[6-9]\d{9}$`.
  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+$digits';
    }
    return '+91$digits';
  }

  String _readErrorMessage(ResponseModel res, String fallback) {
    final raw = res.response?.data;
    if (raw is Map && raw['message'] is String) {
      return raw['message'] as String;
    }
    return fallback;
  }

  /// POSTs a single contact and returns the persisted entry (or null on
  /// failure). Shows a snackbar for known cap / duplicate errors.
  Future<TrustedContact?> _persist(TrustedContact c) async {
    final res = await _repo.create(
      name: c.name,
      contactNo: _normalizePhone(c.phone),
    );
    if (res.isSuccess) {
      final raw = res.response?.data;
      final body = raw is Map && raw['data'] is Map
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : raw is Map
              ? Map<String, dynamic>.from(raw)
              : <String, dynamic>{};
      if (body.isNotEmpty) {
        return TrustedContact.fromEmergencyModel(
            EmergencyContactModel.fromJson(body));
      }
      return c;
    }
    final code = res.response?.statusCode ?? 0;
    if (code == 400) {
      commonSnackBar(message: _readErrorMessage(res, AppStrings.canSaveAtMost3EmergencyContacts.tr));
    } else if (code == 409) {
      commonSnackBar(message: _readErrorMessage(res, AppStrings.numberAlreadySaved.tr));
    } else {
      commonSnackBar(message: _readErrorMessage(res, AppStrings.couldNotSaveContact.tr));
    }
    return null;
  }

  Future<void> _removeAt(int index) async {
    final c = _contacts[index];
    if (c.id == null) {
      // Was never persisted — drop locally.
      setState(() => _contacts.removeAt(index));
      return;
    }
    setState(() => _isSubmitting = true);
    final res = await _repo.deleteOne(c.id!);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    final code = res.response?.statusCode ?? 0;
    // 200 → deleted; 403/404 → already gone, prune locally too.
    if (res.isSuccess || code == 403 || code == 404) {
      setState(() => _contacts.removeAt(index));
    } else {
      commonSnackBar(
          message: _readErrorMessage(res, AppStrings.couldNotRemoveContact.tr));
    }
  }

  Future<void> _openAddSheet() async {
    if (_atLimit) {
      commonSnackBar(
          message:
              AppStrings.canAddUpToEmergencyContacts.tr.replaceAll('{N}', '$kMaxTrustedContacts'));
      return;
    }
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        AppStrings.addContacts.tr,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.whiteE5,
                        ),
                        child: const Icon(Icons.close,
                            size: 16, color: AppColors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _AddOptionTile(
                  icon: Icons.contact_page_outlined,
                  label: AppStrings.chooseFromContacts.tr,
                  onTap: () async {
                    Get.back();
                    await _pickFromContacts();
                  },
                ),
                const SizedBox(height: 10),
                _AddOptionTile(
                  icon: Icons.person_add_alt_1,
                  label: AppStrings.addManually.tr,
                  onTap: () async {
                    Get.back();
                    await _addManually();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFromContacts() async {
    PermissionStatus status = await Permission.contacts.status;
    if (!status.isGranted) {
      status = await Permission.contacts.request();
    }
    if (status.isPermanentlyDenied) {
      commonSnackBar(
          message: AppStrings.contactsPermissionBlocked.tr);
      await openAppSettings();
      return;
    }
    if (!status.isGranted) {
      commonSnackBar(message: AppStrings.contactsPermissionRequired.tr);
      return;
    }

    final remaining = kMaxTrustedContacts - _contacts.length;
    final picked = await Get.to<List<TrustedContact>>(() =>
        ChooseContactsScreen(
          maxSelectable: remaining,
          alreadyAdded: _contacts,
        ));

    if (picked == null || picked.isEmpty) return;
    setState(() => _isSubmitting = true);
    for (final c in picked) {
      if (_atLimit) break;
      if (_contacts.contains(c)) continue;
      final saved = await _persist(c);
      if (!mounted) return;
      if (saved != null) {
        setState(() => _contacts.add(saved));
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _addManually() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.whiteE5),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            size: 16, color: AppColors.black),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CustomText(
                      AppStrings.addContactManually.tr,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
              const SizedBox(height: 18),
              CustomText(AppStrings.enterMobileNumber.tr,
                  fontSize: 13, fontWeight: FontWeight.w600),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.whiteE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Text('🇮🇳', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 4),
                        Text('+91',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: InputDecoration(
                        hintText: AppStrings.eg9876543210.tr,
                        hintStyle: const TextStyle(
                          color: AppColors.grayText,
                          fontSize: 13,
                        ),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CustomText(AppStrings.enterNameLabel.tr,
                  fontSize: 13, fontWeight: FontWeight.w600),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: AppStrings.egRameshKumar.tr,
                  hintStyle: const TextStyle(
                    color: AppColors.grayText,
                    fontSize: 13,
                  ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () async {
                    final phone = phoneCtrl.text.trim();
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      commonSnackBar(message: AppStrings.pleaseEnterAName.tr);
                      return;
                    }
                    if (phone.length != 10 ||
                        int.tryParse(phone) == null) {
                      commonSnackBar(
                          message: AppStrings.enterValidTenDigit.tr);
                      return;
                    }
                    final draft =
                        TrustedContact(name: name, phone: phone);
                    if (_contacts.contains(draft)) {
                      commonSnackBar(
                          message: AppStrings.contactAlreadyAdded.tr);
                      return;
                    }
                    final saved = await _persist(draft);
                    if (!mounted) return;
                    if (saved != null) {
                      setState(() => _contacts.add(saved));
                      Get.back();
                    }
                  },
                  child: Text(
                    AppStrings.save.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: InkWell(
            onTap: () => Get.back(result: _contacts),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.whiteE5),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
              // child: const Icon(Icons.arrow_back,
                  color: AppColors.black, size: 20),
            ),
          ),
        ),
        centerTitle: true,
        title: CustomText(AppStrings.trustedContactsTitle.tr,
            fontSize: 16, fontWeight: FontWeight.w700),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 56, color: AppColors.primaryColor),
                        const SizedBox(height: 6),
                        CustomText(
                          AppStrings.everythingOkay.tr,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        const SizedBox(height: 4),
                        CustomText(
                          AppStrings.trustedContactsInfo.tr,
                          fontSize: 12,
                          color: AppColors.grayText,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  CustomText(
                    AppStrings.liveRideTracking.tr,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 6),
                  CustomText(
                    AppStrings.liveRideTrackingInfo.tr,
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                  const SizedBox(height: 18),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_contacts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: CustomText(
                          AppStrings.noTrustedContactsYet.tr,
                          fontSize: 13,
                          color: AppColors.grayText,
                        ),
                      ),
                    )
                  else
                    ..._contacts.asMap().entries.map((e) =>
                        _ContactRow(
                          contact: e.value,
                          onDelete: () => _removeAt(e.key),
                        )),
                  const SizedBox(height: 6),
                  CustomText(
                    '${_contacts.length}/$kMaxTrustedContacts ${AppStrings.addedCountSuffix.tr}',
                    fontSize: 12,
                    color: AppColors.grayText,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (_atLimit || _isSubmitting || _isLoading)
                            ? AppColors.primaryColor.withValues(alpha: 0.5)
                            : AppColors.primaryColor,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed:
                      (_atLimit || _isSubmitting || _isLoading)
                          ? null
                          : _openAddSheet,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                                AppColors.white),
                          ),
                        )
                      : Text(
                          _contacts.isEmpty
                              ? AppStrings.addContact.tr
                              : AppStrings.addAnotherContact.tr,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add option tile (sheet rows) ───────────────────────────────────────────

class _AddOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.black),
            const SizedBox(width: 14),
            CustomText(label,
                fontSize: 15, fontWeight: FontWeight.w600),
          ],
        ),
      ),
    );
  }
}

// ─── Contact row in trusted list ────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  final TrustedContact contact;
  final VoidCallback onDelete;

  const _ContactRow({required this.contact, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final initial = contact.name.isNotEmpty
        ? contact.name.characters.first.toUpperCase()
        : '#';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryColor,
            child: Text(initial,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(contact.name,
                    fontSize: 14, fontWeight: FontWeight.w700),
                const SizedBox(height: 2),
                CustomText(contact.phone,
                    fontSize: 12, color: AppColors.grayText),
              ],
            ),
          ),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.whiteE5),
              ),
              child: const Icon(Icons.delete_outline,
                  size: 18, color: AppColors.grayText),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Choose Contacts (system contacts list with checkboxes) ─────────────────

class ChooseContactsScreen extends StatefulWidget {
  final int maxSelectable;
  final List<TrustedContact> alreadyAdded;

  const ChooseContactsScreen({
    super.key,
    required this.maxSelectable,
    this.alreadyAdded = const [],
  });

  @override
  State<ChooseContactsScreen> createState() => _ChooseContactsScreenState();
}

class _ChooseContactsScreenState extends State<ChooseContactsScreen> {
  bool _loading = true;
  String _query = '';
  List<TrustedContact> _all = [];
  final Set<TrustedContact> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Strip everything except digits and reduce to a 10-digit local Indian
  /// number — drops `+91` / `91` country prefix, leading zero, parentheses,
  /// dots, spaces, hyphens etc. Returns empty if the result isn't a valid
  /// 10-digit Indian mobile (must start with 6-9).
  String _normalizeIndianPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 10
        ? digits.substring(digits.length - 10)
        : digits;
    if (trimmed.length != 10) return '';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(trimmed)) return '';
    return trimmed;
  }

  Future<void> _load() async {
    try {
      final raw = await FlutterContacts.getContacts(
        withProperties: true,
      );
      final flattened = <TrustedContact>[];
      for (final c in raw) {
        for (final p in c.phones) {
          final clean = _normalizeIndianPhone(p.number);
          if (clean.isEmpty) continue;
          flattened.add(TrustedContact(
            name: c.displayName.trim().isEmpty
                ? clean
                : c.displayName.trim(),
            phone: clean,
          ));
        }
      }
      // De-duplicate by phone (already normalized to 10-digit).
      final seen = <String>{};
      final deduped = <TrustedContact>[];
      for (final c in flattened) {
        if (seen.add(c.phone)) deduped.add(c);
      }
      deduped.sort((a, b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      setState(() {
        _all = deduped;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<TrustedContact> get _filtered {
    if (_query.isEmpty) return _all;
    final q = _query.toLowerCase();
    return _all
        .where((c) =>
            c.name.toLowerCase().contains(q) || c.phone.contains(q))
        .toList();
  }

  void _toggle(TrustedContact c) {
    if (widget.alreadyAdded.contains(c)) return;
    setState(() {
      if (_selected.contains(c)) {
        _selected.remove(c);
      } else {
        if (_selected.length >= widget.maxSelectable) {
          commonSnackBar(
              message:
                  AppStrings.youCanPickUpToContactsHint.tr.replaceAll('{N}', '${widget.maxSelectable}'));
          return;
        }
        _selected.add(c);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.whiteE5),
              ),
              child: const Icon(Icons.close,
                  color: AppColors.black, size: 18),
            ),
          ),
        ),
        title: CustomText(AppStrings.chooseContactsTitle.tr,
            fontSize: 16, fontWeight: FontWeight.w700),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F2F4),
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      color: AppColors.grayText, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: AppStrings.searchNameOrNumber.tr,
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const Expanded(
                child: Center(child: CircularProgressIndicator()))
          else if (_all.isEmpty)
            Expanded(
              child: Center(
                child: CustomText(AppStrings.noContactsFound.tr,
                    fontSize: 13, color: AppColors.grayText),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) {
                  final c = _filtered[i];
                  final isSelected = _selected.contains(c);
                  final isAlready = widget.alreadyAdded.contains(c);
                  final initial = c.name.isNotEmpty
                      ? c.name.characters.first.toUpperCase()
                      : '#';
                  return InkWell(
                    onTap: () => _toggle(c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.whiteE5),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.whiteE5,
                            child: Text(initial,
                                style: const TextStyle(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                CustomText(c.name,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                CustomText(c.phone,
                                    fontSize: 12,
                                    color: AppColors.grayText),
                              ],
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isAlready
                                  ? AppColors.whiteE5
                                  : isSelected
                                      ? AppColors.primaryColor
                                      : AppColors.white,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : AppColors.whiteE5,
                                width: 1.5,
                              ),
                            ),
                            child: (isSelected || isAlready)
                                ? const Icon(Icons.check,
                                    size: 14, color: AppColors.white)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selected.isEmpty
                        ? AppColors.primaryColor.withValues(alpha: 0.5)
                        : AppColors.primaryColor,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Get.back(result: _selected.toList()),
                  child: Text(
                    '${AppStrings.confirmTrustedContactsPrefix.tr} (${_selected.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
