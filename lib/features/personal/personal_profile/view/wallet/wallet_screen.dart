import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/view/payment_setting_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/amount_withdraw_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/wallet_transaction_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/controller/wallet_controller.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/view/tabs/statics_tab.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/getx_utils.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final controller = getOrPut(() => WalletController());
  final referralController = getOrPut(() => ReferralController());

  /// 0 = Statics tab, 1 = Transactions tab.
  int _selectedTab = 0;

  @override
  void initState() {
    controller.getWalletApi();
    // Home uses its OWN unfiltered preview list — separate from the See-All
    // list, so a filter applied on See-All never affects this screen.
    controller.getPreviewTransactionApi();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
      // Let the blue header paint behind the status bar; only guard the
      // bottom/sides so the header reaches the very top of the screen.
      body: SafeArea(
        top: false,
        child: Obx(() {
          bool isInitialLoading = controller.viewWalletBalanceResponse.value.status == Status.LOADING ||
              controller.previewTransactionResponse.value.status == Status.LOADING;

          if (isInitialLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              Container(
                // No fixed height — the banner sizes to its content. Vertical
                // padding gives it height/breathing room, so it grows safely
                // when an extra row appears (e.g. pending balance) instead of
                // overflowing a hard-coded height.
                width: Get.width,
                padding: EdgeInsets.only(
                  top: statusBarHeight + SizeConfig.size20,
                  bottom: SizeConfig.size20,
                ),
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(AppImageAssets.wallet_heater_bg), fit: BoxFit.fill)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: InkWell(
                            onTap: () {
                              Get.back();
                            },
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        CustomText(
                          AppStrings.currentBalance.tr,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: 40,
                        )
                      ],
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        LocalAssets(
                          imagePath: AppIconAssets.walletIcon,
                          height: 26, // reduce icon size
                          width: 26,
                          imgColor: AppColors.white,
                        ),
                        SizedBox(
                          width: 12,
                        ),
                        CustomText(
                          (controller.walletResponseModalClass.value.data?.withdrawableAmount ?? "0")
                              .toString(),
                          fontSize: SizeConfig.heading,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        // Text('\u{20B9}${200}'),
                      ],
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    // Pending balance — shown only when there's money in an
                    // in-flight withdrawal (hidden at 0).
                    if (((controller.walletResponseModalClass.value.data
                                ?.pendingBalance ??
                            0) >
                        0)) ...[
                      _statRow(
                        AppStrings.pendingBalance.tr,
                        controller.walletResponseModalClass.value.data
                                ?.pendingBalance ??
                            0,
                      ),
                      SizedBox(height: 4),
                    ],
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     CustomText(
                    //       'Pending Balance:',
                    //       fontSize: SizeConfig.medium,
                    //       fontWeight: FontWeight.w600,
                    //       color: Colors.white,
                    //     ),
                    //     SizedBox(
                    //       width: 4,
                    //     ),
                    //     CustomText(
                    //       '\u{20B9}controller',
                    //       fontSize: SizeConfig.medium15,
                    //       fontWeight: FontWeight.w600,
                    //       color: Colors.white,
                    //     ),
                    //     SizedBox(
                    //       width: 12,
                    //     ),
                    //     CustomText(
                    //       'Total Earning:',
                    //       fontSize: SizeConfig.medium,
                    //       fontWeight: FontWeight.w600,
                    //       color: Colors.white,
                    //     ),
                    //     SizedBox(
                    //       width: 4,
                    //     ),
                    //     CustomText(
                    //       '\u{20B9}2,500',
                    //       fontSize: SizeConfig.medium15,
                    //       fontWeight: FontWeight.w600,
                    //       color: Colors.white,
                    //     ),
                    //   ],
                    // ),

                    _statsStrip(),
                    SizedBox(
                      height: 14,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35.0),
                      child: Row(
                        children: [
                          Expanded(
                              child: GestureDetector(
                            onTap: () {
                              Get.to(() => PaymentSettingScreen());
                              // Get.toNamed(RouteHelper.getAddBankAccountScreenRoute());
                            },
                            child: Container(
                              height: SizeConfig.size45,
                              decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.white),
                                  borderRadius: BorderRadius.circular(18)),
                              child: Center(
                                child: CustomText(
                                  AppStrings.addAccount.tr,
                                  fontSize: SizeConfig.medium15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )),
                          SizedBox(
                            width: SizeConfig.extraLarge,
                          ),
                          Expanded(
                              child: GestureDetector(
                            onTap: () {
                              Get.to(() => AmountWithdrawScreen())?.then(
                                (value) {
                                  controller.getPreviewTransactionApi();
                                  controller.getWalletApi();
                                },
                              );
                            },
                            child: Container(
                              height: SizeConfig.size45,
                              decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.white),
                                  borderRadius: BorderRadius.circular(18)),
                              child: Center(
                                child: CustomText(
                                  AppStrings.withdraw.tr,
                                  fontSize: SizeConfig.medium15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ))
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    // borderRadius: BorderRadiusGeometry.circular(12),
                  ),
                  margin: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Column(
                    children: [
                      _walletTabBar(),
                      SizedBox(height: 16),
                      Expanded(
                        child: _selectedTab == 0
                            ? StaticsTab(controller: referralController)
                            : _transactionsView(),
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        }),
      ),
      ),
    );
  }

  /// Two-tab switcher (Statics / Transactions) shown at the top of the white
  /// card. Selected tab gets a primary-coloured underline.
  Widget _walletTabBar() {
    Widget tab(String label, int index) {
      final selected = _selectedTab == index;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _selectedTab = index),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? AppColors.primaryColor : AppColors.greyE5,
                  width: 2,
                ),
              ),
            ),
            child: Center(
              child: CustomText(
                label,
                fontSize: SizeConfig.medium15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primaryColor : AppColors.grayText,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab('Statics', 0),
        tab('Transactions', 1),
      ],
    );
  }

  /// Transactions preview list + "See all" link (the previous wallet body).
  Widget _transactionsView() {
    return Column(
      children: [
        (controller.previewTransactionResponseModalClass.value.data?.isEmpty ?? true)
            ? Expanded(
                child: Center(
                  child: CustomText(AppStrings.noTransactionFound.tr),
                ),
              )
            : Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount:
                      ((controller.previewTransactionResponseModalClass.value.data?.length) ??
                          0),
                  itemBuilder: (context, index) {
                    WalletTransactionResponseModalClassDatum data =
                        controller.previewTransactionResponseModalClass.value.data![index];
                    return _customContainer(data: data);
                  },
                  separatorBuilder: (context, index) => SizedBox(
                    height: 20,
                  ),
                ),
              ),
        SizedBox(
          height: 8,
        ),
        InkWell(
          onTap: () => Get.toNamed(RouteConstant.allTransactionsScreen),
          child: CustomText(
            AppStrings.seeAllTransactions.tr,
            fontSize: 14,
            decoration: TextDecoration.underline,
            color: AppColors.skyBlueDF,
          ),
        )
      ],
    );
  }

  /// Lifetime figures (cumulative totals, distinct from the live withdrawable
  /// balance) shown as simple centered rows in the header.
  Widget _statsStrip() {
    final data = controller.walletResponseModalClass.value.data;
    return Column(
      children: [
        // _statRow(AppStrings.totalRewardAmount.tr, data?.totalRewardAmount ?? 0),
        // SizedBox(height: 4),
        _statRow(AppStrings.totalWithdrawals.tr, data?.totalWithdrawalAmount ?? 0),
      ],
    );
  }

  Widget _statRow(String label, num value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomText(
          label,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        SizedBox(width: 8),
        CustomText(
          '\u{20B9}$value',
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _customContainer({required WalletTransactionResponseModalClassDatum data}) {
    return Container(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomText(
                  data.title,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              CustomText(
                '${data.isCredit ? '+' : '-'} \u{20B9}${data.amountInRupees ?? 0}',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: data.isCredit ? AppColors.green39 : AppColors.orange,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                DateFormat(
                  'MMM d, hh:mm a',
                ).format(data.createdAt!.toLocal()),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.grayText,
              ),
              Row(
                children: [
                  Icon(
                    data.isPending
                        ? Icons.watch_later_outlined
                        : data.isRejected
                            ? Icons.cancel_outlined
                            : Icons.check_circle_outline_outlined,
                    color: data.isPending
                        ? AppColors.orange
                        : data.isRejected
                            ? AppColors.red
                            : AppColors.green39,
                    size: 14,
                  ),
                  SizedBox(
                    width: 4,
                  ),
                  CustomText(
                    data.statusLabel,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: data.isPending
                        ? AppColors.orange
                        : data.isRejected
                            ? AppColors.red
                            : AppColors.green39,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
