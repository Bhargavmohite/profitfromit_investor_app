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

  // Logged-in account relationship
  String? ctype;
  int? partnerId;

  int? familyId;
  int? isFamilyMaster;
  bool? canSelectFamily;

  // Readonly-admin client switching
  int? isReadonlyAdmin;
  bool? canSwitchClients;
  int? masterClientId;
  int? activeClientId;
  bool? isClientImpersonating;
  List<ClientList>? clientList;

  String? oldestVoucherDate;
  String? portfolioValue;
  double? xirr;
  String? todaysGainLoss;
  double? todaysGainLossPercentage;
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

  // Full portfolio-performance curve returned by Dashboard API.
  PortfolioCurve? portfolioCurve;

  Data({
    this.name,
    this.ctype,
    this.partnerId,
    this.familyId,
    this.isFamilyMaster,
    this.canSelectFamily,
    this.isReadonlyAdmin,
    this.canSwitchClients,
    this.masterClientId,
    this.activeClientId,
    this.isClientImpersonating,
    this.clientList,
    this.oldestVoucherDate,
    this.portfolioValue,
    this.xirr,
    this.todaysGainLoss,
    this.todaysGainLossPercentage,
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
    this.portfolioCurve,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    name: json["name"]?.toString(),

    ctype: json["ctype"]?.toString(),

    partnerId: json["partner_id"] == null
        ? null
        : int.tryParse(json["partner_id"].toString()),

    familyId: json["family_id"] == null
        ? null
        : int.tryParse(json["family_id"].toString()),

    isFamilyMaster:
        int.tryParse(json["is_family_master"]?.toString() ?? "0") ?? 0,

    canSelectFamily:
        json["can_select_family"] == true ||
        json["can_select_family"]?.toString() == "1" ||
        json["can_select_family"]?.toString().toLowerCase() == "true",

    isReadonlyAdmin:
        int.tryParse(json["is_readonly_admin"]?.toString() ?? "0") ?? 0,

    canSwitchClients:
        json["can_switch_clients"] == true ||
        json["can_switch_clients"]?.toString() == "1" ||
        json["can_switch_clients"]?.toString().toLowerCase() == "true",

    masterClientId: json["master_client_id"] == null
        ? null
        : int.tryParse(json["master_client_id"].toString()),

    activeClientId: json["active_client_id"] == null
        ? null
        : int.tryParse(json["active_client_id"].toString()),

    isClientImpersonating:
        json["is_client_impersonating"] == true ||
        json["is_client_impersonating"]?.toString() == "1" ||
        json["is_client_impersonating"]?.toString().toLowerCase() == "true",

    clientList: json["client_list"] == null
        ? []
        : List<ClientList>.from(
            json["client_list"].map((x) => ClientList.fromJson(x)),
          ),

    oldestVoucherDate: json["oldest_voucher_date"]?.toString(),

    portfolioValue: json["portfolio_value"]?.toString(),

    xirr: double.tryParse(json["xirr"]?.toString() ?? "0") ?? 0.0,

    todaysGainLoss: json["todays_gain_loss"]?.toString(),

    todaysGainLossPercentage:
        double.tryParse(
          json["todays_gain_loss_percentage"]?.toString() ?? "0",
        ) ??
        0.0,

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

    portfolioCurve: json["portfolio_curve"] == null
        ? null
        : PortfolioCurve.fromJson(json["portfolio_curve"]),
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "ctype": ctype,
    "partner_id": partnerId,
    "family_id": familyId,
    "is_family_master": isFamilyMaster,
    "can_select_family": canSelectFamily,
    "is_readonly_admin": isReadonlyAdmin,
    "can_switch_clients": canSwitchClients,
    "master_client_id": masterClientId,
    "active_client_id": activeClientId,
    "is_client_impersonating": isClientImpersonating,
    "client_list": clientList == null
        ? []
        : List<dynamic>.from(clientList!.map((x) => x.toJson())),
    "oldest_voucher_date": oldestVoucherDate,
    "portfolio_value": portfolioValue,
    "xirr": xirr,
    "todays_gain_loss": todaysGainLoss,
    "todays_gain_loss_percentage": todaysGainLossPercentage,
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

    "portfolio_curve": portfolioCurve?.toJson(),
  };
}

class PortfolioCurve {
  double? baseNav;
  double? currentNav;
  String? inceptionDate;
  int? pointCount;

  List<String> dates;
  List<double> portfolioValues;
  List<double> equityValues;
  List<double> ledgerValues;
  List<double> navValues;

  PortfolioCurve({
    this.baseNav,
    this.currentNav,
    this.inceptionDate,
    this.pointCount,
    this.dates = const [],
    this.portfolioValues = const [],
    this.equityValues = const [],
    this.ledgerValues = const [],
    this.navValues = const [],
  });

  static List<double> _toDoubleList(dynamic value) {
    if (value is! List) {
      return <double>[];
    }

    return value
        .map((e) => double.tryParse(e?.toString() ?? "0") ?? 0.0)
        .toList();
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value.map((e) => e?.toString() ?? "").toList();
  }

  factory PortfolioCurve.fromJson(Map<String, dynamic> json) => PortfolioCurve(
    baseNav: double.tryParse(json["base_nav"]?.toString() ?? "100") ?? 100.0,
    currentNav:
        double.tryParse(json["current_nav"]?.toString() ?? "100") ?? 100.0,
    inceptionDate: json["inception_date"]?.toString(),
    pointCount: int.tryParse(json["point_count"]?.toString() ?? "0") ?? 0,
    dates: _toStringList(json["dates"]),
    portfolioValues: _toDoubleList(json["portfolio_values"]),
    equityValues: _toDoubleList(json["equity_values"]),
    ledgerValues: _toDoubleList(json["ledger_values"]),
    navValues: _toDoubleList(json["nav_values"]),
  );

  Map<String, dynamic> toJson() => {
    "base_nav": baseNav,
    "current_nav": currentNav,
    "inception_date": inceptionDate,
    "point_count": pointCount,
    "dates": dates,
    "portfolio_values": portfolioValues,
    "equity_values": equityValues,
    "ledger_values": ledgerValues,
    "nav_values": navValues,
  };
}

class ClientList {
  int? id;
  String? name;
  bool isCurrent;

  ClientList({this.id, this.name, this.isCurrent = false});

  factory ClientList.fromJson(Map<String, dynamic> json) => ClientList(
    id: int.tryParse(json["id"]?.toString() ?? ""),
    name: json["name"]?.toString(),
    isCurrent:
        json["is_current"] == true ||
        json["is_current"]?.toString() == "1" ||
        json["is_current"]?.toString().toLowerCase() == "true",
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "is_current": isCurrent,
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
