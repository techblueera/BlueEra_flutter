class LabContentListViewModel {
  String? name;
  List<LabContentListViewChild>? children;

  LabContentListViewModel({this.name, this.children});

  factory LabContentListViewModel.fromJson(Map<String, dynamic> json) {
    return LabContentListViewModel(
      name: json['name'],
      children: json['children'] != null
          ? (json['children'] as List)
          .map((e) => LabContentListViewChild.fromJson(e))
          .toList()
          : [],
    );
  }
}

class LabContentListViewChild {
  String? key;
  String? name;

  LabContentListViewChild({this.key, this.name});

  factory LabContentListViewChild.fromJson(Map<String, dynamic> json) {
    return LabContentListViewChild(
      key: json['key'],
      name: json['name'],
    );
  }
}
