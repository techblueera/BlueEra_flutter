class SupportCase {
  String? id;
  String? type;
  String? subject;
  String? message;
  String? status;
  String? priority;
  List<dynamic>? attachments;
  List<dynamic>? responses;
  DateTime? createdAt;
  DateTime? updatedAt;

  SupportCase({
    this.id,
    this.type,
    this.subject,
    this.message,
    this.status,
    this.priority,
    this.attachments,
    this.responses,
    this.createdAt,
    this.updatedAt,
  });

  factory SupportCase.fromJson(Map<String, dynamic> json) {
    return SupportCase(
      id: json['_id'],
      type: json['type'],
      subject: json['subject'],
      message: json['message'],
      status: json['status'],
      priority: json['priority'],
      attachments: json['attachments'] as List<dynamic>?,
      responses: json['responses'] as List<dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'subject': subject,
      'message': message,
      'status': status,
      'priority': priority,
      'attachments': attachments,
      'responses': responses,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}