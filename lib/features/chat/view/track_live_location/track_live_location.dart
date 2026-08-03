import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:BlueEra/core/map/blue_map.dart';
import 'package:BlueEra/core/map/lat_lng.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
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
  BlueMapController? mapController;
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

      // Markers derive from state — nothing to build up front.
    }
  }

  // ---- Custom profile-picture markers ----
  // These used to be rasterised through ProfileLocationMarkerGenerator, which
  // downloaded the avatar, drew it on a canvas and PNG-encoded it because the
  // map would only accept bitmaps. Marker children are widgets now, so an
  // avatar is just an avatar — no encode step, and no default pin showing while
  // it runs.

  /// The sender's pin, once a live position has arrived.
  LatLng? _senderLatLng;

  Widget _avatarMarker(String imageUrl, Color borderColor) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 3),
        ),
        child: ClipOval(
          child: imageUrl.isEmpty
              ? Container(color: borderColor)
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: borderColor),
                ),
        ),
      );

  List<BlueMapMarker> get _markers => [
        if (currentLatLng != null)
          BlueMapMarker(
            id: 'my_marker',
            position: currentLatLng!,
            child: _avatarMarker(_myImage, AppColors.primaryColor),
          ),
        if (_senderLatLng != null)
          BlueMapMarker(
            id: 'sender_marker',
            position: _senderLatLng!,
            child: _avatarMarker(_senderImage, Colors.green),
          ),
      ];

  void _updateSenderMarker(double lat, double lng) async {
    if (mounted) setState(() => _senderLatLng = LatLng(lat, lng));

    // Fit both markers
    _fitBothMarkers(LatLng(lat, lng));
  }

  void _fitBothMarkers(LatLng senderPos) {
    final me = currentLatLng;
    if (me == null) return;
    mapController?.fitPoints([me, senderPos], padding: 80);
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
        title: AppStrings.liveLocationLabel.tr,
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(strokeWidth: 2),
                const SizedBox(height: 16),
                CustomText(AppStrings.gettingLocation.tr,
                    color: Colors.grey, fontSize: 14),
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
              child: BlueMap(
                initialCenter: initialTarget,
                initialZoom: 15,
                markers: _markers,
                onMapCreated: (controller) {
                  mapController = controller;
                  // If sender location is already available, fit bounds. No
                  // delay: BlueMap queues camera work until the map is ready,
                  // which is what the 500ms was guessing at.
                  if (senderLat != null && senderLng != null && senderLat != 0) {
                    _fitBothMarkers(LatLng(senderLat, senderLng));
                  }
                },
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
                          ? AppStrings.liveLocationEnded.tr
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
                  : AppStrings.waitingForLocation.tr,
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
                  mapController?.moveTo(LatLng(lat, lng), zoom: 16);
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
