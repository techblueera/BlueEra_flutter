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

