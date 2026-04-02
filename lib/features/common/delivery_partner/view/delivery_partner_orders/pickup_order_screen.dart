import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/order_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/app_enum.dart';
import '../../../../chat/auth/model/rider_orders_details_model.dart';
import '../../../../chat/view/call_screen/rider_call/ride_navigation_overlay_controller.dart';
import '../../../../chat/view/call_screen/rider_call/rider_pickup_navigation_screen.dart';
import '../../../../chat/view/call_screen/rider_call/rider_ride_navigation_screen.dart';
import '../../controller/pip_floating_page_controller.dart';


class PickupOrderScreen extends StatefulWidget {
  const PickupOrderScreen({super.key});

  @override
  State<PickupOrderScreen> createState() => _PickupOrderScreenState();
}

class _PickupOrderScreenState extends State<PickupOrderScreen> {
  final controller = getOrPut(() => DeliverPartnerOrdersController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filterButtons(),
          _buildTabViews(),
        ],
      ),
    );
  }

  Widget _filterButtons() {
    return Obx(() {
      return SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size15),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            LocalAssets(imagePath: AppIconAssets.channelFilterIcon),
            SizedBox(width: SizeConfig.size10),
            Row(
              children: controller.pickUpTabs.map((tab) {
                final isSelected = controller.selectedPickUp.value == tab;
                return Padding(
                  padding: EdgeInsets.only(right: SizeConfig.size14),
                  child: GestureDetector(
                    onTap: () {
                      controller.selectedPickUp.value = tab;
                      if(controller.selectedPickUp.value != PickUpTab.orders && controller.selectedPickUp.value != PickUpTab.rejected){
                        controller.getRidersBookingOrders();
                      }else if(controller.selectedPickUp.value == PickUpTab.rejected){
                        controller.getRiderRejectOrderList();
                      }
                    },
                    child: CustomText(
                      tab.label,
                      decoration: TextDecoration.underline,
                      color: isSelected ? AppColors.primaryColor : AppColors.secondaryTextColor,
                      decorationColor:
                          isSelected ? AppColors.primaryColor : AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTabViews(){
    return Expanded(
      child: Obx(() {
        if (controller.ordersListResponse.value.status ==
            Status.COMPLETE) {
          switch (controller.selectedPickUp.value) {

            case PickUpTab.orders:
              return _buildOngoingRideOrEmpty();

            case PickUpTab.newOrder:
              return _buildOrderList(controller.newOrders);

            case PickUpTab.onGoing:
              return _buildOrderList(controller.onGoingOrders);

            case PickUpTab.completed:
              return _buildOrderList(controller.completedOrders);

            case PickUpTab.cancel:
              return _buildOrderList(controller.cancelledOrders);

            case PickUpTab.rejected:
              return _buildOrderList(controller.rejectedOrders);
          }
        } else {
          return Center(
            child: CustomText(AppStrings.noOrdersFound),
          );
        }
      }),
    );
  }

  Widget _buildOngoingRideOrEmpty() {
    if (!Get.isRegistered<RideNavigationOverlayController>()) {
      return Center(child: CustomText(AppStrings.noOrdersFound));
    }
    final overlayCtrl = Get.find<RideNavigationOverlayController>();

    return Obx(() {
      // Force reactivity by reading observable values
      overlayCtrl.screenType.value;
      overlayCtrl.screenParams.length;

      if (!overlayCtrl.hasOngoingRide) {
        return Center(child: CustomText(AppStrings.noOrdersFound));
      }

      final p = overlayCtrl.screenParams;
      final type = overlayCtrl.screenType.value;
      final customerName = p['customerName'] ?? '';
      final pickupLocation = p['pickupLocation'] ?? '';
      final dropLocation = p['dropLocation'] ?? '';
      final fareAmount = (p['fareAmount'] as num?)?.toDouble() ?? 0.0;
      final paymentMethod = p['paymentMethod'] ?? 'Cash';

      return ListView(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size15,
          vertical: SizeConfig.size10,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CustomText(
              'ONGOING RIDE',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () {
              if (type == 'pickup') {
                Get.to(() => RiderPickupNavigationScreen(
                      pickupLocation: p['pickupLocation'] ?? '',
                      dropLocation: p['dropLocation'] ?? '',
                      pickupLat: (p['pickupLat'] as num?)?.toDouble() ?? 0,
                      pickupLng: (p['pickupLng'] as num?)?.toDouble() ?? 0,
                      dropLat: (p['dropLat'] as num?)?.toDouble() ?? 0,
                      dropLng: (p['dropLng'] as num?)?.toDouble() ?? 0,
                      fareAmount: fareAmount,
                      distanceKm: (p['distanceKm'] as num?)?.toDouble() ?? 0,
                      customerName: customerName,
                      customerImage: p['customerImage'] ?? '',
                      otp: p['otp'] ?? '',
                      paymentMethod: paymentMethod,
                      orderId: p['orderId'] ?? '',
                    ));
              } else {
                Get.to(() => RiderRideNavigationScreen(
                      pickupLocation: p['pickupLocation'] ?? '',
                      dropLocation: p['dropLocation'] ?? '',
                      pickupLat: (p['pickupLat'] as num?)?.toDouble() ?? 0,
                      pickupLng: (p['pickupLng'] as num?)?.toDouble() ?? 0,
                      dropLat: (p['dropLat'] as num?)?.toDouble() ?? 0,
                      dropLng: (p['dropLng'] as num?)?.toDouble() ?? 0,
                      fareAmount: fareAmount,
                      distanceKm: (p['distanceKm'] as num?)?.toDouble() ?? 0,
                      customerName: customerName,
                      customerImage: p['customerImage'] ?? '',
                      paymentMethod: paymentMethod,
                      orderId: p['orderId'] ?? '',
                    ));
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00C853).withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + fare row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00C853),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              type == 'pickup'
                                  ? 'Heading to Pickup'
                                  : 'Ride in Progress',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'OpenSans',
                                color: Color(0xFF00C853),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹${fareAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00C853),
                          fontFamily: 'OpenSans',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Customer name
                  Row(
                    children: [
                      const Icon(Icons.person_rounded,
                          color: Color(0xFF4285F4), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          customerName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'OpenSans',
                            color: Color(0xFF1A1A2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          paymentMethod,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'OpenSans',
                            color: Color(0xFF4285F4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Pickup → Drop
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00C853),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 20,
                            color: Colors.grey.shade300,
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF7043),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pickupLocation,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontFamily: 'OpenSans',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              dropLocation,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontFamily: 'OpenSans',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tap to navigate button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.navigation_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Continue Navigation',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'OpenSans',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  /// Merged view: ongoing orders on top, then new orders below.
  Widget _buildMergedOrderList({
    required List<RiderOrdersDetailsModel> onGoing,
    required List<RiderOrdersDetailsModel> newOrders,
  }) {
    if (onGoing.isEmpty && newOrders.isEmpty) {
      return Center(child: CustomText(AppStrings.noOrdersFound));
    }

    return ListView(
      padding: EdgeInsets.only(
        top: SizeConfig.size10,
        bottom: kBottomNavigationBarHeight + SizeConfig.size40,
        left: SizeConfig.size15,
        right: SizeConfig.size15,
      ),
      children: [
        if (onGoing.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: CustomText(
              'ONGOING',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          ...onGoing.map((order) => OrderCard(
                order: order,
                selectedPickUp: PickUpTab.onGoing,
              )),
        ],
        if (newOrders.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: CustomText(
              'NEW ORDERS',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          ...newOrders.map((order) => OrderCard(
                order: order,
                selectedPickUp: PickUpTab.newOrder,
              )),
        ],
      ],
    );
  }

  Widget _buildOrderList(List<RiderOrdersDetailsModel> ordersList) {
    final groupedOrders = groupOrdersByOrderFor(ordersList);
    final orderForKeys = groupedOrders.keys.toList();

    return
      ordersList.isEmpty
        ? Center(
      child: CustomText(AppStrings.noOrdersFound),
    )
        : ListView.builder(
        padding: EdgeInsets.only(
          top: SizeConfig.size10,
          bottom: kBottomNavigationBarHeight + SizeConfig.size40,
          left: SizeConfig.size15,
          right: SizeConfig.size15,
        ),
        itemCount: orderForKeys.length,
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final orderFor = orderForKeys[index];
          final orders = groupedOrders[orderFor]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 TITLE
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: CustomText(
                  getOrderForTitle(orderFor),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                ),
              ),

              /// 🔹 LIST UNDER TITLE
              ...orders.map((rider) {
                return OrderCard(
                  order: rider,
                  selectedPickUp: controller.selectedPickUp.value,
                );
              }).toList(),
            ],
          );
        },
      );
  }

  Map<String, List<RiderOrdersDetailsModel>> groupOrdersByOrderFor(
      List<RiderOrdersDetailsModel> orders) {
    final Map<String, List<RiderOrdersDetailsModel>> grouped = {};

    for (var order in orders) {
      final key = order.orderFor ?? 'unknown';

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(order);
    }

    return grouped;
  }
  String getOrderForTitle(String orderFor) {
    switch (orderFor) {
      case 'product':
        return 'PRODUCT';
      case 'grocery':
        return 'GROCERY';
      case 'food':
        return 'FOOD';
      case 'medical':
        return 'MEDICAL';
      case 'InCity':
        return 'PASSENGER';
      case 'OutStation':
        return 'PASSENGER';
      case 'HourlyRental':
        return 'HOURLY RENTAL';
      case 'Parcel':
        return 'PARCEL';
      default:
        return orderFor.toUpperCase();
    }
  }

}

class OngoingRideCard extends StatefulWidget {
  const OngoingRideCard({super.key});

  @override
  State<OngoingRideCard> createState() => _OngoingRideCardState();
}

class _OngoingRideCardState extends State<OngoingRideCard> {
  double dragX = 0;
  final controller = getOrPut(() => PipFloatingPageController());

  @override
  void initState() {
    super.initState();

  }

  // @override
  // void dispose() {
  //   controller.setPipStatus(false);
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // await controller.platformData.invokeMethod('enterPip');
        // Get.to(OnGoingPipScreen());
      },
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 360, // 🔑 VERY IMPORTANT
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // 🔑 prevents RenderFlex error
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Title
        const CustomText(
          "Ongoing Ride",
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),

        const SizedBox(height: 8),

        /// Drop Location
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.whiteE5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                "DROP LOCATION",
                fontSize: 12,
                color: Colors.grey,
                letterSpacing: 1,
              ),
              SizedBox(height: 4),
              CustomText(
                "No. 21, 1st Floor, Near Metro Station, Bengaluru",
                fontSize: 13,
                color: Colors.black54,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        _slideToComplete(context),
      ],
    );
  }

  Widget _slideToComplete(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sliderWidth = constraints.maxWidth;
        const buttonWidth = 56.0;

        return Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            children: [
              Center(
                child: CustomText(
                  "Slide to complete",
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Positioned(
                left: dragX,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      dragX += details.delta.dx;
                      dragX = dragX.clamp(
                        0,
                        sliderWidth - buttonWidth,
                      );
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    if (dragX > (sliderWidth - buttonWidth) * 0.7) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Order Completed"),
                        ),
                      );
                    }
                    setState(() => dragX = 0);
                  },
                  child: Container(
                    height: 56,
                    width: buttonWidth,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
