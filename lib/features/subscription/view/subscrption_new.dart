import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../core/api/apiService/api_response.dart';
import '../../../core/constants/getx_utils.dart';
import '../../../core/constants/shared_preference_utils.dart';
import '../../../core/constants/snackbar_helper.dart';
import '../../../core/services/razor_pay_services.dart';
import '../../../widgets/custom_btn.dart';
import '../auth/controller/subscription_controller.dart';
import '../auth/model/subscription_list_details_model.dart';
import 'my_subscription_details.dart';

class SubscriptionScreenNew extends StatefulWidget {
  const SubscriptionScreenNew({super.key});

  @override
  State<SubscriptionScreenNew> createState() => _SubscriptionScreenNewState();
}

class _SubscriptionScreenNewState extends State<SubscriptionScreenNew> with SingleTickerProviderStateMixin{

  final controller = getOrPut(() => SubscriptionController());
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    getInitial();
    controller.subscriptionPlansGetApi();
    _tabController = TabController(length: 2, vsync: this);
  }

  void getInitial() {
    controller.userCurrentPlanApi({
      ApiKeys.status: AppConstants.active
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
          appBarColor: AppColors.white,
          title: "Contribution"
          // title: "Subscription"
      ),

      body: Obx(() {
        if(controller.userSubscriptionResponse.value == Status.INITIAL){
          return Center(child: CircularProgressIndicator());
        }

        if(controller.userSubscriptionResponse.value == Status.ERROR){
          return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  LocalAssets(imagePath: AppIconAssets.warningRedIcon),
                  SizedBox(height: SizeConfig.paddingXSL),
                  CustomText(
                    "oops.. something went wrong.",
                    fontSize: SizeConfig.extraLarge22,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                  ),
                ]
            ),
          );
        }

        return  (controller.mySubscriptionAvailable.value)
            ? Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: AppColors.mainTextColor,
              unselectedLabelColor: AppColors.secondaryTextColor,
              indicatorColor: AppColors.primaryColor,
              indicatorWeight: 4,
              tabAlignment: TabAlignment.fill,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontFamily: AppConstants.OpenSans),
              tabs: [
                Tab(text: "My Plan"),
                Tab(text: "Other Plans"),
              ],
            ),
            Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    MySubscriptionDetails(),
                    AllSubscriptionPlansWidget(),
                  ],
                ))
          ],
        )
            : AllSubscriptionPlansWidget();

      }),
    );
  }


}

class AllSubscriptionPlansWidget extends StatefulWidget {
  AllSubscriptionPlansWidget({super.key});

  @override
  State<AllSubscriptionPlansWidget> createState() => _AllSubscriptionPlansWidgetState();
}

class _AllSubscriptionPlansWidgetState extends State<AllSubscriptionPlansWidget> {
  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => SubscriptionController());

    return Obx(() {
      if (controller.getSubscriptionOfferResponse.value.status ==
          Status.COMPLETE) {

        List<SubscriptionPlanData>? subsList = controller
            .subscriptionPlanDetailsNewModel.value.data;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 16),
              Expanded(child: ListView.separated(
                itemCount: subsList?.length ?? 0,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  SubscriptionPlanData? details = subsList?[index];

                  int styleIndex = index % AppConstants.listOfSubsBg.length;

                  return GestureDetector(
                    onTap: () {
                      if(controller.selectedSubscriptionIndex.contains(index)) return;
                      controller.selectedSubscriptionIndex.clear();
                      controller.selectedSubscriptionIndex.add(index);
                      print('final amount to pay -- ${controller.finalAmount}');
                    },
                    child: CommonSubscriptionCard(
                      details: details,
                      index: index,
                      controller: controller,
                      style: AppConstants.listOfSubsBg[styleIndex],
                      tagText: details?.tier ?? "Basic",
                    ),
                  );
                },
              )),

              (controller.selectedSubscriptionIndex.isNotEmpty)
                ? Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 30),
                child: Column(
                  children: [
                    // CustomBtn(
                    //   width: double.infinity,
                    //   textColor: AppColors.red,
                    //   bgColor: Colors.transparent,
                    //   borderColor: AppColors.red,
                    //   title: "Cancel",
                    //   onTap: () async {
                    //     SubscriptionPlanData?
                    //     subscriptionPlanData = controller
                    //         .subscriptionPlanDetailsNewModel
                    //         .value
                    //         .data?[controller.selectedSubscriptionIndex.first];
                    //
                    //     await controller
                    //         .cancelSubscriptionController(
                    //         params: {
                    //           ApiKeys.subscriptionId: subscriptionPlanData?.id,
                    //           ApiKeys.cancel_at_cycle_end: true,
                    //         });
                    //     if (controller
                    //         .cancelSubscriptionResponse
                    //         .value
                    //         .status ==
                    //         Status.COMPLETE) {
                    //
                    //       controller.mySubscriptionAvailable.value = false;
                    //
                    //     }
                    //   },
                    // ),
                    // SizedBox(height: SizeConfig.paddingXSL),
                    CustomBtn(
                      // height: 48,
                      // isValidate: controller.selectedSubscriptionIndex.isNotEmpty,
                      width: double.infinity,
                      textColor: AppColors.white,
                      bgColor: AppColors.primaryColor,
                      title: "Pay",
                      onTap: () async {
                        SubscriptionPlanData?
                        subscriptionPlanData = controller
                            .subscriptionPlanDetailsNewModel
                            .value
                            .data?[controller.selectedSubscriptionIndex.first];

                        // final offerID = controller
                        //     .selectedOffer.value?.offerId;
                        await controller
                            .createSubscriptionController(
                            params: {
                              ApiKeys.planId: subscriptionPlanData?.planId,
                              ApiKeys.auto_pay: controller.isAutoPayEnabled.value,
                              // ApiKeys.offerId: "",
                              ApiKeys.subscriptionPlanId: subscriptionPlanData?.id,
                            });
                        if (controller
                            .createSubscriptionResponse
                            .value
                            .status ==
                            Status.COMPLETE) {
                          if (controller
                              .subscriptionData
                              .value
                              .success ??
                              false) {
                            final razorpayService =
                            RazorpayService();

                            razorpayService.openCheckout(
                              name: AppConstants.appName,
                              subscriptionId:
                              controller
                                  .subscriptionData
                                  .value
                                  .data
                                  ?.subscriptionId ??
                                  "",
                              description:
                              'Subscription Payment',
                              amount: controller
                                  .finalAmount.
                                  toDouble(),
                              contact: userMobileGlobal,
                              email:
                              '$userMobileGlobal@gmail.com',
                              onPaymentSuccess:
                                  (response) async {
                                await controller
                                    .verifySubscriptionController(
                                    params: {
                                      ApiKeys.razorpay_payment_id:
                                      response.paymentId ??
                                          "",
                                      ApiKeys.razorpay_signature:
                                      response.signature ??
                                          "",
                                      ApiKeys.razorpay_subscription_id:
                                      response.data![
                                      'razorpay_subscription_id'],
                                    });
                              },
                              onPaymentError: (response) {
                                commonSnackBar(
                                    message:
                                    "Payment Failed ${response.message}");
                              },
                            );
                          }
                        }
                      },
                    )
                  ],
                ),
              )
                : SizedBox(),
            ],
          ),
        );
      } else {
        return Center(
          child: CircularProgressIndicator(),
        );
      }
    });
  }

  Widget _header() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(
              "Go Premium ",
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.rating,
            ),
            LocalAssets(
              imagePath: "assets/images/premium.png",
              height: 32,
              width: 32,
            ),
          ],
        ),
        const SizedBox(height: 6),
        const CustomText(
          "No commitment, cancel anytime",
          fontSize: 16,
          fontWeight: FontWeight.w400,

          color: AppColors.secondaryTextColor,
        ),
      ],
    );
  }
}


class CommonSubscriptionCard extends StatelessWidget {
  final SubscriptionPlanData? details;
  final int index;
  final SubscriptionController controller;
  final SubscriptionPlanStyleModel style;
  final String tagText;

  const CommonSubscriptionCard({
    Key? key,
    required this.details,
    required this.index,
    required this.controller,
    required this.style,
    this.tagText = "BASIC",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Obx(() {
          final isSelected =
          controller.selectedSubscriptionIndex.contains(index);

          return isSelected
              ? Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                  AppColors.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _background(),
          )
              : _background();
        }),

        /// Content
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _priceBlock(),
                const SizedBox(width: 34),
                Expanded(child: _features()),
              ],
            ),
          ),
        ),

        /// Tag
        Positioned(
          left: 36,
          top: 16,
          child: _planTag(),
        ),
      ],
    );
  }

  Widget _background() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: LocalAssets(
        imagePath: style.bg,
        width: double.infinity,
        boxFix: BoxFit.cover,
      ),
    );
  }

  Widget _priceBlock() {
    return SizedBox(
      width: 110,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 16),
          CustomText(
            "₹${details?.amount != null ? (details!.amount! / 100) : '0'}",
            fontSize:
            (details?.amount.toString().length ?? 0) > 3
                ? 24
                : 36,
            fontWeight: FontWeight.w700,
            color: style.textColor,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CustomText(
              details?.period ?? "",
              fontSize: 12,
              textAlign: TextAlign.center,
              color: style.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _features() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          "Features",
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: style.textColor,
        ),
        const SizedBox(height: 6),

        /// Description
        _featureItem(
            details?.description == '' || details?.description == null
                ? "N/A"
                : details!.description??''),

        /// Perks
        ...details?.perks?.map(
              (e) => _featureItem(
              e == '' ? "N/A" : e),
        ) ??
            [],
      ],
    );
  }

  Widget _featureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14,
            color: style.textColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: CustomText(
              text,
              fontSize: 12,
              maxLines: 1,
              fontWeight: FontWeight.w400,
              color: style.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planTag() {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: CustomText(
        tagText.toUpperCase(),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
    );
  }
}
class SubscriptionPlanStyleModel {
  final String bg;
  final Color textColor;

  SubscriptionPlanStyleModel({
    required this.bg,
    required this.textColor,
  });

  factory SubscriptionPlanStyleModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlanStyleModel(
      bg: map['bg'] as String,
      textColor: map['textColor'] as Color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bg': bg,
      'textColor': textColor,
    };
  }

  SubscriptionPlanStyleModel copyWith({
    String? bg,
    Color? textColor,
  }) {
    return SubscriptionPlanStyleModel(
      bg: bg ?? this.bg,
      textColor: textColor ?? this.textColor,
    );
  }
}