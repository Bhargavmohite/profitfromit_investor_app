// To parse this JSON data, do
//
//     final watchlistResponse = watchlistResponseFromJson(jsonString);

import 'dart:convert';

WatchlistResponse watchlistResponseFromJson(String str) => WatchlistResponse.fromJson(json.decode(str));

String watchlistResponseToJson(WatchlistResponse data) => json.encode(data.toJson());

class WatchlistResponse {
  int? status;
  String? message;
  Data? data;

  WatchlistResponse({
    this.status,
    this.message,
    this.data,
  });

  factory WatchlistResponse.fromJson(Map<String, dynamic> json) => WatchlistResponse(
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
  List<Gainer>? gainers;
  List<Gainer>? losers;
  List<Gainer>? highestYieldingAssets;
  List<Gainer>? lowestYieldingAssets;

  Data({
    this.gainers,
    this.losers,
    this.highestYieldingAssets,
    this.lowestYieldingAssets,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    gainers: json["gainers"] == null ? [] : List<Gainer>.from(json["gainers"]!.map((x) => Gainer.fromJson(x))),
    losers: json["losers"] == null ? [] : List<Gainer>.from(json["losers"]!.map((x) => Gainer.fromJson(x))),
    highestYieldingAssets: json["highest_yielding_assets"] == null ? [] : List<Gainer>.from(json["highest_yielding_assets"]!.map((x) => Gainer.fromJson(x))),
    lowestYieldingAssets: json["lowest_yielding_assets"] == null ? [] : List<Gainer>.from(json["lowest_yielding_assets"]!.map((x) => Gainer.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "gainers": gainers == null ? [] : List<dynamic>.from(gainers!.map((x) => x.toJson())),
    "losers": losers == null ? [] : List<dynamic>.from(losers!.map((x) => x.toJson())),
    "highest_yielding_assets": highestYieldingAssets == null ? [] : List<dynamic>.from(highestYieldingAssets!.map((x) => x.toJson())),
    "lowest_yielding_assets": lowestYieldingAssets == null ? [] : List<dynamic>.from(lowestYieldingAssets!.map((x) => x.toJson())),
  };
}

class Gainer {
  String? id;
  String? company;
  String? cmp;
  String? avgCost;
  dynamic changePercent;
  dynamic gainerReturn;

  Gainer({
    this.id,
    this.company,
    this.cmp,
    this.avgCost,
    this.changePercent,
    this.gainerReturn,
  });

  factory Gainer.fromJson(Map<String, dynamic> json) => Gainer(
    id: json["id"],
    company: json["company"],
    cmp: json["cmp"],
    avgCost: json["avg_cost"],
    changePercent: json["change_percent"]?.toDouble(),
    gainerReturn: json["return"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "company": company,
    "cmp": cmp,
    "avg_cost": avgCost,
    "change_percent": changePercent,
    "return": gainerReturn,
  };
}