import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> sendSeatData() async {
  var url = Uri.parse(
    "YOUR_GOOGLE_SCRIPT_WEBAPP_URL",
  );

  var response = await http.post(
    url,
    body: jsonEncode({
      "seat_id": "A1",
      "user": "Rahul",
      "status": "Booked"
    }),
  );

  print(response.body);
}
