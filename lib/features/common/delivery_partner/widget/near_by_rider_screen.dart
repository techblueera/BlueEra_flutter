import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/rider_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NearByRidersScreen extends StatefulWidget {
  const NearByRidersScreen({super.key});

  @override
  State<NearByRidersScreen> createState() => _NearByRidersScreenState();
}

class _NearByRidersScreenState extends State<NearByRidersScreen> {
  final controller = getOrPut(() => DeliveryPartnerController());

  @override
  initState(){
    super.initState();
    controller.fetchNearByRidersApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Near by Rider',
      ),
      body: SafeArea(
          child: Obx(()=> controller.isNearByRidersLoading.value
              ? Center(child: CircularProgressIndicator())
              : controller.arrRiders.isNotEmpty ? ListView.builder(
            itemCount: controller.arrRiders.length,
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(
                vertical: SizeConfig.size15,
                horizontal: SizeConfig.size8
            ),
            physics: BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              var rider = controller.arrRiders[index];
              return RiderCard(
                rider: rider,
              );
            },
          ) : Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.paddingXXXL,
              vertical: SizeConfig.paddingL,
            ),
            child: CustomText(
              'No riders are currently available at this location.',
              fontSize: SizeConfig.large18,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
            ),
          )
          )
      ),
    );
  }



}


