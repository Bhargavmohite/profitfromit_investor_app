import 'dart:convert';

LogoutResponse logoutResponseFromJson(String str) => LogoutResponse.fromJson(json.decode(str));

String logoutResponseToJson(LogoutResponse data) => json.encode(data.toJson());

class LogoutResponse {
  int? status;
  String? message;
  Data? data;

  LogoutResponse({
    this.status,
    this.message,
    this.data,
  });

  factory LogoutResponse.fromJson(Map<String, dynamic> json) => LogoutResponse(
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
  Data();

  factory Data.fromJson(Map<String, dynamic> json) => Data(
  );

  Map<String, dynamic> toJson() => {
  };
}