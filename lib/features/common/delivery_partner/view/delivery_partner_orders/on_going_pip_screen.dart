
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_enum.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../chat/auth/model/rider_orders_details_model.dart';
import '../../controller/delivery_partner_orders_controller.dart';
import '../../controller/pip_floating_page_controller.dart';
import '../../widget/order_card.dart';

class OnGoingPipScreen extends StatefulWidget {
  const OnGoingPipScreen({super.key});

  @override
  State<OnGoingPipScreen> createState() => _OnGoingPipScreenState();
}

class _OnGoingPipScreenState extends State<OnGoingPipScreen> with WidgetsBindingObserver {
  double dragX = 0;
  final controller = getOrPut(() => PipFloatingPageController());
  final deliveryOrdersController = getOrPut(() => DeliverPartnerOrdersController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      enablePip();
    });

  }
void enablePip()async{
  await controller.setPipStatus(true);
  await controller.platformData.invokeMethod('enterPip');
  controller.isPipModeOn.value=true;
}
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    switch (state) {
      case AppLifecycleState.inactive:
        controller.isPipModeOn.value=true;
        break;

      case AppLifecycleState.paused:
      // 🔴 App goes to recent / background
      // Good place to prepare PiP UI
        break;

      case AppLifecycleState.resumed:
      // 🟢 App came back from recent / PiP
        controller.isPipModeOn.value = false;
        break;

      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) async {

          if (didPop) return;
          // Also trigger PiP if they click the Back button
          controller.isPipModeOn.value=true;
          await controller.platformData.invokeMethod('enterPip');

        },

        child: Obx(() {
          final orders = controller.isPipModeOn.value
              ? deliveryOrdersController.onGoingOrders.take(1).toList()
              : deliveryOrdersController.onGoingOrders;
          return Scaffold(
            backgroundColor:  !controller.isPipModeOn.value?null:AppColors.white,
            appBar: controller.isPipModeOn.value?null:CommonBackAppBar(
              title: "On Going Ride",
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: double
                      .infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal:
                  !controller.isPipModeOn.value?10:4,
                      vertical:
                  !controller.isPipModeOn.value?10:2),
                  child: Column(
                    children: [
                      if (!controller.isPipModeOn.value) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              /// Animated Ride Indicator
                              Container(
                                height: 44,
                                width: 44,
                                decoration: BoxDecoration(
                                  color:AppColors.whiteE5,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.bike_scooter,
                                  color: Colors.green,
                                  size: 26,
                                ),
                              ),

                              const SizedBox(width: 12),

                              /// Ride Status Text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    CustomText(
                                      "Ride in Progress",
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      // color: bl,
                                    ),
                                    SizedBox(height: 2),
                                    CustomText(
                                      "Heading to drop location",
                                      fontSize: 12,
                                      color: AppColors.grayText,
                                    ),
                                  ],
                                ),
                              ),

                              /// Live Dot
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const CustomText(
                                  "LIVE",
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // ...deliveryOrdersController.onGoingOrders.map((e)=>
                      //     _buildContent(controller.isPipModeOn.value,e)
                      // ).toList(),
                      ...orders.map((rider) {
                        return OrderCard(
                          isPipModeOn: controller.isPipModeOn.value,
                          order: rider,
                          selectedPickUp: PickUpTab.onGoing,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          );
        })

    );
  }

  Widget _buildContent(bool isPip,RiderOrdersDetailsModel orders) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.white
      ),
      padding: EdgeInsets.symmetric(horizontal: !isPip ? 10 : 0,vertical: !isPip ?  10:0),
      margin: EdgeInsets.symmetric(vertical: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // if (!isPip) ...[
          // const SizedBox(height: 8),
            CustomText(
              "Ongoing Ride",
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 8),
          // ],

          /// Drop Location
          Container(
            padding: EdgeInsets.all(isPip ? 10 : 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.whiteE5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "DROP LOCATION",
                  fontSize: isPip ? 13 : 12,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
                const SizedBox(height: 4),
                CustomText(
                  "${orders.dropLocation?.address}",
                  fontSize: isPip ? 14 : 13,
                  color: Colors.black54,
                  maxLines: isPip ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _slideToComplete(isPip),
        ],
      ),
    );
  }

  Widget _slideToComplete(bool isPip) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sliderWidth = constraints.maxWidth;
        final buttonWidth = isPip ? 64.0 : 56.0;

        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.whiteE5,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Stack(
            children: [
              Center(
                child: CustomText(
                  "Slide to complete",
                  fontSize: isPip ? 15 : 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Positioned(
                left: dragX,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      dragX += details.delta.dx;
                      dragX = dragX.clamp(
                        0,
                        sliderWidth - buttonWidth,
                      );
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    if (dragX > (sliderWidth - buttonWidth) * 0.7) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Order Completed")),
                      );
                    }
                    setState(() => dragX = 0);
                  },
                  child: Container(
                    height:48,
                    width: buttonWidth,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}
