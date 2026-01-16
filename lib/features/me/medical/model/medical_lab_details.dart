class MedicalLabDataListModel {
  final String? id;
  final String? businessId;
  final String? catalogNodeId;

  final String? name; // title from API
  final bool? isActive;
  final String? type;
  final int? order;

  final Map<String,dynamic>? data;

  final String? createdAt;
  final String? updatedAt;

  final UiModel? ui;
  final RulesModel? rules;

  final List<MedicalLabDataListModel>? children;

  MedicalLabDataListModel({
    this.id,
    this.businessId,
    this.catalogNodeId,
    this.name,
    this.isActive,
    this.type,
    this.order,
    this.data,
    this.createdAt,
    this.updatedAt,
    this.ui,
    this.rules,
    this.children,
  });

  /// 🔁 copyWith (THIS is what you wanted)
  MedicalLabDataListModel copyWith({
    String? id,
    String? businessId,
    String? catalogNodeId,
    String? name,
    bool? isActive,
    String? type,
    int? order,
    Map<String,dynamic>? data,
    String? createdAt,
    String? updatedAt,
    UiModel? ui,
    RulesModel? rules,
    List<MedicalLabDataListModel>? children,
  }) {
    return MedicalLabDataListModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      catalogNodeId: catalogNodeId ?? this.catalogNodeId,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive, // 👈 key line
      type: type ?? this.type,
      order: order ?? this.order,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ui: ui ?? this.ui,
      rules: rules ?? this.rules,
      children: children ?? this.children,
    );
  }

  factory MedicalLabDataListModel.fromJson(Map<String, dynamic> json) {
    return MedicalLabDataListModel(
      id: json['_id'],
      businessId: json['businessId'],
      catalogNodeId: json['catalogNodeId'],
      name: json['title'],
      isActive: json['isActive'],
      type: json['type'],
      order: json['order'],
      data: json['data'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      ui: json['ui'] != null ? UiModel.fromJson(json['ui']) : null,
      rules: json['rules'] != null ? RulesModel.fromJson(json['rules']) : null,
      children: json['children'] != null
          ? (json['children'] as List)
          .map((e) => MedicalLabDataListModel.fromJson(e))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'businessId': businessId,
      'catalogNodeId': catalogNodeId,
      'title': name,
      'isActive': isActive,
      'type': type,
      'order': order,
      'data': data,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'ui': ui?.toJson(),
      'rules': rules?.toJson(),
      'children': children?.map((e) => e.toJson()).toList(),
    };
  }
}

class UiModel {
  final String? icon;
  final String? color;

  UiModel({this.icon, this.color});

  factory UiModel.fromJson(Map<String, dynamic> json) {
    return UiModel(
      icon: json['icon'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'icon': icon,
      'color': color,
    };
  }
}
class RulesModel {
  final bool? isEditable;
  final bool? isDeletable;

  RulesModel({this.isEditable, this.isDeletable});

  factory RulesModel.fromJson(Map<String, dynamic> json) {
    return RulesModel(
      isEditable: json['isEditable'],
      isDeletable: json['isDeletable'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEditable': isEditable,
      'isDeletable': isDeletable,
    };
  }
}
