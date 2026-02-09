import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/subscription_offer_model.dart';
import 'package:BlueEra/core/api/model/subscription_plan_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/razor_pay_services.dart';
import 'package:BlueEra/features/subscription/auth/controller/subscription_controller.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubscriptionScreen extends StatefulWidget {
  SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionController subscriptionController =
      Get.put(SubscriptionController());

  @override
  void initState() {
   // getDataApiCall();

    super.initState();
  }

  @override
  void dispose() {
    deleteIfRegistered<SubscriptionController>();
    super.dispose();
  }

  getDataApiCall() async {
    await subscriptionController.getSubscriptionPlan();
    await subscriptionController.getSubscriptionOffer();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            physics: ScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.size15, horizontal: SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: SizeConfig.size10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CustomText(
                        AppStrings.goPremium,
                        fontSize: SizeConfig.extraLarge22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.yellow00,
                      ),
                      SizedBox(width: SizeConfig.size5),
                      LocalAssets(
                        imagePath: AppIconAssets.diamond_premium,
                        height: SizeConfig.size25,
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size5),
                  CustomText(
                    AppStrings.noCommitment,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w200,
                    color: AppColors.black1A,
                  ),
                  SizedBox(height: SizeConfig.size10),
                  _premiumCard(),
                  SizedBox(height: SizeConfig.size5),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size16, vertical: 0),
                    // color: AppColors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CustomText(AppStrings.redeemCoin,
                                fontSize: 16, fontWeight: FontWeight.w500),
                            SizedBox(width: 4),
                            Icon(
                              Icons.info_outline,
                              size: 18,
                            ),
                          ],
                        ),
                        Obx(() => Switch(
                              value:
                                  subscriptionController.isRedeemEnabled.value,
                              onChanged: subscriptionController.toggleRedeem,
                              activeColor: Colors.white,
                              activeTrackColor: AppColors.primaryColor,
                            )),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.size15,
                        horizontal: SizeConfig.size10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText(
                              AppStrings.availableCoinAndValue,
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w200,
                              color: AppColors.black,
                            ),
                            CustomText(
                              "₹ 3000 = ₹ 300",
                              fontSize: SizeConfig.medium15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.yellow00,
                            ),
                          ],
                        ),
                        Divider(
                          color: Colors.grey,
                          thickness: 0.2,
                        ),
                        CustomText(
                          AppStrings.choosePaymentType,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w200,
                          color: AppColors.black,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Obx(() => InkWell(
                                  onTap: () {
                                    subscriptionController
                                        .selectMethod(PaymentMethod.upi);
                                  },
                                  child: Row(
                                    children: [
                                      Radio<PaymentMethod>(
                                        fillColor: WidgetStateProperty.all(
                                            AppColors.primaryColor),
                                        value: PaymentMethod.upi,
                                        groupValue: subscriptionController
                                            .selectedMethod.value,
                                        onChanged:
                                            subscriptionController.selectMethod,
                                        activeColor: AppColors.primaryColor,
                                      ),
                                      CustomText(
                                        "UPI",
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                )),
                            SizedBox(width: 20),
                            Obx(() => InkWell(
                                  onTap: () {
                                    subscriptionController
                                        .selectMethod(PaymentMethod.card);
                                  },
                                  child: Row(
                                    children: [
                                      Radio<PaymentMethod>(
                                        fillColor: WidgetStateProperty.all(
                                            AppColors.primaryColor),
                                        value: PaymentMethod.card,
                                        groupValue: subscriptionController
                                            .selectedMethod.value,
                                        onChanged:
                                            subscriptionController.selectMethod,
                                        activeColor: AppColors.primaryColor,
                                      ),
                                      CustomText(
                                        AppStrings.card,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                        CustomText(
                          AppStrings.selectCoinToRedeem,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w200,
                          color: AppColors.black,
                        ),
                        SizedBox(height: SizeConfig.size10),
                        Obx(() {
                          if (subscriptionController.subscriptionOfferModel
                                  .value.data?.isNotEmpty ??
                              false) {
                            return CommonDropdown<OfferData>(
                              items: subscriptionController
                                      .subscriptionOfferModel.value.data ??
                                  [],
                              selectedValue:
                                  subscriptionController.selectedOffer.value,
                              hintText: AppStrings.selectOffer,
                              displayValue: (offer) => ((offer.name ?? "")),
                              onChanged: (offer) {
                                subscriptionController.selectOffer(offer);
                                subscriptionController.calculateAmount();
                              },
                            );
                          }
                          return SizedBox();
                        }),
                        SizedBox(height: SizeConfig.size15),
                        Obx(() {
                          if (subscriptionController.selectedIndex.value !=
                              null) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: SizeConfig.size10,
                                  horizontal: SizeConfig.size10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.shadowColor
                                    .withValues(alpha: 0.20),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CustomText(
                                    AppStrings.finalAmountToPay,
                                    fontSize: SizeConfig.medium15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  CustomText(
                                    "₹${subscriptionController.finalPayAmount}",
                                    fontSize: SizeConfig.large18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.black,
                                  ),
                                ],
                              ),
                            );
                          }
                          return SizedBox();
                        }),
                        SizedBox(height: SizeConfig.size10),
                        CustomText(
                          AppStrings.payThroughUPI,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w200,
                          color: AppColors.red,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CustomText(AppStrings.enableAutoPay,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.info_outline,
                                    size: 18,
                                  ),
                                ],
                              ),
                              Obx(() => Switch(
                                    value: subscriptionController
                                        .isAutoPayEnabled.value,
                                    onChanged:
                                        subscriptionController.toggleAutoPay,
                                    activeColor: Colors.white,
                                    activeTrackColor: AppColors.primaryColor,
                                  )),
                            ],
                          ),
                        ),
                        Obx(() {
                          return Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: SizeConfig.size15,
                                  horizontal: SizeConfig.size10),
                              child: CustomBtn(
                                // bgColor: AppColors.primaryColor,
                                title: AppStrings.pay,
                                isValidate: subscriptionController
                                        .selectedIndex.value !=
                                    null,
                                onTap: subscriptionController
                                            .selectedIndex.value !=
                                        null
                                    ? () async {
                                        final planID = subscriptionController
                                            .subscriptionDetailModel
                                            .value
                                            .data?[subscriptionController
                                                    .selectedIndex.value ??
                                                -1]
                                            .planId;

                                        final offerID = subscriptionController
                                            .selectedOffer.value?.offerId;
                                        await subscriptionController
                                            .createSubscriptionController(
                                                params: {
                                              ApiKeys.planId: planID,
                                              ApiKeys.auto_pay:
                                                  subscriptionController
                                                      .isAutoPayEnabled.value,
                                              ApiKeys.offerId: offerID ?? "",
                                            });
                                        if (subscriptionController
                                                .createSubscriptionResponse
                                                .value
                                                .status ==
                                            Status.COMPLETE) {
                                          if (subscriptionController
                                                  .subscriptionData
                                                  .value
                                                  .success ??
                                              false) {
                                            final razorpayService =
                                                RazorpayService();

                                            razorpayService.openCheckout(
                                              name: AppConstants.appName,
                                              subscriptionId:
                                                  subscriptionController
                                                          .subscriptionData
                                                          .value
                                                          .data
                                                          ?.subscriptionId ??
                                                      "",
                                              description:
                                                  'Subscription Payment',
                                              amount: subscriptionController
                                                      .finalPayAmount.value
                                                      ?.toDouble() ??
                                                  -1,
                                              contact: userMobileGlobal,
                                              email:
                                                  '$userMobileGlobal@gmail.com',
                                              onPaymentSuccess:
                                                  (response) async {
                                                await subscriptionController
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
                                      }
                                    : null,
                              ));
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _premiumCard() {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Obx(() {
          List<GetSubscriptionData>? dataList =
              subscriptionController.subscriptionDetailModel.value.data ?? [];
          if (dataList.isEmpty) {
            return CustomText(AppStrings.noDataFound);
          }
          return ListView.builder(
              scrollDirection: Axis.vertical,
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: dataList.length,
              itemBuilder: (context, index) {
                GetSubscriptionData? subscriptionData = dataList[index];
                List<String> words =
                    subscriptionData.name.toString().split(" ");
                return Obx(() {
                  return InkWell(
                    onTap: () async {
                      subscriptionController.selectedIndex.value = index;
                      subscriptionController.calculateAmount();
                    },
                    child: Container(
                        margin: EdgeInsets.symmetric(
                          vertical: SizeConfig.size5,
                        ),
                        padding: EdgeInsets.symmetric(
                            vertical: SizeConfig.size10,
                            horizontal: SizeConfig.size10),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: subscriptionController
                                            .selectedIndex.value ==
                                        index
                                    ? AppColors.primaryColor
                                    : Colors.white)),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(height: SizeConfig.size10),
                                  _premiumCard2("${words[0]}"),
                                  SizedBox(height: SizeConfig.size10),
                                  CustomText(
                                    "₹${subscriptionData.amount}",
                                    fontSize: SizeConfig.heading,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  SizedBox(height: SizeConfig.size10),
                                  CustomText(
                                    "${subscriptionData.interval} ${subscriptionData.period?.capitalizeFirst} Plan",
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.grey,
                                  )
                                ],
                              ),
                              SizedBox(height: SizeConfig.size5),
                              VerticalDivider(
                                color: Colors.grey,
                                thickness: 0.1,
                              ),
                              Expanded(
                                  child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _premiumCard3(
                                      "${subscriptionData.description}",
                                      AppColors.primaryColor,
                                      AppColors.black,
                                    ),
                                  ),
                                  CustomBtn(
                                    height: SizeConfig.size30,
                                    bgColor: Colors.white,
                                    borderColor: AppColors.primaryColor,
                                    textColor: AppColors.primaryColor,
                                    title: AppStrings.viewDetails,
                                    onTap: () {},
                                  ),
                                ],
                              )),
                            ],
                          ),
                        )),
                  );
                });
              });
        }));
  }

  Widget _premiumCard2(String value) {
    return Container(
        padding: EdgeInsets.symmetric(
            vertical: SizeConfig.size10, horizontal: SizeConfig.size15),
        decoration: BoxDecoration(
          boxShadow: [AppShadows.textFieldShadow],
          borderRadius: BorderRadius.circular(10),
          color: AppColors.primaryColor,
        ),
        child: CustomText(
          value.toUpperCase(),
          color: AppColors.white,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.bold,
        ));
  }

  Widget _premiumCard3(String value, Color color, color2) {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: SizeConfig.size5, horizontal: SizeConfig.size5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalAssets(
            imagePath: AppIconAssets.rightCircleOutlineBlue,
            imgColor: color,
            height: SizeConfig.size15,
          ),
          SizedBox(width: SizeConfig.size5),
          Expanded(
              child: CustomText(
            value,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w300,
            color: color2,
            maxLines: 2,
          ))
        ],
      ),
    );
  }
}
