class FaqModel {
  final String? id;
  final String? question;
  final String? answer;
  final int? order;
  final bool? isActive;
  final DateTime? createdAt;

  FaqModel({
    this.id,
    this.question,
    this.answer,
    this.order,
    this.isActive,
    this.createdAt,
  });

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['_id'],
      question: json['question'],
      answer: json['answer'],
      order: json['order'],
      isActive: json['isActive'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}