import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Result returned from [VehicleFormSheet] when the user submits the
/// form. Held in a public class (vs. anonymous record) so the caller
/// can declare `Navigator.push<VehicleFormResult>` and pass the
/// captured local-file picks through to [VehicleController]
/// for the two-step S3 upload.
class VehicleFormResult {
  final Vehicle draft;
  final File? coverFile;
  final List<File> imageFiles;

  const VehicleFormResult({
    required this.draft,
    this.coverFile,
    this.imageFiles = const [],
  });
}

/// Add / edit form for a vehicle, presented as a full-screen page.
/// Pops with [VehicleFormResult] on submit, `null` on cancel.
///
/// Earlier this widget rendered as a draggable bottom sheet — it's now
/// a Scaffold-based screen so long forms scroll comfortably on small
/// devices, the keyboard never collapses the form, and there's room
/// for per-field validation messages. The class name is kept
/// (`VehicleFormSheet`) so existing imports continue to compile.
class VehicleFormSheet extends StatefulWidget {
  final Vehicle? initial;

  const VehicleFormSheet({super.key, this.initial});

  @override
  State<VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _scrollController = ScrollController();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _regCtrl;
  late final TextEditingController _seatsCtrl;
  late final TextEditingController _mileageCtrl;
  late final TextEditingController _priceCtrl;
  // Stable controller for sub-category — the previous version recreated
  // a TextEditingController on every build, which silently lost the
  // user's cursor position whenever any other field caused a setState.
  late final TextEditingController _subCategoryCtrl;

  String? _category;
  VehicleFuelType? _fuel;
  VehicleTransmission? _transmission;

  File? _coverFile;
  final List<File> _imageFiles = [];

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final v = widget.initial;
    _nameCtrl = TextEditingController(text: v?.name ?? '');
    _descCtrl = TextEditingController(text: v?.description ?? '');
    _brandCtrl = TextEditingController(text: v?.brand ?? '');
    _modelCtrl = TextEditingController(text: v?.model ?? '');
    _yearCtrl = TextEditingController(text: v?.year?.toString() ?? '');
    _colorCtrl = TextEditingController(text: v?.color ?? '');
    _regCtrl = TextEditingController(text: v?.registrationNo ?? '');
    _seatsCtrl =
        TextEditingController(text: v?.seatingCapacity?.toString() ?? '');
    _mileageCtrl = TextEditingController(text: v?.mileage ?? '');
    _priceCtrl =
        TextEditingController(text: v?.price?.toStringAsFixed(0) ?? '');
    _subCategoryCtrl = TextEditingController(text: v?.subCategory ?? '');
    _category = v?.category;
    _fuel = v?.fuelType;
    _transmission = v?.transmission;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _descCtrl,
      _brandCtrl,
      _modelCtrl,
      _yearCtrl,
      _colorCtrl,
      _regCtrl,
      _seatsCtrl,
      _mileageCtrl,
      _priceCtrl,
      _subCategoryCtrl,
    ]) {
      c.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Validators ───────────────────────────────────────────────────
  // All non-required fields short-circuit to `null` when empty so the
  // user is never forced to fill optional inputs.

  String? _vName(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Name is required' : null;

  String? _vYear(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    final maxYear = DateTime.now().year + 1;
    if (n == null) return 'Enter a valid year';
    if (n < 1900 || n > maxYear) return 'Year must be 1900–$maxYear';
    return null;
  }

  String? _vSeats(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    if (n == null || n <= 0 || n > 100) return 'Enter 1–100';
    return null;
  }

  String? _vPrice(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = double.tryParse(v.trim());
    if (n == null || n < 0) return 'Enter a valid price';
    return null;
  }

  Future<void> _pickCover() async {
    final x =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) {
      setState(() => _coverFile = File(x.path));
    }
  }

  Future<void> _pickImages() async {
    final list = await _picker.pickMultiImage(imageQuality: 80);
    if (list.isNotEmpty) {
      setState(() => _imageFiles.addAll(list.map((x) => File(x.path))));
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final draft = Vehicle(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      category: _category,
      subCategory: _subCategoryCtrl.text.trim().isEmpty
          ? null
          : _subCategoryCtrl.text.trim(),
      brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
      model: _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
      year: int.tryParse(_yearCtrl.text.trim()),
      color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
      registrationNo:
          _regCtrl.text.trim().isEmpty ? null : _regCtrl.text.trim(),
      fuelType: _fuel,
      transmission: _transmission,
      seatingCapacity: int.tryParse(_seatsCtrl.text.trim()),
      mileage:
          _mileageCtrl.text.trim().isEmpty ? null : _mileageCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text.trim()),
      currency: 'INR',
      // Location section removed from the form intentionally —
      // `toCreateJson()` is `if (location != null) ...` so passing
      // null here means the partial PUT for an existing vehicle
      // keeps any prior city / state / pincode the server holds.
      location: null,
      coverImage: widget.initial?.coverImage,
      images: widget.initial?.images ?? const [],
    );
    Navigator.pop(
      context,
      VehicleFormResult(
        draft: draft,
        coverFile: _coverFile,
        imageFiles: List.unmodifiable(_imageFiles),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Tablets / landscape phones get the form capped at 640 dp wide
    // and centered. Phones fall through to the natural full width —
    // wrapping with `Center` + `ConstrainedBox(maxWidth: ∞)` was
    // pushing unbounded horizontal constraints into the form's
    // `SingleChildScrollView`, and the inner `Row + Expanded` rows
    // need a finite width to allocate flex space, so the form was
    // failing to lay out correctly on phones.
    final isWide = media.size.width >= 720;

    final body = Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size16,
          SizeConfig.size12,
          SizeConfig.size16,
          SizeConfig.size16,
        ),
        child: Form(
                  key: _formKey,
                  // onUserInteraction so the user sees the validation
                  // message inline as they type (after the first attempt)
                  // rather than only after pressing the submit button.
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _coverPickerTile(),
                      SizedBox(height: SizeConfig.size12),
                      _imagesPickerTile(),
                      SizedBox(height: SizeConfig.size16),
                      _label('Basics'),
                      _field(
                        controller: _nameCtrl,
                        label: 'Name *',
                        validator: _vName,
                        textInputAction: TextInputAction.next,
                      ),
                      _field(
                        controller: _descCtrl,
                        label: 'Description',
                        maxLines: 3,
                      ),
                      Row(children: [
                        Expanded(
                          child: _dropdown<String>(
                            label: 'Category',
                            value: _category,
                            items: const [
                              'CAR',
                              'BIKE',
                              'TRUCK',
                              'BUS',
                              'OTHER'
                            ],
                            onChanged: (v) => setState(() => _category = v),
                          ),
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: _field(
                            controller: _subCategoryCtrl,
                            label: 'Sub-category',
                          ),
                        ),
                      ]),
                      Row(children: [
                        Expanded(
                          child: _field(
                            controller: _brandCtrl,
                            label: 'Brand',
                          ),
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: _field(
                            controller: _modelCtrl,
                            label: 'Model',
                          ),
                        ),
                      ]),
                      Row(children: [
                        Expanded(
                          child: _field(
                            controller: _yearCtrl,
                            label: 'Year',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            validator: _vYear,
                          ),
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: _field(
                            controller: _colorCtrl,
                            label: 'Color',
                          ),
                        ),
                      ]),
                      // Registration no. — explicitly NOT mandatory.
                      // Auto-upper-cased so RC numbers display
                      // consistently in lists ("MH02AB1234").
                      _field(
                        controller: _regCtrl,
                        label: 'Registration no. (optional)',
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(20),
                          _UpperCaseFormatter(),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size12),
                      _label('Specs'),
                      Row(children: [
                        Expanded(
                          child: _dropdown<VehicleFuelType>(
                            label: 'Fuel',
                            value: _fuel,
                            items: VehicleFuelType.values,
                            onChanged: (v) => setState(() => _fuel = v),
                            itemLabel: (e) =>
                                e.toString().split('.').last.toUpperCase(),
                          ),
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: _dropdown<VehicleTransmission>(
                            label: 'Transmission',
                            value: _transmission,
                            items: VehicleTransmission.values,
                            onChanged: (v) =>
                                setState(() => _transmission = v),
                            itemLabel: (e) =>
                                e.toString().split('.').last.toUpperCase(),
                          ),
                        ),
                      ]),
                      Row(children: [
                        Expanded(
                          child: _field(
                            controller: _seatsCtrl,
                            label: 'Seats',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            validator: _vSeats,
                          ),
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: _field(
                            controller: _mileageCtrl,
                            label: 'Mileage',
                          ),
                        ),
                      ]),
                      _field(
                        controller: _priceCtrl,
                        label: 'Price (INR)',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          // Up to 2 decimal places — matches
                          // `price.toStringAsFixed(0)` echo on edit.
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        validator: _vPrice,
                      ),
                      SizedBox(height: SizeConfig.size20),
                    ],
                  ),
                ),
              ),
            );

    final actionBar = Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: CustomText(
              'Cancel',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ),
        SizedBox(width: SizeConfig.size12),
        Expanded(
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              _isEdit ? 'Save changes' : 'Create vehicle',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );

    // Helper that wraps `child` in a topCenter Align + ConstrainedBox
    // only on wide layouts, so phones never end up with unbounded
    // horizontal constraints reaching the form/action-bar.
    Widget capWidth(Widget child) => isWide
        ? Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: child,
            ),
          )
        : child;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: AppColors.mainTextColor),
        title: CustomText(
          _isEdit ? 'Edit vehicle' : 'Add vehicle',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
        ),
      ),
      body: SafeArea(child: capWidth(body)),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size16,
            SizeConfig.size10,
            SizeConfig.size16,
            SizeConfig.size16,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEDEFF4))),
          ),
          child: capWidth(actionBar),
        ),
      ),
    );
  }

  Widget _coverPickerTile() {
    final hasLocal = _coverFile != null;
    final remoteUrl = widget.initial?.coverImage;
    return GestureDetector(
      onTap: _pickCover,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasLocal)
              Image.file(_coverFile!, fit: BoxFit.cover)
            else if (remoteUrl != null && remoteUrl.isNotEmpty)
              Image.network(remoteUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _coverHint())
            else
              _coverHint(),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt_rounded,
                        size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Cover photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverHint() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_a_photo_rounded,
              size: 28, color: AppColors.primaryColor),
          SizedBox(height: SizeConfig.size4),
          CustomText(
            'Tap to add cover',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _imagesPickerTile() {
    final remoteImages = widget.initial?.images ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomText(
              'Gallery images',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickImages,
              icon: Icon(Icons.add_photo_alternate_rounded,
                  size: 18, color: AppColors.primaryColor),
              label: CustomText(
                'Add photos',
                color: AppColors.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size6),
        if (remoteImages.isEmpty && _imageFiles.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomText(
              'No photos picked yet',
              textAlign: TextAlign.center,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
            ),
          )
        else
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size8),
              itemCount: remoteImages.length + _imageFiles.length,
              itemBuilder: (_, i) {
                final isRemote = i < remoteImages.length;
                final widget = isRemote
                    ? Image.network(remoteImages[i], fit: BoxFit.cover)
                    : Image.file(_imageFiles[i - remoteImages.length],
                        fit: BoxFit.cover);
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                          width: 80, height: 80, child: widget),
                    ),
                    if (!isRemote)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: GestureDetector(
                          onTap: () => setState(() =>
                              _imageFiles.removeAt(i - remoteImages.length)),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
        child: CustomText(
          text,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryColor,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T)? itemLabel,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items
            .map((e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(itemLabel?.call(e) ?? e.toString()),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

/// Inline TextInputFormatter that upper-cases incoming text. Used for
/// the registration number so the captured value matches the typical
/// Indian RC display format ("MH02AB1234") regardless of how the user
/// typed it. Kept private to this file because it has no other caller.
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text == newValue.text.toUpperCase()) return newValue;
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
