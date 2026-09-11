import 'dart:convert';

DashboardResponse dashboardResponseFromJson(String str) =>
    DashboardResponse.fromJson(json.decode(str));

String dashboardResponseToJson(DashboardResponse data) =>
    json.encode(data.toJson());

class DashboardResponse {
  int? status;
  String? message;
  Data? data;

  DashboardResponse({this.status, this.message, this.data});

  factory DashboardResponse.fromJson(Map<String, dynamic> json) =>
      DashboardResponse(
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
  int? familyId;
  String? oldestVoucherDate;
  String? portfolioValue;
  double? xirr;
  String? totalGainLoss;
  String? unrealised;
  String? realised;
  String? dividend;

  // Contribution values
  String? payIn;
  String? payOut;
  String? netContribution;

  String? totalHolding;
  String? totalGainer;
  String? totalLoser;

  List<TopHolding>? topHoldings;
  List<FamilyList>? familyList;

  Data({
    this.name,
    this.familyId,
    this.oldestVoucherDate,
    this.portfolioValue,
    this.xirr,
    this.totalGainLoss,
    this.unrealised,
    this.realised,
    this.dividend,
    this.payIn,
    this.payOut,
    this.netContribution,
    this.totalHolding,
    this.totalGainer,
    this.totalLoser,
    this.topHoldings,
    this.familyList,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    name: json["name"]?.toString(),

    familyId: json["family_id"] == null
        ? null
        : int.tryParse(json["family_id"].toString()),

    oldestVoucherDate: json["oldest_voucher_date"]?.toString(),

    portfolioValue: json["portfolio_value"]?.toString(),

    xirr: double.tryParse(json["xirr"]?.toString() ?? "0") ?? 0.0,

    totalGainLoss: json["total_gain_loss"]?.toString(),

    unrealised: json["unrealised"]?.toString(),

    realised: json["realised"]?.toString(),

    dividend: json["dividend"]?.toString(),

    // =============================
    // CONTRIBUTION
    // =============================
    payIn: json["pay_in"]?.toString(),

    payOut: json["pay_out"]?.toString(),

    netContribution: json["net_contribution"]?.toString(),

    totalHolding: json["total_holding"]?.toString() ?? "0",

    totalGainer: json["total_gainer"]?.toString() ?? "0",

    totalLoser: json["total_loser"]?.toString() ?? "0",

    topHoldings: json["top_holdings"] == null
        ? []
        : List<TopHolding>.from(
            json["top_holdings"].map((x) => TopHolding.fromJson(x)),
          ),

    familyList: json["family_list"] == null
        ? []
        : List<FamilyList>.from(
            json["family_list"].map((x) => FamilyList.fromJson(x)),
          ),
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "family_id": familyId,
    "oldest_voucher_date": oldestVoucherDate,
    "portfolio_value": portfolioValue,
    "xirr": xirr,
    "total_gain_loss": totalGainLoss,
    "unrealised": unrealised,
    "realised": realised,
    "dividend": dividend,

    // Contribution
    "pay_in": payIn,
    "pay_out": payOut,
    "net_contribution": netContribution,

    "total_holding": totalHolding,
    "total_gainer": totalGainer,
    "total_loser": totalLoser,

    "top_holdings": topHoldings == null
        ? []
        : List<dynamic>.from(topHoldings!.map((x) => x.toJson())),

    "family_list": familyList == null
        ? []
        : List<dynamic>.from(familyList!.map((x) => x.toJson())),
  };
}

class FamilyList {
  int? id;
  String? name;

  FamilyList({this.id, this.name});

  factory FamilyList.fromJson(Map<String, dynamic> json) => FamilyList(
    id: int.tryParse(json["id"]?.toString() ?? ""),
    name: json["name"]?.toString(),
  );

  Map<String, dynamic> toJson() => {"id": id, "name": name};
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
    id: json["id"]?.toString(),

    assetName: json["asset_name"]?.toString(),

    investedValue: json["invested_value"]?.toString(),

    currentValue: json["current_value"]?.toString(),

    gainPercent:
        double.tryParse(json["gain_percent"]?.toString() ?? "0") ?? 0.0,

    todays: json["todays"]?.toString(),

    todaysPercentage:
        double.tryParse(json["todays_percentage"]?.toString() ?? "0") ?? 0.0,
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
