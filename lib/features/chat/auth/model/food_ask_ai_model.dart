import 'package:BlueEra/features/chat/auth/model/base_ai_chat_model.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';

class FoodAskAiModel extends BaseAiChatModel {
  Data? data;

  FoodAskAiModel({
    super.conversationId,
    super.role,
    super.timestamp,
    super.message,
    this.data,

  });

  factory FoodAskAiModel.fromJson(Map<String, dynamic> json) {
    return FoodAskAiModel(
      message: json['reply'] ?? json['content'],
      role: json['role'],
      conversationId: json['conversationId'],
      timestamp: json['timestamp'],
      data: json['data'] != null ? Data.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'content': message,
    'role': role,
    'conversationId': conversationId,
    'timestamp': timestamp,
    'data': data?.toJson()
  };
}

class Data{
  bool? found;
  GetServiceModel? serviceModel;

  Data({
    this.found,
    this.serviceModel,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      found: json['found'],
      serviceModel: json['service_model'] != null ? GetServiceModel.fromJson(json['service_model']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'found': found,
    'service_model': serviceModel?.toJson(),
  };


}