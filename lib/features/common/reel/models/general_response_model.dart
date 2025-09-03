class GeneralResponseModel {
  final bool success;
  final String message;

  GeneralResponseModel({
    required this.success,
    required this.message,
  });

  factory GeneralResponseModel.fromJson(Map<String, dynamic> json) {
    return GeneralResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
  };
}
