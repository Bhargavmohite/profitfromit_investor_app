import 'dart:convert';

PortfolioChartResponse portfolioChartResponseFromJson(String str) =>
    PortfolioChartResponse.fromJson(json.decode(str));

String portfolioChartResponseToJson(PortfolioChartResponse data) =>
    json.encode(data.toJson());

class PortfolioChartResponse {
  int? status;
  String? message;
  ChartData? data;

  PortfolioChartResponse({this.status, this.message, this.data});

  factory PortfolioChartResponse.fromJson(Map<String, dynamic> json) =>
      PortfolioChartResponse(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null ? null : ChartData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class ChartData {
  int? activeClientId;
  Chart? chart;

  ChartData({this.activeClientId, this.chart});

  factory ChartData.fromJson(Map<String, dynamic> json) => ChartData(
    activeClientId: json["active_client_id"] == null
        ? null
        : int.tryParse(json["active_client_id"].toString()),
    chart: json["chart"] == null ? null : Chart.fromJson(json["chart"]),
  );

  Map<String, dynamic> toJson() => {
    "active_client_id": activeClientId,
    "chart": chart?.toJson(),
  };
}

class Chart {
  double? baseNav;
  double? currentNav;
  String? inceptionDate;
  int? pointCount;
  List<DateTime>? dates;
  List<double>? portfolioValues;
  List<double>? equityValues;
  List<double>? ledgerValues;
  List<double>? navValues;

  Chart({
    this.baseNav,
    this.currentNav,
    this.inceptionDate,
    this.pointCount,
    this.dates,
    this.portfolioValues,
    this.equityValues,
    this.ledgerValues,
    this.navValues,
  });

  factory Chart.fromJson(Map<String, dynamic> json) => Chart(
    baseNav: double.tryParse(json["base_nav"]?.toString() ?? "100") ?? 100.0,
    currentNav:
        double.tryParse(json["current_nav"]?.toString() ?? "100") ?? 100.0,
    inceptionDate: json["inception_date"]?.toString(),
    pointCount: int.tryParse(json["point_count"]?.toString() ?? "0") ?? 0,
    dates: json["dates"] == null
        ? []
        : List<DateTime>.from(
            json["dates"].map((x) => DateTime.parse(x.toString())),
          ),
    portfolioValues: _doubleList(json["portfolio_values"]),
    equityValues: _doubleList(json["equity_values"]),
    ledgerValues: _doubleList(json["ledger_values"]),
    navValues: _doubleList(json["nav_values"]),
  );

  Map<String, dynamic> toJson() => {
    "base_nav": baseNav,
    "current_nav": currentNav,
    "inception_date": inceptionDate,
    "point_count": pointCount,
    "dates": dates == null
        ? []
        : List<dynamic>.from(
            dates!.map(
              (x) =>
                  "${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}",
            ),
          ),
    "portfolio_values": portfolioValues ?? [],
    "equity_values": equityValues ?? [],
    "ledger_values": ledgerValues ?? [],
    "nav_values": navValues ?? [],
  };

  static List<double> _doubleList(dynamic value) {
    if (value is! List) return [];
    return value.map((e) => double.tryParse(e.toString()) ?? 0.0).toList();
  }
}
