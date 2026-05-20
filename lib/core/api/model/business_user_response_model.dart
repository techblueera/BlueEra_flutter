class BusinessUserResponseModel {
  bool? status;
  String? message;
  String? token;
  String? businessId;

  BusinessUserResponseModel({
    this.status,
    this.message,
    this.token,
    this.businessId,
  });

  BusinessUserResponseModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    token = json['token'];
    businessId = json['business'];
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'token': token,
        'business': businessId,
      };
}
