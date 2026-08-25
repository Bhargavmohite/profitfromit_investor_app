import 'dart:convert';

DashboardResponse dashboardResponseFromJson(String str) => DashboardResponse.fromJson(json.decode(str));

String dashboardResponseToJson(DashboardResponse data) => json.encode(data.toJson());

class DashboardResponse {
  int? status;
  String? message;
  Data? data;

  DashboardResponse({
    this.status,
    this.message,
    this.data,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) => DashboardResponse(
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
  String? name;
  String? portfolioValue;
  double? xirr;
  String? totalGainLoss;
  String? unrealised;
  String? realised;
  String? dividend;
  String? totalHolding;
  String? totalGainer;
  String? totalLoser;
  List<TopHolding>? topHoldings;
  List<FamilyList>? familyList;

  Data({
    this.name,
    this.portfolioValue,
    this.xirr,
    this.totalGainLoss,
    this.unrealised,
    this.realised,
    this.dividend,
    this.totalHolding,
    this.totalGainer,
    this.totalLoser,
    this.topHoldings,
    this.familyList,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    name: json["name"],
    portfolioValue: json["portfolio_value"],
    xirr: double.tryParse(json["xirr"].toString()) ?? 0.0,
    totalGainLoss: json["total_gain_loss"],
    unrealised: json["unrealised"],
    realised: json["realised"],
    dividend: json["dividend"],
    totalHolding: json["total_holding"].toString(),
    totalGainer: json["total_gainer"].toString(),
    totalLoser: json["total_loser"].toString(),
    topHoldings: json["top_holdings"] == null ? [] : List<TopHolding>.from(json["top_holdings"]!.map((x) => TopHolding.fromJson(x))),
    familyList: json["family_list"] == null ? [] : List<FamilyList>.from(json["family_list"]!.map((x) => FamilyList.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "portfolio_value": portfolioValue,
    "xirr": xirr,
    "total_gain_loss": totalGainLoss,
    "unrealised": unrealised,
    "realised": realised,
    "dividend": dividend,
    "total_holding": totalHolding,
    "total_gainer": totalGainer,
    "total_loser": totalLoser,
    "top_holdings": topHoldings == null ? [] : List<dynamic>.from(topHoldings!.map((x) => x.toJson())),
    "family_list": familyList == null ? [] : List<dynamic>.from(familyList!.map((x) => x.toJson())),
  };
}

class FamilyList {
  int? id;
  String? name;

  FamilyList({
    this.id,
    this.name,
  });

  factory FamilyList.fromJson(Map<String, dynamic> json) => FamilyList(
    id: json["id"],
    name: json["name"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
  };
}

class TopHolding {
  String? id;
  String? assetName;
  String? investedValue;
  String? currentValue;
  double? gainPercent;
  String? todays;
  double? todaysPercentage;

  TopHolding({
    this.id,
    this.assetName,
    this.investedValue,
    this.currentValue,
    this.gainPercent,
    this.todays,
    this.todaysPercentage,
  });

  factory TopHolding.fromJson(Map<String, dynamic> json) => TopHolding(
    id: json["id"],
    assetName: json["asset_name"],
    investedValue: json["invested_value"],
    currentValue: json["current_value"],
    gainPercent: double.tryParse(json["gain_percent"].toString()) ?? 0.0,
    todays: json["todays"],
    todaysPercentage: json["todays_percentage"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "asset_name": assetName,
    "invested_value": investedValue,
    "current_value": currentValue,
    "gain_percent": gainPercent,
    "todays": todays,
    "todays_percentage": todaysPercentage,
  };
}