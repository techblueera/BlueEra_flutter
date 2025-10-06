class CardModelResponse {
  bool? success;
  List<Categories>? categories;

  CardModelResponse({this.success, this.categories});

  CardModelResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['categories'] != null) {
      categories = <Categories>[];
      json['categories'].forEach((v) {
        categories!.add(new Categories.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.categories != null) {
      data['categories'] = this.categories!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Categories {
  String? sId;
  String? name;
  String? createdAt;
  String? updatedAt;
  int? iV;
  List<Cards>? cards;

  Categories(
      {this.sId,
        this.name,
        this.createdAt,
        this.updatedAt,
        this.iV,
        this.cards});

  Categories.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    if (json['cards'] != null) {
      cards = <Cards>[];
      json['cards'].forEach((v) {
        cards!.add(new Cards.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    if (this.cards != null) {
      data['cards'] = this.cards!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Cards {
  String? timeZone;
  String? language;
  String? photo;
  String? eventDate;
  String? createdBy;
  String? categoryName;
  String? sId;
  String? createdAt;
  String? updatedAt;

  Cards(
      {this.timeZone,
        this.language,
        this.photo,
        this.eventDate,
        this.createdBy,
        this.categoryName,
        this.sId,
        this.createdAt,
        this.updatedAt});

  Cards.fromJson(Map<String, dynamic> json) {
    timeZone = json['timeZone'];
    language = json['language'];
    photo = json['photo'];
    eventDate = json['eventDate'];
    createdBy = json['createdBy'];
    categoryName = json['categoryName'];
    sId = json['_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['timeZone'] = this.timeZone;
    data['language'] = this.language;
    data['photo'] = this.photo;
    data['eventDate'] = this.eventDate;
    data['createdBy'] = this.createdBy;
    data['categoryName'] = this.categoryName;
    data['_id'] = this.sId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}




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
  List<AllCards>? cards;

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
      cards = <AllCards>[];
      json['cards'].forEach((v) {
        cards!.add(new AllCards.fromJson(v));
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

class AllCards {
  String? timeZone;
  String? language;
  String? eventDate;
  String? createdBy;
  String? sId;
  String? createdAt;
  String? updatedAt;
  String? categoryName;
  String? photo;

  AllCards(
      {this.timeZone,
        this.language,
        this.eventDate,
        this.createdBy,
        this.sId,
        this.createdAt,
        this.updatedAt,
        this.categoryName,
        this.photo});

  AllCards.fromJson(Map<String, dynamic> json) {
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