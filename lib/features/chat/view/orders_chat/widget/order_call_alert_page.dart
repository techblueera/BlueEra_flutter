import 'dart:async';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../core/services/notifications/default_ringtone.dart';
import '../../../../../core/services/notifications/ride_notification_data_model.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../common/delivery_partner/controller/delivery_partner_orders_controller.dart';

class ModernSwipeToAction extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const ModernSwipeToAction({
    super.key,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<ModernSwipeToAction> createState() => _ModernSwipeToActionState();
}

class NewDeliveryRequestScreen extends StatefulWidget {
  final String orderId;
  final String customerImage;
  final String distance;
  final String pickupAddress;
  final String dropAddress;
  final NotificationData notificationData;
  final String amount;

  const NewDeliveryRequestScreen({
    super.key,
    required this.orderId,
    required this.customerImage,
    required this.distance,
    required this.pickupAddress,
    required this.amount,
    required this.dropAddress,
    required this.notificationData,
  });

  @override
  State<NewDeliveryRequestScreen> createState() =>
      _NewDeliveryRequestScreenState();
}

class _NewDeliveryRequestScreenState extends State<NewDeliveryRequestScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> glow;
  Timer? _autoEndTimer;
  final orderController = Get.isRegistered<DeliverPartnerOrdersController>()
      ? Get.find<DeliverPartnerOrdersController>()
      : Get.put(DeliverPartnerOrdersController());

  void handleRejectOrder(String orderId) {
    orderController.updateOrderStatusFromPialot(
      {ApiKeys.action: "reject"},
      orderId,
    );
  }

  void handleAcceptOrder(String orderId) {
    orderController.updateOrderStatusFromPialot(
      {ApiKeys.action: "accept"},
      orderId,
    );
  }

  Future<double?> getDistanceInKm(double destLat, double destLng) async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null; // Permission not given
      }

      // Check if GPS is enabled
      bool isLocationOn = await Geolocator.isLocationServiceEnabled();
      if (!isLocationOn) {
        await Geolocator.openLocationSettings();
        return null;
      }

      // Get current location
      Position current = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);

      // Calculate distance in meters
      double distanceInMeters = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        destLat,
        destLng,
      );

      // Convert to KM
      return double.parse((distanceInMeters / 1000).toStringAsFixed(2));
    } catch (e) {
      print("Error getting distance: $e");
      return null;
    }
  }

  double? kmFromPickupLocation;
  double? kmFromDropLocation;

  Future<void> getLocationInKm() async {
    kmFromPickupLocation = await getDistanceInKm(
        double.parse(
            widget.notificationData.metadata?.dropAddress?.lat.toString() ??
                ''),
        double.parse(
            widget.notificationData.metadata?.dropAddress?.long.toString() ??
                ''));
    kmFromDropLocation = await getDistanceInKm(
        double.parse(widget.notificationData.metadata?.deliveredAddress?.lat
                .toString() ??
            ''),
        double.parse(widget.notificationData.metadata?.deliveredAddress?.long
                .toString() ??
            ''));
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    DefaultRingtone.play();
    getLocationInKm();
    // _autoEndTimer = Timer(const Duration(seconds: 30), () {
    //   DefaultRingtone.stop();
    //   if (mounted) Navigator.pop(context); // auto dismiss
    // });
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);

    glow = Tween<double>(begin: 0.8, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _autoEndTimer?.cancel();
    DefaultRingtone.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌙 Diagonal layered background
          Positioned.fill(
            child: RotateScaleAnimation(
              // offset: 12,    // how much shake (try 8–15)
              // duration: 160, // speed (lower = faster)
              child: _buildDiagonalBackground(),
            ),
          ),

          // ⭐
          //
          // Floating delivery icon bubble
          Positioned(
            top: 90,
            left: 0,
            right: 0,
            child: ScaleTransition(
              scale: glow,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withOpacity(0.15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.delivery_dining_rounded,
                    color: Colors.orange,
                    size: 65,
                  ),
                ),
              ),
            ),
          ),

          // 🌟 Main card
          Positioned(
            top: 210,
            left: 25,
            right: 25,
            child: _buildMainRequestCard(),
          ),

          // ⭐ Bottom slider buttons
          Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: // speed (lower = faster)
                  _buildBottomActions()),
        ],
      ),
    );
  }

  // ------------------------------
  //  BACKGROUND
  // ------------------------------
  Widget _buildDiagonalBackground() {
    return Stack(
      children: [
        // Container(color: Colors.black),

        Transform.rotate(
          angle: -0.4,
          child: Container(
            margin: const EdgeInsets.only(top: 40),
            height: 450,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0.8),
                  AppColors.primaryColor.withOpacity(0.4),
                ],
              ),
            ),
          ),
        ),

        Transform.rotate(
          angle: -0.35,
          child: Container(
            margin: const EdgeInsets.only(top: 50),
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  Colors.blueGrey.shade900,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------
  //  MAIN CARD
  // ------------------------------
  Widget _buildMainRequestCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SizeConfig.size25),
        color: AppColors.white,
        border: Border.all(color: AppColors.grayText.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size10),

          Center(
            child: CustomText(
              AppStrings.newDeliveryRequest,
              color: Colors.black,
              fontSize: SizeConfig.size20,
              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(height: SizeConfig.size16),

          /// ---------- Pickup Section ----------
          commonSectionCard(
            title: AppStrings.pickupAddress,
            children: [
              _infoTile(Icons.store_rounded, "${widget.pickupAddress}"),
              _infoTile(Icons.location_on_outlined,
                  "${kmFromPickupLocation ?? "${AppStrings.findingDistance.tr}"}${kmFromPickupLocation != null ? "${AppStrings.kmFare.tr}" : ''}"),
            ],
          ),

          SizedBox(height: SizeConfig.size12),

          /// ---------- Drop Section ----------
          commonSectionCard(
            title: AppStrings.dropAddress,
            children: [
              _infoTile(Icons.store_rounded, '${widget.dropAddress}'),
              _infoTile(Icons.location_on_outlined,
                  "${kmFromDropLocation ?? "${AppStrings.findingDistance.tr}"}${kmFromDropLocation != null ? "${AppStrings.kmFare.tr}" : ''}"),
            ],
          ),

          SizedBox(height: SizeConfig.size20),

          /// ---------- Fare Section ----------
          Container(
            margin: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
            decoration: BoxDecoration(
              color: AppColors.grayText.withOpacity(0.1),
              borderRadius: BorderRadius.circular(SizeConfig.size10),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size18,
                vertical: SizeConfig.size10,
              ),
              child: Center(
                child: CustomText(
                  "${AppStrings.fareAmount.tr}: ₹ ${widget.amount}",
                  color: AppColors.black,
                  fontSize: SizeConfig.size18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          SizedBox(height: SizeConfig.size24),
        ],
      ),
    );
  }

  Widget commonSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.grayText.withOpacity(0.1),
        borderRadius: BorderRadius.circular(SizeConfig.size10),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size18,
          vertical: SizeConfig.size10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              title,
              color: AppColors.primaryColor,
              fontSize: SizeConfig.size16,
              fontWeight: FontWeight.w700,
            ),
            SizedBox(height: SizeConfig.size8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: CustomText(
              value,
              color: AppColors.black,
              maxLines: 2,
              fontWeight: FontWeight.w600,
              fontSize: SizeConfig.size16,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  //  BOTTOM SLIDER BUTTONS
  // ------------------------------
  Widget _buildBottomActions() {
    return ModernSwipeToAction(
      onAccept: () {
        handleAcceptOrder(widget.orderId);
        Navigator.pop(context, "accept");
      },
      onReject: () {
        handleRejectOrder(widget.orderId);
        Navigator.pop(context, "reject");
      },
    );
  }


}

class _ModernSwipeToActionState extends State<ModernSwipeToAction>
    with SingleTickerProviderStateMixin {
  double _dragX = 0;
  final double _dragThreshold = 120;

  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double blink = 0.6 + (_blinkController.value * 0.4);

    return Stack(
      alignment: Alignment.center,
      children: [
        // -------------------------
        // LEFT DECLINE INDICATOR
        // -------------------------
        Positioned(
          left: 10,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _dragX < -20 ? 1 : 0.4,
            child: Row(
              children: [
                Icon(Icons.keyboard_double_arrow_left,
                    size: 30, color: Colors.red.withOpacity(blink)),
                const SizedBox(width: 5),
                CustomText(
                  AppStrings.decline,
                  color: Colors.red.withOpacity(blink),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ],
            ),
          ),
        ),

        // -------------------------
        // RIGHT ACCEPT INDICATOR
        // -------------------------
        Positioned(
          right: 10,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _dragX > 20 ? 1 : 0.4,
            child: Row(
              children: [
                CustomText(
                  AppStrings.accept,
                  color: Colors.green.withOpacity(blink),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                const SizedBox(width: 5),
                Icon(Icons.keyboard_double_arrow_right,
                    size: 30, color: Colors.green.withOpacity(blink)),
              ],
            ),
          ),
        ),

        // -------------------------
        // MAIN SWIPE BUTTON
        // -------------------------
        ShakeAnimation(
          offset: 12, // how much it shakes left-right
          shakeDuration: 500, // speed of one shake
          interval: 2000,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragX += details.delta.dx;
              });
            },
            onHorizontalDragEnd: (_) {
              if (_dragX > _dragThreshold) {
                widget.onAccept();
              } else if (_dragX < -_dragThreshold) {
                widget.onReject();
              }

              setState(() => _dragX = 0);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(_dragX, 0, 0),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: LinearGradient(
                  colors: _dragX > 0
                      ? [Colors.greenAccent, Colors.green]
                      : _dragX < 0
                          ? [Colors.redAccent, Colors.red]
                          : [
                              Colors.white.withOpacity(0.8),
                              Colors.grey.shade200,
                            ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _dragX == 0
                        ? Colors.blue.withOpacity(blink * 0.3)
                        : Colors.black.withOpacity(0.2),
                    blurRadius: _dragX == 0 ? 30 : 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_dragX < 0) ...[
                    const Icon(Icons.close, color: Colors.white, size: 28),
                    const SizedBox(width: 8),
                    const CustomText(AppStrings.swipeToDecline,
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ],
                  if (_dragX == 0) ...[
                    Icon(Icons.swipe,
                        color: Colors.blue.withOpacity(blink), size: 28),
                    const SizedBox(width: 12),
                    CustomText(
                      AppStrings.swipe,
                      color: Colors.black.withOpacity(0.7),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                  if (_dragX > 0) ...[
                    const CustomText(AppStrings.swipeToAccept,
                        color: Colors.white, fontWeight: FontWeight.bold),
                    const SizedBox(width: 8),
                    const Icon(Icons.check, color: Colors.white, size: 28),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final double offset;
  final int shakeDuration; // one shake time (ms)
  final int interval; // wait time after one shake (ms)

  const ShakeAnimation({
    super.key,
    required this.child,
    this.offset = 10,
    this.shakeDuration = 180, // small shake
    this.interval = 3000, // 3 seconds wait
  });

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isStoppedByTouch = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.shakeDuration),
    );

    _animation = Tween<double>(
      begin: -widget.offset,
      end: widget.offset,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _startShakeLoop();
  }

  /// 🔥 Shake once → wait → shake again
  void _startShakeLoop() async {
    while (!_isStoppedByTouch && mounted) {
      await _controller.forward();
      await _controller.reverse();

      if (_isStoppedByTouch || !mounted) return;

      await Future.delayed(Duration(milliseconds: widget.interval));
    }
  }

  void _stopShake() {
    if (!_isStoppedByTouch && mounted) {
      setState(() {
        _isStoppedByTouch = true;
        _controller.stop();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _stopShake,
      // onPanDown: (_) => _stopShake(),

      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          double value = _isStoppedByTouch ? 0 : _animation.value;
          return Transform.translate(offset: Offset(value, 0), child: child);
        },
        child: widget.child,
      ),
    );
  }
}

class RotateScaleAnimation extends StatefulWidget {
  final Widget child;

  const RotateScaleAnimation({super.key, required this.child});

  @override
  State<RotateScaleAnimation> createState() => _RotateScaleAnimationState();
}

class _RotateScaleAnimationState extends State<RotateScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotate;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true); // smooth back & forth

    _rotate = Tween<double>(
      begin: -0.03, // slight left tilt
      end: 0.03, // slight right tilt
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scale = Tween<double>(
      begin: 1.0, // original size
      end: 0.92, // shrink slightly
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Transform.rotate(
          angle: _rotate.value, // rotation
          child: Transform.scale(
            scale: _scale.value, // scaling
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
