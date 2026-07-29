import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/v3/controller/vehicle_buyer_controller_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_listing_draft_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_v3_models.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/customer/vehicle_enquiry_sheet_v3.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// One listing in full — `GET /inventory/:id`.
///
/// The spec sheet is condition-driven, because the two conditions genuinely
/// describe different things: a used vehicle's history (kilometres, owners,
/// RC, insurance) versus a new one's commercial terms (on-road price,
/// availability, delivery, EMI).
///
/// The seller block is rendered defensively: §6 warns that `seller` /
/// `sellerBusiness` come from another service **best-effort** and can be null
/// when it is briefly unavailable, which is a fallback to render, not an
/// error to report.
class VehicleListingDetailScreenV3 extends StatefulWidget {
  final String listingId;

  const VehicleListingDetailScreenV3({super.key, required this.listingId});

  @override
  State<VehicleListingDetailScreenV3> createState() =>
      _VehicleListingDetailScreenV3State();
}

class _VehicleListingDetailScreenV3State
    extends State<VehicleListingDetailScreenV3> {
  final VehicleBuyerControllerV3 _controller =
      getOrPut(() => VehicleBuyerControllerV3());

  VehicleListingV3? _listing;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final listing = await _controller.fetchListing(widget.listingId);
    if (!mounted) return;
    setState(() {
      _listing = listing;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final listing = _listing;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        title: listing?.title.isNotEmpty == true ? listing!.title : 'Vehicle',
        isShadowShow: false,
      ),
      bottomNavigationBar: listing == null ? null : _enquireBar(listing),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : listing == null
                ? Center(
                    child: EmptyStateWidget(
                      message: 'This listing is no longer available.',
                    ),
                  )
                : _body(listing),
      ),
    );
  }

  Widget _body(VehicleListingV3 listing) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size12,
        SizeConfig.size16,
        SizeConfig.size24,
      ),
      children: [
        _gallery(listing),
        SizedBox(height: SizeConfig.size14),
        _priceBlock(listing),
        SizedBox(height: SizeConfig.size16),
        _specSheet(listing),
        if (listing.description.isNotEmpty) ...[
          SizedBox(height: SizeConfig.size16),
          _card(
            title: 'About this vehicle',
            children: [
              CustomText(
                listing.description,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                maxLines: 20,
              ),
            ],
          ),
        ],
        SizedBox(height: SizeConfig.size16),
        _locationCard(listing),
      ],
    );
  }

  /// Seller photos for a used vehicle, catalog artwork for a new one —
  /// [VehicleListingV3.thumbnail] already encodes that precedence, and the
  /// strip below simply shows whatever the listing actually carries.
  Widget _gallery(VehicleListingV3 listing) {
    final images = <String>[
      if (listing.coverImage.isNotEmpty) listing.coverImage,
      ...listing.images.where((i) => i != listing.coverImage),
    ];
    if (images.isEmpty) {
      final fallback = listing.thumbnail;
      if (fallback != null) images.add(fallback);
    }
    if (images.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.whiteF3,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.directions_car_filled_outlined,
            size: 40, color: AppColors.secondaryTextColor),
      );
    }
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size8),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CachedNetworkImage(
            imageUrl: images[i],
            width: images.length == 1
                ? MediaQuery.of(context).size.width - SizeConfig.size32
                : 280,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 280,
              color: AppColors.whiteF3,
            ),
            errorWidget: (_, __, ___) => Container(
              width: 280,
              color: AppColors.whiteF3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceBlock(VehicleListingV3 listing) {
    final price = listing.displayPrice ??
        (listing.isNew ? listing.onRoadPrice : listing.expectedPrice);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                formatVehiclePriceV3(price),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size2),
              CustomText(
                [
                  listing.isNew ? 'New' : 'Used',
                  if (listing.colourLabel.isNotEmpty) listing.colourLabel,
                  if (listing.isNegotiable == true) 'Negotiable',
                ].join(' · '),
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ),
        if (listing.isVerified)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size8,
              vertical: SizeConfig.size4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1F9254).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified,
                    size: 14, color: Color(0xFF1F9254)),
                SizedBox(width: SizeConfig.size4),
                CustomText(
                  'Verified',
                  fontSize: SizeConfig.small11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F9254),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _specSheet(VehicleListingV3 listing) {
    final rows = <MapEntry<String, String>>[];

    void add(String label, String? value) {
      if (value == null || value.trim().isEmpty) return;
      rows.add(MapEntry(label, value.trim()));
    }

    final product = listing.product;
    add('Variant', product?.name);
    add('Fuel', product?.fuelType);
    add('Transmission', product?.transmission);

    if (listing.isNew) {
      add('On-road price', formatVehiclePriceV3(listing.onRoadPrice));
      add('Availability', listing.availability);
      add('Delivery', listing.deliveryTime);
      add('EMI', listing.emiAvailable == null
          ? null
          : (listing.emiAvailable! ? 'Available' : 'Not available'));
      add('Offers', listing.specialOffers);
    } else {
      add('Kilometres', formatKilometresV3(listing.kmDriven));
      add('Registration year', listing.registrationYear?.toString());
      add('Ownership', listing.ownership);
      add('Condition', listing.conditionGrade);
      add('RC', listing.rcAvailable == null
          ? null
          : (listing.rcAvailable! ? 'Available' : 'Not available'));
      add('Insurance valid till', listing.insuranceValidTill);
      add('Service history', listing.serviceHistory);
    }

    if (rows.isEmpty) return const SizedBox.shrink();
    return _card(
      title: 'Details',
      children: rows
          .map(
            (row) => Padding(
              padding: EdgeInsets.only(bottom: SizeConfig.size8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: CustomText(
                      row.key,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                  Expanded(
                    child: CustomText(
                      row.value,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _locationCard(VehicleListingV3 listing) {
    final parts = [
      listing.address,
      listing.city,
      listing.state,
      listing.pincode,
    ].where((p) => p.trim().isNotEmpty).join(', ');
    if (parts.isEmpty) return const SizedBox.shrink();
    return _card(
      title: 'Location',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on_outlined,
                size: 18, color: AppColors.secondaryTextColor),
            SizedBox(width: SizeConfig.size6),
            Expanded(
              child: CustomText(
                parts,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                maxLines: 3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            title,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size10),
          ...children,
        ],
      ),
    );
  }

  /// One enquiry per listing — there is no cart and no payment here; the
  /// request opens a chat card with the seller and that is the whole flow.
  Widget _enquireBar(VehicleListingV3 listing) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size10,
        SizeConfig.size16,
        SizeConfig.size12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: SizeConfig.size48,
          child: ElevatedButton(
            onPressed: () => showVehicleEnquirySheetV3(
              context: context,
              listing: listing,
              controller: _controller,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Contact seller',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontFamily: 'OpenSans',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
