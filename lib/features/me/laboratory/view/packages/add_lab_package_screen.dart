import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_package_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_package_model.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_test_repo.dart';
import 'package:BlueEra/features/me/laboratory/view/packages/my_lab_packages_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// "Add Package" form — targets `POST /packages` per
/// lib/docs/LABORATORY_INTEGRATION.md §1. Opened from the preset list
/// [CreateYourOwnPackagesScreen]; the tapped preset's name pre-fills the
/// name field (still editable).
class AddLabPackageScreen extends StatefulWidget {
  /// The preset name to pre-fill; empty for the "Add Manually" tile.
  final String presetName;

  const AddLabPackageScreen({super.key, this.presetName = ''});

  @override
  State<AddLabPackageScreen> createState() => _AddLabPackageScreenState();
}

class _AddLabPackageScreenState extends State<AddLabPackageScreen> {
  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _surface = Color(0xFFF4F6FA);
  static const Color _line = Color(0xFFE5E7EB);

  late final LabPackageController _pkgCtrl =
      getOrPut(() => LabPackageController());

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mrpController = TextEditingController();
  final _priceController = TextEditingController();

  String _gender = 'All';
  String? _uploadedImageUrl;
  File? _pickedImageFile;

  /// Ids of the tests the user has ticked in the picker sheet.
  final Set<String> _selectedTestIds = <String>{};

  /// Cache of picked tests (id → name) so the "N tests selected" summary
  /// can render the names inline without keeping the sheet open.
  final Map<String, String> _selectedTestNames = <String, String>{};

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.presetName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _mrpController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _selectedTestIds.isNotEmpty &&
      !_pkgCtrl.isSaving.value &&
      !_pkgCtrl.isUploadingImage.value;

  Future<void> _pickCover() async {
    final path = await PhotoPickerService.pickSinglePhoto(
      context,
      AppStrings.photoLabel.tr,
      isOnlyCamera: false,
      isGallery: true,
    );
    if (path == null || path.isEmpty || !mounted) return;
    setState(() {
      _pickedImageFile = File(path);
      _uploadedImageUrl = null; // reset — will re-upload on save
    });
  }

  Future<void> _openTestPicker() async {
    final result = await showModalBottomSheet<Map<String, String>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LabTestPickerSheet(
        initiallySelected: Map<String, String>.from(_selectedTestNames),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedTestIds
        ..clear()
        ..addAll(result.keys);
      _selectedTestNames
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      commonSnackBar(message: 'Package name is required');
      return;
    }
    if (_selectedTestIds.isEmpty) {
      commonSnackBar(message: 'Please select at least 1 test');
      return;
    }
    // Advisable pricing check per FLUTTER_CATALOGUE_INTEGRATION.md PART 14
    // — the backend does not reject it, but customer price above MRP is
    // almost always a data-entry mistake.
    final mrp = int.tryParse(_mrpController.text.trim());
    final price = int.tryParse(_priceController.text.trim());
    if (mrp != null && price != null && price > mrp) {
      commonSnackBar(
          message: 'Customer price must be less than or equal to MRP');
      return;
    }

    // Upload picked image just before submitting so the wire stays clean
    // if the user backs out of the form.
    String? imageUrl = _uploadedImageUrl;
    if (_pickedImageFile != null && imageUrl == null) {
      imageUrl = await _pkgCtrl.uploadPackageImage(_pickedImageFile!);
      if (imageUrl == null) return; // upload failed, snackbar already shown
      _uploadedImageUrl = imageUrl;
    }

    final pkg = LabPackage(
      name: name,
      description: _descriptionController.text.trim(),
      imageUrl: imageUrl,
      testIds: _selectedTestIds.toList(),
      packageMrp: int.tryParse(_mrpController.text.trim()),
      customerPrice: int.tryParse(_priceController.text.trim()),
      gender: _gender,
    );

    final ok = await _pkgCtrl.createPackage(pkg);
    if (ok && mounted) {
      // Land on My Packages so the user sees the newly created package.
      // `Get.off` replaces the form in the stack — back button returns to
      // the presets landing (which pushed this form), not to a stale form.
      Get.off(() => const MyLabPackagesScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonBackAppBar(title: 'Add Package'),
      body: Obx(() {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  SizeConfig.size16,
                  SizeConfig.size12,
                  SizeConfig.size16,
                  SizeConfig.size16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _coverPicker(),
                    SizedBox(height: SizeConfig.size18),
                    _eyebrow('Package name · required'),
                    SizedBox(height: SizeConfig.size8),
                    CommonTextField(
                      textEditController: _nameController,
                      hintText: 'e.g. Full Body Checkup',
                      isValidate: false,
                      onChange: (_) => setState(() {}),
                    ),
                    SizedBox(height: SizeConfig.size18),
                    _eyebrow(
                        'Description · ${AppStrings.optionalLabel.tr}'),
                    SizedBox(height: SizeConfig.size8),
                    CommonTextField(
                      textEditController: _descriptionController,
                      hintText: 'What the package covers',
                      maxLine: 4,
                      minLines: 2,
                      isValidate: false,
                    ),
                    SizedBox(height: SizeConfig.size18),
                    _testsPickerTile(),
                    SizedBox(height: SizeConfig.size18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _eyebrow('MRP (INR)'),
                              SizedBox(height: SizeConfig.size8),
                              CommonTextField(
                                textEditController: _mrpController,
                                hintText: '0',
                                keyBoardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                isValidate: false,
                                onChange: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: SizeConfig.size12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _eyebrow('Customer price (INR)'),
                              SizedBox(height: SizeConfig.size8),
                              CommonTextField(
                                textEditController: _priceController,
                                hintText: '0',
                                keyBoardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                isValidate: false,
                                onChange: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size18),
                    _eyebrow('Gender'),
                    SizedBox(height: SizeConfig.size8),
                    Row(
                      children: [
                        for (final g in LabPackageController.genderOptions) ...[
                          _genderChip(g),
                          SizedBox(width: SizeConfig.size8),
                        ],
                      ],
                    ),
                    SizedBox(height: SizeConfig.size24),
                  ],
                ),
              ),
            ),
            _bottomBar(),
          ],
        );
      }),
    );
  }

  Widget _eyebrow(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
        color: AppColors.secondaryTextColor,
      ),
    );
  }

  Widget _coverPicker() {
    return InkWell(
      onTap: _pkgCtrl.isUploadingImage.value ? null : _pickCover,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        clipBehavior: Clip.antiAlias,
        child: _pickedImageFile != null
            ? Image.file(_pickedImageFile!, fit: BoxFit.cover,
                width: double.infinity, height: 140)
            : (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: _uploadedImageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 140,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 32, color: _accent),
                      SizedBox(height: SizeConfig.size6),
                      CustomText(
                        'Add cover image',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                      ),
                    ],
                  )),
      ),
    );
  }

  Widget _testsPickerTile() {
    final n = _selectedTestIds.length;
    final preview = _selectedTestNames.values.take(3).join(' · ');
    return InkWell(
      onTap: _openTestPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: n > 0 ? _accent : _line,
            width: n > 0 ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.checklist_rtl_rounded,
                size: 22, color: n > 0 ? _accent : AppColors.secondaryTextColor),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    n == 0
                        ? 'Select tests · required'
                        : '$n ${n == 1 ? 'test' : 'tests'} selected',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                  if (preview.isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size4),
                    CustomText(
                      preview,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.secondaryTextColor),
          ],
        ),
      ),
    );
  }

  Widget _genderChip(String g) {
    final on = _gender == g;
    return InkWell(
      onTap: () => setState(() => _gender = g),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size14, vertical: SizeConfig.size8),
        decoration: BoxDecoration(
          color: on ? _accent.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? _accent : _line, width: on ? 1.4 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              on
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              size: 14,
              color: on ? _accent : AppColors.secondaryTextColor,
            ),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              g,
              fontSize: 12.5,
              fontWeight: on ? FontWeight.w700 : FontWeight.w600,
              color: on ? _accent : AppColors.mainTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final saving = _pkgCtrl.isSaving.value || _pkgCtrl.isUploadingImage.value;
    final enabled = _canSubmit && !saving;
    return Container(
      padding: EdgeInsets.fromLTRB(SizeConfig.size16, SizeConfig.size10,
          SizeConfig.size16, SizeConfig.size14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: enabled ? _save : null,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: enabled
                  ? const LinearGradient(colors: [_accentDeep, _accent])
                  : null,
              color: enabled ? null : _line,
              borderRadius: BorderRadius.circular(14),
            ),
            child: saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : CustomText(
                    'Save Package',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: enabled ? Colors.white : AppColors.greyCA,
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Multi-select test picker
// ─────────────────────────────────────────────────────────────────────────

/// Bottom sheet that fetches the lab's own PathologyTests across all six
/// known collections and lets the owner tick tests to include in the
/// package. Selections carry ids **and** names so the parent form can
/// preview the selection without keeping the sheet open.
class _LabTestPickerSheet extends StatefulWidget {
  final Map<String, String> initiallySelected; // id → name

  const _LabTestPickerSheet({required this.initiallySelected});

  @override
  State<_LabTestPickerSheet> createState() => _LabTestPickerSheetState();
}

class _LabTestPickerSheetState extends State<_LabTestPickerSheet> {
  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _surface = Color(0xFFF4F6FA);
  static const Color _line = Color(0xFFE5E7EB);

  /// Use the repo directly (not the shared [LabTestController]) so this
  /// sheet's fetch doesn't overwrite the tests list the parent Tests tab
  /// keeps in state — per FLUTTER_CATALOGUE_INTEGRATION.md PART 5, the
  /// picker loads the full lab-scoped test list once via
  /// `GET /pathology-tests` (token, no pagination) and does client-side
  /// search over it.
  final LabTestRepo _testRepo = LabTestRepo();

  bool _loading = true;
  String? _loadError;

  /// The full flat list of the lab's tests (single fetch).
  List<PathologyTest> _allTests = const <PathologyTest>[];

  /// Live selection: id → name (name kept so the parent can preview).
  late final Map<String, String> _selected =
      Map<String, String>.from(widget.initiallySelected);

  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadAllTests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllTests() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      // Empty groupCategory → unfiltered lab-scoped list (see
      // LabTestController.fetchPopularTests for the same convention).
      final res = await _testRepo.getPathologyTests('');
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        _allTests = data
            .whereType<Map<String, dynamic>>()
            .map(PathologyTest.fromJson)
            .toList();
      } else {
        _loadError = res.message ?? 'Failed to load tests';
      }
    } catch (e) {
      _loadError = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PathologyTest> get _filteredTests {
    if (_search.trim().isEmpty) return _allTests;
    final q = _search.trim().toLowerCase();
    return _allTests
        .where((t) => (t.testName ?? '').toLowerCase().contains(q))
        .toList();
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
            children: [
              _grabber(),
              _header(),
              _searchField(),
              const Divider(height: 1, thickness: 1, color: _line),
              Flexible(child: _body()),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: _accentDeep),
          ),
        ),
      );
    }
    if (_loadError != null) {
      return Padding(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: Column(
          children: [
            CustomText(
              _loadError!,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size10),
            InkWell(
              onTap: _loadAllTests,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16,
                    vertical: SizeConfig.size8),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomText('Retry',
                    fontSize: 13, fontWeight: FontWeight.w700, color: _accent),
              ),
            ),
          ],
        ),
      );
    }
    final tests = _filteredTests;
    if (tests.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: Center(
          child: CustomText(
            _search.isNotEmpty
                ? 'No matching tests.'
                : 'No tests yet — add one from the Tests tab first.',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.only(top: SizeConfig.size6),
      itemCount: tests.length,
      itemBuilder: (_, i) => _testRow(tests[i]),
    );
  }

  Widget _grabber() => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: EdgeInsets.only(top: SizeConfig.size10, bottom: SizeConfig.size6),
          decoration: BoxDecoration(
            color: _line,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _header() {
    return Padding(
      padding: EdgeInsets.fromLTRB(SizeConfig.size20, SizeConfig.size6,
          SizeConfig.size14, SizeConfig.size10),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              'Select tests',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(null),
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

  Widget _searchField() {
    return Padding(
      padding: EdgeInsets.fromLTRB(SizeConfig.size16, 0, SizeConfig.size16,
          SizeConfig.size10),
      child: CommonTextField(
        textEditController: _searchController,
        hintText: 'Search by test name',
        isValidate: false,
        onChange: (v) => setState(() => _search = v),
      ),
    );
  }

  Widget _testRow(PathologyTest t) {
    final id = t.id ?? '';
    if (id.isEmpty) return const SizedBox.shrink();
    final on = _selected.containsKey(id);
    return InkWell(
      onTap: () => setState(() {
        if (on) {
          _selected.remove(id);
        } else {
          _selected[id] = t.testName ?? '';
        }
      }),
      child: Padding(
        padding: EdgeInsets.fromLTRB(SizeConfig.size16, SizeConfig.size6,
            SizeConfig.size16, SizeConfig.size6),
        child: Row(
          children: [
            Icon(
              on
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: on ? _accent : AppColors.secondaryTextColor,
              size: 22,
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    t.testName ?? '',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((t.customerPrice ?? 0) > 0)
                    CustomText(
                      '₹${t.customerPrice}',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    final n = _selected.length;
    return Container(
      padding: EdgeInsets.fromLTRB(SizeConfig.size16, SizeConfig.size10,
          SizeConfig.size16, SizeConfig.size12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              n == 0
                  ? 'No tests selected'
                  : '$n ${n == 1 ? 'test' : 'tests'} selected',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: n > 0 ? _accent : AppColors.secondaryTextColor,
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(_selected),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size18, vertical: SizeConfig.size10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_accentDeep, _accent]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
