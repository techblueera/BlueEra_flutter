import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../auth/controller/call_controller.dart';
import 'rider_pickup_navigation_screen.dart';

/// Incoming ride request screen for the rider.
/// Reads ride details from [CallController.fareCallRideDetails] metadata.
/// Shown when a fare-call type incoming call is detected.
class IncomingRiderOrderScreen extends StatefulWidget {
  const IncomingRiderOrderScreen({super.key});

  @override
  State<IncomingRiderOrderScreen> createState() =>
      _IncomingRiderOrderScreenState();
}

class _IncomingRiderOrderScreenState extends State<IncomingRiderOrderScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _timerController;
  final AudioPlayer _ringtonePlayer = AudioPlayer();
  late Timer _countdownTimer;
  late Worker _callStatusWorker;
  int _remainingSeconds = 45; // 45s as per backend timeout
  bool _isAccepting = false;

  // Ride details extracted from CallController metadata
  late final CallController _callController;
  late final String _pickupAddress;
  late final String _dropAddress;
  late final double _pickupLat;
  late final double _pickupLng;
  late final double _dropLat;
  late final double _dropLng;
  late final double _fare;
  late final double _distance;
  late final String _customerName;
  late final String _customerImage;
  late final String _paymentMethod;

  @override
  void initState() {
    super.initState();

    _callController = Get.find<CallController>();
    final ride = _callController.fareCallRideDetails.value;

    // Extract ride details from metadata
    _pickupAddress = ride?['pickup']?['address'] ?? 'Pickup location';
    _dropAddress = ride?['drop']?['address'] ?? 'Drop location';
    _pickupLat = _toDouble(ride?['pickup']?['lat']);
    _pickupLng = _toDouble(ride?['pickup']?['lng']);
    _dropLat = _toDouble(ride?['drop']?['lat']);
    _dropLng = _toDouble(ride?['drop']?['lng']);
    _fare = _toDouble(ride?['fare']);
    _distance = _toDouble(ride?['distance']);
    _customerName = _callController.callerName.value.isNotEmpty
        ? _callController.callerName.value
        : 'Customer';
    _customerImage = _callController.callerImage.value;
    _paymentMethod = ride?['modeOfPayment'] ?? 'postpaid';

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..forward();

    _playRingtone();
    HapticFeedback.heavyImpact();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _stopRingtone();
          // Auto-decline: backend handles timeout, just close screen
          _callController.declineCall();
        }
      });
    });

    // Watch call status — if call cancelled/ended externally, close this screen
    _callStatusWorker = ever(_callController.callStatus, (status) {
      if (!mounted) return;
      if (status == CallStatus.idle || status == CallStatus.ended) {
        _stopRingtone();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _playRingtone() async {
    try {
      await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
      await _ringtonePlayer.play(AssetSource('sound/iphone_tone.mp3'));
    } catch (_) {}
  }

  void _stopRingtone() {
    _ringtonePlayer.stop();
  }

  @override
  void dispose() {
    _callStatusWorker.dispose();
    _countdownTimer.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    _timerController.dispose();
    _ringtonePlayer.stop();
    _ringtonePlayer.dispose();
    super.dispose();
  }

  /// Rider taps "Accept Ride" — accept the call first, then accept the ride via API
  Future<void> _onAcceptRide() async {
    _stopRingtone();
    setState(() => _isAccepting = true);

    // 1. Accept the audio call (standard call flow)
    final callAccepted = await _callController.acceptCall();
    if (!callAccepted) {
      if (mounted) setState(() => _isAccepting = false);
      return;
    }

    // 2. Accept the ride via fare-call ride-action API
    final rideAccepted = await _callController.acceptFareCallRide();
    if (!rideAccepted) {
      if (mounted) setState(() => _isAccepting = false);
      return;
    }

    if (!mounted) return;

    // 3. Navigate to pickup navigation map screen
    Get.off(() => RiderPickupNavigationScreen(
          pickupLocation: _pickupAddress,
          dropLocation: _dropAddress,
          pickupLat: _pickupLat,
          pickupLng: _pickupLng,
          dropLat: _dropLat,
          dropLng: _dropLng,
          fareAmount: _fare,
          distanceKm: _distance,
          customerName: _customerName,
          customerImage: _customerImage,
          otp: '', // OTP will be entered by rider from customer
          paymentMethod: _paymentMethod,
        ));
  }

  /// Rider taps "Reject Ride" — reject via API, call ends, next rider called
  Future<void> _onRejectRide() async {
    _stopRingtone();
    await _callController.rejectFareCallRide();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Decline on back press
        _onRejectRide();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1923),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F2027),
                Color(0xFF203A43),
                Color(0xFF0F1923),
              ],
              stops: [0.0, 0.4, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildHeader(),
                const SizedBox(height: 16),
                Expanded(child: _buildRideInfoCard()),
                _buildBottomActions(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final opacity = 0.5 + (_pulseController.value * 0.5);
              return Opacity(opacity: opacity, child: child);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00C853).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delivery_dining_rounded,
                      color: Color(0xFF00C853), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'New Ride Request',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00C853),
                      fontFamily: 'OpenSans',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          _buildCountdownTimer(),
        ],
      ),
    );
  }

  Widget _buildCountdownTimer() {
    final color = _remainingSeconds <= 10
        ? const Color(0xFFFF5252)
        : const Color(0xFF00C853);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: AnimatedBuilder(
              animation: _timerController,
              builder: (context, _) {
                return CircularProgressIndicator(
                  value: 1.0 - _timerController.value,
                  strokeWidth: 3,
                  color: color,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                );
              },
            ),
          ),
          Text(
            '$_remainingSeconds',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'OpenSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideInfoCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildCustomerRow(),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildFareDistanceHeader(),
                Divider(
                    color: Colors.white.withValues(alpha: 0.08), height: 1),
                _buildRouteTimeline(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentChip(),
        ],
      ),
    );
  }

  Widget _buildCustomerRow() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2A3942),
            border: Border.all(
              color: const Color(0xFF00C853).withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: _customerImage.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    _customerImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF8696A0),
                        size: 28),
                  ),
                )
              : const Icon(Icons.person_rounded,
                  color: Color(0xFF8696A0), size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _customerName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'OpenSans',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Customer',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontFamily: 'OpenSans',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFareDistanceHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Icon(Icons.currency_rupee_rounded,
                    color: const Color(0xFF00C853).withValues(alpha: 0.7),
                    size: 20),
                const SizedBox(height: 6),
                Text(
                  '₹${_fare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00C853),
                    fontFamily: 'OpenSans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Estimated Fare',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                    fontFamily: 'OpenSans',
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          Expanded(
            child: Column(
              children: [
                Icon(Icons.route_rounded,
                    color: const Color(0xFF42A5F5).withValues(alpha: 0.7),
                    size: 20),
                const SizedBox(height: 6),
                Text(
                  '${_distance.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF42A5F5),
                    fontFamily: 'OpenSans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total Distance',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                    fontFamily: 'OpenSans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteTimeline() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const SizedBox(height: 3),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00C853),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C853).withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              ...List.generate(
                4,
                (_) => Container(
                  width: 2,
                  height: 8,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF7043),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7043).withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PICKUP',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00C853).withValues(alpha: 0.8),
                    fontFamily: 'OpenSans',
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _pickupAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontFamily: 'OpenSans',
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Text(
                  'DROP-OFF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF7043).withValues(alpha: 0.8),
                    fontFamily: 'OpenSans',
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _dropAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontFamily: 'OpenSans',
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _paymentMethod.toLowerCase() == 'prepaid'
                ? Icons.account_balance_wallet_rounded
                : Icons.money_rounded,
            color: const Color(0xFFFFC107),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            _paymentMethod,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
              fontFamily: 'OpenSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    if (_isAccepting) {
      return Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: Color(0xFF00C853),
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Accepting ride...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              fontFamily: 'OpenSans',
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Reject Ride
          _buildActionButton(
            icon: Icons.close_rounded,
            color: const Color(0xFFEA4335),
            label: 'Reject',
            onTap: _onRejectRide,
          ),
          // Accept Ride
          _buildActionButton(
            icon: Icons.check_rounded,
            color: const Color(0xFF00C853),
            label: 'Accept',
            isAccept: true,
            onTap: _onAcceptRide,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    bool isAccept = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _slideController,
            builder: (context, child) {
              if (!isAccept) return child!;
              final scale = 1.0 + (_slideController.value * 0.08);
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 34),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'OpenSans',
            ),
          ),
        ],
      ),
    );
  }
}
