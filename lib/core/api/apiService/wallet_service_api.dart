/// All `wallet-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
///
/// Note: `walletReferralHistory` contains a double slash
/// (`wallet-service//wallet/referral-history`) — preserved to mirror what
/// the client currently sends.
mixin WalletServiceApi {
  // Payment Setting;
  final String addAccountApi = "wallet-service/withdrawal-methods";
  final String getAccountApi = "/wallet-service/payment/getAccounts";
  final String updateAccountIdApi = "/wallet-service/payment/updateAccount/";
  final String accountDeleteApi = "/wallet-service/payment/deleteAccount/";
  final String setDefaultBankApi = "/wallet-service/payment/setDefaultBank/";

  // Wallet
  final String WithdrawalApi = "wallet-service/withdrawals";
  final String WalletApi = "wallet-service/wallet";
  final String walletWithdrawalMethod = "wallet-service/withdrawal-methods";
  final String WalletTransctionApi = "wallet-service/transactions?";

  final String walletPendingReferral = 'wallet-service/wallet/pending-referral';

  // final String  joinAsBdm= 'wallet-service/bdm';
  final String getBdm = 'wallet-service/bdm';
  // final String  saveNewReferralCode= 'wallet-service/referral/save';
  final String bdmRegisterStepOne = 'wallet-service/bdm/register/step1';
  final String bdmRegisterStepTwo = 'wallet-service/bdm/register/step2';
  final String getBdmStatus = 'wallet-service/bdm/status';
  final String walletReferralStats = 'wallet-service/wallet/referral-stats';
  final String walletReferralHistory =
      'wallet-service//wallet/referral-history';
  final String walletDirectReferralIncome =
      'wallet-service/wallet/direct-referral-income';
  final String BdmDocumentsUpload = 'wallet-service/bdm/documents/upload';
  String checkReferral(String referralCode) =>
      'wallet-service/wallet/check-referral/$referralCode';
  final String referralSuggestions = 'wallet-service/bdm/referral-suggestions';
}
