import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:mappls_gl/mappls_gl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/common/Discover/widget/tooltip_generator.dart';
import 'package:flutter/services.dart';


class SendLocationPage extends StatefulWidget {
  final Function(double lat,double long,String? placeName,String? address) onSubmit;
   final Function(double lat,double long,String? duration) onLiveLocationSubmit;
  const SendLocationPage({required this.onSubmit,required this.onLiveLocationSubmit});
  @override
  _SendLocationPageState createState() => _SendLocationPageState();
}

class _SendLocationPageState extends State<SendLocationPage> {

  MapplsMapController? mapController;
  LatLng? _currentPosition;
  LatLng? alternatCurrentPos;

  List<Placemark> _nearbyPlaces = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    final permission = await Permission.location.request();
    if (permission.isGranted) {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        alternatCurrentPos = LatLng(pos.latitude, pos.longitude);
      });
      await _fetchNearbyPlaces(pos);
    }
  }

  Future<void> _fetchNearbyPlaces(Position position) async {
    List<Placemark> placemarks =
    await placemarkFromCoordinates(position.latitude, position.longitude);

    setState(() {
      _nearbyPlaces = placemarks;
      if (placemarks.isNotEmpty) {
        // _address =
        // "${placemarks.first.name}, ${placemarks.first.locality}, ${placemarks.first.country}";
      }
    });
  }

  // Future<void> _onMapCreated(MapplsMapController controller) async {
  //   mapController = controller;
  //   await _addMarker();
  // }

  Future<void> _addMarker() async {

    if (_currentPosition?.latitude != 0.0 && _currentPosition?.longitude != 0.0) {
      await mapController?.addSymbol(
        SymbolOptions(
          geometry: LatLng(_currentPosition?.latitude??0.0, _currentPosition?.longitude??0.0),
          iconSize: 1.2,
        ),
      );
      setState(() {});
    }
  }
  Symbol? _userSymbol;
  bool _isImageAdded = false;

  Future<void> _onStyleLoadedCallback() async {
    try {
      // 🔥 Image only once
      if (!_isImageAdded) {
        final Uint8List markerBytes =
        await TooltipGeneratorOnlyLocationIcon.createIconOnly(
          svgAssetPath: AppIconAssets.locationMarkerIcon,
        );

        await mapController?.addImage(
          "svg-composite-icon",
          markerBytes,
        );

        _isImageAdded = true;
      }

      // 🔥 Symbol create only once
      if (_userSymbol == null && _currentPosition != null) {
        _userSymbol = await mapController?.addSymbol(
          SymbolOptions(
            geometry: _currentPosition!,
            iconImage: "svg-composite-icon",
            iconSize: 1.0,
          ),
        );
      }
    } catch (e) {
      debugPrint("Marker error: $e");
    }
  }

  Future<Duration?> showLocationDurationSheet(BuildContext context) {
    Duration selectedDuration = const Duration(minutes: 15);
    String durationToLabel(Duration duration) {
      if (duration.inMinutes == 15) return "15min";
      if (duration.inHours == 1) return "1h";
      if (duration.inHours == 8) return "8h";
      return "${duration.inMinutes}min";
    }

    return showModalBottomSheet<Duration>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔹 Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // 🔹 Title
                  const Text(
                    "Share live location for",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Options
                  _DurationTile(
                    title: "15 minutes",
                    subtitle: "Quick share",
                    icon: Icons.timer_outlined,
                    selected: selectedDuration == const Duration(minutes: 15),
                    onTap: () {
                      setState(() {
                        selectedDuration = const Duration(minutes: 15);
                      });
                    },
                  ),
                  _DurationTile(
                    title: "1 hour",
                    subtitle: "Short trip",
                    icon: Icons.schedule,
                    selected: selectedDuration == const Duration(hours: 1),
                    onTap: () {
                      setState(() {
                        selectedDuration = const Duration(hours: 1);
                      });
                    },
                  ),
                  _DurationTile(
                    title: "8 hours",
                    subtitle: "All day",
                    icon: Icons.location_on_outlined,
                    selected: selectedDuration == const Duration(hours: 8),
                    onTap: () {
                      setState(() {
                        selectedDuration = const Duration(hours: 8);
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // 🔹 Submit Button
                  CustomBtn(
                    height: 48,
                      isValidate: true,
                      onTap: (){
                      widget.onLiveLocationSubmit(_currentPosition!.latitude, _currentPosition!.longitude,durationToLabel(selectedDuration));
                     Get.back();
                      }, title: "Send"),
                   SizedBox(height: SizeConfig.size40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Send location",
      ),
      body: (_currentPosition == null)
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          SizedBox(
            height: 250,
            child:
            MapplsMap(
                myLocationTrackingMode: MyLocationTrackingMode.tracking,
                onMapCreated: (MapplsMapController controller) async {
                  mapController = controller;
                },
                  initialCameraPosition: CameraPosition(
                    target: alternatCurrentPos!,
                    zoom: 15.0,
                  ),
                myLocationEnabled: true,
              onUserLocationUpdated: (userLocation) {
                final LatLng newPos = LatLng(
                  userLocation.position.latitude,
                  userLocation.position.longitude,
                );

                setState(() {
                  _currentPosition = newPos;
                });

                // 🔥 Just move existing symbol
                if (_userSymbol != null) {
                  mapController?.updateSymbol(
                    _userSymbol!,
                    SymbolOptions(
                      geometry: newPos,
                    ),
                  );
                }
              },
              onStyleLoadedCallback: () {
                  // setState(() => isMapLoading = false);
                  _onStyleLoadedCallback();
                },
                zoomGesturesEnabled: true,
              compassEnabled: false,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              scrollGesturesEnabled: true,
              // onSymbolTapped: _onSymbolTapped,
            ),

          ),
          const SizedBox(height: 6,),

          ListTile(
            leading: Icon(Icons.my_location,color: Colors.black,),
            title: CustomText("Send Live Location",
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            subtitle: CustomText("Accurate to ~2 meters",
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.outline,
            ),
            onTap: () async{
              final Duration? duration =
                  await showLocationDurationSheet(context);

              if (duration != null) {
                print("User selected duration: $duration");

                // 🔥 start location sharing logic here
                // startSharingLocation(duration);
              }
              // Handle send current location
              // widget.onSubmit(_currentPosition!.latitude, _currentPosition!.longitude,null,null);
            },
          ),
          Divider(color: AppColors.grey99,),
          ListTile(
            leading: LocalAssets(imagePath: AppIconAssets.location_new,height: 24,width: 24,),

            title: CustomText("Send your current location",
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            subtitle: CustomText("Accurate to ~8 meters",
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.outline,
            ),
            onTap: () {
              // Handle send current location
              widget.onSubmit(_currentPosition!.latitude, _currentPosition!.longitude,null,null);
            },
          ),
          Divider(color: AppColors.grey99,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Align(
                alignment: Alignment.centerLeft,
                child: CustomText("Nearby places",
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                )),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _nearbyPlaces.length,
              itemBuilder: (context, index) {
                final place = _nearbyPlaces[index];
                return ListTile(
                  leading: Icon(Icons.location_pin,color: Colors.black,),
                  title: CustomText(place.name ?? "Unknown",
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  subtitle: CustomText(
                      "${place.street}, ${place.locality}, ${place.postalCode}",
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.outline,
                  ),
                  onTap: ()async {
                    // Handle selected place
                    final fullAddress =
                        "${place.name}, ${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
                    try {
                      List<Location> locations = await locationFromAddress(fullAddress);
                      if (locations.isNotEmpty) {
                        final selected = locations.first;
                        widget.onSubmit(selected.latitude, selected.longitude,"${place.street}, ${place.locality}, ${place.postalCode}","${place.name ?? "Unknown"}");
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to get location for this place")),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class _DurationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DurationTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.blue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
              selected ? Colors.blue : Colors.grey.shade300,
              child: Icon(
                icon,
                color: selected ? Colors.white : Colors.black54,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
