// import 'dart:convert';
//
// HoldingsDetailResponse holdingsDetailResponseFromJson(String str) => HoldingsDetailResponse.fromJson(json.decode(str));
//
// String holdingsDetailResponseToJson(HoldingsDetailResponse data) => json.encode(data.toJson());
//
// class HoldingsDetailResponse {
//   int? status;
//   String? message;
//   Data? data;
//
//   HoldingsDetailResponse({
//     this.status,
//     this.message,
//     this.data,
//   });
//
//   factory HoldingsDetailResponse.fromJson(Map<String, dynamic> json) => HoldingsDetailResponse(
//     status: json["status"],
//     message: json["message"],
//     data: json["data"] == null ? null : Data.fromJson(json["data"]),
//   );
//
//   Map<String, dynamic> toJson() => {
//     "status": status,
//     "message": message,
//     "data": data?.toJson(),
//   };
// }
//
// class Data {
//   String? totalInvested;
//   List<Holding>? holdings;
//
//   Data({
//     this.totalInvested,
//     this.holdings,
//   });
//
//   factory Data.fromJson(Map<String, dynamic> json) => Data(
//     totalInvested: json["total_invested"],
//     holdings: json["holdings"] == null ? [] : List<Holding>.from(json["holdings"]!.map((x) => Holding.fromJson(x))),
//   );
//
//   Map<String, dynamic> toJson() => {
//     "total_invested": totalInvested,
//     "holdings": holdings == null ? [] : List<dynamic>.from(holdings!.map((x) => x.toJson())),
//   };
// }
//
// class Holding {
//   String? id;
//   String? assetName;
//   String? investedValue;
//   String? currentValue;
//   double? gainPercent;
//
//   Holding({
//     this.id,
//     this.assetName,
//     this.investedValue,
//     this.currentValue,
//     this.gainPercent,
//   });
//
//   factory Holding.fromJson(Map<String, dynamic> json) => Holding(
//     id: json["id"],
//     assetName: json["asset_name"],
//     investedValue: json["invested_value"],
//     currentValue: json["current_value"],
//     gainPercent: json["gain_percent"]?.toDouble(),
//   );
//
//   Map<String, dynamic> toJson() => {
//     "id": id,
//     "asset_name": assetName,
//     "invested_value": investedValue,
//     "current_value": currentValue,
//     "gain_percent": gainPercent,
//   };
// }

import 'dart:convert';

HoldingsDetailResponse holdingsDetailResponseFromJson(String str) => HoldingsDetailResponse.fromJson(json.decode(str));

String holdingsDetailResponseToJson(HoldingsDetailResponse data) => json.encode(data.toJson());

class HoldingsDetailResponse {
  int? status;
  String? message;
  Data? data;

  HoldingsDetailResponse({
    this.status,
    this.message,
    this.data,
  });

  factory HoldingsDetailResponse.fromJson(Map<String, dynamic> json) => HoldingsDetailResponse(
    status: json["status"],
    message: json["message"],
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  String? totalInvested;
  String? todays;
  double? todaysPercentage;
  List<Holding>? holdings;

  Data({
    this.totalInvested,
    this.todays,
    this.todaysPercentage,
    this.holdings,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    totalInvested: json["total_invested"],
    todays: json["todays"],
    todaysPercentage: json["todays_percentage"]?.toDouble(),
    holdings: json["holdings"] == null ? [] : List<Holding>.from(json["holdings"]!.map((x) => Holding.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "total_invested": totalInvested,
    "todays": todays,
    "todays_percentage": todaysPercentage,
    "holdings": holdings == null ? [] : List<dynamic>.from(holdings!.map((x) => x.toJson())),
  };
}

class Holding {
  String? id;
  String? assetName;
  String? investedValue;
  String? currentValue;
  String? todays;
  double? todaysPercentage;
  double? gainPercent;

  Holding({
    this.id,
    this.assetName,
    this.investedValue,
    this.currentValue,
    this.todays,
    this.todaysPercentage,
    this.gainPercent,
  });

  factory Holding.fromJson(Map<String, dynamic> json) => Holding(
    id: json["id"],
    assetName: json["asset_name"],
    investedValue: json["invested_value"],
    currentValue: json["current_value"],
    todays: json["todays"],
    todaysPercentage: json["todays_percentage"]?.toDouble(),
    gainPercent: json["gain_percent"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "asset_name": assetName,
    "invested_value": investedValue,
    "current_value": currentValue,
    "todays": todays,
    "todays_percentage": todaysPercentage,
    "gain_percent": gainPercent,
  };
}