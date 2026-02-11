import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:flutter/material.dart' hide Key;
import 'package:flutter/rendering.dart' hide Key;
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:image_picker/image_picker.dart';
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
  // if (foundationObj.kDebugMode) {
  log(logMsg);
  // }
}

///UN FOCUS KEYBOARD
unFocus() {
  FocusManager.instance.primaryFocus?.unfocus();
}

bool isAllowedImageExtension_(String path) {
  final allowedExtensions = ['jpg', 'jpeg', 'png'];
  final ext = path.split('.').last.toLowerCase();
  return allowedExtensions.contains(ext);
}

///DATE FORMAT
dateFormatddMMyyyy(DateTime date) {
  return DateFormat('dd-MM-yyyy').format(date);
}

bool isSuccessStatus(int? statusCode) {
  return statusCode == 200 || statusCode == 201;
}

//function to get year
int getYear(DateTime date) {
  return date.year;
}

//function for format data
String formatDate2(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

String obfuscateEmail(String email) {
  final parts = email.split("@");
  if (parts.length != 2) return email;
  return "${parts[0][0]}*${parts[1]}";
}

///OPEN GMAIL...
// On iOS, you cannot open the default mail inbox programmatically. Apple doesn’t allow it.
Future<void> openGmail() async {
  const url = 'googlegmail://co'; // this opens Gmail's compose screen

  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    // Fallback to opening Gmail in browser
    const webUrl = 'https://mail.google.com/';
    if (await canLaunchUrl(Uri.parse(webUrl))) {
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Gmail';
    }
  }
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

/// Posted dd MMM yyyy
String formatPostedDate(DateTime dateTime) {
  // Convert to local time if needed
  DateTime localDateTime = dateTime.toLocal();

  // Format date as "dd MMM yyyy"
  String formattedDate = "${localDateTime.day.toString().padLeft(2, '0')} "
      "${getMonthName(localDateTime.month)} "
      "${localDateTime.year}";

  return "Posted $formattedDate";
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
String postDeepLink({String? postId}) {
  return 'https://blueera.ai/app/post/${(postId ?? "")}';
}

/// Generate deep link for a Video item
String videoDeepLink({String? videoId}) {
  return 'https://blueera.ai/app/video/${(videoId ?? "")}';
}

/// Generate deep link for a Short/Reel item
String shortDeepLink({String? shortId}) {
  return 'https://blueera.ai/app/video/${(shortId ?? "")}';
}

/// Generate deep link for a Job post item
String jobDeepLink({String? jobId}) {
  return 'https://blueera.ai/app/job/${(jobId ?? "")}';
}

/// Generate deep link for a Profile
String profileDeepLink({String? userId,required String accountType}) {
  return 'https://blueera.ai/app/profile/${(userId ?? "")}/${accountType}';
}

/// Generate deep link for a Product item
String productDeepLink({String? productId}) {
  return 'https://blueera.ai/app/product/${productId ?? ""}';
}

/// Generate deep link for a Product item
String serviceDeepLink({String? serviceId}) {
  return 'https://blueera.ai/app/food/${serviceId ?? ""}';
}

/// Generate deep link for a Product item
String foodServiceDeepLink({String? foodServiceId}) {
  return 'https://blueera.ai/app/food/${foodServiceId ?? ""}';
}

/// Generate "5 days ago" or something similar
String timeAgo(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inSeconds < 60) {
    return 'just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min${difference.inMinutes > 1 ? '' : ''} ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hour${difference.inHours > 1 ? '' : ''} ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} day${difference.inDays > 1 ? '' : ''} ago';
  } else if (difference.inDays < 14) {
    return '1 week ago';
  } else if (difference.inDays < 21) {
    return '2 weeks ago';
  } else if (difference.inDays < 28) {
    return '3 weeks ago';
  } else {
    final months = (difference.inDays / 30).floor();
    if (months == 1) {
      return '1 month ago';
    } else if (months > 1) {
      return '$months months ago';
    }
    return date.toLocal().toString().split(' ')[0]; // fallback: show date
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
    return date.toLocal().toString().split(' ')[0]; // fallback
  }
}

/// Hashtag method
void formatHashtags(TextEditingController controller) {
  final text = controller.text.trimRight(); // handle trailing spaces
  final words = text.split(RegExp(r'\s+'));

  final formatted = words.map((word) {
    if (word.startsWith('#')) return word;
    return '#$word';
  }).join(' ');

  // Only update if something changed
  if (text != formatted) {
    final selection = controller.selection;
    final offsetAdjustment = formatted.length - text.length;

    controller.value = TextEditingValue(
      text: formatted + (controller.text.endsWith(' ') ? ' ' : ''),
      selection: TextSelection.collapsed(
        offset: selection.baseOffset + offsetAdjustment,
      ),
    );
  }
}

// void formatHashtags(TextEditingController controller) {
//   final text = controller.text;
//   final cursorPosition = controller.selection.baseOffset;
//
//   // Only update if the last character is a space
//   if (text.isNotEmpty && text.endsWith(' ')) {
//     final words = text.trim().split(RegExp(r'\s+'));
//
//     final formatted = words.map((word) {
//       if (word.startsWith('#')) {
//         return word;
//       } else {
//         return '#$word';
//       }
//     }).join(' ') + ' '; // Keep the space at the end
//
//     controller.value = TextEditingValue(
//       text: formatted,
//       selection: TextSelection.collapsed(offset: formatted.length),
//     );
//   }
// }

// Future<BitmapDescriptor> createMarkerUsingTearDropImage({
//   required String tearDropAssetPath,
//   required String centerIconAssetPath,
// }) async {
//   final recorder = ui.PictureRecorder();
//   final canvas = Canvas(recorder);
//   final paint = Paint()..isAntiAlias = true;
//
//   // Load the teardrop background image
//   final tearDropData = await rootBundle.load(tearDropAssetPath);
//   final tearDropCodec = await ui.instantiateImageCodec(
//     tearDropData.buffer.asUint8List(),
//     targetWidth: 40, // adjust as per required visual size
//     targetHeight: 60,
//   );
//   final tearDropFrame = await tearDropCodec.getNextFrame();
//   final tearDropImage = tearDropFrame.image;
//
//   final int width = tearDropImage.width;
//   final int height = tearDropImage.height;
//
//   // Draw the background image (tear drop)
//   canvas.drawImage(tearDropImage, Offset.zero, paint);
//
//   // Load the center icon
//   final centerIconData = await rootBundle.load(centerIconAssetPath);
//   final centerIconCodec = await ui.instantiateImageCodec(
//     centerIconData.buffer.asUint8List(),
//     targetWidth: (width * 0.5).toInt(), // ~40% width
//     targetHeight: (width * 0.5).toInt(), // keep it square
//   );
//   final centerIconFrame = await centerIconCodec.getNextFrame();
//   final centerIcon = centerIconFrame.image;
//
//   // Position icon near the upper circular part of the tear-drop
//   final Offset centerOffset = Offset(
//     (width - centerIcon.width) / 2,
//     (height * 0.28) -
//         (centerIcon.height /
//             2), // Adjust vertically for perfect center of bulge
//   );
//
//   // Draw the icon on top of tear drop
//   canvas.drawImage(centerIcon, centerOffset, paint);
//
//   // Finish and convert to BitmapDescriptor
//   final picture = recorder.endRecording();
//   final img = await picture.toImage(width, height);
//   final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//
//   return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
// }

void setupScrollVisibilityListener({
  required ScrollController controller,
  required bool Function() isCurrentlyVisible,
  required void Function(bool) onVisibilityChanged,
}) {
  controller.addListener(() {
    final direction = controller.position.userScrollDirection;
    final currentVisible = isCurrentlyVisible();

    if (direction == ScrollDirection.reverse && currentVisible) {
      onVisibilityChanged(false);
    } else if (direction == ScrollDirection.forward && !currentVisible) {
      onVisibilityChanged(true);
    }
  });
}

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
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
  String fileName = path.basename(file.path); // e.g., "video123.mp4"

  String extension = path.extension(file.path); // e.g., ".mp4"

  String? mimeType = lookupMimeType(file.path); // e.g., "video/mp4"

  print("📁 File Name: $fileName");
  print("🧩 Extension: $extension");
  print("📎 MIME Type: $mimeType");

  return {
    'fileName': fileName,
    'extension': extension,
    'mimeType': mimeType,
  };
}

bool isNetworkImage(dynamic image) =>
    image is String &&
    (image.startsWith('http://') || image.startsWith('https://'));

bool isFileImage(dynamic image) => image is File || image is XFile;

Widget staggeredDotsWaveLoading({Color color = AppColors.primaryColor,EdgeInsets? padding}) {
  return Center(
      child: Padding(
          padding: padding??EdgeInsets.all(SizeConfig.size15),
          child: LoadingAnimationWidget.staggeredDotsWave(
              size: SizeConfig.size40, color: color)));
}

/// Returns true if user has not disabled AND API has not been called today
Future<GreetingCheckResult> canCallCardApi() async {
  final dontShow = await SharedPreferenceUtils.getSecureValue(
    SharedPreferenceUtils.disableGreetingCardKey,
  );

  final today = DateTime.now().toIso8601String(); // yyyy-MM-dd
  log('today--> $today');

  if (dontShow == "true") {
    log("User disabled greeting card ❌");
    return GreetingCheckResult(canCall: false, today: today);
  }

  // ✅ Then check daily condition
  final lastDate = await SharedPreferenceUtils.getSecureValue(
    SharedPreferenceUtils.lastGreetingCallKey,
  );

  final canCall = lastDate != today.substring(0, 10);
  return GreetingCheckResult(canCall: canCall, today: today);
}

/// Save user preference (don't show again)
Future<void> disableGreetingCard() async {
  await SharedPreferenceUtils.setSecureValue(
    SharedPreferenceUtils.disableGreetingCardKey,
    "true",
  );
}

/// Save today's date after successful API call
Future<void> saveApiCallDate() async {
  final today = DateTime.now().toIso8601String().substring(0, 10);
  await SharedPreferenceUtils.setSecureValue(
      SharedPreferenceUtils.lastGreetingCallKey, today);
}

bool isHlsUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  return url.toLowerCase().endsWith('.m3u8');
}

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
  final hex = '#'
          '${r.toInt().toRadixString(16).padLeft(2, '0')}'
          '${g.toInt().toRadixString(16).padLeft(2, '0')}'
          '${b.toInt().toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();

  return hex;
}

double calculateDiscount(String priceText, String mrpText) {
  final price = num.tryParse(priceText.replaceAll('₹', '').trim()) ?? 0;
  final mrp = num.tryParse(mrpText.replaceAll('₹', '').trim()) ?? 0;

  if (mrp == 0) return 0;

  final discount = ((mrp - price) / mrp) * 100;

  // Round or format to two decimals
  final formatted = discount.toStringAsFixed(2);

  // If before decimal is single-digit, add leading zero
  final parts = formatted.split('.');
  if (parts[0].length == 1) {
    // return as double but formatted string parsed back to double
    return double.parse('0$formatted');
  }

  return double.parse(formatted);
}

Map<String, dynamic> normalizeMap(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(key.toString(), normalizeMap(val)),
    );
  } else {
    return value;
  }
}

// Future<String?> compressVideo(File videoFile) async {
//   String? videoPath;
//   try {
//     // 1. Start the compression process
//     final MediaInfo? info = await VideoCompress.compressVideo(
//       videoFile.path,
//       quality: VideoQuality.LowQuality,
//       // Choose quality: Low, Medium, High, Default
//       deleteOrigin: false,
//       // Set to true to delete the original file after compression
//       // Optional: set a callback to listen to the progress
//       includeAudio: true,
//       startTime: 0,
//       duration: 0,
//     );
//
//     if (info != null) {
//       videoPath = info.path;
//       print('✅ Compression completed!');
//       print('Original Size: ${videoFile.lengthSync() / (1024 * 1024)} MB');
//       print('Compressed Path: ${info.path}');
//       print('Compressed Size: ${info.filesize! / (1024 * 1024)} MB');
//       // You can now use the compressed video file at info.path
//       // The MediaInfo object also contains other metadata like duration, thumbnail path, etc.
//     }
//     return videoPath;
//   } catch (e) {
//     print('❌ Compression failed: $e');
//   }
//   return null;
// }

String formatBytesToMB(int bytes) {
  double mb = bytes / (1024 * 1024);
  return mb.toStringAsFixed(2);
}

bool validateEmail(String email) {
  final emailRegex = RegExp(r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
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
    DateTime startDate = DateTime.parse(startDateString);
    DateTime now = DateTime.now();

    int years = now.year - startDate.year;
    int months = now.month - startDate.month;

    // Adjust if the current month is before the start month
    if (months < 0) {
      years--;
      months += 12;
    }

    return {
      "years": years < 0 ? 0 : years, // Prevent negative years
      "months": months
    };
  } catch (e) {
    return {"years": 0, "months": 0};
  }
}

Map<String, String> getServicesMinMaxTimings(List<Timings>? timingsList) {
  if (timingsList == null || timingsList.isEmpty) return {"start": "--", "end": "--"};

  Timings? earliest = timingsList.first;
  Timings? latest = timingsList.first;

  for (final t in timingsList) {
    final startTime = parse12HourTime(t.start ?? "00:00 AM");
    final earliestStart = parse12HourTime(earliest?.start ?? "00:00 AM");
    if (startTime.isBefore(earliestStart)) earliest = t;

    final endTime = parse12HourTime(t.end ?? "00:00 AM");
    final latestEnd = parse12HourTime(latest?.end ?? "00:00 AM");
    if (endTime.isAfter(latestEnd)) latest = t;
  }

  return {
    "start": earliest?.start ?? "--",
    "end": latest?.end ?? "--",
  };
}

DateTime parse12HourTime(String timeStr) {
  final format = RegExp(r'(\d+):(\d+)\s*(AM|PM)');
  final match = format.firstMatch(timeStr.trim());

  if (match != null) {
    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    final period = match.group(3);

    if (period == "PM" && hour != 12) hour += 12;
    if (period == "AM" && hour == 12) hour = 0;

    return DateTime(0, 1, 1, hour, minute);
  }

  return DateTime(0); // fallback
}

double? calculateDistance(double targetLat, double targetLng){
  double userLat = LocationService.lat;
  double userLng = LocationService.lat;
  if(userLat == 0.0 || userLng == 0.0) return null;
  double distanceMeters = geo.Geolocator.distanceBetween(
    userLat,
    userLng,
    targetLat,
    targetLng,
  );

  // Road factor ≈ 1.27 (very close to Google distance)
  const double roadFactor = 1.27;

  return (distanceMeters * roadFactor) / 1000;
}


Future<Uint8List> getBytesFromSvgAsset(
    String assetName,
    double size,
    ) async {
  final pictureInfo =
  await vg.loadPicture(SvgAssetLoader(assetName), null);

  final double width = pictureInfo.size.width;
  final double height = pictureInfo.size.height;

  final double scale = size / width;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.scale(scale);
  canvas.drawPicture(pictureInfo.picture);

  final picture = recorder.endRecording();

  final image = await picture.toImage(
    (width * scale).toInt(),
    (height * scale).toInt(),
  );

  final byteData =
  await image.toByteData(format: ui.ImageByteFormat.png);

  pictureInfo.picture.dispose();

  return byteData!.buffer.asUint8List();
}

