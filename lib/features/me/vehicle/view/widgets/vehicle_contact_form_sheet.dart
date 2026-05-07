import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


/// Add / edit form for a single [VehicleContact] (a "branch" /
/// contact entry on the Vehicle service). Presented as a full-screen
/// page so long forms scroll comfortably and the keyboard never
/// collapses the form on small devices — same pattern as
/// `VehicleFormSheet`. Pops with a [VehicleContact] on submit, `null`
/// on cancel; the caller then runs the controller's
/// [VehicleController.addContact] / [VehicleController.updateContact]
/// against the result.
class VehicleContactFormSheet extends StatefulWidget {
  final VehicleContact? initial;

  const VehicleContactFormSheet({super.key, this.initial});

  @override
  State<VehicleContactFormSheet> createState() =>
      _VehicleContactFormSheetState();
}

class _VehicleContactFormSheetState extends State<VehicleContactFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  late final TextEditingController _locationNameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _pincodeCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _altPhoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _mapLinkCtrl;
  bool _isPrimary = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _locationNameCtrl = TextEditingController(text: c?.locationName ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _cityCtrl = TextEditingController(text: c?.city ?? '');
    _stateCtrl = TextEditingController(text: c?.state ?? '');
    _countryCtrl = TextEditingController(text: c?.country ?? '');
    _pincodeCtrl =
        TextEditingController(text: c?.pincode?.toString() ?? '');
    _phoneCtrl =
        TextEditingController(text: c?.phoneNumber?.number ?? '');
    _altPhoneCtrl =
        TextEditingController(text: c?.alternatePhoneNumber?.number ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _websiteCtrl = TextEditingController(text: c?.website ?? '');
    _hoursCtrl = TextEditingController(text: c?.openingHours ?? '');
    _mapLinkCtrl = TextEditingController(text: c?.mapLink ?? '');
    _isPrimary = c?.isPrimary ?? false;
  }

  @override
  void dispose() {
    for (final c in [
      _locationNameCtrl,
      _addressCtrl,
      _cityCtrl,
      _stateCtrl,
      _countryCtrl,
      _pincodeCtrl,
      _phoneCtrl,
      _altPhoneCtrl,
      _emailCtrl,
      _websiteCtrl,
      _hoursCtrl,
      _mapLinkCtrl,
    ]) {
      c.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Validators ───────────────────────────────────────────────────
  String? _vLocation(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Location name is required' : null;

  String? _vEmail(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }

  String? _vPhone(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final digits = v.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6 || digits.length > 15) {
      return 'Enter a valid phone';
    }
    return null;
  }

  String? _vPincode(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (!RegExp(r'^\d{4,8}$').hasMatch(v.trim())) {
      return 'Enter a valid pincode';
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    String? trimOrNull(String s) => s.trim().isEmpty ? null : s.trim();

    final phone = trimOrNull(_phoneCtrl.text);
    final altPhone = trimOrNull(_altPhoneCtrl.text);

    final patched = VehicleContact(
      id: widget.initial?.id,
      userId: widget.initial?.userId,
      businessId: widget.initial?.businessId,
      locationName: _locationNameCtrl.text.trim(),
      address: trimOrNull(_addressCtrl.text),
      city: trimOrNull(_cityCtrl.text),
      state: trimOrNull(_stateCtrl.text),
      country: trimOrNull(_countryCtrl.text),
      pincode: int.tryParse(_pincodeCtrl.text.trim()),
      lat: widget.initial?.lat,
      lon: widget.initial?.lon,
      phoneNumber: phone == null
          ? null
          : VehiclePhoneNumber(
              // Default Indian dial code; the form doesn't expose a
              // country-code picker yet — easy to wire later without
              // reshaping the model.
              pre: widget.initial?.phoneNumber?.pre ?? 91,
              number: phone,
            ),
      alternatePhoneNumber: altPhone == null
          ? null
          : VehiclePhoneNumber(
              pre: widget.initial?.alternatePhoneNumber?.pre ?? 91,
              number: altPhone,
            ),
      email: trimOrNull(_emailCtrl.text),
      website: trimOrNull(_websiteCtrl.text),
      openingHours: trimOrNull(_hoursCtrl.text),
      mapLink: trimOrNull(_mapLinkCtrl.text),
      isPrimary: _isPrimary,
      isActive: widget.initial?.isActive ?? true,
    );
    Navigator.pop(context, patched);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxContentWidth = media.size.width >= 720 ? 640.0 : double.infinity;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: AppColors.mainTextColor),
        title: CustomText(
          _isEdit ? 'Edit contact' : 'Add contact',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Scrollbar(
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
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Location'),
                      _field(
                        controller: _locationNameCtrl,
                        label: 'Location name *',
                        validator: _vLocation,
                      ),
                      _field(
                        controller: _addressCtrl,
                        label: 'Address',
                        maxLines: 2,
                      ),
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
                      Row(children: [
                        Expanded(
                          child: _field(
                            controller: _countryCtrl,
                            label: 'Country',
                          ),
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: _field(
                            controller: _pincodeCtrl,
                            label: 'Pincode',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(8),
                            ],
                            validator: _vPincode,
                          ),
                        ),
                      ]),
                      _field(
                        controller: _mapLinkCtrl,
                        label: 'Map link (optional)',
                        keyboardType: TextInputType.url,
                      ),
                      SizedBox(height: SizeConfig.size12),
                      _label('Reach us'),
                      _field(
                        controller: _phoneCtrl,
                        label: 'Phone',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+\-\s()]')),
                          LengthLimitingTextInputFormatter(20),
                        ],
                        validator: _vPhone,
                      ),
                      _field(
                        controller: _altPhoneCtrl,
                        label: 'Alternate phone',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+\-\s()]')),
                          LengthLimitingTextInputFormatter(20),
                        ],
                        validator: _vPhone,
                      ),
                      _field(
                        controller: _emailCtrl,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: _vEmail,
                      ),
                      _field(
                        controller: _websiteCtrl,
                        label: 'Website',
                        keyboardType: TextInputType.url,
                      ),
                      _field(
                        controller: _hoursCtrl,
                        label: 'Opening hours (e.g. Mon–Sat · 9–7)',
                      ),
                      SizedBox(height: SizeConfig.size8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _isPrimary,
                        onChanged: (v) => setState(() => _isPrimary = v),
                        title: CustomText(
                          'Primary contact',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                        ),
                        subtitle: CustomText(
                          'Shown first on your public profile.',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                      SizedBox(height: SizeConfig.size20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isEdit ? 'Save changes' : 'Add contact',
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
          ),
        ),
      ),
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        inputFormatters: inputFormatters,
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
