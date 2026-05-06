import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public detail screen for a single vehicle
/// (`GET /vehicles/get/:id`).
///
/// Pulls owner + business hydration via [VehicleController.fetchVehicleById]
/// (the server enriches both via gRPC) and surfaces the full spec
/// sheet, image gallery, owner card, and primary contact CTAs.
class VehicleDetailScreen extends StatefulWidget {
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final VehicleController _ctrl =
      getOrPut(() => VehicleController(), permanent: true);
  int _galleryIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _ctrl.fetchVehicleById(widget.vehicleId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      body: Obx(() {
        final state = _ctrl.vehicleDetailState.value;
        if (state.status == Status.LOADING && _ctrl.selectedVehicle.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == Status.ERROR && _ctrl.selectedVehicle.value == null) {
          return _errorView(state.message ?? 'Failed to load');
        }
        final v = _ctrl.selectedVehicle.value;
        if (v == null) return _errorView('Vehicle not found');
        return _buildBody(v);
      }),
    );
  }

  Widget _errorView(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: Colors.red.shade400),
              SizedBox(height: SizeConfig.size12),
              CustomText(msg,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor),
              SizedBox(height: SizeConfig.size16),
              ElevatedButton.icon(
                onPressed: () => _ctrl.fetchVehicleById(widget.vehicleId),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
              SizedBox(height: SizeConfig.size8),
              TextButton(
                onPressed: () => Get.back<void>(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );

  Widget _buildBody(Vehicle v) {
    final allImages = [
      if ((v.coverImage ?? '').isNotEmpty) v.coverImage!,
      ...v.images,
    ];
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: const Color(0xFF1E88FF),
          foregroundColor: Colors.white,
          expandedHeight: 280,
          flexibleSpace: FlexibleSpaceBar(
            title: CustomText(
              v.name,
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            background: _gallery(allImages),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            _headerCard(v),
            _specsCard(v),
            if ((v.description ?? '').isNotEmpty) _descriptionCard(v),
            if (v.location != null) _locationCard(v),
            if (v.user != null || v.business != null) _ownerCard(v),
            SizedBox(height: SizeConfig.size20),
          ]),
        ),
      ],
    );
  }

  Widget _gallery(List<String> images) {
    if (images.isEmpty) {
      return Container(
        color: const Color(0xFFEAF2FB),
        alignment: Alignment.center,
        child: Icon(
          Icons.directions_car_rounded,
          size: 96,
          color: AppColors.primaryColor.withValues(alpha: 0.5),
        ),
      );
    }
    return Stack(
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _galleryIndex = i),
          itemBuilder: (_, i) => CachedNetworkImage(
            imageUrl: images[i],
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) =>
                Container(color: const Color(0xFFEAF2FB)),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _galleryIndex ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: i == _galleryIndex ? 1 : 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _headerCard(Vehicle v) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  v.name,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
              ),
              if (v.isVerified ?? false)
                Icon(Icons.verified_rounded,
                    color: AppColors.primaryColor, size: 18),
            ],
          ),
          SizedBox(height: SizeConfig.size4),
          CustomText(
            [
              if ((v.brand ?? '').isNotEmpty) v.brand,
              if ((v.model ?? '').isNotEmpty) v.model,
              if (v.year != null) '${v.year}',
            ].whereType<String>().join(' '),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(height: SizeConfig.size12),
          if (v.price != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CustomText(
                  _priceLabel(v),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryColor,
                ),
                SizedBox(width: SizeConfig.size4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: CustomText(
                    v.currency ?? 'INR',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _specsCard(Vehicle v) {
    final entries = <MapEntry<String, String>>[
      if ((v.category ?? '').isNotEmpty) MapEntry('Category', v.category!),
      if ((v.subCategory ?? '').isNotEmpty)
        MapEntry('Sub-category', v.subCategory!),
      if (v.fuelType != null) MapEntry('Fuel', v.fuelType!.wire),
      if (v.transmission != null) MapEntry('Transmission', v.transmission!.wire),
      if (v.seatingCapacity != null)
        MapEntry('Seating', '${v.seatingCapacity}'),
      if ((v.mileage ?? '').isNotEmpty) MapEntry('Mileage', v.mileage!),
      if ((v.color ?? '').isNotEmpty) MapEntry('Color', v.color!),
      if ((v.registrationNo ?? '').isNotEmpty)
        MapEntry('Reg. no.', v.registrationNo!),
    ];
    if (entries.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Specifications',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size10),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: entries
                .map((e) => SizedBox(
                      width: (MediaQuery.of(context).size.width - 24 - 32 - 16) /
                          2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            e.key,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryTextColor,
                          ),
                          SizedBox(height: SizeConfig.size4),
                          CustomText(
                            e.value,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mainTextColor,
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _descriptionCard(Vehicle v) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'About this vehicle',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size8),
          CustomText(
            v.description!,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _locationCard(Vehicle v) {
    final loc = v.location!;
    final parts = <String>[
      if ((loc.address ?? '').isNotEmpty) loc.address!,
      if ((loc.city ?? '').isNotEmpty) loc.city!,
      if ((loc.state ?? '').isNotEmpty) loc.state!,
      if (loc.pincode != null) loc.pincode!.toString(),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_rounded, color: AppColors.primaryColor),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Location',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size4),
                CustomText(
                  parts.join(', '),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
          if (loc.lat != null && loc.lon != null)
            IconButton(
              icon: Icon(Icons.directions_rounded, color: AppColors.primaryColor),
              onPressed: () => _openMaps(loc.lat!, loc.lon!),
            ),
        ],
      ),
    );
  }

  Widget _ownerCard(Vehicle v) {
    final ownerName = (v.user?['name'] ?? v.business?['business_name'] ?? '')
        .toString();
    final ownerImage =
        (v.user?['profile_image'] ?? v.business?['logo_image'] ?? '').toString();
    final ownerPhone = (v.user?['contact_no'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: ownerImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: ownerImage,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _avatarFallback(),
                  )
                : _avatarFallback(),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  ownerName.isEmpty ? 'Listed by' : ownerName,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                CustomText(
                  v.business != null ? 'Business' : 'Personal',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
          if (ownerPhone.isNotEmpty)
            IconButton(
              icon: Icon(Icons.call_rounded, color: AppColors.primaryColor),
              onPressed: () => _dial(ownerPhone),
            ),
        ],
      ),
    );
  }

  Widget _avatarFallback() => Container(
        width: 48,
        height: 48,
        color: AppColors.primaryColor.withValues(alpha: 0.10),
        alignment: Alignment.center,
        child: Icon(Icons.person_rounded, color: AppColors.primaryColor),
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEFF4)),
      );

  String _priceLabel(Vehicle v) {
    if (v.price == null) return '';
    final cur = (v.currency ?? 'INR').toUpperCase();
    final symbol = cur == 'INR' ? '₹ ' : '$cur ';
    final p = v.price!;
    String formatted;
    if (p >= 1e7) {
      formatted = '${(p / 1e7).toStringAsFixed(2)} Cr';
    } else if (p >= 1e5) {
      formatted = '${(p / 1e5).toStringAsFixed(2)} L';
    } else {
      formatted = p.toStringAsFixed(0);
    }
    return '$symbol$formatted';
  }

  Future<void> _dial(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMaps(double lat, double lon) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
