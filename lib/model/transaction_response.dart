import 'dart:convert';

TransactionResponse transactionResponseFromJson(String str) => TransactionResponse.fromJson(json.decode(str));

String transactionResponseToJson(TransactionResponse data) => json.encode(data.toJson());

class TransactionResponse {
  int? status;
  String? message;
  Data? data;

  TransactionResponse({
    this.status,
    this.message,
    this.data,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) => TransactionResponse(
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
  List<Transaction>? transactions;

  Data({
    this.transactions,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    transactions: json["transactions"] == null ? [] : List<Transaction>.from(json["transactions"]!.map((x) => Transaction.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "transactions": transactions == null ? [] : List<dynamic>.from(transactions!.map((x) => x.toJson())),
  };
}

class Transaction {
  String? id;
  String? type;
  String? companyName;
  String? date;
  String? quantity;
  String? price;
  String? amount;
  String? brokerage;
  String? balanceQty;
  String? displayText;
  String? color;
  String? colorCode;

  Transaction({
    this.id,
    this.type,
    this.companyName,
    this.date,
    this.quantity,
    this.price,
    this.amount,
    this.brokerage,
    this.balanceQty,
    this.displayText,
    this.color,
    this.colorCode,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json["id"],
    type: json["type"],
    companyName: json["company_name"],
    date: json["date"],
    quantity: json["quantity"],
    price: json["price"],
    amount: json["amount"],
    brokerage: json["brokerage"],
    balanceQty: json["balance_qty"],
    displayText: json["display_text"],
    color: json["color"],
    colorCode: json["color_code"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type,
    "company_name": companyName,
    "date": date,
    "quantity": quantity,
    "price": price,
    "amount": amount,
    "brokerage": brokerage,
    "balance_qty": balanceQty,
    "display_text": displayText,
    "color": color,
    "color_code": colorCode,
  };
}
