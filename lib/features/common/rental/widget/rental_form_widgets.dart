import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/rental/controller/property_controller.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared form-building primitives for the "List Your Property"
/// (For Sale: Houses & Apartments) static create flow. Used across
/// all three steps so the visual language stays identical without
/// duplicating field decoration / counter logic.

const Color _kFieldFill = Color(0xFFF4F6FA);
const Color _kFieldBorder = Color(0xFFDDE2EE);

/// The six top-level "Rent & Properties" categories that the v2
/// dashboard's chip strip + bottom-sheet grid expose. The screens use
/// this to parameterize the header card and to decide which step-2
/// form to push.
enum RentalCategory {
  housesSale,
  housesRent,
  newProjectsSale,
  landsPlotsSale,
  shopsOfficesRent,
  shopsOfficesSale;

  String get headerSubtitle {
    switch (this) {
      case RentalCategory.housesSale:
        return 'For Sale: Houses & Apartments';
      case RentalCategory.housesRent:
        return 'For Rent: Houses & Apartments';
      case RentalCategory.newProjectsSale:
        return 'For Sale: New Projects & Properties';
      case RentalCategory.landsPlotsSale:
        return 'Lands & Plots For Sale';
      case RentalCategory.shopsOfficesRent:
        return 'For Rent: Shops & Offices';
      case RentalCategory.shopsOfficesSale:
        return 'For Sale: Shops & Offices';
    }
  }

  String get headerImage {
    switch (this) {
      case RentalCategory.housesSale:
        return AppImageAssets.propertyHouseSell;
      case RentalCategory.housesRent:
        return AppImageAssets.propertyHouseRent;
      case RentalCategory.newProjectsSale:
        return AppImageAssets.propertyNewProjectSell;
      case RentalCategory.landsPlotsSale:
        return AppImageAssets.propertyLandPlotSell;
      case RentalCategory.shopsOfficesRent:
        return AppImageAssets.propertyShopOfficeRent;
      case RentalCategory.shopsOfficesSale:
        return AppImageAssets.propertyShopOfficeSell;
    }
  }

  String get chipLabel {
    switch (this) {
      case RentalCategory.housesSale:
        return 'Houses Sale';
      case RentalCategory.housesRent:
        return 'Houses Rent';
      case RentalCategory.newProjectsSale:
        return 'New Projects';
      case RentalCategory.landsPlotsSale:
        return 'Lands & Plots';
      case RentalCategory.shopsOfficesRent:
        return 'Shops Rent';
      case RentalCategory.shopsOfficesSale:
        return 'Shops Sale';
    }
  }

  bool get isSale =>
      this == RentalCategory.housesSale ||
      this == RentalCategory.newProjectsSale ||
      this == RentalCategory.landsPlotsSale ||
      this == RentalCategory.shopsOfficesSale;

  /// Step-1 appbar title. Lands / shops get category-specific
  /// phrasings to match the designs; the rest fall back to the
  /// generic "List Your Property" title.
  String get listYourTitle {
    switch (this) {
      case RentalCategory.landsPlotsSale:
        return 'List Your Land & Plots';
      case RentalCategory.shopsOfficesRent:
      case RentalCategory.shopsOfficesSale:
        return 'List Your Shops & Offices';
      case RentalCategory.housesSale:
      case RentalCategory.housesRent:
      case RentalCategory.newProjectsSale:
        return 'List Your Property';
    }
  }

  /// Step-2 appbar title.
  String get specificationsTitle {
    switch (this) {
      case RentalCategory.landsPlotsSale:
        return 'Land & Plots Specifications';
      case RentalCategory.shopsOfficesRent:
      case RentalCategory.shopsOfficesSale:
        return 'Shops & Offices Specifications';
      case RentalCategory.housesSale:
      case RentalCategory.housesRent:
      case RentalCategory.newProjectsSale:
        return 'Property Specifications';
    }
  }
}

/// Step progress bar — blue fill that animates to [progress] (0.0–1.0).
/// Sits below the app bar on every rental flow screen.
class RentalStepProgressBar extends StatelessWidget {
  final double progress;

  const RentalStepProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      color: const Color(0xFFDDE2EE),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// White container wrapping the bottom "Next" / "Post Now" button.
class RentalBottomBar extends StatelessWidget {
  final Widget child;

  const RentalBottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      ),
    );
  }
}

/// Location picker field with inline Google Places autocomplete and
/// "Direct My Location" button. Syncs to [PropertyController].
class RentalLocationField extends StatefulWidget {
  const RentalLocationField({super.key});

  @override
  State<RentalLocationField> createState() => _RentalLocationFieldState();
}

class _RentalLocationFieldState extends State<RentalLocationField> {
  late final PropertyController _ctrl;
  final _locationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<PropertyController>();
    if (_ctrl.locationAddress.value.isNotEmpty) {
      _locationCtrl.text = _ctrl.locationAddress.value;
    }
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonLocationSearchField(
          controller: _locationCtrl,
          title: 'Where Is Your Property Located',
          hintText: 'E.g. Gomti Nagar, Lucknow...',
          isShowLeading: false,
          onSelected: (placeId, lat, lng, address) {
            _locationCtrl.text = address;
            _ctrl.locationAddress.value = address;
            _ctrl.locationLat.value = lat;
            _ctrl.locationLng.value = lng;
          },
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _useCurrentLocation,
          child: Row(
            children: [
              CustomText(
                'Direct My Location',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.my_location,
                size: 14,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _useCurrentLocation() async {
    await LocationService.fetchLocation();
    _ctrl.locationLat.value = LocationService.lat;
    _ctrl.locationLng.value = LocationService.lng;
    final addr = LocationService.userCurrentAddress.value;
    final parts = [addr.street, addr.city, addr.state]
        .where((e) => e.isNotEmpty)
        .toList();
    final address = parts.isNotEmpty ? parts.join(', ') : 'Current Location';
    _ctrl.locationAddress.value = address;
    _locationCtrl.text = address;
  }
}

/// White rounded-corner card used as the form container on each step.
class RentalFormCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const RentalFormCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// Top-of-page category strip — house illustration + two-line title
/// + chevron. Visual is informational only; the chevron is decorative
/// because the category is fixed for this static flow.
class RentalCategoryHeader extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;

  RentalCategoryHeader({
    super.key,
    String? image,
    this.title = 'Rent & Properties',
    this.subtitle = 'For Sale: Houses & Apartments',
  }) : image = image ?? AppImageAssets.propertyHouseSell;

  /// Convenience constructor that derives the header image + subtitle
  /// from a [RentalCategory]. Used when the screen is launched from
  /// the v2 dashboard's bottom sheet so the header always matches the
  /// tile the user tapped.
  RentalCategoryHeader.forCategory(RentalCategory category, {Key? key})
      : this(
          key: key,
          image: category.headerImage,
          subtitle: category.headerSubtitle,
        );

  @override
  Widget build(BuildContext context) {
    return RentalFormCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: LocalAssets(imagePath: image, boxFix: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  subtitle,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: AppColors.mainTextColor),
        ],
      ),
    );
  }
}

/// Shared "Lister Name" input used on every step-2 specification
/// screen. Binds directly to [PropertyController.listedByName] so
/// each screen can drop in `const RentalListedByNameField()` without
/// threading state through. Validator is required + non-empty.
class RentalListedByNameField extends StatelessWidget {
  const RentalListedByNameField({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PropertyController>();
    return RentalLabeledField(
      label: 'Lister Name',
      hint: 'Enter your name',
      textInputAction: TextInputAction.next,
      onChanged: (v) => ctrl.listedByName.value = v,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Please enter your name';
        return null;
      },
    );
  }
}

/// Labeled text field with an optional character counter rendered
/// underneath on the right (matches the "0/70" / "0/2000" hint in
/// the mockup). Owns its own controller so callers don't need to
/// thread one in — this is a static flow with no submission.
class RentalLabeledField extends StatefulWidget {
  final String label;
  final String hint;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  const RentalLabeledField({
    super.key,
    required this.label,
    required this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.controller,
    this.onChanged,
    this.validator,
    this.textInputAction,
  });

  @override
  State<RentalLabeledField> createState() => _RentalLabeledFieldState();
}

class _RentalLabeledFieldState extends State<RentalLabeledField> {
  late final TextEditingController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
    if (widget.maxLength != null) {
      _controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          CustomText(
            widget.label,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: _controller,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          validator: widget.validator,
          buildCounter:
              (_, {required currentLength, required isFocused, maxLength}) =>
                  null,
          decoration: _fieldDecoration(widget.hint),
        ),
        if (widget.maxLength != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: CustomText(
              '${_controller.text.length}/${widget.maxLength}',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ],
    );
  }
}

/// Labeled dropdown — selection is local only (visual feedback).
class RentalLabeledDropdown extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> items;

  const RentalLabeledDropdown({
    super.key,
    required this.label,
    required this.hint,
    this.items = const ['Option 1', 'Option 2', 'Option 3'],
  });

  @override
  State<RentalLabeledDropdown> createState() => _RentalLabeledDropdownState();
}

class _RentalLabeledDropdownState extends State<RentalLabeledDropdown> {
  String? _value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          widget.label,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _value,
          isExpanded: true,
          // DropdownButtonFormField doesn't reliably surface the
          // decoration's hintText when no value is picked yet, so give
          // it an explicit hint widget — that's what renders as the
          // placeholder until the user selects an item.
          hint: Text(
            widget.hint,
            style: TextStyle(
              color: AppColors.secondaryTextColor.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          icon:
              Icon(Icons.keyboard_arrow_down, color: AppColors.mainTextColor),
          items: widget.items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _value = v),
          decoration: _fieldDecoration(widget.hint),
        ),
      ],
    );
  }
}

InputDecoration _fieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: AppColors.secondaryTextColor.withValues(alpha: 0.75),
      fontWeight: FontWeight.w500,
      fontSize: 14,
    ),
    filled: true,
    fillColor: _kFieldFill,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _kFieldBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _kFieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.5)),
    ),
  );
}

/// Labeled wrap-chip selector — renders a bold label, then a [Wrap]
/// of rounded pill chips. Tapping a chip selects it (single-select).
class RentalChipSelector extends StatefulWidget {
  final String label;
  final List<String> options;
  final int initialIndex;
  final ValueChanged<int>? onChanged;

  const RentalChipSelector({
    super.key,
    required this.label,
    required this.options,
    this.initialIndex = 0,
    this.onChanged,
  });

  @override
  State<RentalChipSelector> createState() => _RentalChipSelectorState();
}

class _RentalChipSelectorState extends State<RentalChipSelector> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          widget.label,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(widget.options.length, (i) {
            final selected = i == _selected;
            return GestureDetector(
              onTap: () {
                setState(() => _selected = i);
                widget.onChanged?.call(i);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryColor.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.primaryColor
                        : _kFieldBorder,
                    width: selected ? 1.4 : 1,
                  ),
                ),
                child: CustomText(
                  widget.options[i],
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? AppColors.primaryColor
                      : AppColors.secondaryTextColor,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Labeled text field with an inline suffix widget (e.g. a unit
/// dropdown like "sq.ft."). Used for area fields on step 2.
class RentalFieldWithSuffix extends StatefulWidget {
  final String label;
  final String hint;
  final Widget suffix;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const RentalFieldWithSuffix({
    super.key,
    required this.label,
    required this.hint,
    required this.suffix,
    this.keyboardType,
    this.onChanged,
  });

  @override
  State<RentalFieldWithSuffix> createState() => _RentalFieldWithSuffixState();
}

class _RentalFieldWithSuffixState extends State<RentalFieldWithSuffix> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          CustomText(
            widget.label,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _controller,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: AppColors.secondaryTextColor.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            filled: true,
            fillColor: _kFieldFill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: widget.suffix,
            ),
            suffixIconConstraints:
                const BoxConstraints(minHeight: 0, minWidth: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kFieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kFieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: AppColors.primaryColor.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Area text field with a unit dropdown (sq.ft., sq.m., sq.yd., acres).
/// Syncs value and unit to [PropertyController].
class RentalAreaField extends StatefulWidget {
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;
  // Optional validator wired into the underlying TextFormField so this
  // field participates in the same Form().validate() flow every other
  // screen uses, instead of relying on controller-side string checks.
  final String? Function(String?)? validator;

  const RentalAreaField({
    super.key,
    this.label = 'Add Area Details',
    this.hint = 'E.g. 4060',
    this.onChanged,
    this.validator,
  });

  @override
  State<RentalAreaField> createState() => _RentalAreaFieldState();
}

class _RentalAreaFieldState extends State<RentalAreaField> {
  late final PropertyController _ctrl;
  final _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<PropertyController>();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          widget.label,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        const SizedBox(height: 8),
        // Field + unit selector are siblings now (was nested as a
        // `suffixIcon` before). 8-px gap between them; the dropdown
        // sits centered to the field's natural height.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextFormField(
                controller: _textCtrl,
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  widget.onChanged?.call(v);
                },
                validator: widget.validator,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                    color:
                        AppColors.secondaryTextColor.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: _kFieldFill,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kFieldBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kFieldBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color:
                            AppColors.primaryColor.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _unitDropdown(),
          ],
        ),
      ],
    );
  }

  /// Inline popup-menu dropdown styled as a pill that matches the
  /// area field's chrome. Replaces the old "tap → bottom sheet" flow
  /// — tapping now anchors a small Material popup right under the
  /// pill so the user picks a unit without losing context.
  Widget _unitDropdown() {
    return Obx(() {
      final currentUnit = _ctrl.areaUnit.value;
      return PopupMenuButton<String>(
        initialValue: currentUnit,
        tooltip: 'Select unit',
        onSelected: (val) => _ctrl.areaUnit.value = val,
        color: Colors.white,
        elevation: 8,
        offset: const Offset(0, 8),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _kFieldBorder),
        ),
        itemBuilder: (_) =>
            PropertyController.areaUnitOptions.map((unit) {
          final selected = unit == currentUnit;
          return PopupMenuItem<String>(
            value: unit,
            height: 40,
            child: Row(
              children: [
                CustomText(
                  unit,
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.primaryColor
                      : AppColors.mainTextColor,
                ),
                if (selected) ...[
                  const Spacer(),
                  Icon(Icons.check_rounded,
                      size: 16, color: AppColors.primaryColor),
                ],
              ],
            ),
          );
        }).toList(),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _kFieldFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kFieldBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                currentUnit,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Full-width primary blue CTA used at the bottom of each step.
class RentalPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const RentalPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withValues(alpha: 0.18),
        highlightColor: Colors.white.withValues(alpha: 0.08),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isLoading
                ? AppColors.primaryColor.withValues(alpha: 0.7)
                : AppColors.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: isLoading
              ? staggeredDotsWaveLoading(
                  color: Colors.white,
                  padding: EdgeInsets.zero,
                )
              : CustomText(
            label,
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Dashed rounded-rectangle border painter — used by the photo upload
/// tiles on step 3. Self-contained so this file is the only place
/// dashed-stroke geometry needs to be edited.
class DashedRRectBorder extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  DashedRRectBorder({
    required this.color,
    this.radius = 12,
    this.dashWidth = 6,
    this.dashSpace = 4,
    this.strokeWidth = 1.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRRectBorder old) =>
      old.color != color ||
      old.radius != radius ||
      old.dashWidth != dashWidth ||
      old.dashSpace != dashSpace ||
      old.strokeWidth != strokeWidth;
}
