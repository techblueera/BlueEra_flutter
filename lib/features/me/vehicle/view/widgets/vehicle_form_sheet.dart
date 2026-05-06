import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Result returned from [VehicleFormSheet] when the user submits the
/// form. Held in a public class (vs. anonymous record) so the home
/// screen can declare `showModalBottomSheet<VehicleFormResult>` and
/// pass the captured local-file picks through to [VehicleController]
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

/// Add / edit form for a vehicle, presented as a draggable bottom
/// sheet. Pops with [VehicleFormResult] on submit, `null` on cancel.
///
/// When [initial] is null we render the "Add" copy and the picked
/// images are uploaded after the create call in the parent. When
/// [initial] is supplied we pre-populate every field; the parent
/// converts the patched draft back into a partial `toCreateJson` for
/// the PUT update.
class VehicleFormSheet extends StatefulWidget {
  final Vehicle? initial;

  const VehicleFormSheet({super.key, this.initial});

  @override
  State<VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

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
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _pincodeCtrl;
  late final TextEditingController _addressCtrl;

  String? _category;
  String? _subCategory;
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
    _cityCtrl = TextEditingController(text: v?.location?.city ?? '');
    _stateCtrl = TextEditingController(text: v?.location?.state ?? '');
    _pincodeCtrl =
        TextEditingController(text: v?.location?.pincode?.toString() ?? '');
    _addressCtrl = TextEditingController(text: v?.location?.address ?? '');
    _category = v?.category;
    _subCategory = v?.subCategory;
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
      _cityCtrl,
      _stateCtrl,
      _pincodeCtrl,
      _addressCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCover() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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
      subCategory: _subCategory,
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
      location: VehicleLocation(
        address:
            _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
        pincode: int.tryParse(_pincodeCtrl.text.trim()),
      ),
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
    final maxHeight = MediaQuery.of(context).size.height * 0.92;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size16,
                vertical: SizeConfig.size4,
              ),
              child: Row(
                children: [
                  CustomText(
                    _isEdit ? 'Edit vehicle' : 'Add vehicle',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  SizeConfig.size16,
                  SizeConfig.size12,
                  SizeConfig.size16,
                  SizeConfig.size16,
                ),
                child: Form(
                  key: _formKey,
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
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
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
                            items: const ['CAR', 'BIKE', 'TRUCK', 'BUS', 'OTHER'],
                            onChanged: (v) => setState(() => _category = v),
                          ),
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: _field(
                            controller: TextEditingController(text: _subCategory ?? ''),
                            label: 'Sub-category',
                            onChanged: (v) => _subCategory = v,
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
                      _field(
                        controller: _regCtrl,
                        label: 'Registration no.',
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
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: SizeConfig.size12),
                      _label('Location'),
                      _field(controller: _addressCtrl, label: 'Address'),
                      Row(children: [
                        Expanded(
                          child: _field(
                            controller: _cityCtrl,
                            label: 'City',
                          ),
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: _field(
                            controller: _stateCtrl,
                            label: 'State',
                          ),
                        ),
                      ]),
                      _field(
                        controller: _pincodeCtrl,
                        label: 'Pincode',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size16,
                SizeConfig.size10,
                SizeConfig.size16,
                SizeConfig.size16 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEDEFF4))),
              ),
              child: Row(
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
              ),
            ),
          ],
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
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
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
