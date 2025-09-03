import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:geolocator/geolocator.dart';
String? globalLat="",globalLong="",globalCurrentAddress;
Future<Position?> getCurrentLocation() async {
  globalLat="";
  globalLong="";
  globalCurrentAddress="";
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    commonSnackBar(message: "Location services are disabled.");
    return null;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      commonSnackBar(message: "Location permission is denied.");

      return null;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    commonSnackBar(
        message:
            "Location permission is permanently denied. Please enable it from settings.");

    await Geolocator.openAppSettings();
    return null;
  }
Position currentLocation=await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high);
  globalLat=currentLocation.latitude.toString();
  globalLong=currentLocation.longitude.toString();
  // globalCurrentAddress=
  return currentLocation;
}
