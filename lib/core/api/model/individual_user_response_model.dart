class IndividualUserResponseModel {
  bool? status;
  String? message;
  String? token;

  IndividualUserResponseModel({this.status, this.message, this.token});

  IndividualUserResponseModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    token = json['token'];
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'token': token,
      };
}
