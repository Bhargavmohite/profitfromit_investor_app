import 'dart:convert';

PortfolioChartResponse portfolioChartResponseFromJson(String str) => PortfolioChartResponse.fromJson(json.decode(str));

String portfolioChartResponseToJson(PortfolioChartResponse data) => json.encode(data.toJson());

class PortfolioChartResponse {
  int? status;
  String? message;
  ChartData? data;

  PortfolioChartResponse({
    this.status,
    this.message,
    this.data,
  });

  factory PortfolioChartResponse.fromJson(Map<String, dynamic> json) => PortfolioChartResponse(
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
  Chart? chart;

  ChartData({
    this.chart,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) => ChartData(
    chart: json["chart"] == null ? null : Chart.fromJson(json["chart"]),
  );

  Map<String, dynamic> toJson() => {
    "chart": chart?.toJson(),
  };
}

class Chart {
  List<DateTime>? dates;
  List<double>? portfolioValues;

  Chart({
    this.dates,
    this.portfolioValues,
  });

  factory Chart.fromJson(Map<String, dynamic> json) => Chart(
    dates: json["dates"] == null ? [] : List<DateTime>.from(json["dates"]!.map((x) => DateTime.parse(x))),
    portfolioValues: (json["portfolio_values"] as List?)?.map((e) => double.tryParse(e.toString()) ?? 0.0).toList() ?? [],
  );

  Map<String, dynamic> toJson() => {
    "dates": dates == null ? [] : List<dynamic>.from(dates!.map((x) => "${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}")),
    "portfolio_values": portfolioValues == null ? [] : List<dynamic>.from(portfolioValues!.map((x) => x)),
  };
}