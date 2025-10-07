import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class ConsultBottomSheet extends StatelessWidget {
  ConsultBottomSheet({Key? key}) : super(key: key);

  final List<_Service> _services = [
    _Service('Swadesh\nSamaan',  AppIconAssets.localGoodsIcon),
    _Service('Consult by\ncontent creation', AppIconAssets.contentCreationIcon),
    _Service('Self\nEmployment ', AppIconAssets.selfEmploymentIcon),
    _Service('Desi\nKhana', AppIconAssets.foodBowlIcon),
    _Service('Home\nServices', AppIconAssets.homeServiceIcon),
    _Service('Rental\nServices', AppIconAssets.homeRentalIcon),
    _Service('Delivery', AppIconAssets.deliveryBoyIcon),
    _Service('Part-Time\njobs', AppIconAssets.jobSearchIcon),
    _Service('Teaching', AppIconAssets.jobSearchIcon),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                'Earn With BlueEra',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2-column grid
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _services.length,
              itemBuilder: (_, i) => _ServiceCard(service: _services[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Service {
  final String label;
  final String icon;
  const _Service(this.label, this.icon);
}

class _ServiceCard extends StatelessWidget {
  final _Service service;
  const _ServiceCard({Key? key, required this.service}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => Navigator.pop(context, service.label),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.greyE5, width: 1),
                    boxShadow: [AppShadows.textFieldShadow]
                ),
                alignment: Alignment.center,
                child: LocalAssets(imagePath: service.icon)),
            const SizedBox(height: 12),
            CustomText(
              service.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
          ],
        ),
      ),
    );
  }
}