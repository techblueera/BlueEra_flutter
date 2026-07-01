import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/view/payment_setting_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/amount_withdraw_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/controller/wallet_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/widget/wallet_statics_view.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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

  @override
  void initState() {
    controller.getWalletApi();
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
          bool isInitialLoading =
              controller.viewWalletBalanceResponse.value.status == Status.LOADING;

          if (isInitialLoading) {
            return _buildWalletShimmer(statusBarHeight);
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
                  top: statusBarHeight + SizeConfig.size12,
                  bottom: SizeConfig.size12,
                ),
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(AppImageAssets.wallet_heater_bg), fit: BoxFit.fill)),
                // Inner translucent "glass frame" inset from the blue edges —
                // a thin white rounded border wrapping the whole header
                // content, matching the design.
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                  padding: EdgeInsets.symmetric(
                    vertical: SizeConfig.size16,
                    horizontal: SizeConfig.size10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top row: back button (left) · centered title · coin
                    // wallet pill (right). A Stack keeps the title screen-centred
                    // even though the two side widgets differ in width.
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomText(
                          AppStrings.currentBalance.tr,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () => Get.back(),
                            customBorder: const CircleBorder(),
                            child: Container(
                              height: SizeConfig.size34,
                              width: SizeConfig.size34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _coinPill(),
                        ),
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
                          // Current balance = eligible + awaited amounts.
                          '\u{20B9}${(controller.walletResponseModalClass.value.data?.eligibleBalance ?? 0) + (controller.walletResponseModalClass.value.data?.awaitedBalance ?? 0)}*',
                          fontSize: SizeConfig.heading,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    // Lifetime figures: Pending Balance + Total Earning on one
                    // row, Total Withdrawals beneath — matches the new design.
                    _headerStats(),
                    SizedBox(
                      height: 16,
                    ),
                    // Three actions: Add Account | Withdraw | History. History
                    // opens the transactions list (the old Transactions tab).
                    Row(
                      children: [
                        Expanded(
                          child: _headerButton(
                            label: AppStrings.addAccount.tr,
                            onTap: () => Get.to(() => PaymentSettingScreen()),
                          ),
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: _headerButton(
                            label: AppStrings.withdraw.tr,
                            onTap: () {
                              Get.to(() => AmountWithdrawScreen())?.then(
                                (value) => controller.getWalletApi(),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: _headerButton(
                            label: AppStrings.history.tr,
                            onTap: () => Get.toNamed(
                                RouteConstant.allTransactionsScreen),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                ),
              ),
              // Statics body — each section is its own white card (Joining
              // Bonus + income donuts). Left transparent so the app-wide
              // background (AppHomeBackground, set in App Background settings)
              // shows through behind the cards. Transactions moved to the
              // header "History" button.
              Expanded(
                child: WalletStaticsView(controller: referralController),
              )
            ],
          );
        }),
      ),
      ),
    );
  }

  /// Full-screen loading placeholder that mirrors the real layout: the blue
  /// balance header (label / amount / stat / two action buttons) over the same
  /// background, then the white card with a tab bar and a few transaction rows.
  Widget _buildWalletShimmer(double statusBarHeight) {
    return Column(
      children: [
        // ── Header (same blue background as the live header) ──────────
        Container(
          width: Get.width,
          padding: EdgeInsets.only(
            top: statusBarHeight + SizeConfig.size20,
            bottom: SizeConfig.size20,
          ),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppImageAssets.wallet_heater_bg),
              fit: BoxFit.fill,
            ),
          ),
          child: buildLoadingShimmer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                shimmerContainer(height: 16, width: 120, radius: 6),
                SizedBox(height: SizeConfig.size14),
                shimmerContainer(height: 30, width: 160, radius: 8),
                SizedBox(height: SizeConfig.size14),
                shimmerContainer(height: 16, width: 180, radius: 6),
                SizedBox(height: SizeConfig.size20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 35.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: shimmerContainer(
                            height: SizeConfig.size45, radius: 18),
                      ),
                      SizedBox(width: SizeConfig.extraLarge),
                      Expanded(
                        child: shimmerContainer(
                            height: SizeConfig.size45, radius: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── White card: tab bar + transaction-row placeholders ────────
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: buildLoadingShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: shimmerContainer(height: 18, radius: 6)),
                      SizedBox(width: 24),
                      Expanded(child: shimmerContainer(height: 18, radius: 6)),
                    ],
                  ),
                  SizedBox(height: 24),
                  ...List.generate(
                    6,
                    (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              shimmerContainer(
                                  height: 14, width: 140, radius: 6),
                              shimmerContainer(height: 14, width: 60, radius: 6),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              shimmerContainer(height: 12, width: 90, radius: 6),
                              shimmerContainer(height: 12, width: 50, radius: 6),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Coin-wallet pill shown at the top-right of the blue header — a white,
  /// gold-bordered capsule with a coin icon + the coin balance.
  ///
  /// TODO(coins): wire to the coin-wallet API once available. Coins are dummy
  /// (0) for now, matching the Coin Wallet card.
  Widget _coinPill() {
    const num coins = 0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size6,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3C24B), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(
            imagePath: AppImageAssets.coinIcon,
            height: 20,
            width: 20,
          ),
          SizedBox(width: SizeConfig.size6),
          CustomText(
            '$coins',
            fontSize: SizeConfig.medium15,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
        ],
      ),
    );
  }

  /// Header figures: Eligible Withdrawal + Awaited Amount on one row, Total
  /// Earning beneath — bound to the wallet API (eligibleBalance /
  /// awaitedBalance / computedTotalEarning).
  Widget _headerStats() {
    final data = controller.walletResponseModalClass.value.data;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statInline('Eligible Withdrawal', data?.eligibleBalance ?? 0),
            SizedBox(width: SizeConfig.size16),
            _statInline('Awaited Amount', data?.awaitedBalance ?? 0),
          ],
        ),
        SizedBox(height: 6),
        _statInline(
            AppStrings.totalEarning.tr, data?.computedTotalEarning ?? 0),
      ],
    );
  }

  /// "<label>: ₹<value>" inline pair in white, used by [_headerStats].
  Widget _statInline(String label, num value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          '$label: ',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        CustomText(
          '\u{20B9}$value',
          fontSize: SizeConfig.medium15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ],
    );
  }

  /// Frosted-glass action button used for the three header actions:
  /// translucent white fill over a backdrop blur, a soft white border and a
  /// 12-px radius — matching the design's glass buttons.
  Widget _headerButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: SizeConfig.size40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: CustomText(
              label,
              fontSize: SizeConfig.medium15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
