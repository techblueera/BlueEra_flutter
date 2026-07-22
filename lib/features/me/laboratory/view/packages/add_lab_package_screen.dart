import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_package_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_test_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_package_model.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_test_repo.dart';
import 'package:BlueEra/features/me/laboratory/view/packages/my_lab_packages_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// Shared palette for the form + both picker sheets. Kept as top-level
// consts so the sheet widgets outside the state class can use them.
const Color _accent = AppColors.primaryColor;
const Color _accentDeep = AppColors.blue5CAF;
const Color _surface = Color(0xFFF4F6FA);
const Color _cardBg = Colors.white;
const Color _line = Color(0xFFE5E7EB);

/// "Add Package" / "Edit Package" form — targets `POST /packages` for create
/// and `PUT /packages/{id}` for edit per FLUTTER_CATALOGUE_INTEGRATION.md
/// PART 5 and PART 9B. Opened from the preset list
/// [CreateYourOwnPackagesScreen] in create mode; opened from
/// [MyLabPackagesScreen] with [editingPackage] set in edit mode.
class AddLabPackageScreen extends StatefulWidget {
  /// The preset name to pre-fill in create mode; empty for the "Add Manually"
  /// tile. Ignored when [editingPackage] is provided.
  final String presetName;

  /// When non-null, the form runs in edit mode: fields are pre-populated from
  /// this package and saving performs `PUT /packages/{id}`.
  final LabPackage? editingPackage;

  const AddLabPackageScreen({
    super.key,
    this.presetName = '',
    this.editingPackage,
  });

  @override
  State<AddLabPackageScreen> createState() => _AddLabPackageScreenState();
}

class _AddLabPackageScreenState extends State<AddLabPackageScreen> {
  late final LabPackageController _pkgCtrl =
      getOrPut(() => LabPackageController());
  final LabTestRepo _testRepo = LabTestRepo();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mrpController = TextEditingController();
  final _priceController = TextEditingController();

  String _gender = 'All';
  String? _uploadedImageUrl;

  // Two photo slots per mockup. Backend `LabPackage.imageUrl` is a single
  // string — only slot 1 is uploaded and persisted; slot 2 is a visual
  // placeholder for future multi-image support.
  File? _pickedImageFile1;
  File? _pickedImageFile2;

  /// id → PathologyTest for selected tests. Keeps category, price, and name
  /// so the form can group by category, auto-fill MRP from the running
  /// total, and preserve the selection across sheet re-opens.
  final Map<String, PathologyTest> _selectedTests = <String, PathologyTest>{};

  /// Last value the form auto-filled into [_mrpController]. If the current
  /// field content differs, the user has typed their own MRP and we won't
  /// overwrite it on the next selection change.
  int? _lastAutoFilledMrp;

  /// Full lab-scoped test list cached across the two picker sheets so
  /// reopening "Add More" doesn't re-hit `GET /pathology-tests`.
  List<PathologyTest> _allTestsCache = const <PathologyTest>[];
  bool _loadingAllTests = false;
  String? _allTestsError;

  bool get _isEditing => widget.editingPackage != null;

  @override
  void initState() {
    super.initState();
    final pkg = widget.editingPackage;
    if (pkg != null) {
      _nameController.text = pkg.name ?? '';
      _descriptionController.text = pkg.description ?? '';
      _mrpController.text = pkg.packageMrp?.toString() ?? '';
      _priceController.text = pkg.customerPrice?.toString() ?? '';
      _gender = (pkg.gender?.isNotEmpty ?? false) ? pkg.gender! : 'All';
      _uploadedImageUrl =
          (pkg.imageUrl?.isNotEmpty ?? false) ? pkg.imageUrl : null;
      _lastAutoFilledMrp = pkg.packageMrp;
      // Prefill selected tests from the populated array on the package —
      // `/packages/me` returns tests populated with the fields we need
      // (_id, testName, groupCategory, customerPrice).
      for (final t in (pkg.tests ?? const <PathologyTest>[])) {
        final id = t.id ?? '';
        if (id.isNotEmpty) _selectedTests[id] = t;
      }
    } else {
      _nameController.text = widget.presetName;
    }
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
      _selectedTests.isNotEmpty &&
      !_pkgCtrl.isSaving.value &&
      !_pkgCtrl.isUploadingImage.value;

  Future<void> _pickPhoto(int slot) async {
    final path = await PhotoPickerService.pickSinglePhoto(
      context,
      AppStrings.photoLabel.tr,
      isOnlyCamera: false,
      isGallery: true,
    );
    if (path == null || path.isEmpty || !mounted) return;
    setState(() {
      if (slot == 1) {
        _pickedImageFile1 = File(path);
        _uploadedImageUrl = null; // re-upload on save
      } else {
        _pickedImageFile2 = File(path);
      }
    });
  }

  Future<void> _ensureAllTestsLoaded() async {
    if (_allTestsCache.isNotEmpty || _loadingAllTests) return;
    setState(() {
      _loadingAllTests = true;
      _allTestsError = null;
    });
    try {
      // Empty groupCategory → unfiltered lab-scoped list (see
      // LabTestController.fetchPopularTests for the same convention).
      final res = await _testRepo.getPathologyTests('');
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        _allTestsCache = data
            .whereType<Map<String, dynamic>>()
            .map(PathologyTest.fromJson)
            .toList();
      } else {
        _allTestsError = res.message ?? 'Failed to load tests';
      }
    } catch (e) {
      _allTestsError = '$e';
    } finally {
      if (mounted) setState(() => _loadingAllTests = false);
    }
  }

  Future<void> _openTestPicker() async {
    await _ensureAllTestsLoaded();
    if (!mounted) return;
    if (_allTestsCache.isEmpty) {
      commonSnackBar(
        message: _allTestsError ??
            'No tests available — add tests from the Tests tab first.',
      );
      return;
    }

    // Step 1: category landing (img_1).
    final selectedCategory = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTestCategoriesSheet(allTests: _allTestsCache),
    );
    if (selectedCategory == null || !mounted) return;

    // Step 2: test picker with tabs (img_2).
    final result = await showModalBottomSheet<Map<String, PathologyTest>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTestsInCategorySheet(
        allTests: _allTestsCache,
        initialCategory: selectedCategory,
        initialSelected: Map<String, PathologyTest>.from(_selectedTests),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _selectedTests
        ..clear()
        ..addAll(result);
      _syncMrpFromSelection();
    });
  }

  void _syncMrpFromSelection() {
    final total = _selectedTests.values
        .fold<int>(0, (sum, t) => sum + (t.customerPrice ?? 0));
    final current = _mrpController.text.trim();
    final currentInt = int.tryParse(current);
    // Skip if the user has typed a custom value that we didn't put there.
    final userHasCustomValue =
        current.isNotEmpty && currentInt != _lastAutoFilledMrp;
    if (userHasCustomValue) return;
    _mrpController.text = total > 0 ? total.toString() : '';
    _lastAutoFilledMrp = total > 0 ? total : null;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      commonSnackBar(message: 'Package name is required');
      return;
    }
    if (_selectedTests.isEmpty) {
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

    // Only slot 1 is persisted — see field docs above.
    String? imageUrl = _uploadedImageUrl;
    if (_pickedImageFile1 != null && imageUrl == null) {
      imageUrl = await _pkgCtrl.uploadPackageImage(_pickedImageFile1!);
      if (imageUrl == null) return;
      _uploadedImageUrl = imageUrl;
    }

    // When the form was opened from a preset tile (or an edit that already
    // had one), stamp the preset as `packageType` so the tests-tab preset
    // grid + `/packages/me?packageType=...` filter can identify this
    // package by preset. `name` stays the lab's own display title. See
    // FLUTTER_CATALOGUE_INTEGRATION.md PART 3B §`packageType` vs `name`.
    final presetType = _isEditing
        ? (widget.editingPackage?.packageType ?? widget.presetName).trim()
        : widget.presetName.trim();
    final pkg = LabPackage(
      name: name,
      description: _descriptionController.text.trim(),
      imageUrl: imageUrl,
      testIds: _selectedTests.keys.toList(),
      packageMrp: int.tryParse(_mrpController.text.trim()),
      customerPrice: int.tryParse(_priceController.text.trim()),
      packageType: presetType.isEmpty ? null : presetType,
      gender: _gender,
    );

    final bool ok;
    if (_isEditing) {
      ok = await _pkgCtrl.updatePackage(
        widget.editingPackage!.id ?? '',
        pkg.toCreateJson(),
      );
    } else {
      ok = await _pkgCtrl.createPackage(pkg);
    }
    if (ok && mounted) {
      // Edit is opened directly from the list, so pop back. Create can be
      // reached via the preset landing (multiple screens deep), so replace
      // the stack down to the list.
      if (_isEditing) {
        Get.back();
      } else {
        Get.off(() => const MyLabPackagesScreen());
      }
    }
  }

  // ── Grouping helpers ──────────────────────────────────────────────

  /// Selected tests grouped by category, preserving the display order
  /// defined in [LabTestController.groupCategoryList]. Categories with no
  /// selection are omitted.
  List<MapEntry<String, List<PathologyTest>>> _selectedByCategory() {
    final result = <String, List<PathologyTest>>{};
    for (final t in _selectedTests.values) {
      final cat = (t.groupCategory ?? '').isEmpty ? 'Other' : t.groupCategory!;
      result.putIfAbsent(cat, () => []).add(t);
    }
    final ordered = <MapEntry<String, List<PathologyTest>>>[];
    for (final cat in LabTestController.groupCategoryList) {
      if (result.containsKey(cat)) ordered.add(MapEntry(cat, result[cat]!));
    }
    // Tack on any unknown-category buckets at the end.
    for (final entry in result.entries) {
      if (!LabTestController.groupCategoryList.contains(entry.key)) {
        ordered.add(entry);
      }
    }
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: _isEditing
            ? 'Edit Package'
            : (widget.presetName.isNotEmpty
                ? widget.presetName
                : 'Add Package'),
      ),
      body: Obx(() {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  SizeConfig.size12,
                  SizeConfig.size12,
                  SizeConfig.size12,
                  SizeConfig.size16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _uploadPhotoCard(),
                    SizedBox(height: SizeConfig.size12),
                    _packageNameCard(),
                    SizedBox(height: SizeConfig.size12),
                    _descriptionCard(),
                    SizedBox(height: SizeConfig.size12),
                    _testsCard(),
                    SizedBox(height: SizeConfig.size12),
                    _pricesCard(),
                    SizedBox(height: SizeConfig.size12),
                    _genderCard(),
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

  // ── Card widgets ─────────────────────────────────────────────────

  Widget _sectionCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ??
          EdgeInsets.symmetric(
              horizontal: SizeConfig.size14, vertical: SizeConfig.size14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line, width: 1),
      ),
      child: child,
    );
  }

  Widget _sectionHeader(String label, {Widget? trailing}) {
    return Row(
      children: [
        CustomText(
          label,
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _uploadPhotoCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Upload Photo'),
          SizedBox(height: SizeConfig.size12),
          Row(
            children: [
              Expanded(child: _photoSlot(1, _pickedImageFile1)),
              SizedBox(width: SizeConfig.size12),
              Expanded(child: _photoSlot(2, _pickedImageFile2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoSlot(int slot, File? file) {
    final showUploadedThumb =
        slot == 1 && file == null && (_uploadedImageUrl?.isNotEmpty ?? false);
    return GestureDetector(
      onTap: _pkgCtrl.isUploadingImage.value ? null : () => _pickPhoto(slot),
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        dashPattern: const [6, 4],
        color: _accent,
        strokeWidth: 1.2,
        padding: EdgeInsets.zero,
        child: Container(
          height: 92,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: file != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 92,
                  ),
                )
              : showUploadedThumb
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: _uploadedImageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 92,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_camera_outlined,
                            color: _accent, size: 22),
                        SizedBox(height: SizeConfig.size6),
                        CustomText(
                          'Upload Now',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _accent,
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _packageNameCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Package Name'),
          SizedBox(height: SizeConfig.size10),
          CommonTextField(
            textEditController: _nameController,
            hintText: 'E.g. Text',
            isValidate: false,
            onChange: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _descriptionCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Description'),
          SizedBox(height: SizeConfig.size10),
          CommonTextField(
            textEditController: _descriptionController,
            hintText:
                "Hello Everyone @india User\nNow I am Using https://blueera.ai it's Amazing, I suggest to Join Me.",
            maxLine: 5,
            minLines: 3,
            isValidate: false,
          ),
        ],
      ),
    );
  }

  Widget _testsCard() {
    final groups = _selectedByCategory();
    final hasSelection = groups.isNotEmpty;
    return _sectionCard(
      padding: EdgeInsets.all(SizeConfig.size14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Include Tests in Your Package',
            trailing: hasSelection
                ? GestureDetector(
                    onTap: _openTestPicker,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 16, color: _accent),
                        SizedBox(width: SizeConfig.size4),
                        CustomText(
                          'Add More',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _accent,
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          SizedBox(height: SizeConfig.size12),
          if (!hasSelection)
            _emptyTestsState()
          else
            _selectedTestsGroups(groups),
        ],
      ),
    );
  }

  Widget _emptyTestsState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14, vertical: SizeConfig.size20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(
              imagePath: AppIconAssets.emptyIcon, height: 50, width: 50),
          SizedBox(height: SizeConfig.size8),
          CustomText(
            'No Tests Added Yet',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size4),
          CustomText(
            'Add diagnostic tests to build your package.',
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size14),
          _loadingAllTests
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: _accentDeep),
                )
              : GestureDetector(
                  onTap: _openTestPicker,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size16,
                        vertical: SizeConfig.size10),
                    decoration: BoxDecoration(
                      color: _accent,
                      // gradient:
                      //     const LinearGradient(colors: [_accentDeep, _accent]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded,
                            size: 16, color: Colors.white),
                        SizedBox(width: SizeConfig.size4),
                        CustomText(
                          'Add Now',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _selectedTestsGroups(
      List<MapEntry<String, List<PathologyTest>>> groups) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int i = 0; i < groups.length; i++) ...[
            _selectedGroupRow(groups[i].key, groups[i].value.length),
            if (i < groups.length - 1)
              const Divider(height: 1, thickness: 1, color: _line, indent: 44),
          ],
        ],
      ),
    );
  }

  Widget _selectedGroupRow(String category, int count) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size12),
      child: Row(
        children: [
          _categoryIcon(category),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: CustomText(
              category,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border:
                  Border(top: BorderSide(color: Color(0xffDDE2EE), width: 1)),
            ),
            child: CustomText(
              '$count ${count == 1 ? 'Test' : 'Tests'}',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.grey7E,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pricesCard() {
    return _sectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _priceLabel('MRP (INR)'),
                SizedBox(height: SizeConfig.size8),
                CommonTextField(
                  textEditController: _mrpController,
                  hintText: 'E.g. Text',
                  keyBoardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  isValidate: false,
                  borderColor: AppColors.geryFC,
                  borderWidth: 1,
                  prefixText: '₹ ',
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
                _priceLabel('Customer Price (INR)'),
                SizedBox(height: SizeConfig.size8),
                CommonTextField(
                  textEditController: _priceController,
                  hintText: 'E.g. Text',
                  keyBoardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  isValidate: false,
                  onChange: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceLabel(String text) {
    return CustomText(
      text,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.mainTextColor,
    );
  }

  Widget _genderCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Gender'),
          SizedBox(height: SizeConfig.size10),
          Row(
            children: [
              for (final g in LabPackageController.genderOptions) ...[
                _genderChip(g),
                SizedBox(width: SizeConfig.size8),
              ],
            ],
          ),
        ],
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
              on ? Icons.check_circle_rounded : Icons.circle_outlined,
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
                    _isEditing ? 'Update Package' : 'Save Package',
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
//  Shared sheet chrome
// ─────────────────────────────────────────────────────────────────────────

/// SVG asset path for a `groupCategory` value — mirrors the mapping used
/// by the v2 lab category screen so both surfaces share the same iconography.
String _iconAssetForCategory(String cat) {
  switch (cat) {
    case 'Blood & Routine Tests':
      return AppIconAssets.routineTestIcon;
    case 'Preventive & Wellness Checkups':
      return AppIconAssets.wellnessTestIcon;
    case 'Women, Pregnancy & Child Health':
      return AppIconAssets.womenTestIcon;
    case 'Diagnostics & Imaging':
      return AppIconAssets.imagingTestIcon;
    case 'Organ & System Health':
      return AppIconAssets.organTestIcon;
    case 'Infection, Cancer & Immunity':
      return AppIconAssets.infectionTestIcon;
    default:
      return AppIconAssets.routineTestIcon;
  }
}

Widget _categoryIcon(String cat, {double size = 20}) => LocalAssets(
      imagePath: _iconAssetForCategory(cat),
      height: size,
      width: size,
      imgColor: AppColors.grey7E,
    );

Widget _sheetGrabber() => Center(
      child: Container(
        width: 40,
        height: 4,
        margin:
            EdgeInsets.only(top: SizeConfig.size10, bottom: SizeConfig.size6),
        decoration: BoxDecoration(
          color: _line,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );

Widget _sheetHeader(BuildContext context, String title) {
  return Padding(
    padding: EdgeInsets.fromLTRB(SizeConfig.size20, SizeConfig.size6,
        SizeConfig.size14, SizeConfig.size10),
    child: Row(
      children: [
        Expanded(
          child: CustomText(
            title,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
        ),
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

// ─────────────────────────────────────────────────────────────────────────
//  Sheet 1 · category landing (img_1)
// ─────────────────────────────────────────────────────────────────────────

/// Categories overview shown when the user taps "Add Now" / "Add More".
/// Pops the tapped category name so the parent can chain the tests sheet.
class _AddTestCategoriesSheet extends StatelessWidget {
  final List<PathologyTest> allTests;
  const _AddTestCategoriesSheet({required this.allTests});

  Map<String, int> _categoryCounts() {
    final counts = <String, int>{};
    for (final t in allTests) {
      final cat = t.groupCategory ?? '';
      if (cat.isEmpty) continue;
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _categoryCounts();
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
            _sheetGrabber(),
            _sheetHeader(context, 'Add Tests'),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
                itemCount: LabTestController.groupCategoryList.length,
                itemBuilder: (_, i) {
                  final cat = LabTestController.groupCategoryList[i];
                  return _categoryRow(context, cat, counts[cat] ?? 0);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryRow(BuildContext context, String cat, int count) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(cat),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16,
          vertical: SizeConfig.size6,
        ),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xffDDE2EE), width: 1)),
          child: Row(
            children: [
              _categoryIcon(cat),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: CustomText(
                  cat,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (count > 0) ...[
                Container(
                  constraints: const BoxConstraints(minWidth: 26),
                  padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size8, vertical: SizeConfig.size4),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _accent,
                    ),
                  ),
                ),
                SizedBox(width: SizeConfig.size8),
              ],
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.secondaryTextColor),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Sheet 2 · category-tab test picker (img_2)
// ─────────────────────────────────────────────────────────────────────────

/// Test picker with horizontal category tabs, search, and checkbox rows.
/// Pops the updated id → [PathologyTest] map on "Add Selected Tests".
class _AddTestsInCategorySheet extends StatefulWidget {
  final List<PathologyTest> allTests;
  final String initialCategory;
  final Map<String, PathologyTest> initialSelected;

  const _AddTestsInCategorySheet({
    required this.allTests,
    required this.initialCategory,
    required this.initialSelected,
  });

  @override
  State<_AddTestsInCategorySheet> createState() =>
      _AddTestsInCategorySheetState();
}

class _AddTestsInCategorySheetState extends State<_AddTestsInCategorySheet> {
  late String _activeCategory = widget.initialCategory;
  late final Map<String, PathologyTest> _selected =
      Map<String, PathologyTest>.from(widget.initialSelected);
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PathologyTest> get _testsForCategory {
    final base = widget.allTests
        .where((t) => (t.groupCategory ?? '') == _activeCategory)
        .toList();
    if (_search.trim().isEmpty) return base;
    final q = _search.trim().toLowerCase();
    return base
        .where((t) => (t.testName ?? '').toLowerCase().contains(q))
        .toList();
  }

  int get _totalPrice =>
      _selected.values.fold<int>(0, (sum, t) => sum + (t.customerPrice ?? 0));

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
              _sheetGrabber(),
              _sheetHeader(context, 'Add Tests'),
              _categoryTabs(),
              SizedBox(height: SizeConfig.size10),
              _searchField(),
              const Divider(height: 1, thickness: 1, color: _line),
              Flexible(child: _testsList()),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryTabs() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
        itemCount: LabTestController.groupCategoryList.length,
        separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size8),
        itemBuilder: (_, i) {
          final cat = LabTestController.groupCategoryList[i];
          final on = cat == _activeCategory;
          return InkWell(
            onTap: () => setState(() => _activeCategory = cat),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size14, vertical: SizeConfig.size6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? _accent : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: on ? _accent : _line, width: 1),
              ),
              child: CustomText(
                cat,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: on ? Colors.white : AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        0,
        SizeConfig.size16,
        SizeConfig.size10,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'Search Anything…',
          hintStyle: TextStyle(
            color: AppColors.secondaryTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon:
              Icon(Icons.search_rounded, color: AppColors.secondaryTextColor),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic_none_rounded,
                  color: AppColors.secondaryTextColor, size: 20),
              SizedBox(width: SizeConfig.size10),
              Icon(Icons.camera_alt_outlined,
                  color: AppColors.secondaryTextColor, size: 20),
              SizedBox(width: SizeConfig.size12),
            ],
          ),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
          filled: true,
          fillColor: _surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accent, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _testsList() {
    final tests = _testsForCategory;
    if (tests.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(SizeConfig.size20),
        child: Center(
          child: CustomText(
            _search.isNotEmpty
                ? 'No matching tests.'
                : 'No tests in this category.',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16, vertical: SizeConfig.size10),
      itemCount: tests.length,
      separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size8),
      itemBuilder: (_, i) => _testCard(tests[i]),
    );
  }

  Widget _testCard(PathologyTest t) {
    final id = t.id ?? '';
    if (id.isEmpty) return const SizedBox.shrink();
    final on = _selected.containsKey(id);
    return InkWell(
      onTap: () => setState(() {
        if (on) {
          _selected.remove(id);
        } else {
          _selected[id] = t;
        }
      }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? _accent : _line, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                  ),
                  if ((t.description ?? '').trim().isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size4),
                    CustomText(
                      t.description!,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if ((t.customerPrice ?? 0) > 0) ...[
                    SizedBox(height: SizeConfig.size6),
                    CustomText(
                      '₹${t.customerPrice}',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                    ),
                  ],
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
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size10,
        SizeConfig.size16,
        SizeConfig.size12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CustomText(
                '$n ${n == 1 ? 'Test' : 'Tests'} Selected',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: n > 0 ? _accent : AppColors.secondaryTextColor,
              ),
              const Spacer(),
              if (_totalPrice > 0)
                CustomText(
                  'Est. Value: ₹$_totalPrice',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          GestureDetector(
            onTap: n == 0 ? null : () => Navigator.of(context).pop(_selected),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: n > 0
                    ? const LinearGradient(colors: [_accentDeep, _accent])
                    : null,
                color: n > 0 ? null : _line,
                borderRadius: BorderRadius.circular(14),
              ),
              child: CustomText(
                'Add Selected Tests',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: n > 0 ? Colors.white : AppColors.greyCA,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
