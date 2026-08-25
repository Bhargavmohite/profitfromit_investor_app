// To parse this JSON data, do
//
//     final analyticsResponse = analyticsResponseFromJson(jsonString);

import 'dart:convert';

AnalyticsResponse analyticsResponseFromJson(String str) => AnalyticsResponse.fromJson(json.decode(str));

String analyticsResponseToJson(AnalyticsResponse data) => json.encode(data.toJson());

class AnalyticsResponse {
  int? status;
  String? message;
  Data? data;

  AnalyticsResponse({
    this.status,
    this.message,
    this.data,
  });

  factory AnalyticsResponse.fromJson(Map<String, dynamic> json) => AnalyticsResponse(
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
  String? totalValue;
  List<MarketCap>? sector;
  List<MarketCap>? marketCap;

  Data({
    this.totalValue,
    this.sector,
    this.marketCap,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    totalValue: json["total_value"],
    sector: json["sector"] == null ? [] : List<MarketCap>.from(json["sector"]!.map((x) => MarketCap.fromJson(x))),
    marketCap: json["market_cap"] == null ? [] : List<MarketCap>.from(json["market_cap"]!.map((x) => MarketCap.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "total_value": totalValue,
    "sector": sector == null ? [] : List<dynamic>.from(sector!.map((x) => x.toJson())),
    "market_cap": marketCap == null ? [] : List<dynamic>.from(marketCap!.map((x) => x.toJson())),
  };
}

class MarketCap {
  String? label;
  String? amount;
  double? percent;
  List<Company>? companies;

  MarketCap({
    this.label,
    this.amount,
    this.percent,
    this.companies,
  });

  factory MarketCap.fromJson(Map<String, dynamic> json) => MarketCap(
    label: json["label"],
    amount: json["amount"],
    percent: json["percent"]?.toDouble(),
    companies: json["companies"] == null ? [] : List<Company>.from(json["companies"]!.map((x) => Company.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "label": label,
    "amount": amount,
    "percent": percent,
    "companies": companies == null ? [] : List<dynamic>.from(companies!.map((x) => x.toJson())),
  };
}

class Company {
  String? name;
  double? percent;

  Company({
    this.name,
    this.percent,
  });

  factory Company.fromJson(Map<String, dynamic> json) => Company(
    name: json["name"],
    percent: json["percent"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "percent": percent,
  };
}