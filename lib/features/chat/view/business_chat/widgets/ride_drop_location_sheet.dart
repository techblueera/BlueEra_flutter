import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';

import 'package:BlueEra/core/api/model/place_prediction.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/features/chat/auth/controller/saved_address_controller.dart';
import 'package:BlueEra/features/chat/auth/model/saved_address_model.dart';

/// Opens the ride drop-location bottom sheet. Returns the chosen
/// [SavedAddress] (via the sheet's Confirm action) or null if dismissed.
Future<SavedAddress?> showRideDropLocationSheet(BuildContext context) {
  return showModalBottomSheet<SavedAddress>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RideDropLocationSheet(),
  );
}

class _RideDropLocationSheet extends StatefulWidget {
  const _RideDropLocationSheet();

  @override
  State<_RideDropLocationSheet> createState() => _RideDropLocationSheetState();
}

class _RideDropLocationSheetState extends State<_RideDropLocationSheet> {
  final addressController = getOrPut(() => SavedAddressController());

  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  final _houseNoController = TextEditingController();
  final _landmarkController = TextEditingController();

  String? _selectedId;
  bool _showAddForm = false;

  // Label selector for a new address. One of [_labelOptions]; when 'Other'
  // is chosen the free-text [_labelController] field is shown so the user
  // can type a custom label. The saved address stores the resolved label.
  static const _labelOptions = ['Home', 'Office', 'Other'];
  String _labelType = 'Home';

  // Google place-suggestion state for the address field.
  final _predictions = <PlacePrediction>[].obs;
  final _isSearching = false.obs;
  Timer? _debounce;
  // The address field starts as a tap-to-choose entry point: tapping it opens
  // a "current location vs. search manually" dialog. Once the user picks
  // "Search manually", [_manualSearch] flips so the field becomes an editable
  // Google-suggestions search box (and stops re-opening the dialog on tap).
  final _addressFocus = FocusNode();
  bool _manualSearch = false;
  // Coordinates of the picked suggestion (null until a suggestion is tapped).
  double? _pickedLat;
  double? _pickedLng;

  @override
  void dispose() {
    _debounce?.cancel();
    _addressFocus.dispose();
    _labelController.dispose();
    _addressController.dispose();
    _houseNoController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _onAddressChanged(String query) {
    // A manual edit invalidates any previously picked coordinates.
    _pickedLat = null;
    _pickedLng = null;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchPredictions(query.trim());
    });
  }

  Future<void> _fetchPredictions(String query) async {
    if (query.isEmpty) {
      _predictions.clear();
      return;
    }
    _isSearching.value = true;
    try {
      final response = await PlaceRepo().autoCompleteSearch(query: query);
      if (response.statusCode == 200) {
        final list = response.response?.data?['predictions'] as List? ?? [];
        final parsed = await compute(PlacePrediction.fromList, list);
        _predictions.assignAll(parsed);
      } else {
        _predictions.clear();
      }
    } catch (_) {
      _predictions.clear();
    } finally {
      _isSearching.value = false;
    }
  }

  Future<void> _selectPrediction(PlacePrediction p) async {
    _debounce?.cancel();
    FocusScope.of(context).unfocus();
    final description = p.description ?? '';
    _addressController.text = description;
    _addressController.selection =
        TextSelection.collapsed(offset: description.length);
    _predictions.clear();

    final placeId = p.placeId ?? '';
    if (placeId.isEmpty) return;
    _isSearching.value = true;
    try {
      final res = await PlaceRepo().getCompletePlaceDetails(placeId: placeId);
      final loc =
          res.response?.data?['result']?['geometry']?['location'];
      _pickedLat = (loc?['lat'] as num?)?.toDouble();
      _pickedLng = (loc?['lng'] as num?)?.toDouble();
    } catch (_) {
      // Coordinates are best-effort; the typed address still gets saved.
    } finally {
      _isSearching.value = false;
    }
  }

  void _resetAddForm() {
    _labelType = 'Home';
    _manualSearch = false;
    _labelController.clear();
    _addressController.clear();
    _houseNoController.clear();
    _landmarkController.clear();
    _predictions.clear();
    _pickedLat = null;
    _pickedLng = null;
  }

  Future<void> _saveNewAddress() async {
    // Resolve the label from the radio selection: Home/Office save as-is,
    // 'Other' saves the typed custom label.
    final customLabel = _labelController.text.trim();
    final label = _labelType == 'Other' ? customLabel : _labelType;
    final address = _addressController.text.trim();
    final houseNo = _houseNoController.text.trim();
    final landmark = _landmarkController.text.trim();
    if (address.isEmpty) {
      commonSnackBar(message: 'Please select the drop address');
      return;
    }
    if (houseNo.isEmpty) {
      commonSnackBar(message: 'Please enter the house / flat no');
      return;
    }
    if (_labelType == 'Other' && customLabel.isEmpty) {
      commonSnackBar(message: 'Please enter a label');
      return;
    }
    final saved = await addressController.addAddress(
      label: label.isEmpty ? 'Address' : label,
      address: address,
      houseNo: houseNo,
      landmark: landmark,
      lat: _pickedLat,
      lng: _pickedLng,
    );
    _resetAddForm();
    setState(() {
      _showAddForm = false;
      _selectedId = saved.id; // auto-select the freshly added address
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: CustomText(
                    'Select drop location',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    final list = addressController.addresses;
                    if (list.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: CustomText(
                          'No saved addresses yet. Add a new one below.',
                          fontSize: 13.5,
                          color: Colors.grey.shade500,
                        ),
                      );
                    }
                    return Column(
                      children: list
                          .map((a) => _addressTile(a))
                          .toList(),
                    );
                  }),
                  const SizedBox(height: 8),
                  if (_showAddForm) _buildAddForm() else _buildAddButton(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedId == null) {
                      commonSnackBar(message: 'Please select a drop location');
                      return;
                    }
                    final i = addressController.addresses
                        .indexWhere((a) => a.id == _selectedId);
                    if (i < 0) return;
                    Navigator.pop(context, addressController.addresses[i]);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const CustomText(
                    'Confirm drop location',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressTile(SavedAddress a) {
    final isSelected = _selectedId == a.id;
    return InkWell(
      onTap: () => setState(() => _selectedId = a.id),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryColor : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    a.label,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    a.fullAddress,
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                addressController.removeAddress(a.id);
                if (_selectedId == a.id) setState(() => _selectedId = null);
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.delete_outline,
                    size: 18, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: () => setState(() => _showAddForm = true),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_location_alt_outlined,
                color: AppColors.primaryColor, size: 20),
            const SizedBox(width: 10),
            CustomText(
              'Add new address',
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelSelector(),
          const SizedBox(height: 10),
          // Address entry. Until "Search manually" is chosen the field is
          // read-only and a tap opens the current-location / manual-search
          // dialog; in manual mode it becomes an editable Google-suggestions
          // search box.
          TextField(
            controller: _addressController,
            focusNode: _addressFocus,
            readOnly: !_manualSearch,
            textCapitalization: TextCapitalization.sentences,
            minLines: 1,
            maxLines: 2,
            keyboardType: TextInputType.multiline,
            onTap: _manualSearch ? null : _showAddressSourceDialog,
            onChanged: _onAddressChanged,
            decoration: _fieldDecoration('Search drop address').copyWith(
              prefixIcon: const Icon(Icons.search,
                  size: 20, color: AppColors.primaryColor),
            ),
          ),
          _buildPredictions(),
          const SizedBox(height: 10),
          // Manually-entered house / flat / building number.
          TextField(
            controller: _houseNoController,
            textCapitalization: TextCapitalization.words,
            decoration: _fieldDecoration('House / Flat / Building no'),
          ),
          const SizedBox(height: 10),
          // Optional landmark to help the rider.
          TextField(
            controller: _landmarkController,
            textCapitalization: TextCapitalization.sentences,
            decoration: _fieldDecoration('Landmark (optional)'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _resetAddForm();
                    setState(() => _showAddForm = false);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const CustomText('Cancel',
                      color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveNewAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const CustomText('Save',
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tapping the (read-only) address field opens this chooser: fill from the
  /// device's current location, or switch the field into manual search mode.
  Future<void> _showAddressSourceDialog() async {
    FocusScope.of(context).unfocus();
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const CustomText(
          'Set drop address',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _addressSourceOption(
              ctx,
              value: 'current',
              icon: Icons.my_location,
              title: 'Use current location',
              subtitle: 'Auto-fill from your GPS',
            ),
            const SizedBox(height: 10),
            _addressSourceOption(
              ctx,
              value: 'manual',
              icon: Icons.search,
              title: 'Search address',
              subtitle: 'Type to find the drop address',
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'current') {
      await _useCurrentLocation();
    } else if (choice == 'manual') {
      setState(() => _manualSearch = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _addressFocus.requestFocus();
      });
    }
  }

  Widget _addressSourceOption(
    BuildContext ctx, {
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(ctx, value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    subtitle,
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  /// Fetches the device location, reverse-geocodes it to an address string,
  /// and fills the address field + picked coordinates.
  Future<void> _useCurrentLocation() async {
    _isSearching.value = true;
    try {
      final result =
          await LocationService.fetchLocation(openSettingsOnDeny: true);
      if (result == null || !LocationService.hasUsableLocation) {
        commonSnackBar(message: 'Unable to fetch current location');
        return;
      }
      final lat = LocationService.lat;
      final lng = LocationService.lng;
      final address = await _preciseAddress(lat, lng);
      _addressController.text = address;
      _addressController.selection =
          TextSelection.collapsed(offset: address.length);
      _pickedLat = lat;
      _pickedLng = lng;
      _predictions.clear();
      // Keep the field in read-only "tap to change" mode after auto-fill.
      setState(() => _manualSearch = false);
    } catch (_) {
      commonSnackBar(message: 'Unable to fetch current location');
    } finally {
      _isSearching.value = false;
    }
  }

  /// Reverse-geocodes [lat]/[lng] into a precise, building-level address.
  /// Leads with the building/premise name and street number so the rider
  /// gets at least a building reference, then street → area → city → state →
  /// PIN. Duplicate fragments are dropped and the result is capped to the
  /// first few parts so it stays within ~2 lines. Falls back to the shared
  /// formatter if the placemark lookup fails.
  Future<String> _preciseAddress(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final ordered = <String>[
          p.name ?? '',            // building / premise / house no
          p.subThoroughfare ?? '', // street / building number
          p.thoroughfare ?? '',    // street / road
          p.subLocality ?? '',     // locality / area
          p.locality ?? '',        // city
          p.administrativeArea ?? '', // state
          p.postalCode ?? '',      // PIN
        ];
        final seen = <String>{};
        final parts = <String>[];
        for (final fragment in ordered) {
          final value = fragment.trim();
          if (value.isEmpty) continue;
          if (seen.add(value.toLowerCase())) parts.add(value);
        }
        // Cap to the most specific 5 fragments so the address comfortably
        // fits the 2-line field while still carrying the building reference.
        if (parts.isNotEmpty) {
          return parts.take(5).join(', ');
        }
      }
    } catch (_) {
      // Best-effort: fall through to the shared formatter below.
    }
    return LocationService.getAddressUsingLatLng(latitude: lat, longitude: lng);
  }

  /// Radio selector for the address label — Home / Office / Other. Picking
  /// 'Other' reveals a free-text field so the user can name the place; the
  /// chosen label is what gets saved with the address.
  Widget _buildLabelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 4),
          child: CustomText(
            'Save as',
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Row(
          children: _labelOptions.map((opt) {
            return Expanded(
              child: InkWell(
                onTap: () => setState(() => _labelType = opt),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Radio<String>(
                      value: opt,
                      groupValue: _labelType,
                      onChanged: (v) => setState(() => _labelType = v!),
                      activeColor: AppColors.primaryColor,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Flexible(
                      child: CustomText(
                        opt,
                        fontSize: 13,
                        color: Colors.black87,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_labelType == 'Other') ...[
          const SizedBox(height: 8),
          TextField(
            controller: _labelController,
            textCapitalization: TextCapitalization.words,
            decoration: _fieldDecoration('Enter label (e.g. Gym, Friend\'s place)'),
          ),
        ],
      ],
    );
  }

  /// Inline list of Google place suggestions shown under the address field
  /// (an inline list rather than an overlay, so it scrolls with the sheet).
  Widget _buildPredictions() {
    return Obx(() {
      if (_isSearching.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }
      if (_predictions.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(top: 6),
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: _predictions.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),
          itemBuilder: (context, index) {
            final p = _predictions[index];
            return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Icon(Icons.location_on_outlined,
                  size: 18, color: Colors.grey.shade600),
              title: CustomText(
                p.description ?? '',
                fontSize: 13,
                color: Colors.black87,
                maxLines: 2,
              ),
              onTap: () => _selectPrediction(p),
            );
          },
        ),
      );
    });
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey.shade500),
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryColor),
      ),
    );
  }
}
