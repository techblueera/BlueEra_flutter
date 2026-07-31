import 'dart:async';

import 'package:BlueEra/widgets/static_map_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../track_live_location/track_live_location.dart';
import 'component_widgets.dart';
import '../../../common/auth/controller/auth_controller.dart';

class LiveLocationMessageCard extends StatefulWidget {
  final Messages? messages;
  final String? message;
  final double lat;
  final double long;
  final String time;
  final bool isReceiveMsg;
  final ChatThemeController chatThemeController;

  const LiveLocationMessageCard({
    super.key,
    required this.messages,
    required this.message,
    required this.lat,
    required this.long,
    required this.time,
    required this.isReceiveMsg,
    required this.chatThemeController,
  });

  @override
  State<LiveLocationMessageCard> createState() =>
      _LiveLocationMessageCardState();
}

class _LiveLocationMessageCardState extends State<LiveLocationMessageCard> {
  /// Where the share was when the message was sent. Fixed for the life of this
  /// card — the moving position is [TrackLiveLocationPage]'s job, which is what
  /// the bubble taps through to.
  late LatLng _currentPosition;
  Timer? _expiryTimer;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _currentPosition = (widget.messages?.myMessage == true)
        ? LatLng(widget.lat, widget.long)
        : LatLng(
            double.parse("${widget.messages?.latitude ?? "0"}"),
            double.parse("${widget.messages?.longitude ?? "0"}"),
          );
    _initExpiryState();
  }

  void _initExpiryState() {
    // Use server-provided isEnded flag as initial state
    if (widget.messages?.isEnded == true) {
      _isExpired = true;
      return;
    }

    // Schedule client-side timer for live → ended transition
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
        // Fallback: use validity-based calculation
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 256,
      width: 257,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: widget.isReceiveMsg
            ? widget.chatThemeController.receiveMessageBgColor.value
            : widget.chatThemeController.myMessageBgColor.value,
      ),
      padding: const EdgeInsets.all(2),
      child: Align(
        alignment: widget.isReceiveMsg
            ? Alignment.centerLeft
            : Alignment.centerRight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMapView(context),
                    if (widget.message != null) const SizedBox(height: 10),
                    if (widget.message != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMessageText(),
                          timeAndReadInfoWidget(
                            message: widget.messages!,
                            isMyMessage: widget.messages?.myMessage ?? false,
                            time: widget.time,
                            timeColor: AppColors.black,
                            indicateColor:
                                widget.messages?.messageRead == 1
                                    ? Colors.blue
                                    : Colors.grey,
                          )
                        ],
                      ),
                    if (widget.message != null) const SizedBox(height: 10),
                    _isExpired
                        ? Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey.shade100,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            child: Center(
                              child: CustomText(
                                "Live Location Ended",
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : InkWell(
                            onTap: () {
                              Get.to(() => TrackLiveLocationPage(
                                  messages: widget.messages));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.white,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Center(
                                child: CustomText(
                                  "View Live Location",
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The map thumbnail in the bubble.
  ///
  /// A **picture**, not a live `GoogleMap`. Chat rows are disposed when they
  /// scroll out of view and rebuilt when they scroll back, so the interactive
  /// map this replaced bought a Dynamic Maps load on every single pass — and a
  /// busy thread can hold several location shares. [StaticMapPreview] is a
  /// cheaper SKU *and* disk-cached, so the second view onwards is free.
  /// See `docs/GOOGLE_MAPS_COST_GUIDE.md` §3.5.
  ///
  /// Nothing is lost by it: the coordinate here is fixed at [initState] and
  /// never updates (the live position lives on [TrackLiveLocationPage], which
  /// this taps through to), and in-bubble pan/zoom on a 254px thumbnail was not
  /// how anyone read this card.
  Widget _buildMapView(BuildContext context) {
    final height = widget.message != null ? 160.0 : 238.0;
    return GestureDetector(
      onTap: () {
        if (_isExpired) return;
        Get.to(() => TrackLiveLocationPage(messages: widget.messages));
      },
      child: SizedBox(
        height: height,
        width: 254,
        child: Stack(
          alignment: Alignment.center,
          children: [
            StaticMapPreview(
              latitude: _currentPosition.latitude,
              longitude: _currentPosition.longitude,
              width: 254,
              height: height,
              desaturated: _isExpired,
              // The avatar below is the marker; Google's pin would sit on top
              // of it.
              showMarker: false,
            ),
            _profileMarker(),
          ],
        ),
      ),
    );
  }

  /// The sender's photo, centred on the map — the same cue the custom
  /// [BitmapDescriptor] marker used to give, now drawn as a plain widget over
  /// the static image instead of being rasterised into a live map.
  Widget _profileMarker() {
    final imageUrl = (widget.messages?.myMessage == true)
        ? Get.find<AuthController>().imgPath.value
        : widget.messages?.sender?.profileImage ?? '';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(color: AppColors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.trim().isEmpty
          ? const Icon(Icons.person, size: 24, color: AppColors.grayText)
          : CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => const ColoredBox(color: AppColors.greyE5),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.person, size: 24, color: AppColors.grayText),
            ),
    );
  }

  String calculateExpiredAtTime({
    required String createdAtIso,
    required String durationLabel,
  }) {
    // If we have live_location_expires_at, use it directly
    final expiresAt = widget.messages?.live_location_expires_at;
    if (expiresAt != null && expiresAt.isNotEmpty) {
      try {
        final expiredAt = DateTime.parse(expiresAt).toLocal();
        final hour = expiredAt.hour % 12 == 0 ? 12 : expiredAt.hour % 12;
        final minute = expiredAt.minute.toString().padLeft(2, '0');
        final period = expiredAt.hour >= 12 ? "PM" : "AM";
        return "$hour:$minute $period";
      } catch (_) {}
    }

    // Fallback to createdAt + validity calculation
    final createdAt = DateTime.parse(createdAtIso).toLocal();

    Duration duration;
    if (durationLabel.endsWith("min")) {
      final mins = int.parse(durationLabel.replaceAll("min", ""));
      duration = Duration(minutes: mins);
    } else if (durationLabel.endsWith("h")) {
      final hrs = int.parse(durationLabel.replaceAll("h", ""));
      duration = Duration(hours: hrs);
    } else {
      duration = Duration.zero;
    }

    final expiredAt = createdAt.add(duration);
    final hour = expiredAt.hour % 12 == 0 ? 12 : expiredAt.hour % 12;
    final minute = expiredAt.minute.toString().padLeft(2, '0');
    final period = expiredAt.hour >= 12 ? "PM" : "AM";

    return "$hour:$minute $period";
  }

  Widget _buildMessageText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isExpired
                    ? Icons.location_off_rounded
                    : Icons.share_location_rounded,
                size: 16,
                color: _isExpired ? Colors.grey : AppColors.black,
              ),
              const SizedBox(width: 6),
              CustomText(
                _isExpired
                    ? "Location ended"
                    : "Live Until ${calculateExpiredAtTime(createdAtIso: widget.messages?.createdAt ?? '', durationLabel: widget.message ?? '')}",
                maxLines: 1,
                fontWeight: FontWeight.w500,
                color: _isExpired ? Colors.grey : AppColors.black,
                fontSize: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
