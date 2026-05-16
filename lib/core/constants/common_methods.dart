import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:flutter/material.dart' hide Key;
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../features/common/service/model/get_service_model.dart';
import 'app_colors.dart';

///SHOW APP LOGS
logs(String logMsg) {
  log(logMsg);
}

///UN FOCUS KEYBOARD
unFocus() {
  FocusManager.instance.primaryFocus?.unfocus();
}

///DATE FORMAT
dateFormatddMMyyyy(DateTime date) {
  return DateFormat('dd-MM-yyyy').format(date);
}

/// Helper to convert month number to short name
String getMonthName(int monthNumber) {
  switch (monthNumber) {
    case 1:
      return 'Jan';
    case 2:
      return 'Feb';
    case 3:
      return 'Mar';
    case 4:
      return 'Apr';
    case 5:
      return 'May';
    case 6:
      return 'Jun';
    case 7:
      return 'Jul';
    case 8:
      return 'Aug';
    case 9:
      return 'Sep';
    case 10:
      return 'Oct';
    case 11:
      return 'Nov';
    case 12:
      return 'Dec';
    default:
      return 'Invalid Month';
  }
}

///GENERATE YEAR LIST....
List<String> generateList(int startYear, int endYear) {
  endYear = DateTime.now().year;
  List<String> yearsList = [];
  for (int year = startYear; year <= endYear; year++) {
    yearsList.add(year.toString());
  }
  return yearsList;
}

///GENERATE POST DEEPLINK
String postDeepLink({String? postId}) =>
    _withBdmReferral('https://beapp.in/app/post/${postId ?? ""}');

/// Generate deep link for a Video item
String videoDeepLink({String? videoId}) =>
    _withBdmReferral('https://beapp.in/app/video/${videoId ?? ""}');

/// Generate deep link for a Short/Reel item
String shortDeepLink({String? shortId}) =>
    _withBdmReferral('https://beapp.in/app/video/${shortId ?? ""}');

/// Generate deep link for a Job post item
String jobDeepLink({String? jobId}) =>
    _withBdmReferral('https://beapp.in/app/job/${jobId ?? ""}');

/// Generate deep link for a Profile.
String profileDeepLink({String? userId}) =>
    _withBdmReferral('https://beapp.in/app/profile/${userId ?? ""}');

/// Generate deep link for a Product item
String productDeepLink({String? productId}) =>
    _withBdmReferral('https://beapp.in/app/product/${productId ?? ""}');

/// Generate deep link for a Service item
String serviceDeepLink({String? serviceId}) =>
    _withBdmReferral('https://beapp.in/app/food/${serviceId ?? ""}');

/// Generate deep link for a Food Service item
String foodServiceDeepLink({String? foodServiceId}) =>
    _withBdmReferral('https://beapp.in/app/food/${foodServiceId ?? ""}');

/// Returns the signed-in user's BDM referral code (when their BDM
/// application status is `COMPLETED`), or `null`. Public companion
/// to the auto-attach inside [_withBdmReferral] — call sites that
/// need the raw code (e.g. the Play Store `referrer` param, an
/// app-download share body) should read it through here so the
/// "what counts as a valid referral code" rule lives in one place.
String? currentBdmReferralCode() => _currentUserReferralCodeIfBdmCompleted();

/// Appends `?referralCode=<code>` to [base] when the signed-in
/// user is a verified BDM (status `COMPLETED`); returns [base]
/// unchanged otherwise. All deeplink builders in this file route
/// through here so the referral-attach rule lives in one place.
///
/// Assumes [base] has no existing query string — every current
/// deeplink builder generates a path-only URL. If that ever
/// changes, switch to detecting an existing `?` and using `&`.
String _withBdmReferral(String base) {
  final code = _currentUserReferralCodeIfBdmCompleted();
  if (code == null || code.isEmpty) return base;
  return '$base?referralCode=${Uri.encodeQueryComponent(code)}';
}

/// Returns the signed-in user's referral code only when their BDM
/// application status is `COMPLETED` (per [ReferralController]). All
/// lookups are guarded with `Get.isRegistered` + try/catch so URL
/// generation can never throw if a controller hasn't been registered
/// yet (e.g. share surfaces opened before the referral flow loads).
String? _currentUserReferralCodeIfBdmCompleted() {
  try {
    if (!Get.isRegistered<ReferralController>()) return null;
    final referral = Get.find<ReferralController>();
    if (referral.referralBdmDetails.value.status != 'COMPLETED') return null;

    if (accountTypeGlobal == AppConstants.business) {
      if (!Get.isRegistered<ViewBusinessDetailsController>()) return null;
      return Get.find<ViewBusinessDetailsController>()
          .businessProfileDetails
          .value
          ?.data
          ?.referral_code;
    }
    if (!Get.isRegistered<ViewPersonalDetailsController>()) return null;
    return Get.find<ViewPersonalDetailsController>()
        .personalProfileDetails
        .value
        .user
        ?.referral_code;
  } catch (_) {
    return null;
  }
}

/// Generate "5 days ago" or something similar
String timeAgo(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inSeconds < 60) {
    return 'just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} m ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} h ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} d ago';
  } else if (difference.inDays < 14) {
    return '1 w ago';
  } else if (difference.inDays < 21) {
    return '2 w ago';
  } else if (difference.inDays < 28) {
    return '3 weeks ago';
  } else {
    final months = (difference.inDays / 30).floor();
    if (months == 1) {
      return '1 month ago';
    } else if (months > 1) {
      return '$months months ago';
    }
    return date.toLocal().toString().split(' ')[0];
  }
}

String timeAgoFormatted(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inSeconds < 60) {
    return 'just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}h';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d';
  } else if (difference.inDays < 14) {
    return '1w';
  } else if (difference.inDays < 21) {
    return '2w';
  } else if (difference.inDays < 28) {
    return '3w';
  } else {
    final months = (difference.inDays / 30).floor();
    if (months >= 1) {
      return '${months}mo';
    }
    return date.toLocal().toString().split(' ')[0];
  }
}

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

Future<Size?> getVideoDimensions(String videoPath) async {
  final controller = VideoPlayerController.file(File(videoPath));
  await controller.initialize();
  final size = controller.value.size;
  controller.dispose();
  return size;
}

Future<Size> getImageDimensions(File imageFile) async {
  final data = await imageFile.readAsBytes();
  final image = await decodeImageFromList(data);
  return Size(image.width.toDouble(), image.height.toDouble());
}

Map<String, String?> getFileInfo(File file) {
  final fileName = path.basename(file.path);
  final extension = path.extension(file.path);
  final mimeType = lookupMimeType(file.path);

  return {
    'fileName': fileName,
    'extension': extension,
    'mimeType': mimeType,
  };
}

bool isNetworkImage(dynamic image) =>
    image is String &&
    (image.trim().toLowerCase().startsWith('http://') ||
        image.trim().toLowerCase().startsWith('https://'));

Widget staggeredDotsWaveLoading(
    {Color color = AppColors.primaryColor, EdgeInsets? padding}) {
  return Center(
      child: Padding(
          padding: padding ?? EdgeInsets.all(SizeConfig.size15),
          child: LoadingAnimationWidget.staggeredDotsWave(
              size: SizeConfig.size40, color: color)));
}

/// Save user preference (don't show again)
Future<void> disableGreetingCard() async {
  await SharedPreferenceUtils.setSecureValue(
    SharedPreferenceUtils.disableGreetingCardKey,
    "true",
  );
}

bool isHlsUrl(String? url) =>
    url?.toLowerCase().endsWith('.m3u8') ?? false;

Future<void> launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}

Color hexToColor(String hexString) {
  hexString = hexString.replaceAll('#', '');
  if (hexString.length == 6) {
    hexString = 'FF$hexString'; // Add opacity if not present
  }
  return Color(int.parse(hexString, radix: 16));
}

// Hex without alpha: #RRGGBB
String colorToHex(Color color) {
  final r = color.r * 255.0;
  final g = color.g * 255.0;
  final b = color.b * 255.0;
  return '#'
          '${r.toInt().toRadixString(16).padLeft(2, '0')}'
          '${g.toInt().toRadixString(16).padLeft(2, '0')}'
          '${b.toInt().toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}

double calculateDiscount(String priceText, String mrpText) {
  final price = num.tryParse(priceText.replaceAll('₹', '').trim()) ?? 0;
  final mrp = num.tryParse(mrpText.replaceAll('₹', '').trim()) ?? 0;

  if (mrp == 0) return 0;

  final discount = ((mrp - price) / mrp) * 100;
  return double.parse(discount.toStringAsFixed(2));
}

String formatBytesToMB(int bytes) {
  final mb = bytes / (1024 * 1024);
  return mb.toStringAsFixed(2);
}

bool validateEmail(String email) {
  final emailRegex = RegExp(
      r'^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
  return emailRegex.hasMatch(email);
}

String normalisePhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), ''); // keep only 0-9
  if (digits.length == 10 && digits[0] != '0') {
    return '+91$digits'; // add country code
  }
  return '+$digits'; // assume it already had country code
}

Future<void> openDialer(String contactNumber) async {
  final phone = normalisePhone(contactNumber);
  final uri = Uri(scheme: 'tel', path: phone);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> openGoogleMaps({
  required double latitude,
  required double longitude,
}) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
  );

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not open Google Maps';
  }
}

Map<String, int> calculateExperience(String startDateString) {
  try {
    final startDate = DateTime.parse(startDateString);
    final now = DateTime.now();

    int years = now.year - startDate.year;
    int months = now.month - startDate.month;

    if (months < 0) {
      years--;
      months += 12;
    }

    return {
      "years": years < 0 ? 0 : years,
      "months": months,
    };
  } catch (e) {
    return {"years": 0, "months": 0};
  }
}

Map<String, String> getServicesMinMaxTimings(List<Timings>? timingsList) {
  if (timingsList == null || timingsList.isEmpty) {
    return {"start": "--", "end": "--"};
  }

  Timings earliest = timingsList.first;
  Timings latest = timingsList.first;

  for (final t in timingsList) {
    final startTime = parse12HourTime(t.start ?? "00:00 AM");
    final earliestStart = parse12HourTime(earliest.start ?? "00:00 AM");
    if (startTime.isBefore(earliestStart)) earliest = t;

    final endTime = parse12HourTime(t.end ?? "00:00 AM");
    final latestEnd = parse12HourTime(latest.end ?? "00:00 AM");
    if (endTime.isAfter(latestEnd)) latest = t;
  }

  return {
    "start": earliest.start ?? "--",
    "end": latest.end ?? "--",
  };
}

DateTime parse12HourTime(String timeStr) {
  final format = RegExp(r'(\d+):(\d+)\s*(AM|PM)');
  final match = format.firstMatch(timeStr.trim());

  if (match != null) {
    int hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3);

    if (period == "PM" && hour != 12) hour += 12;
    if (period == "AM" && hour == 12) hour = 0;

    return DateTime(0, 1, 1, hour, minute);
  }

  return DateTime(0); // fallback
}

double? calculateDistance(double targetLat, double targetLng) {
  final userLat = LocationService.lat;
  final userLng = LocationService.lng;
  if (userLat == 0.0 || userLng == 0.0) return null;

  final distanceMeters = geo.Geolocator.distanceBetween(
    userLat,
    userLng,
    targetLat,
    targetLng,
  );

  // Road factor ≈ 1.27 (very close to Google distance)
  const roadFactor = 1.27;
  return (distanceMeters * roadFactor) / 1000;
}

String? calculateDistanceInt(double targetLat, double targetLng) =>
    calculateDistance(targetLat, targetLng)?.toStringAsFixed(0);

Future<Uint8List> getBytesFromSvgAsset(
  String assetName,
  double size,
) async {
  final pictureInfo = await vg.loadPicture(SvgAssetLoader(assetName), null);

  final width = pictureInfo.size.width;
  final height = pictureInfo.size.height;
  final scale = size / width;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.scale(scale);
  canvas.drawPicture(pictureInfo.picture);

  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (width * scale).toInt(),
    (height * scale).toInt(),
  );

  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  pictureInfo.picture.dispose();

  return byteData!.buffer.asUint8List();
}

Future<void> copyToClipboard(BuildContext context, String textToCopy) async {
  await Clipboard.setData(ClipboardData(text: textToCopy));

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Copied to clipboard!"),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
