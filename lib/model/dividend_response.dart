import 'dart:convert';

DividendResponse dividendResponseFromJson(String str) =>
    DividendResponse.fromJson(json.decode(str));

String dividendResponseToJson(DividendResponse data) =>
    json.encode(data.toJson());

// ============================================================
// DIVIDEND RESPONSE
// ============================================================

class DividendResponse {
  int? status;
  String? message;
  DividendData? data;

  DividendResponse({this.status, this.message, this.data});

  factory DividendResponse.fromJson(Map<String, dynamic> json) =>
      DividendResponse(
        status: int.tryParse(json["status"]?.toString() ?? "0"),
        message: json["message"]?.toString(),
        data: json["data"] == null ? null : DividendData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

// ============================================================
// DIVIDEND DATA
// ============================================================

class DividendData {
  int? activeClientId;
  String? activeClientName;

  double? totalDividend;
  String? totalDividendFormatted;

  int? dividendCount;

  List<DividendEntry>? dividends;

  DividendData({
    this.activeClientId,
    this.activeClientName,
    this.totalDividend,
    this.totalDividendFormatted,
    this.dividendCount,
    this.dividends,
  });

  factory DividendData.fromJson(Map<String, dynamic> json) => DividendData(
    activeClientId: _toInt(json["active_client_id"]),
    activeClientName: json["active_client_name"]?.toString(),

    totalDividend: _toDouble(json["total_dividend"]),
    totalDividendFormatted: json["total_dividend_formatted"]?.toString(),

    dividendCount: _toInt(json["dividend_count"]),

    dividends: json["dividends"] == null
        ? []
        : List<DividendEntry>.from(
            json["dividends"].map((x) => DividendEntry.fromJson(x)),
          ),
  );

  Map<String, dynamic> toJson() => {
    "active_client_id": activeClientId,
    "active_client_name": activeClientName,
    "total_dividend": totalDividend,
    "total_dividend_formatted": totalDividendFormatted,
    "dividend_count": dividendCount,
    "dividends": dividends == null
        ? []
        : List<dynamic>.from(dividends!.map((x) => x.toJson())),
  };
}

// ============================================================
// DIVIDEND ENTRY
// ============================================================

class DividendEntry {
  String? id;

  /// API date in YYYY-MM-DD format.
  String? date;

  /// User-facing date such as "15 Sep 2026".
  String? displayDate;

  String? companyName;
  String? isin;

  double? perShareDividend;
  String? perShareDividendFormatted;

  double? quantity;

  double? totalDividend;
  String? totalDividendFormatted;

  DividendEntry({
    this.id,
    this.date,
    this.displayDate,
    this.companyName,
    this.isin,
    this.perShareDividend,
    this.perShareDividendFormatted,
    this.quantity,
    this.totalDividend,
    this.totalDividendFormatted,
  });

  factory DividendEntry.fromJson(Map<String, dynamic> json) => DividendEntry(
    id: json["id"]?.toString(),
    date: json["date"]?.toString(),
    displayDate: json["display_date"]?.toString(),
    companyName: json["company_name"]?.toString(),
    isin: json["isin"]?.toString(),

    perShareDividend: _toDouble(json["per_share_dividend"]),
    perShareDividendFormatted: json["per_share_dividend_formatted"]?.toString(),

    quantity: _toDouble(json["quantity"]),

    totalDividend: _toDouble(json["total_dividend"]),
    totalDividendFormatted: json["total_dividend_formatted"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "date": date,
    "display_date": displayDate,
    "company_name": companyName,
    "isin": isin,
    "per_share_dividend": perShareDividend,
    "per_share_dividend_formatted": perShareDividendFormatted,
    "quantity": quantity,
    "total_dividend": totalDividend,
    "total_dividend_formatted": totalDividendFormatted,
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
