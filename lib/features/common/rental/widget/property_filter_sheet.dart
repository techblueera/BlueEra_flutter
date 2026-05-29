import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/rental/controller/property_discover_controller.dart';
import 'package:BlueEra/features/common/rental/controller/property_filter_registry.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A 99acres-style filtering bottom sheet: a left sidebar listing the
/// available filter "sections" and a right pane showing the controls
/// for whichever section is selected. A bottom bar exposes
/// "Clear all" + "Apply".
///
/// Sections are derived from the live filter state so they stay in sync
/// with whatever the backend supports for the current category:
///   • Budget   — min / max price range (free-text)
///   • Locality — city free-text
///   • one section per [PropertyDiscoverController.visibleFilterDefs]
///     entry (BHK, Property Type, Posted By, Bathrooms, …)
///
/// Edits are kept in a local working copy and only pushed to the
/// controller when the user taps Apply, so a dismiss leaves the live
/// filters untouched.
class PropertyFilterSheet extends StatefulWidget {
  final PropertyDiscoverController controller;

  /// Section to open on first build. Matches a [_FilterSection.key]
  /// (`'budget'`, `'locality'`, or a [FilterId.name]). Falls back to
  /// the first section when null / unknown.
  final String? initialSectionKey;

  const PropertyFilterSheet({
    super.key,
    required this.controller,
    this.initialSectionKey,
  });

  @override
  State<PropertyFilterSheet> createState() => _PropertyFilterSheetState();
}

class _FilterSection {
  final String key;
  final String label;
  final FilterDef? def; // null for budget / locality

  const _FilterSection({required this.key, required this.label, this.def});
}

const Color _kRailBg = Color(0xFFF7F8FA);
const Color _kBorder = Color(0xFFDDE2EE);

class _PropertyFilterSheetState extends State<PropertyFilterSheet> {
  late final TextEditingController _cityCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late Map<FilterId, List<String>> _values;
  late List<_FilterSection> _sections;
  int _selected = 0;

  PropertyDiscoverController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _cityCtrl = TextEditingController(text: _ctrl.city.value);
    _minCtrl = TextEditingController(text: _ctrl.minPrice.value);
    _maxCtrl = TextEditingController(text: _ctrl.maxPrice.value);
    _values = Map<FilterId, List<String>>.from(_ctrl.currentFilterValues);
    _sections = _buildSections();

    if (widget.initialSectionKey != null) {
      final idx =
          _sections.indexWhere((s) => s.key == widget.initialSectionKey);
      if (idx >= 0) _selected = idx;
    }
  }

  List<_FilterSection> _buildSections() {
    return [
      const _FilterSection(key: 'budget', label: 'Budget'),
      const _FilterSection(key: 'locality', label: 'Locality'),
      for (final d in _ctrl.visibleFilterDefs)
        _FilterSection(key: d.id.name, label: d.label, def: d),
    ];
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  /// True when [section] currently holds a value (drives the little
  /// "active" dot next to its sidebar label).
  bool _sectionActive(_FilterSection s) {
    switch (s.key) {
      case 'budget':
        return _minCtrl.text.trim().isNotEmpty ||
            _maxCtrl.text.trim().isNotEmpty;
      case 'locality':
        return _cityCtrl.text.trim().isNotEmpty;
      default:
        return s.def != null && (_values[s.def!.id]?.isNotEmpty ?? false);
    }
  }

  /// Count of pending selections in the local working copy — drives the
  /// "Apply Filters (n)" badge. Mirrors
  /// [PropertyDiscoverController.activeFilterCount]: city + price each
  /// count once, every picked option counts individually.
  int get _pendingCount {
    int count = 0;
    if (_cityCtrl.text.trim().isNotEmpty) count++;
    if (_minCtrl.text.trim().isNotEmpty || _maxCtrl.text.trim().isNotEmpty) {
      count++;
    }
    for (final v in _values.values) {
      count += v.length;
    }
    return count;
  }

  void _clearAll() {
    setState(() {
      _cityCtrl.clear();
      _minCtrl.clear();
      _maxCtrl.clear();
      _values.clear();
    });
  }

  void _apply() {
    Get.back();
    _ctrl.applyAllFilters(
      cityVal: _cityCtrl.text.trim(),
      min: _minCtrl.text.trim(),
      max: _maxCtrl.text.trim(),
      filters: _values,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          const Divider(height: 1, color: _kBorder),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sidebar(),
                const VerticalDivider(width: 1, color: _kBorder),
                Expanded(child: _content()),
              ],
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _kBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CustomText(
                  'Filters',
                  fontSize: SizeConfig.large18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
              ),
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF4F6FA),
                    border: Border.all(color: _kBorder),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: Color(0xFF505050)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sidebar() {
    return Container(
      width: 128,
      color: _kRailBg,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _sections.length,
        itemBuilder: (_, i) {
          final s = _sections[i];
          final selected = i == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: selected ? Colors.white : _kRailBg,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Row(
                children: [
                  // Blue selection bar on the left edge of the active row.
                  Container(
                    width: 3,
                    height: 20,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: CustomText(
                      s.label,
                      fontSize: SizeConfig.small,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.mainTextColor
                          : AppColors.secondaryTextColor,
                      maxLines: 2,
                    ),
                  ),
                  if (_sectionActive(s))
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryColor,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _content() {
    final s = _sections[_selected];
    switch (s.key) {
      case 'budget':
        return _budgetContent();
      case 'locality':
        return _localityContent();
      default:
        return _optionsContent(s.def!);
    }
  }

  Widget _budgetContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      children: [
        CustomText(
          'Budget in ₹',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: RentalLabeledField(
                label: 'Min',
                hint: 'No min',
                controller: _minCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: CustomText(
                'to',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
            ),
            Expanded(
              child: RentalLabeledField(
                label: 'Max',
                hint: 'No max',
                controller: _maxCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _localityContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      children: [
        RentalLabeledField(
          label: 'City / Locality',
          hint: 'E.g. Mumbai, Delhi...',
          controller: _cityCtrl,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  /// Multi-select vertical option list for a registry [def] (99acres
  /// style — tap to toggle each option independently). A trailing
  /// "Select All" / "Clear All" row toggles the whole set at once.
  Widget _optionsContent(FilterDef def) {
    final selectedList = _values[def.id] ?? const <String>[];
    final allSelected = selectedList.length == def.options.length &&
        def.options.isNotEmpty;

    void toggle(String option) {
      setState(() {
        final list = List<String>.from(_values[def.id] ?? const <String>[]);
        if (list.contains(option)) {
          list.remove(option);
        } else {
          list.add(option);
        }
        if (list.isEmpty) {
          _values.remove(def.id);
        } else {
          _values[def.id] = list;
        }
      });
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: def.options.length + 1,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFF0F2F6), indent: 16),
      itemBuilder: (_, i) {
        // Last row → Select All / Clear All toggle.
        if (i == def.options.length) {
          return InkWell(
            onTap: () {
              setState(() {
                if (allSelected) {
                  _values.remove(def.id);
                } else {
                  _values[def.id] = List<String>.from(def.options);
                }
              });
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: CustomText(
                allSelected ? 'Clear All' : 'Select All',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
          );
        }

        final option = def.options[i];
        final selected = selectedList.contains(option);
        return InkWell(
          onTap: () => toggle(option),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                _checkBox(selected),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomText(
                    option,
                    fontSize: SizeConfig.medium,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.primaryColor
                        : AppColors.mainTextColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _checkBox(bool selected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: selected ? AppColors.primaryColor : _kBorder,
          width: 1.4,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _clearAll,
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryColor),
                  ),
                  child: CustomText(
                    'Clear all',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: RentalPrimaryButton(
                label: _pendingCount > 0
                    ? 'Apply Filters ($_pendingCount)'
                    : 'Apply Filters',
                onTap: _apply,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
