class WalletReferralHistoryResponse {
  bool? success;
  List<WalletReferralHistoryData>? data;

  WalletReferralHistoryResponse({this.success, this.data});

  WalletReferralHistoryResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <WalletReferralHistoryData>[];
      json['data'].forEach((v) {
        data!.add(new WalletReferralHistoryData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class WalletReferralHistoryData {
  String? userId;
  String? name;
  String? profileImage;
  String? profession;
  String? subscriptionStatus;
  String? rawStatus;
  int? planCost;
  int? referralIncome;

  WalletReferralHistoryData(
      {this.userId,
        this.name,
        this.profileImage,
        this.profession,
        this.subscriptionStatus,
        this.rawStatus,
        this.planCost,
        this.referralIncome});

  WalletReferralHistoryData.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    name = json['name'];
    profileImage = json['profileImage'];
    profession = json['profession'];
    subscriptionStatus = json['subscriptionStatus'];
    rawStatus = json['rawStatus'];
    planCost = json['planCost'];
    referralIncome = json['referralIncome'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userId'] = this.userId;
    data['name'] = this.name;
    data['profileImage'] = this.profileImage;
    data['profession'] = this.profession;
    data['subscriptionStatus'] = this.subscriptionStatus;
    data['rawStatus'] = this.rawStatus;
    data['planCost'] = this.planCost;
    data['referralIncome'] = this.referralIncome;
    return data;
  }
}