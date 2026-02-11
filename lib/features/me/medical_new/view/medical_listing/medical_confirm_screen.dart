import 'dart:developer';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical_new/controller/user_medical_controller.dart';
import 'package:BlueEra/features/me/medical_new/widget/medical_bill_details.dart';
import 'package:BlueEra/features/me/medical_new/widget/medical_rider_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MedicalConfirmScreen extends StatefulWidget {
  final String orderId;
  const MedicalConfirmScreen({super.key, required this.orderId});

  @override
  State<MedicalConfirmScreen> createState() => _MedicalConfirmScreenState();
}

class _MedicalConfirmScreenState extends State<MedicalConfirmScreen> {
  final controller = getOrPut(() => UserMedicalController());

  @override
  initState(){

    super.initState();
    controller.fetchNearByRidersApi();
  }

  @override
  void dispose() {
    controller.subscription?.cancel();
    log('Subscription cancelled successfully');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.yourCart,
      ),
      body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                vertical: SizeConfig.size15,
                horizontal: SizeConfig.size8
            ),
            child: Column(
              children: [
                MedicalBillDetails(controller: controller),

                SizedBox(height: SizeConfig.paddingXSL),

                Obx(()=> controller.isNearByRidersLoading.value
                ? Padding(
                  padding: EdgeInsets.all(SizeConfig.size20),
                  child: CircularProgressIndicator(),
                )
                : controller.arrRiders.isNotEmpty ? ListView.builder(
                  itemCount: controller.arrRiders.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    var rider = controller.arrRiders[index];
                    log('order id -- ${widget.orderId}');
                    return MedicalRiderCard(
                        rider: rider,
                        orderId: widget.orderId,
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

              ],
            ),
          )
      ),
    );
  }
}


