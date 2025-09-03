import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:BlueEra/environment_config.dart';

class RewardedAdService {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: androidRewardedAdUnitId!, // replace with your test/live ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
          debugPrint("✅ Rewarded Ad Loaded");
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint("❌ Rewarded Ad Failed: $error");
          _isAdLoaded = false;
        },
      ),
    );
  }

  void showRewardedAd(BuildContext context) {
    if (_rewardedAd != null && _isAdLoaded) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint("🎁 User earned reward: ${reward.amount} ${reward.type}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Reward Earned: ${reward.amount} ${reward.type}")),
          );
        },
      );
      _rewardedAd = null;
      _isAdLoaded = false;
      loadRewardedAd(); // preload next ad
    }
  }

  void dispose() {
    _rewardedAd?.dispose();
  }
}
