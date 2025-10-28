/// vehicles : [{"type":"Tata 407","eta":null,"fare":{"currency":"INR","minor_amount":84621},"capacity":{"value":2500.0,"unit":"kg"},"size":{"length":{"value":9.0,"unit":"ft"},"breadth":{"value":5.5,"unit":"ft"},"height":{"value":6.0,"unit":"ft"}}},{"type":"Ace (Helper + 1 Labour)","eta":null,"fare":{"currency":"INR","minor_amount":54275},"capacity":{"value":750.0,"unit":"kg"},"size":{"length":{"value":7.0,"unit":"ft"},"breadth":{"value":4.5,"unit":"ft"},"height":{"value":5.5,"unit":"ft"}}},{"type":"3 Wheeler","eta":null,"fare":{"currency":"INR","minor_amount":36697},"capacity":{"value":500.0,"unit":"kg"},"size":{"length":{"value":6.0,"unit":"ft"},"breadth":{"value":5.0,"unit":"ft"},"height":{"value":5.0,"unit":"ft"}}},{"type":"2 Wheeler","eta":null,"fare":{"currency":"INR","minor_amount":8556},"capacity":{"value":20.0,"unit":"kg"},"size":{"length":{"value":9.0,"unit":"ft"},"breadth":{"value":5.5,"unit":"ft"},"height":{"value":6.0,"unit":"ft"}}}]

class GetPorterVehicleOptionModel {
  GetPorterVehicleOptionModel({
      this.vehicles,});

  GetPorterVehicleOptionModel.fromJson(dynamic json) {
    if (json['vehicles'] != null) {
      vehicles = [];
      json['vehicles'].forEach((v) {
        vehicles?.add(Vehicles.fromJson(v));
      });
    }
  }
  List<Vehicles>? vehicles;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (vehicles != null) {
      map['vehicles'] = vehicles?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

/// type : "Tata 407"
/// eta : null
/// fare : {"currency":"INR","minor_amount":84621}
/// capacity : {"value":2500.0,"unit":"kg"}
/// size : {"length":{"value":9.0,"unit":"ft"},"breadth":{"value":5.5,"unit":"ft"},"height":{"value":6.0,"unit":"ft"}}

class Vehicles {
  Vehicles({
      this.type, 
      this.eta, 
      this.fare, 
      this.capacity, 
      this.size,});

  Vehicles.fromJson(dynamic json) {
    type = json['type'];
    eta = json['eta'];
    fare = json['fare'] != null ? Fare.fromJson(json['fare']) : null;
    capacity = json['capacity'] != null ? Capacity.fromJson(json['capacity']) : null;
    size = json['size'] != null ? Size.fromJson(json['size']) : null;
  }
  String? type;
  dynamic eta;
  Fare? fare;
  Capacity? capacity;
  Size? size;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type'] = type;
    map['eta'] = eta;
    if (fare != null) {
      map['fare'] = fare?.toJson();
    }
    if (capacity != null) {
      map['capacity'] = capacity?.toJson();
    }
    if (size != null) {
      map['size'] = size?.toJson();
    }
    return map;
  }

}

/// length : {"value":9.0,"unit":"ft"}
/// breadth : {"value":5.5,"unit":"ft"}
/// height : {"value":6.0,"unit":"ft"}

class Size {
  Size({
      this.length, 
      this.breadth, 
      this.height,});

  Size.fromJson(dynamic json) {
    length = json['length'] != null ? Length.fromJson(json['length']) : null;
    breadth = json['breadth'] != null ? Breadth.fromJson(json['breadth']) : null;
    height = json['height'] != null ? Height.fromJson(json['height']) : null;
  }
  Length? length;
  Breadth? breadth;
  Height? height;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (length != null) {
      map['length'] = length?.toJson();
    }
    if (breadth != null) {
      map['breadth'] = breadth?.toJson();
    }
    if (height != null) {
      map['height'] = height?.toJson();
    }
    return map;
  }

}

/// value : 6.0
/// unit : "ft"

class Height {
  Height({
      this.value, 
      this.unit,});

  Height.fromJson(dynamic json) {
    value = json['value'];
    unit = json['unit'];
  }
  num? value;
  String? unit;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['value'] = value;
    map['unit'] = unit;
    return map;
  }

}

/// value : 5.5
/// unit : "ft"

class Breadth {
  Breadth({
      this.value, 
      this.unit,});

  Breadth.fromJson(dynamic json) {
    value = json['value'];
    unit = json['unit'];
  }
  num? value;
  String? unit;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['value'] = value;
    map['unit'] = unit;
    return map;
  }

}

/// value : 9.0
/// unit : "ft"

class Length {
  Length({
      this.value, 
      this.unit,});

  Length.fromJson(dynamic json) {
    value = json['value'];
    unit = json['unit'];
  }
  num? value;
  String? unit;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['value'] = value;
    map['unit'] = unit;
    return map;
  }

}

/// value : 2500.0
/// unit : "kg"

class Capacity {
  Capacity({
      this.value, 
      this.unit,});

  Capacity.fromJson(dynamic json) {
    value = json['value'];
    unit = json['unit'];
  }
  num? value;
  String? unit;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['value'] = value;
    map['unit'] = unit;
    return map;
  }

}

/// currency : "INR"
/// minor_amount : 84621

class Fare {
  Fare({
      this.currency, 
      this.minorAmount,});

  Fare.fromJson(dynamic json) {
    currency = json['currency'];
    minorAmount = json['minor_amount'];
  }
  String? currency;
  num? minorAmount;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['currency'] = currency;
    map['minor_amount'] = minorAmount;
    return map;
  }

}