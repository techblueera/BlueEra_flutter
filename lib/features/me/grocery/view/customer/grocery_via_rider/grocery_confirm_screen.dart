import 'dart:developer';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_rider_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_rider_card.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_bill_details.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroceryConfirmScreen extends StatefulWidget {
  final String orderId;
  const GroceryConfirmScreen({super.key, required this.orderId});

  @override
  State<GroceryConfirmScreen> createState() => _GroceryConfirmScreenState();
}

class _GroceryConfirmScreenState extends State<GroceryConfirmScreen> {
  final controller = getOrPut(() => GroceryRiderConsumerController());

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
                GroceryBillDetails(controller: controller),

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
                    return GroceryRiderCard(
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
                      AppStrings.groceryViewNoRidersAvailable.tr,
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


