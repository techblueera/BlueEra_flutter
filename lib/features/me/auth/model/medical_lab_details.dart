class MedicalLabDataListModel {
  final String? moduleCode;
  final String? name;
  final String? id;
  final String? key;
  final String? type;
  final String? description;
  final int? order;
  final UiModel? ui;
  final RulesModel? rules;
  final List<MedicalLabDataListModel>? children;

  MedicalLabDataListModel({
    this.moduleCode,
    this.name,
    this.key,
    this.id,
    this.type,
    this.description,
    this.order,
    this.ui,
    this.rules,
    this.children,
  });

  factory MedicalLabDataListModel.fromJson(Map<String, dynamic> json) {
    return MedicalLabDataListModel(
      moduleCode: json['moduleCode'],
      name: json['name'],
      id: json['_id'],
      key: json['key'],
      type: json['type'],
      description: json['description'],
      order: json['order'],
      ui: json['ui'] != null ? UiModel.fromJson(json['ui']) : null,
      rules:
      json['rules'] != null ? RulesModel.fromJson(json['rules']) : null,
      children: json['children'] != null
          ? (json['children'] as List)
          .map((e) => MedicalLabDataListModel.fromJson(e))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleCode': moduleCode,
      'name': name,
      'key': key,
      'id': id,
      'type': type,
      'description': description,
      'order': order,
      'ui': ui?.toJson(),
      'rules': rules?.toJson(),
      'children': children?.map((e) => e.toJson()).toList(),
    };
  }
}

class UiModel {
  final String? icon;
  final String? layout;

  UiModel({this.icon, this.layout});

  factory UiModel.fromJson(Map<String, dynamic> json) {
    return UiModel(
      icon: json['icon'],
      layout: json['layout'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'icon': icon,
      'layout': layout,
    };
  }
}

class RulesModel {
  final bool? allowChildren;
  final bool? allowOfferings;
  final bool? prescriptionRequired;
  final List<String>? visibilityRestrictions;

  RulesModel({
    this.allowChildren,
    this.allowOfferings,
    this.prescriptionRequired,
    this.visibilityRestrictions,
  });

  factory RulesModel.fromJson(Map<String, dynamic> json) {
    return RulesModel(
      allowChildren: json['allowChildren'],
      allowOfferings: json['allowOfferings'],
      prescriptionRequired: json['prescriptionRequired'],
      visibilityRestrictions:
      json['visibilityRestrictions'] != null
          ? List<String>.from(json['visibilityRestrictions'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowChildren': allowChildren,
      'allowOfferings': allowOfferings,
      'prescriptionRequired': prescriptionRequired,
      'visibilityRestrictions': visibilityRestrictions,
    };
  }
}
