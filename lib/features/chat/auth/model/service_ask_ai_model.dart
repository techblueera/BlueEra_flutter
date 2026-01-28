import 'package:BlueEra/features/chat/auth/model/base_ai_chat_model.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';

class ServiceAskAiModel extends BaseAiChatModel {
  Data? data;

  ServiceAskAiModel({
    super.conversationId,
    super.role,
    super.timestamp,
    super.message,
    this.data,

  });

  factory ServiceAskAiModel.fromJson(Map<String, dynamic> json) {
    return ServiceAskAiModel(
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
  bool? success;
  List<GetServiceModel>? serviceModel;

  Data({
    this.success,
    this.serviceModel,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      success: json['success'],
      serviceModel: json['data'] != null
          ? (json['data'] as List)
          .map((i) => GetServiceModel.fromJson(i))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'data': serviceModel?.map((e) => e.toJson()).toList(),
  };


}