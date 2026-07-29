import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/me/vehicle/v3/controller/vehicle_v3_controller.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_basket_entry_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_listing_draft_v3.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Review + publish, the last step of the add flow — the vehicle counterpart
/// of `AddGroceryVariantScreen`.
///
/// One card per basket entry. Identity and specs came from the catalog and are
/// shown read-only; what a merchant edits here is only what the server asks
/// them for, and that differs by condition (§2 of the integration guide):
///
/// * **NEW** — on-road price, availability, delivery. Photos come from the
///   catalog, so there is no picker.
/// * **USED** — asking price, kilometres, year, and **their own photos**.
///
/// Publishing sends one `POST /inventory` per entry: unlike grocery and
/// medical, this endpoint documents a single-listing body, not an array.
class AddVehicleVariantScreenV3 extends StatefulWidget {
  const AddVehicleVariantScreenV3({super.key});

  @override
  State<AddVehicleVariantScreenV3> createState() =>
      _AddVehicleVariantScreenV3State();
}

class _AddVehicleVariantScreenV3State extends State<AddVehicleVariantScreenV3> {
  final controller = getOrPut(() => VehicleV3Controller());

  Future<void> _publish() async {
    final published = await controller.publishBasket();
    if (published == 0 || !mounted) return;
    commonSnackBar(
      message: published == 1
          ? 'Vehicle listed successfully.'
          : '$published vehicles listed successfully.',
    );
    // Unwind the add flow back to the dashboard, which reloads off
    // `listingsNeedRefresh`.
    Get.until((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: 'Review & publish'),
      bottomNavigationBar: _publishBar(),
      body: SafeArea(
        child: Obx(() {
          final entries = controller.basket;
          if (entries.isEmpty) {
            return Center(
              child: CustomText(
                'Nothing to publish yet.',
                fontSize: SizeConfig.medium,
                color: AppColors.secondaryTextColor,
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size8,
              vertical: SizeConfig.size12,
            ),
            itemCount: entries.length,
            itemBuilder: (_, i) => _entryCard(entries[i]),
          );
        }),
      ),
    );
  }

  Widget _entryCard(VehicleBasketEntryV3 entry) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size12),
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _entryHeader(entry),
          SizedBox(height: SizeConfig.size12),
          if (entry.isNew) ..._newFields(entry) else ..._usedFields(entry),
        ],
      ),
    );
  }

  Widget _entryHeader(VehicleBasketEntryV3 entry) {
    final image = entry.colour.firstImage ?? entry.trim.firstImage;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 72,
            height: 56,
            child: image == null
                ? Container(
                    color: AppColors.whiteF3,
                    child: Icon(Icons.directions_car_filled_outlined,
                        color: AppColors.secondaryTextColor),
                  )
                : CachedNetworkImage(imageUrl: image, fit: BoxFit.cover),
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                entry.trim.name,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: SizeConfig.size2),
              Row(
                children: [
                  _conditionToggle(entry),
                  if (entry.colour.colorName.isNotEmpty) ...[
                    SizedBox(width: SizeConfig.size6),
                    Flexible(
                      child: CustomText(
                        entry.colour.colorName,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => controller.removeFromBasket(entry.colour.id),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.close_rounded,
                size: 18, color: AppColors.secondaryTextColor),
          ),
        ),
      ],
    );
  }

  /// New/used can still be flipped here without going back — tapping swaps the
  /// field set below with it.
  Widget _conditionToggle(VehicleBasketEntryV3 entry) {
    final isNew = entry.isNew;
    final color = isNew ? const Color(0xFF1F9254) : const Color(0xFFB25E00);
    return InkWell(
      onTap: () => setState(() {
        entry.condition = isNew
            ? VehicleListingCondition.used
            : VehicleListingCondition.isNew;
        entry.seedPriceFromCatalog();
      }),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8, vertical: SizeConfig.size2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              isNew ? 'NEW' : 'USED',
              fontSize: SizeConfig.small11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            SizedBox(width: SizeConfig.size2),
            Icon(Icons.swap_horiz_rounded, size: 12, color: color),
          ],
        ),
      ),
    );
  }

  List<Widget> _newFields(VehicleBasketEntryV3 entry) => [
        _numberField(
          label: 'On-road price (₹)',
          initial: entry.onRoadPrice?.toString(),
          onChanged: (v) => entry.onRoadPrice = num.tryParse(v),
        ),
        _textField(
          label: 'Delivery time',
          hint: 'e.g. 2–3 weeks',
          initial: entry.deliveryTime,
          onChanged: (v) => entry.deliveryTime = v,
        ),
      ];

  List<Widget> _usedFields(VehicleBasketEntryV3 entry) => [
        _numberField(
          label: 'Asking price (₹)',
          initial: entry.expectedPrice?.toString(),
          onChanged: (v) => entry.expectedPrice = num.tryParse(v),
        ),
        Row(
          children: [
            Expanded(
              child: _numberField(
                label: 'Kilometres',
                initial: entry.kmDriven?.toString(),
                onChanged: (v) => entry.kmDriven = int.tryParse(v),
              ),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: _numberField(
                label: 'Year',
                initial: entry.registrationYear?.toString(),
                onChanged: (v) => entry.registrationYear = int.tryParse(v),
              ),
            ),
          ],
        ),
        _photoRow(entry),
      ];

  /// USED only — the server takes the seller's own photos for a used vehicle,
  /// and [VehicleListingDraftV3.validate] refuses to publish without at least
  /// one.
  Widget _photoRow(VehicleBasketEntryV3 entry) {
    return Padding(
      padding: EdgeInsets.only(top: SizeConfig.size4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Photos (required)',
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size6),
          Wrap(
            spacing: SizeConfig.size8,
            runSpacing: SizeConfig.size8,
            children: [
              for (final path in entry.photoPaths)
                Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(File(path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: InkWell(
                        onTap: () =>
                            setState(() => entry.photoPaths.remove(path)),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(Icons.close,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              if (entry.photoPaths.length < VehicleListingDraftV3.maxImages)
                InkWell(
                  onTap: () => _pickPhotos(entry),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.greyE5),
                    ),
                    child: Icon(Icons.add_a_photo_outlined,
                        color: AppColors.primaryColor, size: 18),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhotos(VehicleBasketEntryV3 entry) async {
    final remaining =
        VehicleListingDraftV3.maxImages - entry.photoPaths.length;
    if (remaining <= 0) return;
    final picked = await PhotoPickerService.pickMultiplePhotos(
      context,
      'Add vehicle photos',
      maxImages: remaining,
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    setState(() => entry.photoPaths.addAll(picked));
  }

  Widget _textField({
    required String label,
    String? hint,
    String? initial,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            label,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size4),
          TextFormField(
            initialValue: initial,
            onChanged: onChanged,
            decoration: _decoration(hint),
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required String label,
    String? initial,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            label,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size4),
          TextFormField(
            initialValue: initial,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: onChanged,
            decoration: _decoration(null),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String? hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.greyE5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.greyE5),
        ),
      );

  Widget _publishBar() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.all(SizeConfig.size15),
      child: SafeArea(
        child: Obx(() {
          final count = controller.basket.length;
          return CustomBtn(
            onTap: count == 0 ? null : _publish,
            isValidate: count > 0,
            radius: SizeConfig.size8,
            bgColor:
                count > 0 ? AppColors.primaryColor : AppColors.greyB4,
            title: count == 1
                ? 'Publish 1 vehicle'
                : 'Publish $count vehicles',
            isLoading: controller.isSubmitting.value,
          );
        }),
      ),
    );
  }
}
