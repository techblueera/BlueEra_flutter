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

