import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/vehicle/v3/controller/vehicle_v3_controller.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_basket_entry_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_listing_draft_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_v3_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Tapping "+" on a trim in the add rails opens this: **pick a colour, then
/// say whether it's new or used** — and the trim lands in the basket.
///
/// Grocery can add a product straight from its rail because a grocery product
/// identifies itself. A vehicle can't: `POST /inventory` requires the colour
/// (`productVariant`) and a `condition`, and the condition decides which
/// fields the server expects afterwards. Both are asked here, in one sheet,
/// so the rail stays a one-tap surface.
///
/// Colours come from `GET /products/:productId` — the only endpoint that
/// returns them (§4 step 5) — so the sheet fetches on open rather than
/// trusting the rail payload, which may carry a trimmed-down variant list.
Future<void> showVehicleColourConditionSheetV3({
  required BuildContext context,
  required VehicleTrimV3 trim,
  required VehicleV3Controller controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ColourConditionSheet(trim: trim, controller: controller),
  );
}

class _ColourConditionSheet extends StatefulWidget {
  final VehicleTrimV3 trim;
  final VehicleV3Controller controller;

  const _ColourConditionSheet({required this.trim, required this.controller});

  @override
  State<_ColourConditionSheet> createState() => _ColourConditionSheetState();
}

class _ColourConditionSheetState extends State<_ColourConditionSheet> {
  late VehicleTrimV3 _trim = widget.trim;
  bool _loading = true;

  VehicleColorVariantV3? _colour;
  String _condition = VehicleListingCondition.isNew;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // The rail row may already carry colours; re-read anyway so the specs the
    // review screen pre-fills from are the full ones.
    final detail = await widget.controller.fetchTrimDetail(widget.trim.id);
    if (!mounted) return;
    setState(() {
      if (detail != null) _trim = detail;
      _colour = _trim.variants.isNotEmpty ? _trim.variants.first : null;
      _loading = false;
    });
  }

  void _add() {
    final colour = _colour;
    if (colour == null) {
      commonSnackBar(message: 'Pick a colour first.');
      return;
    }
    final entry = VehicleBasketEntryV3(
      trim: _trim,
      colour: colour,
      condition: _condition,
    )..seedPriceFromCatalog();
    widget.controller.toggleBasketEntry(entry);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size20,
        SizeConfig.size12,
        SizeConfig.size20,
        SizeConfig.size20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: SafeArea(
        top: false,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  SizedBox(height: SizeConfig.size16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Colour'),
                          SizedBox(height: SizeConfig.size8),
                          if (_trim.variants.isEmpty)
                            CustomText(
                              // No colour means no `productVariant`, so this
                              // trim genuinely cannot be listed.
                              'This variant has no colours in the catalog yet, '
                              'so it cannot be listed.',
                              fontSize: SizeConfig.small,
                              color: AppColors.secondaryTextColor,
                              maxLines: 3,
                            )
                          else
                            Wrap(
                              spacing: SizeConfig.size8,
                              runSpacing: SizeConfig.size8,
                              children:
                                  _trim.variants.map(_colourChip).toList(),
                            ),
                          SizedBox(height: SizeConfig.size16),
                          _label('Condition'),
                          SizedBox(height: SizeConfig.size8),
                          Row(
                            children: [
                              Expanded(
                                child: _conditionTile(
                                  value: VehicleListingCondition.isNew,
                                  title: 'New',
                                  subtitle: 'Catalog photos',
                                  icon: Icons.new_releases_outlined,
                                ),
                              ),
                              SizedBox(width: SizeConfig.size10),
                              Expanded(
                                child: _conditionTile(
                                  value: VehicleListingCondition.used,
                                  title: 'Used',
                                  subtitle: 'Your own photos',
                                  icon: Icons.history_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.size16),
                  SizedBox(
                    height: SizeConfig.size48,
                    child: ElevatedButton(
                      onPressed: _trim.variants.isEmpty ? null : _add,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        disabledBackgroundColor:
                            AppColors.primaryColor.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add to list',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'OpenSans',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _header() {
    final image = _trim.firstImage;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 64,
            height: 52,
            child: image == null
                ? Container(
                    color: AppColors.whiteF3,
                    child: Icon(Icons.directions_car_filled_outlined,
                        color: AppColors.secondaryTextColor),
                  )
                : CachedNetworkImage(imageUrl: image, fit: BoxFit.cover),
          ),
        ),
        SizedBox(width: SizeConfig.size12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                _trim.name,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (_trim.exShowroomPrice != null)
                CustomText(
                  '${formatVehiclePriceV3(_trim.exShowroomPrice)} ex-showroom',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _colourChip(VehicleColorVariantV3 colour) {
    final selected = _colour?.id == colour.id;
    return InkWell(
      onTap: () => setState(() => _colour = colour),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryColor : AppColors.greyE5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _swatch(colour.colorHex),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.greyE5),
              ),
            ),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              colour.colorName.isEmpty ? 'Colour' : colour.colorName,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: selected
                  ? AppColors.primaryColor
                  : AppColors.mainTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _conditionTile({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _condition == value;
    return InkWell(
      onTap: () => setState(() => _condition = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor.withValues(alpha: 0.08)
              : const Color(0xFFF6F9FE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryColor : const Color(0xFFE0E8F4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 20,
                color: selected
                    ? AppColors.primaryColor
                    : AppColors.secondaryTextColor),
            SizedBox(height: SizeConfig.size4),
            CustomText(
              title,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
            ),
            CustomText(
              subtitle,
              fontSize: SizeConfig.small11,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => CustomText(
        text,
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w700,
        color: AppColors.mainTextColor,
      );

  Color _swatch(String hex) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length != 6) return AppColors.whiteF3;
    final value = int.tryParse('FF$cleaned', radix: 16);
    return value == null ? AppColors.whiteF3 : Color(value);
  }
}
