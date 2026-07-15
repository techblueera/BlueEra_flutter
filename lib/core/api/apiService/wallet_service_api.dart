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

  /// UPI details of a given user — used to render a pay-to QR for the
  /// conversation person. e.g. `wallet-service/wallet/user/<id>/upi`.
  String getUserUpiApi(String userId) =>
      'wallet-service/wallet/user/$userId/upi';

  // final String  joinAsBdm= 'wallet-service/bdm';
  final String getBdm = 'wallet-service/bdm';
  // final String  saveNewReferralCode= 'wallet-service/referral/save';
  final String bdmRegisterStepOne = 'wallet-service/bdm/register/step1';
  final String bdmRegisterStepTwo = 'wallet-service/bdm/register/step2';
  final String getBdmStatus = 'wallet-service/bdm/status';
  final String walletReferralStats = 'wallet-service/wallet/referral-stats';

  /// `PUT wallet-service/wallet/referral` — updates the signed-in user's
  /// referral code (body: `{ "referralCode": "<code>" }`). Allowed only
  /// while the profile's `referralCodeEditable` flag is true.
  final String walletReferralUpdate = 'wallet-service/wallet/referral';
  final String walletReferralHistory =
      'wallet-service//wallet/referral-history';
  final String walletDirectReferralIncome =
      'wallet-service/wallet/direct-referral-income';
  final String BdmDocumentsUpload = 'wallet-service/bdm/documents/upload';
  String checkReferral(String referralCode) =>
      'wallet-service/wallet/check-referral/$referralCode';
  final String referralSuggestions = 'wallet-service/bdm/referral-suggestions';
}
