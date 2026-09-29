import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/coin/controller/earn_coin_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/controller/wallet_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  test('wallet, referral and coin controllers outlive the screen that '
      'first used them', () {
    final wallet = WalletController.to;
    final referral = ReferralController.to;
    final coins = EarnCoinController.to;

    // What GetX does when the route that registered them closes.
    Get.delete<WalletController>();
    Get.delete<ReferralController>();
    Get.delete<EarnCoinController>();

    expect(WalletController.to, same(wallet));
    expect(ReferralController.to, same(referral));
    expect(EarnCoinController.to, same(coins));
  });

  test('logout (a forced delete) starts the next account fresh', () {
    final referral = ReferralController.to;

    Get.delete<ReferralController>(force: true);

    expect(ReferralController.to, isNot(same(referral)));
  });
}
