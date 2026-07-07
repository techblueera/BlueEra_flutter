import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_package_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_test_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_package_model.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
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
    if (ok && mounted) Get.back();
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
  static const List<String> _collections = [
    'Blood & Routine Tests',
    'Preventive & Wellness Checkups',
    'Women, Pregnancy & Child Health',
    'Diagnostics & Imaging',
    'Organ & System Health',
    'Infection, Cancer & Immunity',
  ];

  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _surface = Color(0xFFF4F6FA);
  static const Color _line = Color(0xFFE5E7EB);

  final _testCtrl = getOrPut(() => LabTestController());

  /// Aggregated tests per collection — loaded on demand when a section is
  /// first expanded.
  final Map<String, List<PathologyTest>> _testsByCollection = {};
  final Set<String> _loadingCollections = {};

  /// Live selection: id → name (name kept so the parent can preview).
  late final Map<String, String> _selected =
      Map<String, String>.from(widget.initiallySelected);

  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    // Preload the first collection so the user sees content immediately.
    _loadCollection(_collections.first);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCollection(String collection) async {
    if (_testsByCollection.containsKey(collection) ||
        _loadingCollections.contains(collection)) {
      return;
    }
    setState(() => _loadingCollections.add(collection));
    try {
      // Reuse the shared repo through the shared controller so this
      // doesn't clobber any list state the tests-list screen has open.
      // Fetching in isolation via a scratch controller keeps the Rx list
      // on the shared instance untouched.
      await _testCtrl.fetchTests(collection);
      _testsByCollection[collection] =
          _testCtrl.tests.map((t) => t).toList();
    } finally {
      if (mounted) setState(() => _loadingCollections.remove(collection));
    }
  }

  List<PathologyTest> _filter(List<PathologyTest> tests) {
    if (_search.trim().isEmpty) return tests;
    final q = _search.trim().toLowerCase();
    return tests
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
              Flexible(
                child: ListView.builder(
                  padding: EdgeInsets.only(top: SizeConfig.size6),
                  itemCount: _collections.length,
                  itemBuilder: (_, i) => _collectionSection(_collections[i]),
                ),
              ),
              _footer(),
            ],
          ),
        ),
      ),
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

  Widget _collectionSection(String collection) {
    final loaded = _testsByCollection[collection];
    final loading = _loadingCollections.contains(collection);
    final tests = _filter(loaded ?? const []);
    final pickedInSection =
        (loaded ?? const []).where((t) => _selected.containsKey(t.id)).length;
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        onExpansionChanged: (open) {
          if (open) _loadCollection(collection);
        },
        tilePadding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16, vertical: SizeConfig.size2),
        childrenPadding: EdgeInsets.only(bottom: SizeConfig.size6),
        initiallyExpanded: collection == _collections.first,
        title: CustomText(
          collection,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        subtitle: pickedInSection > 0
            ? CustomText(
                '$pickedInSection selected',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _accent,
              )
            : null,
        children: [
          if (loading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size14),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _accentDeep),
                ),
              ),
            )
          else if (loaded == null)
            const SizedBox.shrink()
          else if (tests.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(SizeConfig.size16,
                  SizeConfig.size4, SizeConfig.size16, SizeConfig.size12),
              child: CustomText(
                _search.isNotEmpty
                    ? 'No matching tests in this category.'
                    : 'No tests in this category yet — add one from the Tests tab.',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
            )
          else
            ...tests.map(_testRow),
        ],
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
