import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/v3/controller/vehicle_buyer_controller_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_listing_draft_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_v3_models.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/customer/vehicle_listing_detail_screen_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/widgets/vehicle_listing_card_v3.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Every live listing for one trim — `GET /inventory/browse?productId=`.
///
/// This is where the rollup opens back out: one trim card on discovery stands
/// for N sellers, and each of those is a separate listing with its own
/// condition, kilometres, price and photos.
class VehicleTrimListingsScreenV3 extends StatefulWidget {
  final VehicleTrimV3 trim;

  const VehicleTrimListingsScreenV3({super.key, required this.trim});

  @override
  State<VehicleTrimListingsScreenV3> createState() =>
      _VehicleTrimListingsScreenV3State();
}

class _VehicleTrimListingsScreenV3State
    extends State<VehicleTrimListingsScreenV3> {
  final VehicleBuyerControllerV3 _controller =
      getOrPut(() => VehicleBuyerControllerV3());

  @override
  void initState() {
    super.initState();
    _controller.fetchListingsForTrim(widget.trim.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(title: widget.trim.name, isShadowShow: false),
      body: SafeArea(
        child: Obx(() {
          final loading =
              _controller.trimListingsStatus.value == Status.LOADING ||
                  _controller.trimListingsStatus.value == Status.INITIAL;
          final listings = _controller.trimListings;

          if (loading) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (listings.isEmpty) {
            return Center(
              child: EmptyStateWidget(
                message: 'No one is selling this model near you right now.',
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => _controller.fetchListingsForTrim(widget.trim.id),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size12,
                SizeConfig.size12,
                SizeConfig.size12,
                SizeConfig.size24,
              ),
              itemCount: listings.length + 1,
              separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
              itemBuilder: (_, i) {
                if (i == 0) return _header(listings.length);
                final listing = listings[i - 1];
                return VehicleListingCardV3(
                  listing: listing,
                  onTap: () => Get.to(
                    () => VehicleListingDetailScreenV3(listingId: listing.id),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _header(int count) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size4),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              count == 1 ? '1 seller nearby' : '$count sellers nearby',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
            ),
          ),
          if (widget.trim.exShowroomPrice != null)
            CustomText(
              '${formatVehiclePriceV3(widget.trim.exShowroomPrice)} ex-showroom',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
        ],
      ),
    );
  }
}
