
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_enum.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../chat/auth/model/rider_orders_details_model.dart';
import '../../../../chat/view/call_screen/rider_call/rider_pickup_navigation_screen.dart';
import '../../../../chat/view/call_screen/rider_call/rider_ride_navigation_screen.dart';
import '../../controller/delivery_partner_orders_controller.dart';
import '../../controller/pip_floating_page_controller.dart';
import '../../widget/order_card.dart';

class OnGoingPipScreen extends StatefulWidget {
  const OnGoingPipScreen({super.key});

  @override
  State<OnGoingPipScreen> createState() => _OnGoingPipScreenState();
}

class _OnGoingPipScreenState extends State<OnGoingPipScreen> with WidgetsBindingObserver {
  double dragX = 0;
  final controller = getOrPut(() => PipFloatingPageController());
  final deliveryOrdersController = getOrPut(() => DeliverPartnerOrdersController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      enablePip();
    });

  }
void enablePip()async{
  await controller.setPipStatus(true);
  await controller.platformData.invokeMethod('enterPip');
  controller.isPipModeOn.value=true;
}
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    switch (state) {
      case AppLifecycleState.inactive:
        controller.isPipModeOn.value=true;
        break;

      case AppLifecycleState.paused:
      // 🔴 App goes to recent / background
      // Good place to prepare PiP UI
        break;

      case AppLifecycleState.resumed:
      // 🟢 App came back from recent / PiP
        controller.isPipModeOn.value = false;
        break;

      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  /// Check if an order is a fare-call order
  bool _isFareCallOrder(RiderOrdersDetailsModel order) {

    return order.orderType == 'fare-call';
  }

  /// Check if pickup OTP has been verified (status is 'picked-up' or later)
  bool _isPickupOtpVerified(RiderOrdersDetailsModel order) {
    return order.status == 'picked-up' || order.status == 'completed';
  }

  /// Navigate to the appropriate screen based on OTP verification status
  void _navigateToFareCallOrder(RiderOrdersDetailsModel order) {
    final pickupLat = order.pickupLocation?.location?.coordinates != null &&
            order.pickupLocation!.location!.coordinates!.length >= 2
        ? order.pickupLocation!.location!.coordinates![1].toDouble()
        : 0.0;
    final pickupLng = order.pickupLocation?.location?.coordinates != null &&
            order.pickupLocation!.location!.coordinates!.length >= 2
        ? order.pickupLocation!.location!.coordinates![0].toDouble()
        : 0.0;
    final dropLat = order.dropLocation?.location?.coordinates != null &&
            order.dropLocation!.location!.coordinates!.length >= 2
        ? order.dropLocation!.location!.coordinates![1].toDouble()
        : 0.0;
    final dropLng = order.dropLocation?.location?.coordinates != null &&
            order.dropLocation!.location!.coordinates!.length >= 2
        ? order.dropLocation!.location!.coordinates![0].toDouble()
        : 0.0;

    final customerName = order.user?.name ?? 'Customer';
    final customerImage = order.user?.profileImage ?? '';
    final fare = order.fare?.toDouble() ?? 0.0;
    final distance = double.tryParse(order.distancePickupToDrop ?? '') ?? 0.0;
    final paymentMethod = order.modeOfPayment ?? 'Cash';
    final pickupAddress = order.dropLocation?.address ?? 'Pickup location';
    final dropAddress = order.dropLocation?.address ?? 'Drop location';

    if (_isPickupOtpVerified(order)) {
      // OTP verified — go to ride navigation (pickup → drop)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RiderRideNavigationScreen(
            pickupLocation: pickupAddress,
            dropLocation: dropAddress,
            pickupLat: pickupLat,
            pickupLng: pickupLng,
            dropLat: dropLat,
            dropLng: dropLng,
            fareAmount: fare,
            distanceKm: distance,
            customerName: customerName,
            customerImage: customerImage,
            paymentMethod: paymentMethod,
          ),
        ),
      );
    } else {
      // OTP not verified — go to pickup navigation (with OTP entry)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RiderPickupNavigationScreen(
            pickupLocation: pickupAddress,
            dropLocation: dropAddress,
            pickupLat: pickupLat,
            pickupLng: pickupLng,
            dropLat: dropLat,
            dropLng: dropLng,
            fareAmount: fare,
            distanceKm: distance,
            customerName: customerName,
            customerImage: customerImage,
            otp: order.pickupOTP ?? '',
            paymentMethod: paymentMethod,
            customerUserId: order.user?.id ?? '',
          ),
        ),
      );
    }
  }

  /// Build a mini card for a fare-call ongoing order
  Widget _buildFareCallMiniCard(RiderOrdersDetailsModel order) {
    final isOtpVerified = _isPickupOtpVerified(order);
    final customerName = order.user?.name ?? 'Customer';
    final dropAddress = order.dropLocation?.address ?? 'Drop location';
    final fare = order.fare?.toDouble() ?? 0.0;
    final status = isOtpVerified ? 'Ride in Progress' : 'Heading to Pickup';
    final statusColor = isOtpVerified ? const Color(0xFF4285F4) : const Color(0xFF00C853);

    return GestureDetector(
      onTap: () => _navigateToFareCallOrder(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status row
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                CustomText(
                  status,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
                const Spacer(),
                // Fare badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomText(
                    '\u20B9${fare.toStringAsFixed(0)}',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00C853),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Customer + drop info
            Row(
              children: [
                Icon(Icons.delivery_dining_rounded, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        customerName,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      const SizedBox(height: 2),
                      CustomText(
                        dropAddress,
                        fontSize: 11,
                        color: AppColors.grayText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Navigate arrow
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.navigation_rounded,
                    color: statusColor,
                    size: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) async {

          if (didPop) return;
          // Also trigger PiP if they click the Back button
          controller.isPipModeOn.value=true;
          await controller.platformData.invokeMethod('enterPip');

        },

        child: Obx(() {
          final orders = controller.isPipModeOn.value
              ? deliveryOrdersController.onGoingOrders.take(1).toList()
              : deliveryOrdersController.onGoingOrders;
          debugPrint('[ONGOING_PIP] orders count=${orders.length}, isPip=${controller.isPipModeOn.value}');
          for (final o in orders) {
            debugPrint('[ONGOING_PIP] order: id=${o.orderId}, status=${o.status}, orderType=${o.orderType}, fare=${o.fare}, drop=${o.dropLocation?.address}');
          }

          return Scaffold(
            backgroundColor:  !controller.isPipModeOn.value?null:AppColors.white,
            appBar: controller.isPipModeOn.value?null:CommonBackAppBar(
              title: "On Going Ride",
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: double
                      .infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal:
                  !controller.isPipModeOn.value?10:4,
                      vertical:
                  !controller.isPipModeOn.value?10:2),
                  child: SingleChildScrollView(
                    child: Column(
                    children: [
                      if (!controller.isPipModeOn.value) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              /// Animated Ride Indicator
                              Container(
                                height: 44,
                                width: 44,
                                decoration: BoxDecoration(
                                  color:AppColors.whiteE5,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.bike_scooter,
                                  color: Colors.green,
                                  size: 26,
                                ),
                              ),

                              const SizedBox(width: 12),

                              /// Ride Status Text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    CustomText(
                                      "Ride in Progress",
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      // color: bl,
                                    ),
                                    SizedBox(height: 2),
                                    CustomText(
                                      "Heading to drop location",
                                      fontSize: 12,
                                      color: AppColors.grayText,
                                    ),
                                  ],
                                ),
                              ),

                              /// Live Dot
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const CustomText(
                                  "LIVE",
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // All ongoing orders as mini cards (tappable → navigate to map)
                      ...orders.map((order) => _buildFareCallMiniCard(order)),
                    ],
                  ),
                  ),
                ),
              ),
            ),
          );
        })

    );
  }

  Widget _buildContent(bool isPip,RiderOrdersDetailsModel orders) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.white
      ),
      padding: EdgeInsets.symmetric(horizontal: !isPip ? 10 : 0,vertical: !isPip ?  10:0),
      margin: EdgeInsets.symmetric(vertical: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // if (!isPip) ...[
          // const SizedBox(height: 8),
            CustomText(
              "Ongoing Ride",
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 8),
          // ],

          /// Drop Location
          Container(
            padding: EdgeInsets.all(isPip ? 10 : 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.whiteE5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "DROP LOCATION",
                  fontSize: isPip ? 13 : 12,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
                const SizedBox(height: 4),
                CustomText(
                  "${orders.dropLocation?.address}",
                  fontSize: isPip ? 14 : 13,
                  color: Colors.black54,
                  maxLines: isPip ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _slideToComplete(isPip),
        ],
      ),
    );
  }

  Widget _slideToComplete(bool isPip) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sliderWidth = constraints.maxWidth;
        final buttonWidth = isPip ? 64.0 : 56.0;

        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.whiteE5,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Stack(
            children: [
              Center(
                child: CustomText(
                  "Slide to complete",
                  fontSize: isPip ? 15 : 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Positioned(
                left: dragX,
                child: GestureDetector(
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
                        const SnackBar(content: Text("Order Completed")),
                      );
                    }
                    setState(() => dragX = 0);
                  },
                  child: Container(
                    height:48,
                    width: buttonWidth,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(32),
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
