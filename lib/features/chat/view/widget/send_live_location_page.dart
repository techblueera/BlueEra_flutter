import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/map/blue_map.dart';
import 'package:BlueEra/core/map/lat_lng.dart';
import 'package:permission_handler/permission_handler.dart';


class SendLocationPage extends StatefulWidget {
  final Function(double lat,double long,String? placeName,String? address) onSubmit;
   final Function(double lat,double long,String? duration) onLiveLocationSubmit;
  const SendLocationPage({required this.onSubmit,required this.onLiveLocationSubmit});
  @override
  _SendLocationPageState createState() => _SendLocationPageState();
}

class _SendLocationPageState extends State<SendLocationPage> {

  LatLng? _currentPosition;
  LatLng? alternatCurrentPos;
  List<Placemark> _nearbyPlaces = [];
  BlueMapController? _mapController;
  String _selectedDuration = '15min';

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
      _mapController?.moveTo(_currentPosition!, zoom: 16);
      await _fetchNearbyPlaces(pos);
    }
  }

  Future<void> _fetchNearbyPlaces(Position position) async {
    final double lat = position.latitude;
    final double lng = position.longitude;
    // Offset ~200-500m in different directions to get diverse nearby places
    final List<List<double>> offsets = [
      [0, 0],
      [0.002, 0.002],
      [-0.002, 0.002],
      [0.002, -0.002],
      [-0.002, -0.002],
      [0.004, 0],
      [0, 0.004],
      [-0.004, 0],
      [0, -0.004],
    ];

    final Set<String> seen = {};
    final List<Placemark> allPlaces = [];

    for (final offset in offsets) {
      try {
        final placemarks = await placemarkFromCoordinates(
          lat + offset[0], lng + offset[1],
        );
        for (final place in placemarks) {
          final key = '${place.name}_${place.street}_${place.postalCode}';
          if (!seen.contains(key) && place.name != null && place.name!.isNotEmpty) {
            seen.add(key);
            allPlaces.add(place);
          }
        }
      } catch (_) {}
      if (allPlaces.length >= 8) break;
    }

    setState(() {
      _nearbyPlaces = allPlaces;
    });
  }

  Widget _buildDurationTab(String value, String label) {
    final bool isSelected = _selectedDuration == value;
    return GestureDetector(
      onTap: () {
        if (_currentPosition != null) {
          widget.onLiveLocationSubmit(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            value,
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withValues(alpha: 0.1)
              : Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: CustomText(
          label,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? AppColors.primaryColor : AppColors.grayText,
        ),
      ),
    );
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  CustomText(
                    AppStrings.shareLiveLocationFor.tr,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 20),
                  _DurationTile(
                    title: AppStrings.fifteenMinutes.tr,
                    subtitle: AppStrings.quickShare.tr,
                    icon: Icons.timer_outlined,
                    selected: selectedDuration == const Duration(minutes: 15),
                    onTap: () {
                      setState(() {
                        selectedDuration = const Duration(minutes: 15);
                      });
                    },
                  ),
                  _DurationTile(
                    title: AppStrings.oneHour.tr,
                    subtitle: AppStrings.shortTrip.tr,
                    icon: Icons.schedule_outlined,
                    selected: selectedDuration == const Duration(hours: 1),
                    onTap: () {
                      setState(() {
                        selectedDuration = const Duration(hours: 1);
                      });
                    },
                  ),
                  _DurationTile(
                    title: AppStrings.eightHours.tr,
                    subtitle: AppStrings.allDay.tr,
                    icon: Icons.access_time_filled_outlined,
                    selected: selectedDuration == const Duration(hours: 8),
                    onTap: () {
                      setState(() {
                        selectedDuration = const Duration(hours: 8);
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomBtn(
                    height: 50,
                    isValidate: true,
                    onTap: () {
                      widget.onLiveLocationSubmit(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                        durationToLabel(selectedDuration),
                      );
                      Get.back();
                    },
                    title: AppStrings.shareLiveLocation.tr,
                  ),
                  SizedBox(height: SizeConfig.size20),
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
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: CommonBackAppBar(
        title: AppStrings.sendLocationLabel.tr,
      ),
      body: (_currentPosition == null)
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(height: 16),
                  CustomText(
                    AppStrings.gettingYourLocation.tr,
                    fontSize: 14,
                    color: AppColors.grayText,
                  ),
                ],
              ),
            )
          : Column(
        children: [
          // Map section
          Container(
            height: 220,
            margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BlueMap(
                initialCenter:
                    _currentPosition ?? const LatLng(26.7836, 80.9013),
                initialZoom: 16,
                myLocationEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                  final pos = _currentPosition;
                  if (pos != null) controller.moveTo(pos, zoom: 16);
                },
              ),
            ),
          ),
          SizedBox(height: 12),

          // Location action cards
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Live location section with inline duration tabs
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Color(0xFF00BFA5).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.my_location_rounded, color: Color(0xFF00BFA5), size: 22),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText("Send Live Location",
                              fontSize: 15, fontWeight: FontWeight.w600,
                            ),
                            SizedBox(height: 2),
                            CustomText("Accurate to ~2 meters",
                              fontSize: 12, color: AppColors.grayText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                // Duration tabs + send button
                Padding(
                  padding: EdgeInsets.only(left: 74,right: 16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDurationTab('15min', '15 min'),
                      _buildDurationTab('1h', '1 hour'),

                      _buildDurationTab('8h', '8 hours'),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Divider(height: 1, indent: 74, color: Colors.grey.shade200),
                // Current location tile
                InkWell(
                  onTap: () {
                    widget.onSubmit(_currentPosition!.latitude, _currentPosition!.longitude, null, null);
                  },
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.near_me_rounded, color: AppColors.primaryColor, size: 22),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText("Send Current Location",
                                fontSize: 15, fontWeight: FontWeight.w600,
                              ),
                              SizedBox(height: 2),
                              CustomText("Accurate to ~8 meters",
                                fontSize: 13, color: AppColors.grayText,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Nearby places header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CustomText(AppStrings.nearbyPlaces.tr,
                  fontSize: 15, fontWeight: FontWeight.w700,
                ),
                SizedBox(width: 6),
                CustomText("(${_nearbyPlaces.length})",
                  fontSize: 13, color: AppColors.grayText,
                ),
              ],
            ),
          ),
          SizedBox(height: 8),

          // Nearby places list
          Expanded(
            child: _nearbyPlaces.isEmpty
                ? Center(
                    child: CustomText(AppStrings.noNearbyPlacesFound.tr,
                      fontSize: 14, color: AppColors.grayText,
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _nearbyPlaces.length,
                    separatorBuilder: (_, __) => Divider(height: 1, indent: 58, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final place = _nearbyPlaces[index];
                      return InkWell(
                        onTap: () async {
                          final fullAddress =
                              "${place.name}, ${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
                          try {
                            List<Location> locations = await locationFromAddress(fullAddress);
                            if (locations.isNotEmpty) {
                              final selected = locations.first;
                              widget.onSubmit(
                                selected.latitude,
                                selected.longitude,
                                "${place.street}, ${place.locality}, ${place.postalCode}",
                                "${place.name ?? "Unknown"}",
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppStrings.failedToGetLocation.tr)),
                            );
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.place_outlined, color: AppColors.grayText, size: 20),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(place.name ?? "Unknown",
                                      fontSize: 14, fontWeight: FontWeight.w600,
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2),
                                    CustomText(
                                      "${place.street}, ${place.locality}, ${place.postalCode}",
                                      fontSize: 12, color: AppColors.grayText,
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor.withValues(alpha: 0.06) : Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryColor.withValues(alpha: 0.12)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? AppColors.primaryColor : AppColors.grayText,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 1),
                  CustomText(
                    subtitle,
                    fontSize: 12,
                    color: AppColors.grayText,
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: AppColors.primaryColor, size: 22),
          ],
        ),
      ),
    );
  }
}
