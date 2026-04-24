import 'package:intl/intl.dart';

String formatISO8601Date(String tzString) {
  try {
    // 1. Parse the TZ String to DateTime object
    DateTime date = DateTime.parse(tzString).toLocal(); // .toLocal() shifts it to user's timezone

    // 2. Logic for the Ordinal Suffix (st, nd, rd, th)
    int day = date.day;
    String suffix;
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:  suffix = 'st'; break;
        case 2:  suffix = 'nd'; break;
        case 3:  suffix = 'rd'; break;
        default: suffix = 'th';
      }
    }

    // 3. Format the Month and Year
    String monthYear = DateFormat("MMM, yyyy").format(date);

    return "$day$suffix $monthYear";
  } catch (e) {
    return "Invalid Date";
  }
}

List<String> generateFullDayTimeList() {
  final List<String> times = [];
  for (int hour = 0; hour < 24; hour++) {
    for (int min in [0, 30]) {
      final period = hour < 12 ? 'AM' : 'PM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final displayMin = min.toString().padLeft(2, '0');
      times.add('$displayHour:$displayMin $period');
    }
  }
  return times;
}

DateTime? parseTime(String time) {
  try {
    final format = DateFormat('h:mm a'); // e.g. 7:00 AM
    return format.parse(time.trim());
  } catch (_) {
    return null;
  }
}

/// Formats the gap between [iso] and now as a human string:
/// "Just now", "5 minutes ago", "2 hours ago", "3 days ago", "2 months ago",
/// "1 year ago". Returns an empty string if [iso] is null/empty/invalid.
String timeAgo(String? iso) {
  if (iso == null || iso.trim().isEmpty) return '';
  final t = DateTime.tryParse(iso);
  if (t == null) return '';
  final diff = DateTime.now().difference(t);
  if (diff.isNegative) return 'Just now';
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} ${diff.inMinutes == 1 ? "minute" : "minutes"} ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"} ago';
  }
  if (diff.inDays < 30) {
    return '${diff.inDays} ${diff.inDays == 1 ? "day" : "days"} ago';
  }
  final months = (diff.inDays / 30).floor();
  if (months < 12) return '$months ${months == 1 ? "month" : "months"} ago';
  final years = (diff.inDays / 365).floor();
  return '$years ${years == 1 ? "year" : "years"} ago';
}

