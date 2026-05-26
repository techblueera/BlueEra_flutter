import 'symbol_details_model.dart';

class SymbolLikeEntry {
  final String? id;
  final String? userId;
  final String? symbolId;
  final DateTime? createdAt;
  final UserModel? user;

  SymbolLikeEntry({this.id, this.userId, this.symbolId, this.createdAt, this.user});

  factory SymbolLikeEntry.fromJson(Map<String, dynamic> json) {
    return SymbolLikeEntry(
      id: json['_id'],
      userId: json['user_id'],
      symbolId: json['symbol_id'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}

class SymbolViewEntry {
  final String? id;
  final String? userId;
  final String? symbolId;
  final DateTime? seenAt;
  final UserModel? user;

  SymbolViewEntry({this.id, this.userId, this.symbolId, this.seenAt, this.user});

  factory SymbolViewEntry.fromJson(Map<String, dynamic> json) {
    return SymbolViewEntry(
      id: json['_id'],
      userId: json['user_id'],
      symbolId: json['symbol_id'],
      seenAt: json['seen_at'] != null
          ? DateTime.tryParse(json['seen_at'])
          : null,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}
