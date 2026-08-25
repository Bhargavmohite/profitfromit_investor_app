import 'dart:convert';

StockDetailResponse stockDetailResponseFromJson(String str) => StockDetailResponse.fromJson(json.decode(str));

String stockDetailResponseToJson(StockDetailResponse data) => json.encode(data.toJson());

class StockDetailResponse {
  int? status;
  String? message;
  Data? data;

  StockDetailResponse({
    this.status,
    this.message,
    this.data,
  });

  factory StockDetailResponse.fromJson(Map<String, dynamic> json) => StockDetailResponse(
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
  String? companyName;
  String? isin;
  Summary? summary;
  List<Transaction>? transactions;

  Data({
    this.companyName,
    this.isin,
    this.summary,
    this.transactions,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    companyName: json["company_name"],
    isin: json["isin"],
    summary: json["summary"] == null ? null : Summary.fromJson(json["summary"]),
    transactions: json["transactions"] == null ? [] : List<Transaction>.from(json["transactions"]!.map((x) => Transaction.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "company_name": companyName,
    "isin": isin,
    "summary": summary?.toJson(),
    "transactions": transactions == null ? [] : List<dynamic>.from(transactions!.map((x) => x.toJson())),
  };
}

class Summary {
  String? holdingQty;
  String? avgBuyPrice;
  String? investedValue;
  String? currentValue;
  String? totalGain;
  double? totalGainPercent;
  String? xirr;
  String? totalHoldingValue;
  String? totalBuyAmount;
  String? totalSellAmount;
  String? realisedGain;
  String? unrealisedGain;
  String? todaysGain;
  String? dividend;

  Summary({
    this.holdingQty,
    this.avgBuyPrice,
    this.investedValue,
    this.currentValue,
    this.totalGain,
    this.totalGainPercent,
    this.xirr,
    this.totalHoldingValue,
    this.totalBuyAmount,
    this.totalSellAmount,
    this.realisedGain,
    this.unrealisedGain,
    this.todaysGain,
    this.dividend,
  });

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
    holdingQty: json["holding_qty"],
    avgBuyPrice: json["avg_buy_price"],
    investedValue: json["invested_value"],
    currentValue: json["current_value"],
    totalGain: json["total_gain"],
    totalGainPercent: json["total_gain_percent"]?.toDouble(),
    xirr: json["xirr"],
    totalHoldingValue: json["total_holding_value"],
    totalBuyAmount: json["total_buy_amount"],
    totalSellAmount: json["total_sell_amount"],
    realisedGain: json["realised_gain"],
    unrealisedGain: json["unrealised_gain"],
    todaysGain: json["todays_gain"],
    dividend: json["dividend"],
  );

  Map<String, dynamic> toJson() => {
    "holding_qty": holdingQty,
    "avg_buy_price": avgBuyPrice,
    "invested_value": investedValue,
    "current_value": currentValue,
    "total_gain": totalGain,
    "total_gain_percent": totalGainPercent,
    "xirr": xirr,
    "total_holding_value": totalHoldingValue,
    "total_buy_amount": totalBuyAmount,
    "total_sell_amount": totalSellAmount,
    "realised_gain": realisedGain,
    "unrealised_gain": unrealisedGain,
    "todays_gain": todaysGain,
    "dividend": dividend,
  };
}

class Transaction {
  dynamic id;
  String? date;
  String? action;
  dynamic quantity;
  String? price;
  String? amount;
  String? brokerage;
  String? balanceQty;
  dynamic isManual;

  Transaction({
    this.id,
    this.date,
    this.action,
    this.quantity,
    this.price,
    this.amount,
    this.brokerage,
    this.balanceQty,
    this.isManual,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json["id"],
    date: json["date"],
    action: json["action"],
    quantity: json["quantity"],
    price: json["price"],
    amount: json["amount"],
    brokerage: json["brokerage"],
    balanceQty: json["balance_qty"],
    isManual: json["is_manual"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "date": date,
    "action": action,
    "quantity": quantity,
    "price": price,
    "amount": amount,
    "brokerage": brokerage,
    "balance_qty": balanceQty,
    "is_manual": isManual,
  };
}
