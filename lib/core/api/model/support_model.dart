class SupportCase {
  final String id;
  final String? user;
  final String type;
  final String? name;
  final String email;
  final String message;
  final String? caseId;
  final String? faqQuestion;
  final String? faqAnswer;
  final String status;
  final DateTime createdAt;
  final int v;

  SupportCase({
    required this.id,
    this.user,
    required this.type,
    this.name,
    required this.email,
    required this.message,
    this.caseId,
    this.faqQuestion,
    this.faqAnswer,
    required this.status,
    required this.createdAt,
    required this.v,
  });

  factory SupportCase.fromJson(Map<String, dynamic> json) {
    return SupportCase(
      id: json['_id'] ?? '',
      user: json['user'],
      type: json['type'] ?? '',
      name: json['name'],
      email: json['email'] ?? '',
      message: json['message'] ?? '',
      caseId: json['case_id'],
      faqQuestion: json['faq_question'],
      faqAnswer: json['faq_answer'],
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      v: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user,
      'type': type,
      'name': name,
      'email': email,
      'message': message,
      'case_id': caseId,
      'faq_question': faqQuestion,
      'faq_answer': faqAnswer,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      '__v': v,
    };
  }
}
