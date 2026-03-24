import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class DiscoverCartIcon extends StatelessWidget {
  const DiscoverCartIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.pushNamed(
            context, RouteHelper.getYourCartScreenRoute()),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: LocalAssets(
            imagePath: AppIconAssets.cartIcon,
            height: SizeConfig.size24,
            width: SizeConfig.size24,
          ),
        ),
      ),
    );
  }
}
