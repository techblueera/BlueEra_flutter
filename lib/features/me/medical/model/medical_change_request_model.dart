class MedicalChangeRequestsResponse {
  List<MedicalChangeRequest>? data;
  ChangeRequestPagination? pagination;

  MedicalChangeRequestsResponse({this.data, this.pagination});

  MedicalChangeRequestsResponse.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <MedicalChangeRequest>[];
      json['data'].forEach((v) {
        data!.add(MedicalChangeRequest.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? ChangeRequestPagination.fromJson(json['pagination'])
        : null;
  }
}

class MedicalChangeRequest {
  String? sId;
  ChangeRequestVariant? variant;
  String? requestedBy;
  Map<String, dynamic>? changes;
  String? status;
  String? rejectionReason;
  String? createdAt;
  String? updatedAt;

  MedicalChangeRequest({
    this.sId,
    this.variant,
    this.requestedBy,
    this.changes,
    this.status,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  MedicalChangeRequest.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    variant = json['variant'] != null
        ? ChangeRequestVariant.fromJson(json['variant'])
        : null;
    requestedBy = json['requestedBy'];
    changes = json['changes'] != null
        ? Map<String, dynamic>.from(json['changes'])
        : null;
    status = json['status'];
    rejectionReason = json['rejectionReason'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }
}

class ChangeRequestVariant {
  String? sId;
  String? variantName;
  String? sku;

  ChangeRequestVariant({this.sId, this.variantName, this.sku});

  ChangeRequestVariant.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    variantName = json['variantName'];
    sku = json['sku'];
  }
}

class ChangeRequestPagination {
  int? total;
  int? page;
  int? limit;
  int? totalPages;

  ChangeRequestPagination({this.total, this.page, this.limit, this.totalPages});

  ChangeRequestPagination.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    page = json['page'];
    limit = json['limit'];
    totalPages = json['totalPages'];
  }
}