import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/l10n/app_localizations_en.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' as foundationObj;
import 'package:flutter/material.dart' hide Key;
import 'package:flutter/rendering.dart' hide Key;
import 'package:flutter/services.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

import 'app_colors.dart';

///SHOW APP LOGS
logs(String logMsg) {
  // if (foundationObj.kDebugMode) {
    print(logMsg);
  // }
}
// https://be-user-bck.s3.ap-south-1.amazonaws.com/user/temp/profile/guest8024173s
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

List<String> businessType = ["Product", "Service", "Both"];
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

AppLocalizationsEn loc = AppLocalizationsEn();

final List<String> courseTypes = [loc.fullName, loc.partTime, loc.distance];

courseTypeApiKey({String? keyName}) {
  return keyName == loc.fullName
      ? "FULL_TIME"
      : keyName == loc.partTime
          ? "PART_TIME"
          : keyName == loc.distance
              ? "DISTANCE"
              : "";
}

courseTypeApiValue({String? keyName}) {
  return keyName == "FULL_TIME"
      ? loc.fullName
      : keyName == "PART_TIME"
          ? loc.partTime
          : keyName == "DISTANCE"
              ? loc.distance
              : "";
}

///GENERATE POST DEEPLINK
String postDeepLink({String? postId}) {
  // updatedURL
  // return 'https://api.blueera.ai/api/post-service/app/post/${(postId ?? "")}';
  // Updated to new host for deep linking and sharing (friendly path)
  return 'https://blueera.ai/app/post/${(postId ?? "")}';
  // return '${baseUrl}${blueEraPostLink}/${encryptString(postId ?? "")}';
  // return 'https://p3qw782za2.execute-api.ap-south-1.amazonaws.com/.well-known/${(postId ?? "")}';
  // return '${baseUrl}${blueEraPostLink}/${encryptString(postId ?? "")}';
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
String profileDeepLink({String? userId}) {
  return 'https://blueera.ai/app/profile/${(userId ?? "")}';
}

// String staticDeepLink() {
//   return "https://dart.dev/tools/pub/publishing";
//   // return "https://www.myntra.com/apparel-set/gosriki/gosriki-women-kurta-with-trousers-&-dupatta-set/31079027/buy?utm_source=social_share_pdp&utm_medium=deeplink&utm_campaign=social_share_pdp_deeplink";
// }

String encryptString(String rawString) {
  // 16-byte key and IV, same as your example
  final key = Key.fromUtf8('8080808080808080');
  final iv = IV.fromUtf8('8080808080808080');

  final encrypter = Encrypter(
    AES(key, mode: AESMode.cbc),
  );

  // Encrypt the raw string
  final encrypted = encrypter.encrypt(rawString, iv: iv);

  return encrypted.base64;
}

String decryptString(String encryptedBase64) {
  final key = Key.fromUtf8('8080808080808080');
  final iv = IV.fromUtf8('8080808080808080');

  final encrypter = Encrypter(
    AES(key, mode: AESMode.cbc),
  );

  final decrypted = encrypter.decrypt64(encryptedBase64, iv: iv);

  return decrypted;
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
      return '${months}m';
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

Map<String, String?> getFileInfo(File file) {
  // ✅ Original file name with extension
  String fileName = path.basename(file.path); // e.g., "video123.mp4"

  // ✅ File extension
  String extension = path.extension(file.path); // e.g., ".mp4"

  // ✅ MIME type
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

Widget staggeredDotsWaveLoading(){
  return Center(
      child: Padding(
          padding: EdgeInsets.all(SizeConfig.size15),
          child: LoadingAnimationWidget.staggeredDotsWave(
              size: SizeConfig.size40,
              color: AppColors.primaryColor
          )
      )
  );
}

/// Returns true if user has not disabled AND API has not been called today
Future<GreetingCheckResult> canCallCardApi() async {
  final dontShow = await SharedPreferenceUtils.getSecureValue(
    SharedPreferenceUtils.disableGreetingCardKey,
  );

  final today = DateTime.now().toIso8601String(); // yyyy-MM-dd
  log('today--> $today');

  if (dontShow == true) {
    log("User disabled greeting card ❌");
    return GreetingCheckResult(canCall: false, today: today);  }

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
    true,
  );
}

/// Save today's date after successful API call
Future<void> saveApiCallDate() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.lastGreetingCallKey, today);
}

