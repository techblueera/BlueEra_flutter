import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../widgets/cached_avatar_widget.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../common/auth/controller/auth_controller.dart';
import '../../../common/Discover/widget/tooltip_generator.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../../auth/socket/live_location_track_socket.dart';

class TrackLiveLocationPage extends StatefulWidget {
  const TrackLiveLocationPage({super.key, required this.messages});

  final Messages? messages;

  @override
  State<TrackLiveLocationPage> createState() => _TrackLiveLocationPageState();
}

class _TrackLiveLocationPageState extends State<TrackLiveLocationPage> {
  GoogleMapController? mapController;
  final chatThemeController = getOrPut(() => ChatThemeController());
  final chatViewController = getOrPut(() => ChatViewController());
  LatLng? currentLatLng;
  Timer? _expiryTimer;
  bool _isExpired = false;

  /// Sender (the other person) info
  String get _senderName => widget.messages?.sender?.name ?? 'User';
  String get _senderImage => widget.messages?.sender?.profileImage ?? '';

  /// My info
  String get _myName => userNameGlobal.isNotEmpty ? userNameGlobal : 'You';
  String get _myImage {
    try {
      return Get.find<AuthController>().imgPath.value;
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _initExpiryState();
    _determinePosition();
  }

  void _initExpiryState() {
    if (widget.messages?.isEnded == true) {
      _isExpired = true;
      return;
    }

    final expiresAt = widget.messages?.live_location_expires_at;
    if (expiresAt != null && expiresAt.isNotEmpty) {
      try {
        final expiryTime = DateTime.parse(expiresAt);
        final remaining = expiryTime.difference(DateTime.now());
        if (remaining.isNegative) {
          _isExpired = true;
        } else {
          _expiryTimer = Timer(remaining, () {
            if (mounted) {
              setState(() {
                _isExpired = true;
              });
            }
          });
        }
      } catch (_) {
        _initExpiryFromValidity();
      }
    } else {
      _initExpiryFromValidity();
    }
  }

  void _initExpiryFromValidity() {
    final createdAt = widget.messages?.createdAt;
    final validity = widget.messages?.live_location_validity;
    if (createdAt == null || validity == null) return;

    try {
      final created = DateTime.parse(createdAt);
      Duration duration;
      if (validity.endsWith("min")) {
        duration = Duration(minutes: int.parse(validity.replaceAll("min", "")));
      } else if (validity.endsWith("h")) {
        duration = Duration(hours: int.parse(validity.replaceAll("h", "")));
      } else {
        return;
      }

      final expiryTime = created.add(duration);
      final remaining = expiryTime.difference(DateTime.now());
      if (remaining.isNegative) {
        _isExpired = true;
      } else {
        _expiryTimer = Timer(remaining, () {
          if (mounted) {
            setState(() {
              _isExpired = true;
            });
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    LiveTrackingSocketService().disconnectSocket();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    final permission = await Permission.location.request();
    if (permission.isGranted) {
      Position pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      if (!mounted) return;
      setState(() {
        currentLatLng = LatLng(pos.latitude, pos.longitude);
      });

      chatThemeController.viewLiverLocationReceivedUserId.value =
          widget.messages?.senderId ?? '';
      chatThemeController.connectSocket(widget.messages?.senderId ?? '');

      _buildCustomMarkers();
    }
  }

  // ---- Custom profile-picture markers ----
  final Set<Marker> _markers = {};

  Future<void> _buildCustomMarkers() async {
    if (currentLatLng == null) return;

    // Build my marker
    try {
      if (_myImage.isNotEmpty) {
        final Uint8List myBytes = await ProfileLocationMarkerGenerator
            .createMarker(
                imageUrl: _myImage,
                imageSize: 70,
                borderWidth: 3,
                borderColor: AppColors.primaryColor);
        _markers.add(Marker(
          markerId: const MarkerId('my_marker'),
          position: currentLatLng!,
          icon: BitmapDescriptor.bytes(myBytes),
          anchor: const Offset(0.5, 0.5),
        ));
      } else {
        _markers.add(Marker(
          markerId: const MarkerId('my_marker'),
          position: currentLatLng!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ));
      }
    } catch (_) {
      _markers.add(Marker(
        markerId: const MarkerId('my_marker'),
        position: currentLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }

    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _getSenderMarkerIcon() async {
    try {
      if (_senderImage.isNotEmpty) {
        final Uint8List bytes = await ProfileLocationMarkerGenerator
            .createMarker(
                imageUrl: _senderImage,
                imageSize: 70,
                borderWidth: 3,
                borderColor: Colors.green);
        return BitmapDescriptor.bytes(bytes);
      }
    } catch (_) {}
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  void _updateSenderMarker(double lat, double lng) async {
    final senderIcon = await _getSenderMarkerIcon();
    _markers.removeWhere((m) => m.markerId.value == 'sender_marker');
    _markers.add(Marker(
      markerId: const MarkerId('sender_marker'),
      position: LatLng(lat, lng),
      icon: senderIcon,
      anchor: const Offset(0.5, 0.5),
    ));
    if (mounted) setState(() {});

    // Fit both markers
    _fitBothMarkers(LatLng(lat, lng));
  }

  void _fitBothMarkers(LatLng senderPos) {
    if (currentLatLng == null || mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        min(currentLatLng!.latitude, senderPos.latitude),
        min(currentLatLng!.longitude, senderPos.longitude),
      ),
      northeast: LatLng(
        max(currentLatLng!.latitude, senderPos.latitude),
        max(currentLatLng!.longitude, senderPos.longitude),
      ),
    );

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  /// Haversine distance in km
  double _calculateDistanceKm(LatLng a, LatLng b) {
    const R = 6371.0; // Earth radius in km
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final sinLat = sin(dLat / 2);
    final sinLon = sin(dLon / 2);
    final calc = sinLat * sinLat +
        cos(_degToRad(a.latitude)) *
            cos(_degToRad(b.latitude)) *
            sinLon *
            sinLon;
    return R * 2 * atan2(sqrt(calc), sqrt(1 - calc));
  }

  double _degToRad(double deg) => deg * (pi / 180);

  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m away';
    } else {
      return '${km.toStringAsFixed(1)} km away';
    }
  }

  String _calculateExpiry() {
    // Use live_location_expires_at if available
    final expiresAt = widget.messages?.live_location_expires_at;
    if (expiresAt != null && expiresAt.isNotEmpty) {
      try {
        final expiry = DateTime.parse(expiresAt).toLocal();
        final hour = expiry.hour % 12 == 0 ? 12 : expiry.hour % 12;
        final minute = expiry.minute.toString().padLeft(2, '0');
        final period = expiry.hour >= 12 ? "PM" : "AM";
        return "$hour:$minute $period";
      } catch (_) {}
    }

    // Fallback to createdAt + validity
    final createdAt = widget.messages?.createdAt;
    final validity = widget.messages?.live_location_validity;
    if (createdAt == null || validity == null) return '';

    try {
      final created = DateTime.parse(createdAt).toLocal();
      Duration duration;
      if (validity.endsWith("min")) {
        duration =
            Duration(minutes: int.parse(validity.replaceAll("min", "")));
      } else if (validity.endsWith("h")) {
        duration = Duration(hours: int.parse(validity.replaceAll("h", "")));
      } else {
        return '';
      }

      final expiry = created.add(duration);
      final hour = expiry.hour % 12 == 0 ? 12 : expiry.hour % 12;
      final minute = expiry.minute.toString().padLeft(2, '0');
      final period = expiry.hour >= 12 ? "PM" : "AM";
      return "$hour:$minute $period";
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMyMessage = widget.messages?.myMessage == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonBackAppBar(
        title: "Live location",
        isShadowShow: false,
      ),
      body: Obx(() {
        final senderLoc = chatThemeController.senderLiveLocation.value;
        final senderLat = senderLoc.latitude;
        final senderLng = senderLoc.longitude;

        // Update sender marker when location changes
        if (senderLat != null && senderLng != null && senderLat != 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateSenderMarker(senderLat, senderLng);
          });
        }

        final bool ready = isMyMessage
            ? (currentLatLng != null)
            : (senderLat != null && senderLat != 0);

        if (!ready) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 2),
                SizedBox(height: 16),
                Text('Getting location...',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          );
        }

        final initialTarget = isMyMessage
            ? currentLatLng!
            : LatLng(senderLat ?? 0, senderLng ?? 0);

        // Calculate distance
        String distanceText = '';
        if (currentLatLng != null && senderLat != null && senderLng != null && senderLat != 0) {
          final dist =
              _calculateDistanceKm(currentLatLng!, LatLng(senderLat, senderLng));
          distanceText = _formatDistance(dist);
        }

        final expiryTime = _calculateExpiry();

        return Column(
          children: [
            // ---- Map ----
            Expanded(
              child: GoogleMap(
                onMapCreated: (controller) {
                  mapController = controller;
                  // If sender location already available, fit bounds
                  if (senderLat != null && senderLng != null && senderLat != 0) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      _fitBothMarkers(LatLng(senderLat, senderLng));
                    });
                  }
                },
                initialCameraPosition: CameraPosition(
                  target: initialTarget,
                  zoom: 15.0,
                ),
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                markers: _markers,
                padding: const EdgeInsets.only(bottom: 200),
              ),
            ),

            // ---- Bottom panel (WhatsApp style) ----
            _buildBottomPanel(
              senderLat: senderLat,
              senderLng: senderLng,
              distanceText: distanceText,
              expiryTime: expiryTime,
              isMyMessage: isMyMessage,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildBottomPanel({
    double? senderLat,
    double? senderLng,
    required String distanceText,
    required String expiryTime,
    required bool isMyMessage,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live location header
            if (expiryTime.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: _isExpired ? Colors.grey.shade100 : Colors.green.shade50,
                child: Row(
                  children: [
                    Icon(
                        _isExpired
                            ? Icons.location_off_rounded
                            : Icons.share_location_rounded,
                        size: 18,
                        color: _isExpired
                            ? Colors.grey
                            : Colors.green.shade700),
                    const SizedBox(width: 8),
                    CustomText(
                      _isExpired
                          ? "Live location ended"
                          : "Live until $expiryTime",
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _isExpired
                          ? Colors.grey
                          : Colors.green.shade700,
                    ),
                  ],
                ),
              ),

            // Sender row
            _buildUserRow(
              name: _senderName,
              imageUrl: _senderImage,
              subtitle: (senderLat != null && senderLat != 0)
                  ? distanceText
                  : 'Waiting for location...',
              borderColor: Colors.green,
              isOnline: senderLat != null && senderLat != 0,
            ),

            Divider(height: 1, color: Colors.grey.shade200),

            // My row
            _buildUserRow(
              name: _myName,
              imageUrl: _myImage,
              subtitle: currentLatLng != null ? 'You' : 'Getting location...',
              borderColor: AppColors.primaryColor,
              isOnline: currentLatLng != null,
              isMe: true,
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRow({
    required String name,
    required String imageUrl,
    required String subtitle,
    required Color borderColor,
    bool isOnline = false,
    bool isMe = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Profile picture with border
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2.5),
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: imageUrl.isNotEmpty
                      ? CachedAvatarWidget(
                          imageUrl: imageUrl,
                          size: 40,
                          borderRadius: 20,
                          showProfileOnFullScreen: false,
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: Icon(Icons.person,
                              color: Colors.grey.shade600, size: 24),
                        ),
                ),
              ),
              // Online indicator dot
              if (isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Name and distance
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  isMe ? '$name (You)' : name,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                const SizedBox(height: 2),
                CustomText(
                  subtitle,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isOnline ? Colors.grey.shade600 : Colors.orange,
                ),
              ],
            ),
          ),

          // Navigate button
          if (isOnline && !isMe)
            InkWell(
              onTap: () {
                // Center map on this user
                final lat =
                    chatThemeController.senderLiveLocation.value.latitude;
                final lng =
                    chatThemeController.senderLiveLocation.value.longitude;
                if (lat != null && lng != null) {
                  mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
                  );
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.my_location,
                    size: 20, color: AppColors.primaryColor),
              ),
            ),
        ],
      ),
    );
  }
}
