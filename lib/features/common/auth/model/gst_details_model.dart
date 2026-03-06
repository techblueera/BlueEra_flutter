class GstDetailsModel {
  Data? data;
  String? statusCd;
  String? statusDesc;

  GstDetailsModel({this.data, this.statusCd, this.statusDesc});

  GstDetailsModel.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    statusCd = json['status_cd'];
    statusDesc = json['status_desc'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['status_cd'] = statusCd;
    data['status_desc'] = statusDesc;
    return data;
  }
}

class Data {
  String? stjCd;
  String? lgnm;
  String? stj;
  String? dty;
  List<dynamic>? adadr;
  String? cxdt;
  List<String>? nba;
  String? gstin;
  String? lstupdt;
  String? rgdt;
  String? ctb;
  Pradr? pradr;
  String? tradeNam;
  String? sts;
  String? ctjCd;
  String? ctj;
  String? einvoiceStatus;

  Data(
      {this.stjCd,
      this.lgnm,
      this.stj,
      this.dty,
      this.adadr,
      this.cxdt,
      this.nba,
      this.gstin,
      this.lstupdt,
      this.rgdt,
      this.ctb,
      this.pradr,
      this.tradeNam,
      this.sts,
      this.ctjCd,
      this.ctj,
      this.einvoiceStatus});

  Data.fromJson(Map<String, dynamic> json) {
    stjCd = json['stjCd'];
    lgnm = json['lgnm'];
    stj = json['stj'];
    dty = json['dty'];
    adadr = json['adadr'];
    cxdt = json['cxdt'];
    nba = json['nba']?.cast<String>();
    gstin = json['gstin'];
    lstupdt = json['lstupdt'];
    rgdt = json['rgdt'];
    ctb = json['ctb'];
    pradr = json['pradr'] != null ? Pradr.fromJson(json['pradr']) : null;
    tradeNam = json['tradeNam'];
    sts = json['sts'];
    ctjCd = json['ctjCd'];
    ctj = json['ctj'];
    einvoiceStatus = json['einvoiceStatus'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['stjCd'] = stjCd;
    data['lgnm'] = lgnm;
    data['stj'] = stj;
    data['dty'] = dty;
    data['adadr'] = adadr;
    data['cxdt'] = cxdt;
    data['nba'] = nba;
    data['gstin'] = gstin;
    data['lstupdt'] = lstupdt;
    data['rgdt'] = rgdt;
    data['ctb'] = ctb;
    if (pradr != null) {
      data['pradr'] = pradr!.toJson();
    }
    data['tradeNam'] = tradeNam;
    data['sts'] = sts;
    data['ctjCd'] = ctjCd;
    data['ctj'] = ctj;
    data['einvoiceStatus'] = einvoiceStatus;
    return data;
  }
}

class Pradr {
  Addr? addr;
  String? ntr;

  Pradr({this.addr, this.ntr});

  Pradr.fromJson(Map<String, dynamic> json) {
    addr = json['addr'] != null ? Addr.fromJson(json['addr']) : null;
    ntr = json['ntr'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (addr != null) {
      data['addr'] = addr!.toJson();
    }
    data['ntr'] = ntr;
    return data;
  }
}

class Addr {
  String? bnm;
  String? loc;
  String? st;
  String? bno;
  String? dst;
  String? lt;
  String? locality;
  String? pncd;
  String? landMark;
  String? stcd;
  String? geocodelvl;
  String? flno;
  String? lg;

  Addr(
      {this.bnm,
      this.loc,
      this.st,
      this.bno,
      this.dst,
      this.lt,
      this.locality,
      this.pncd,
      this.landMark,
      this.stcd,
      this.geocodelvl,
      this.flno,
      this.lg});

  Addr.fromJson(Map<String, dynamic> json) {
    bnm = json['bnm'];
    loc = json['loc'];
    st = json['st'];
    bno = json['bno'];
    dst = json['dst'];
    lt = json['lt'];
    locality = json['locality'];
    pncd = json['pncd'];
    landMark = json['landMark'];
    stcd = json['stcd'];
    geocodelvl = json['geocodelvl'];
    flno = json['flno'];
    lg = json['lg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['bnm'] = bnm;
    data['loc'] = loc;
    data['st'] = st;
    data['bno'] = bno;
    data['dst'] = dst;
    data['lt'] = lt;
    data['locality'] = locality;
    data['pncd'] = pncd;
    data['landMark'] = landMark;
    data['stcd'] = stcd;
    data['geocodelvl'] = geocodelvl;
    data['flno'] = flno;
    data['lg'] = lg;
    return data;
  }

  String getFullAddress() {
    List<String> parts = [];
    if (bno != null && bno!.isNotEmpty) parts.add(bno!);
    if (bnm != null && bnm!.isNotEmpty) parts.add(bnm!);
    if (flno != null && flno!.isNotEmpty) parts.add(flno!);
    if (st != null && st!.isNotEmpty) parts.add(st!);
    if (locality != null && locality!.isNotEmpty) parts.add(locality!);
    if (landMark != null && landMark!.isNotEmpty) parts.add("Near $landMark");
    if (loc != null && loc!.isNotEmpty) parts.add(loc!);
    if (dst != null && dst!.isNotEmpty) parts.add(dst!);
    if (stcd != null && stcd!.isNotEmpty) parts.add(stcd!);
    if (pncd != null && pncd!.isNotEmpty) parts.add(pncd!);
    return parts.join(", ");
  }
}
