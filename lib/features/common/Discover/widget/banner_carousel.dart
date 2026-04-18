import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A reusable banner carousel with gradient scrim, back button,
/// location pill, and dot indicators.
class BannerCarousel extends StatefulWidget {
  final List<String> images;
  final VoidCallback onBack;
  final double statusBarHeight;

  /// Optional overlay gradient painted on top of the banner. If null,
  /// a default dark vignette is drawn for text readability.
  final LinearGradient? overlayGradient;

  /// Optional stroke painted around the banner (matches the bottom
  /// rounded corners). Pass a white `BorderSide` to get a crisp edge
  /// where the banner meets the content below.
  final BorderSide? bottomBorderSide;

  /// Background fill behind the rounded banner (visible in the
  /// corner gaps). Defaults to [AppColors.appBackgroundColor]; pass
  /// [Colors.transparent] when the surrounding screen paints its own
  /// backdrop and you want it to show through.
  final Color? backgroundColor;

  /// Shape applied to the banner image clip and the optional stroke.
  /// Defaults to a 24px bottom radius; pass [BorderRadius.zero] to
  /// get a straight-bottomed banner that meets the content below
  /// cleanly.
  final BorderRadiusGeometry? bannerBorderRadius;

  const BannerCarousel({
    super.key,
    required this.images,
    required this.onBack,
    required this.statusBarHeight,
    this.overlayGradient,
    this.bottomBorderSide,
    this.backgroundColor,
    this.bannerBorderRadius,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  int _bannerIndex = 0;
  bool _isLocationLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = (screenWidth * 8 / 16) + widget.statusBarHeight;
    final BorderRadiusGeometry clipRadius = widget.bannerBorderRadius ??
        const BorderRadius.vertical(bottom: Radius.circular(24));

    return Container(
      height: bannerHeight,
      width: double.infinity,
      color: widget.backgroundColor ?? AppColors.appBackgroundColor,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: clipRadius,
            child: CarouselSlider.builder(
              itemCount: widget.images.length,
              options: CarouselOptions(
                height: bannerHeight,
                viewportFraction: 1.0,
                autoPlay: widget.images.length > 1,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration:
                    const Duration(milliseconds: 800),
                autoPlayCurve: Curves.easeInOutCubic,
                enableInfiniteScroll: widget.images.length > 1,
                onPageChanged: (index, _) =>
                    setState(() => _bannerIndex = index),
              ),
              itemBuilder: (context, index, _) {
                return CachedNetworkImage(
                  imageUrl: widget.images[index],
                  width: double.infinity,
                  height: bannerHeight,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: AppColors.greyE5),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.greyE5),
                );
              },
            ),
          ),

          // Gradient scrim
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: widget.overlayGradient ??
                      LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          AppColors.black.withValues(alpha: 0.35),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                ),
              ),
            ),
          ),

          // Optional stroke that follows the ClipRRect shape.
          if (widget.bottomBorderSide != null)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: clipRadius,
                      side: widget.bottomBorderSide!,
                    ),
                  ),
                ),
              ),
            ),

          // Top row: back + location
          Positioned(
            top: widget.statusBarHeight + SizeConfig.size4,
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            child: Row(
              children: [
                _circleIconButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: widget.onBack,
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(child: _locationPill()),
              ],
            ),
          ),

          // Dot indicator
          if (widget.images.length > 1)
            Positioned(
              bottom: SizeConfig.size20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  final active = i == _bannerIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size3),
                    width: active ? SizeConfig.size16 : SizeConfig.size6,
                    height: SizeConfig.size6,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.white
                          : AppColors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(SizeConfig.size8),
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child:
              Icon(icon, color: AppColors.white, size: SizeConfig.size20),
        ),
      ),
    );
  }

  Widget _locationPill() {
    return Obx(() {
      final loc = LocationService.userCurrentAddress.value;
      final title =
          [loc.subLocality, loc.city].where((e) => e.isNotEmpty).join(', ');
      return InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _isLocationLoading ? null : _changeLocation,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size10, vertical: SizeConfig.size8),
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined,
                  color: AppColors.white, size: SizeConfig.size20),
              SizedBox(width: SizeConfig.size6),
              Flexible(
                child: CustomText(
                  title.isEmpty ? 'Select location' : title,
                  fontSize: SizeConfig.medium,
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: SizeConfig.size4),
              _isLocationLoading
                  ? SizedBox(
                      width: SizeConfig.size14,
                      height: SizeConfig.size14,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.white),
                      ),
                    )
                  : Icon(Icons.keyboard_arrow_down,
                      color: AppColors.white, size: SizeConfig.size18),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _changeLocation() async {
    setState(() => _isLocationLoading = true);
    await LocationService.fetchLocation(openSettingsOnDeny: true);
    if (!mounted) return;
    setState(() => _isLocationLoading = false);
  }
}
