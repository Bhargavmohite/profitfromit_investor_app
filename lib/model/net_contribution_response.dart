import 'dart:convert';

NetContributionResponse netContributionResponseFromJson(String str) =>
    NetContributionResponse.fromJson(json.decode(str));

String netContributionResponseToJson(NetContributionResponse data) =>
    json.encode(data.toJson());

// ============================================================
// NET CONTRIBUTION RESPONSE
// ============================================================

class NetContributionResponse {
  int? status;
  String? message;
  NetContributionData? data;

  NetContributionResponse({this.status, this.message, this.data});

  factory NetContributionResponse.fromJson(Map<String, dynamic> json) =>
      NetContributionResponse(
        status: int.tryParse(json["status"]?.toString() ?? "0"),
        message: json["message"]?.toString(),
        data: json["data"] == null
            ? null
            : NetContributionData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

// ============================================================
// NET CONTRIBUTION DATA
// ============================================================

class NetContributionData {
  int? activeClientId;
  String? activeClientName;

  double? netContribution;
  String? netContributionFormatted;

  double? payInTotal;
  String? payInTotalFormatted;

  double? payOutTotal;
  String? payOutTotalFormatted;

  double? buybackTotal;
  String? buybackTotalFormatted;

  double? totalOutflow;
  String? totalOutflowFormatted;

  List<ContributionEntry>? payIn;
  List<ContributionEntry>? payOut;
  List<ContributionEntry>? buyback;

  NetContributionData({
    this.activeClientId,
    this.activeClientName,
    this.netContribution,
    this.netContributionFormatted,
    this.payInTotal,
    this.payInTotalFormatted,
    this.payOutTotal,
    this.payOutTotalFormatted,
    this.buybackTotal,
    this.buybackTotalFormatted,
    this.totalOutflow,
    this.totalOutflowFormatted,
    this.payIn,
    this.payOut,
    this.buyback,
  });

  factory NetContributionData.fromJson(Map<String, dynamic> json) =>
      NetContributionData(
        activeClientId: _toInt(json["active_client_id"]),
        activeClientName: json["active_client_name"]?.toString(),

        netContribution: _toDouble(json["net_contribution"]),
        netContributionFormatted: json["net_contribution_formatted"]
            ?.toString(),

        payInTotal: _toDouble(json["pay_in_total"]),
        payInTotalFormatted: json["pay_in_total_formatted"]?.toString(),

        payOutTotal: _toDouble(json["pay_out_total"]),
        payOutTotalFormatted: json["pay_out_total_formatted"]?.toString(),

        buybackTotal: _toDouble(json["buyback_total"]),
        buybackTotalFormatted: json["buyback_total_formatted"]?.toString(),

        totalOutflow: _toDouble(json["total_outflow"]),
        totalOutflowFormatted: json["total_outflow_formatted"]?.toString(),

        payIn: json["pay_in"] == null
            ? []
            : List<ContributionEntry>.from(
                json["pay_in"].map((x) => ContributionEntry.fromJson(x)),
              ),

        payOut: json["pay_out"] == null
            ? []
            : List<ContributionEntry>.from(
                json["pay_out"].map((x) => ContributionEntry.fromJson(x)),
              ),

        buyback: json["buyback"] == null
            ? []
            : List<ContributionEntry>.from(
                json["buyback"].map((x) => ContributionEntry.fromJson(x)),
              ),
      );

  Map<String, dynamic> toJson() => {
    "active_client_id": activeClientId,
    "active_client_name": activeClientName,

    "net_contribution": netContribution,
    "net_contribution_formatted": netContributionFormatted,

    "pay_in_total": payInTotal,
    "pay_in_total_formatted": payInTotalFormatted,

    "pay_out_total": payOutTotal,
    "pay_out_total_formatted": payOutTotalFormatted,

    "buyback_total": buybackTotal,
    "buyback_total_formatted": buybackTotalFormatted,

    "total_outflow": totalOutflow,
    "total_outflow_formatted": totalOutflowFormatted,

    "pay_in": payIn == null
        ? []
        : List<dynamic>.from(payIn!.map((x) => x.toJson())),

    "pay_out": payOut == null
        ? []
        : List<dynamic>.from(payOut!.map((x) => x.toJson())),

    "buyback": buyback == null
        ? []
        : List<dynamic>.from(buyback!.map((x) => x.toJson())),
  };
}

// ============================================================
// CONTRIBUTION ENTRY
// ============================================================

class ContributionEntry {
  int? id;

  /// API date in YYYY-MM-DD format.
  String? date;

  /// User-facing date such as "24 Sep 2026".
  String? displayDate;

  double? amount;
  String? amountFormatted;

  String? narration;

  ContributionEntry({
    this.id,
    this.date,
    this.displayDate,
    this.amount,
    this.amountFormatted,
    this.narration,
  });

  factory ContributionEntry.fromJson(Map<String, dynamic> json) =>
      ContributionEntry(
        id: _toInt(json["id"]),
        date: json["date"]?.toString(),
        displayDate: json["display_date"]?.toString(),
        amount: _toDouble(json["amount"]),
        amountFormatted: json["amount_formatted"]?.toString(),
        narration: json["narration"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "date": date,
    "display_date": displayDate,
    "amount": amount,
    "amount_formatted": amountFormatted,
    "narration": narration,
  };
}

// ============================================================
// SAFE PARSERS
// ============================================================

double _toDouble(dynamic value) {
  if (value == null) {
    return 0.0;
  }

  return double.tryParse(value.toString()) ?? 0.0;
}

int _toInt(dynamic value) {
  if (value == null) {
    return 0;
  }

  return int.tryParse(value.toString()) ?? 0;
}
