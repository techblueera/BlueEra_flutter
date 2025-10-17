class CardResponseModel {
  bool? success;
  int? totalCards;
  int? totalPages;
  int? currentPage;
  bool? hasNextPage;
  bool? hasPrevPage;
  int? limit;
  String? order;
  DateFilter? dateFilter;
  List<Cards>? cards;

  CardResponseModel(
      {this.success,
        this.totalCards,
        this.totalPages,
        this.currentPage,
        this.hasNextPage,
        this.hasPrevPage,
        this.limit,
        this.order,
        this.dateFilter,
        this.cards});

  CardResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    totalCards = json['totalCards'];
    totalPages = json['totalPages'];
    currentPage = json['currentPage'];
    hasNextPage = json['hasNextPage'];
    hasPrevPage = json['hasPrevPage'];
    limit = json['limit'];
    order = json['order'];
    dateFilter = json['dateFilter'] != null
        ? new DateFilter.fromJson(json['dateFilter'])
        : null;
    if (json['cards'] != null) {
      cards = <Cards>[];
      json['cards'].forEach((v) {
        cards!.add(new Cards.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['totalCards'] = this.totalCards;
    data['totalPages'] = this.totalPages;
    data['currentPage'] = this.currentPage;
    data['hasNextPage'] = this.hasNextPage;
    data['hasPrevPage'] = this.hasPrevPage;
    data['limit'] = this.limit;
    data['order'] = this.order;
    if (this.dateFilter != null) {
      data['dateFilter'] = this.dateFilter!.toJson();
    }
    if (this.cards != null) {
      data['cards'] = this.cards!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class DateFilter {
  String? gte;
  String? lte;

  DateFilter({this.gte, this.lte});

  DateFilter.fromJson(Map<String, dynamic> json) {
    gte = json['$gte'];
    lte = json['$lte'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['$gte'] = this.gte;
    data['$lte'] = this.lte;
    return data;
  }
}

class Cards {
  String? timeZone;
  String? language;
  String? eventDate;
  String? createdBy;
  String? sId;
  String? createdAt;
  String? updatedAt;
  String? categoryName;
  String? photo;

  Cards(
      {this.timeZone,
        this.language,
        this.eventDate,
        this.createdBy,
        this.sId,
        this.createdAt,
        this.updatedAt,
        this.categoryName,
        this.photo});

  Cards.fromJson(Map<String, dynamic> json) {
    timeZone = json['timeZone'];
    language = json['language'];
    eventDate = json['eventDate'];
    createdBy = json['createdBy'];
    sId = json['_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    categoryName = json['categoryName'];
    photo = json['photo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['timeZone'] = this.timeZone;
    data['language'] = this.language;
    data['eventDate'] = this.eventDate;
    data['createdBy'] = this.createdBy;
    data['_id'] = this.sId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['categoryName'] = this.categoryName;
    data['photo'] = this.photo;
    return data;
  }
}