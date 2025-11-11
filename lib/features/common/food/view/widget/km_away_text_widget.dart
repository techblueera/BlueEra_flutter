import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/map/view/location_service.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class KmAwayTextWidget extends StatefulWidget {
  final String lat, long;
  final double? isPadding;
  final bool isUnderlineShow;

  KmAwayTextWidget(
      {super.key, required this.lat, required this.long, this.isPadding, this.isUnderlineShow = true});

  @override
  State<KmAwayTextWidget> createState() => _KmAwayTextWidgetState();
}

class _KmAwayTextWidgetState extends State<KmAwayTextWidget> {
  var kmAway;

  @override
  Widget build(BuildContext context) {
    double latitude = double.tryParse(widget.lat) ?? 0.0;
    double longitude = double.tryParse(widget.long) ?? 0.0;
    if (latitude != 0.0 && longitude != 0.0) {
      kmAway = calculateDistanceKm(
          LocationService.lat, LocationService.lng, latitude, longitude);
    }
    if ((kmAway) != null)
      return InkWell(
        onTap: () {
          canGoogleMapOpen(latitude: latitude, longitude: longitude);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: widget.isPadding ?? SizeConfig.size10,
              vertical: widget.isPadding ?? 0
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LocalAssets(
                imagePath: AppIconAssets.location_new,
                imgColor: AppColors.primaryColor,
              height: 10,width: 10,
              ),
              SizedBox(
                width: SizeConfig.size5,
              ),
              CustomText(
                "${kmAway.toStringAsFixed(0)} km away",
                fontSize: SizeConfig.size8,
                maxLines: 1,
                color: AppColors.primaryColor,
                decoration: widget.isUnderlineShow ? TextDecoration.underline : null,
                decorationColor: widget.isUnderlineShow ? AppColors.primaryColor : null,
                decorationStyle: widget.isUnderlineShow ? TextDecorationStyle.solid : null,
              ),
            ],
          ),
        ),
      );
    return SizedBox.shrink();
  }
}
