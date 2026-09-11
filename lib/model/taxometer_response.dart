import 'dart:convert';

TaxometerResponse taxometerResponseFromJson(String str) =>
    TaxometerResponse.fromJson(json.decode(str));

String taxometerResponseToJson(TaxometerResponse data) =>
    json.encode(data.toJson());

// ============================================================
// TAXOMETER RESPONSE
// ============================================================

class TaxometerResponse {
  int? status;
  String? message;
  TaxometerData? data;

  TaxometerResponse({this.status, this.message, this.data});

  factory TaxometerResponse.fromJson(Map<String, dynamic> json) =>
      TaxometerResponse(
        status: int.tryParse(json["status"]?.toString() ?? "0"),
        message: json["message"]?.toString(),
        data: json["data"] == null
            ? null
            : TaxometerData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

// ============================================================
// TAXOMETER DATA
// ============================================================

class TaxometerData {
  TaxometerClient? client;

  String? financialYear;

  List<String>? financialYears;

  TaxData? taxData;

  TaxometerData({
    this.client,
    this.financialYear,
    this.financialYears,
    this.taxData,
  });

  factory TaxometerData.fromJson(Map<String, dynamic> json) => TaxometerData(
    client: json["client"] == null
        ? null
        : TaxometerClient.fromJson(json["client"]),

    financialYear: json["financial_year"]?.toString(),

    financialYears: json["financial_years"] == null
        ? []
        : List<String>.from(json["financial_years"].map((x) => x.toString())),

    taxData: json["tax_data"] == null
        ? null
        : TaxData.fromJson(json["tax_data"]),
  );

  Map<String, dynamic> toJson() => {
    "client": client?.toJson(),

    "financial_year": financialYear,

    "financial_years": financialYears ?? [],

    "tax_data": taxData?.toJson(),
  };
}

// ============================================================
// CLIENT
// ============================================================

class TaxometerClient {
  int? id;
  String? name;
  String? ccode;

  TaxometerClient({this.id, this.name, this.ccode});

  factory TaxometerClient.fromJson(Map<String, dynamic> json) =>
      TaxometerClient(
        id: int.tryParse(json["id"]?.toString() ?? "0"),

        name: json["name"]?.toString(),

        ccode: json["ccode"]?.toString(),
      );

  Map<String, dynamic> toJson() => {"id": id, "name": name, "ccode": ccode};
}

// ============================================================
// TAX DATA
// ============================================================

class TaxData {
  // ----------------------------------------------------------
  // REALIZED CAPITAL GAINS
  // ----------------------------------------------------------

  double? grossRealizedStcg;
  double? grossRealizedLtcg;

  double? stclSetoffAmount;

  double? netRealizedStcg;
  double? netRealizedLtcg;

  // ----------------------------------------------------------
  // UNREALIZED CAPITAL GAINS
  // ----------------------------------------------------------

  double? unrealizedStcg;
  double? unrealizedLtcg;

  // ----------------------------------------------------------
  // TAX
  // ----------------------------------------------------------

  double? stcgTax;
  double? ltcgTax;

  double? exemptionLimit;
  double? utilizedExemption;
  double? remainingExemption;

  double? taxableLtcg;

  double? totalTax;

  // ----------------------------------------------------------
  // DIVIDEND
  // ----------------------------------------------------------

  double? dividend;
  double? dividendTax;

  String? dividendNote;

  // ----------------------------------------------------------
  // SMART TAX OPTIMIZATION
  // ----------------------------------------------------------

  double? exemptionHarvestAmount;
  double? exemptionSavings;

  double? taxLossHarvestAmount;
  double? taxLossSavings;

  TaxData({
    this.grossRealizedStcg,
    this.grossRealizedLtcg,
    this.stclSetoffAmount,
    this.netRealizedStcg,
    this.netRealizedLtcg,
    this.unrealizedStcg,
    this.unrealizedLtcg,
    this.stcgTax,
    this.ltcgTax,
    this.exemptionLimit,
    this.utilizedExemption,
    this.remainingExemption,
    this.taxableLtcg,
    this.totalTax,
    this.dividend,
    this.dividendTax,
    this.dividendNote,
    this.exemptionHarvestAmount,
    this.exemptionSavings,
    this.taxLossHarvestAmount,
    this.taxLossSavings,
  });

  factory TaxData.fromJson(Map<String, dynamic> json) => TaxData(
    // ====================================================
    // REALIZED
    // ====================================================
    grossRealizedStcg: _toDouble(json["gross_realized_stcg"]),

    grossRealizedLtcg: _toDouble(json["gross_realized_ltcg"]),

    stclSetoffAmount: _toDouble(json["stcl_setoff_amount"]),

    netRealizedStcg: _toDouble(json["net_realized_stcg"]),

    netRealizedLtcg: _toDouble(json["net_realized_ltcg"]),

    // ====================================================
    // UNREALIZED
    // ====================================================
    unrealizedStcg: _toDouble(json["unrealized_stcg"]),

    unrealizedLtcg: _toDouble(json["unrealized_ltcg"]),

    // ====================================================
    // TAX
    // ====================================================
    stcgTax: _toDouble(json["stcg_tax"]),

    ltcgTax: _toDouble(json["ltcg_tax"]),

    exemptionLimit: _toDouble(json["exemption_limit"]),

    utilizedExemption: _toDouble(json["utilized_exemption"]),

    remainingExemption: _toDouble(json["remaining_exemption"]),

    taxableLtcg: _toDouble(json["taxable_ltcg"]),

    totalTax: _toDouble(json["total_tax"]),

    // ====================================================
    // DIVIDEND
    // ====================================================
    dividend: _toDouble(json["dividend"]),

    dividendTax: _toDouble(json["dividend_tax"]),

    dividendNote: json["dividend_note"]?.toString(),

    // ====================================================
    // OPTIMIZATION
    // ====================================================
    exemptionHarvestAmount: _toDouble(json["exemption_harvest_amount"]),

    exemptionSavings: _toDouble(json["exemption_savings"]),

    taxLossHarvestAmount: _toDouble(json["tax_loss_harvest_amount"]),

    taxLossSavings: _toDouble(json["tax_loss_savings"]),
  );

  Map<String, dynamic> toJson() => {
    // Realized
    "gross_realized_stcg": grossRealizedStcg,

    "gross_realized_ltcg": grossRealizedLtcg,

    "stcl_setoff_amount": stclSetoffAmount,

    "net_realized_stcg": netRealizedStcg,

    "net_realized_ltcg": netRealizedLtcg,

    // Unrealized
    "unrealized_stcg": unrealizedStcg,

    "unrealized_ltcg": unrealizedLtcg,

    // Tax
    "stcg_tax": stcgTax,

    "ltcg_tax": ltcgTax,

    "exemption_limit": exemptionLimit,

    "utilized_exemption": utilizedExemption,

    "remaining_exemption": remainingExemption,

    "taxable_ltcg": taxableLtcg,

    "total_tax": totalTax,

    // Dividend
    "dividend": dividend,

    "dividend_tax": dividendTax,

    "dividend_note": dividendNote,

    // Optimization
    "exemption_harvest_amount": exemptionHarvestAmount,

    "exemption_savings": exemptionSavings,

    "tax_loss_harvest_amount": taxLossHarvestAmount,

    "tax_loss_savings": taxLossSavings,
  };
}

// ============================================================
// SAFE NUMBER PARSER
//
// API might send:
// 400
// 400.00
// "400"
// "400.00"
//
// All will safely become double.
// ============================================================

double _toDouble(dynamic value) {
  if (value == null) {
    return 0.0;
  }

  return double.tryParse(value.toString()) ?? 0.0;
}
