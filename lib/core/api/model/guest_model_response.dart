
class GuestUserResModel {
  bool? status;
  String? message;
  String? token;
  String? businessId;

  GuestUserResModel({this.status, this.message, this.token, this.businessId});

  GuestUserResModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    token = json['token'];
    businessId = json['business'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    data['token'] = this.token;
    data['business'] = this.businessId;
    return data;
  }
}
