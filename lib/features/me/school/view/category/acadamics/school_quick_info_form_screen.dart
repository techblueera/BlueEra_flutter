import 'package:BlueEra/core/api/model/school_quick_info_field.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_chip.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Category-agnostic Quick Info edit form. Iterates the field descriptors
/// loaded by [SchoolAboutUsController.fetchSchoolQuickInfo] and renders an
/// input per descriptor `type`:
///
///  * `stringArray` → dropdown-picker + chip list (multi-select). If the
///    descriptor has no suggestions, a plain "type + add" text field is used
///    instead so free text still works.
///  * `string`      → dropdown when suggestions exist, plain text field
///    otherwise.
///  * `number`      → numeric text field.
///
/// See lib/docs/SCHOOL_QUICK_INFO_UI_INTEGRATION.md.
class SchoolQuickInfoFormScreen extends StatefulWidget {
  const SchoolQuickInfoFormScreen({super.key});

  @override
  State<SchoolQuickInfoFormScreen> createState() =>
      _SchoolQuickInfoFormScreenState();
}

class _SchoolQuickInfoFormScreenState extends State<SchoolQuickInfoFormScreen> {
  final SchoolAboutUsController _controller =
      Get.find<SchoolAboutUsController>();

  // Editable value snapshot, keyed by field.key. Shape mirrors the payload
  // the backend expects: List<String> for stringArray, String for string,
  // int for number.
  final Map<String, dynamic> _values = <String, dynamic>{};

  // Snapshot of `_values` at hydration time. Used by [_buildPayload] to
  // compute a diff so the partial PUT only sends fields the user actually
  // touched — including sending `[]` when the user cleared a previously
  // populated list, which is how the API is documented to clear a field
  // (doc §7).
  final Map<String, dynamic> _initialValues = <String, dynamic>{};

  // TextEditingControllers for string/number inputs plus the free-text
  // adder used by stringArray fields.
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, TextEditingController> _adderControllers = {};

  @override
  void initState() {
    super.initState();
    _hydrateFromController();
    // Refetch to pick up the descriptor list + latest saved values. The
    // response drives which inputs render.
    _controller.fetchSchoolQuickInfo().then((_) {
      if (!mounted) return;
      _hydrateFromController();
    });
  }

  /// Snapshot the controller's saved values + descriptors into local
  /// editable state. Called on mount and again after the refetch completes.
  /// Also captures an [_initialValues] snapshot so [_buildPayload] can send
  /// only the fields the user actually modified.
  void _hydrateFromController() {
    setState(() {
      _values.clear();
      _initialValues.clear();
      for (final field in _controller.quickInfoFields) {
        final v = _controller.quickInfoValues[field.key];
        final coerced = _coerceForType(v, field.type);
        _values[field.key] = coerced;
        // Deep-copy list values so mutating `_values` later doesn't also
        // mutate the initial snapshot.
        _initialValues[field.key] =
            coerced is List ? List<String>.from(coerced) : coerced;
      }
      // Reset the text controllers so their editing state matches the newly
      // hydrated values.
      for (final field in _controller.quickInfoFields) {
        if (field.type == 'string' || field.type == 'number') {
          final ctl = _textControllers.putIfAbsent(
              field.key, TextEditingController.new);
          ctl.text = _values[field.key]?.toString() ?? '';
        }
        if (field.type == 'stringArray') {
          _adderControllers.putIfAbsent(field.key, TextEditingController.new);
        }
      }
    });
  }

  /// Coerce whatever the backend sent back into the shape the input expects.
  /// Guards against a saved `"CBSE"` string arriving where a list-field is
  /// expected, or a numeric `900` arriving as a JSON string.
  dynamic _coerceForType(dynamic v, String type) {
    switch (type) {
      case 'stringArray':
        if (v is List) return v.map((e) => e.toString()).toList();
        if (v is String && v.isNotEmpty) return <String>[v];
        return <String>[];
      case 'number':
        if (v is num) return v.toInt();
        if (v is String) return int.tryParse(v);
        return null;
      case 'string':
      default:
        return v?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    for (final c in _adderControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Build the payload for `PUT /schools/:id/quick-info`. Diffs the local
  /// state against [_initialValues] so we only send fields the user
  /// actually touched. Empty lists **are** sent when the field was
  /// previously populated — that's how the API clears a list (doc §7).
  Map<String, dynamic> _buildPayload() {
    final out = <String, dynamic>{};
    for (final field in _controller.quickInfoFields) {
      final current = _values[field.key];
      final initial = _initialValues[field.key];
      if (_isSameValue(current, initial)) continue;

      if (current is List) {
        // Send even empty lists here — they're a legitimate "clear" per
        // doc §7. Entries are trimmed and blanks dropped by the backend.
        out[_payloadKeyFor(field.key)] =
            current.map((e) => e.toString()).toList();
      } else if (current is String) {
        out[_payloadKeyFor(field.key)] = current.trim();
      } else if (current == null) {
        // Number cleared → let the backend default. Skipping is safer than
        // sending null, which the shape validator may reject.
        continue;
      } else {
        out[_payloadKeyFor(field.key)] = current;
      }
    }
    return out;
  }

  /// Deep-ish equality for the value shapes we handle. Lists compare
  /// element-wise; primitives compare by value.
  bool _isSameValue(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a == null && b == null) return true;
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (a[i]?.toString() != b[i]?.toString()) return false;
      }
      return true;
    }
    return a == b;
  }

  /// The API's list field for boards is stored under the singular key
  /// `board` even though the descriptor exposes it as `board` too, so the
  /// mapping is a no-op here — kept as a hook in case future fields
  /// diverge.
  String _payloadKeyFor(String descriptorKey) => descriptorKey;

  Future<void> _onSave() async {
    final payload = _buildPayload();
    if (payload.isEmpty) {
      Get.back();
      return;
    }
    final ok = await _controller.updateSchoolQuickInfoValues(payload);
    if (ok) Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: _controller.quickInfoCategory.value != null
            ? '${_controller.quickInfoCategory.value} Quick Info'
            : 'Quick Info',
        isShadowShow: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size12),
          child: SingleChildScrollView(
            child: Obx(() {
              final fields = _controller.quickInfoFields.toList();
              if (_controller.isQuickInfoLoading.value && fields.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (fields.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(SizeConfig.size24),
                  child: CustomText(
                    'No Quick Info fields available for this listing yet.',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return CommonCardWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < fields.length; i++) ...[
                      _buildFieldSection(fields[i]),
                      if (i != fields.length - 1)
                        SizedBox(height: SizeConfig.size24),
                    ],
                    SizedBox(height: SizeConfig.size24),
                    Obx(() {
                      final saving = _controller.isQuickInfoSaving.value;
                      return CustomBtn(
                        onTap: saving ? null : _onSave,
                        title: saving ? AppStrings.saving.tr : AppStrings.save,
                        isValidate: !saving,
                      );
                    }),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldSection(QuickInfoField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(field.label, fontSize: SizeConfig.small),
        SizedBox(height: SizeConfig.size8),
        _buildInputForField(field),
      ],
    );
  }

  Widget _buildInputForField(QuickInfoField field) {
    switch (field.type) {
      case 'stringArray':
        return _buildStringArrayInput(field);
      case 'number':
        return _buildNumberInput(field);
      case 'string':
      default:
        return _buildStringInput(field);
    }
  }

  Widget _buildStringArrayInput(QuickInfoField field) {
    final selected = (_values[field.key] as List?)?.cast<String>() ?? const [];
    final remaining =
        field.suggestions.where((s) => !selected.contains(s)).toList();

    // Per doc §4/§7: suggestions are *never* a closed set. The user must
    // always be able to type a custom value — even for fields like `board`
    // and `mediumOfInstruction` that ship a curated suggestion list.
    // Render the custom-text adder unconditionally; when there are still
    // unpicked suggestions, also expose the dropdown as a shortcut.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CustomAdderRow(
          controller: _adderControllers[field.key]!,
          placeholder:
              field.placeholder ?? 'Add ${field.label.toLowerCase()}',
          onAdd: (val) => _addToArray(field.key, val),
        ),
        if (remaining.isNotEmpty) ...[
          SizedBox(height: SizeConfig.size10),
          CommonDropdown<String>(
            items: remaining,
            selectedValue: null,
            hintText: 'Or pick from suggestions',
            displayValue: (v) => v,
            onChanged: (val) {
              if (val == null || val.trim().isEmpty) return;
              _addToArray(field.key, val.trim());
            },
          ),
        ],
        if (selected.isNotEmpty) ...[
          SizedBox(height: SizeConfig.size10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selected
                .map((v) => CommonChip(
                      label: v,
                      onDeleted: () => _removeFromArray(field.key, v),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildStringInput(QuickInfoField field) {
    // Per doc §8 example: `string` fields use a plain text input regardless
    // of whether the descriptor ships suggestions. When it does, we surface
    // the suggestions as tap-to-fill chips beneath the field so the user
    // still benefits from the curated list without being locked into it.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonTextField(
          textEditController: _textControllers[field.key]!,
          hintText: field.placeholder ?? 'e.g. ${field.label}',
          onChange: (val) => _values[field.key] = val,
        ),
        if (field.suggestions.isNotEmpty) ...[
          SizedBox(height: SizeConfig.size8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: field.suggestions
                .map((s) => InkWell(
                      onTap: () {
                        _textControllers[field.key]!.text = s;
                        setState(() => _values[field.key] = s);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: CustomText(s, fontSize: 12),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildNumberInput(QuickInfoField field) {
    return CommonTextField(
      textEditController: _textControllers[field.key]!,
      hintText: field.placeholder ?? 'e.g. 500',
      keyBoardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChange: (val) => _values[field.key] = int.tryParse(val),
    );
  }

  void _addToArray(String key, String value) {
    final list = (_values[key] as List?)?.cast<String>() ?? <String>[];
    if (list.contains(value)) return;
    setState(() {
      _values[key] = [...list, value];
    });
  }

  void _removeFromArray(String key, String value) {
    final list = (_values[key] as List?)?.cast<String>() ?? <String>[];
    setState(() {
      _values[key] = list.where((e) => e != value).toList();
    });
  }
}

/// Text field + "Add" button used for stringArray fields that ship no
/// suggestion list — lets the user grow the chip set freely.
class _CustomAdderRow extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onAdd;

  const _CustomAdderRow({
    required this.controller,
    required this.placeholder,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: CommonTextField(
            textEditController: controller,
            hintText: placeholder,
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        SizedBox(
          width: 88,
          child: CustomBtn(
            onTap: () {
              final v = controller.text.trim();
              if (v.isEmpty) return;
              onAdd(v);
              controller.clear();
            },
            title: AppStrings.add.tr,
            isValidate: true,
          ),
        ),
      ],
    );
  }
}
