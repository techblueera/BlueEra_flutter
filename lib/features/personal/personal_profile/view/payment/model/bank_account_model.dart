class BankAccountModel {
  final String id;
  final String bankName;
  final String logo;
  final String accountNumber;
  final String ifscCode;
  final bool isDefault;

  BankAccountModel({
    required this.id,
    required this.bankName,
    required this.logo,
    required this.accountNumber,
    required this.ifscCode,
    this.isDefault = false,
  });
}