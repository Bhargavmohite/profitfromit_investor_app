import 'dart:convert';

SendOTPResponse SendOtpResponseFromJson(String str) => SendOTPResponse.fromJson(json.decode(str));

String SendOtpResponseToJson(SendOTPResponse data) => json.encode(data.toJson());

class SendOTPResponse {
  int? status;
  String? message;
  Data? data;

  SendOTPResponse({
    this.status,
    this.message,
    this.data,
  });

  factory SendOTPResponse.fromJson(Map<String, dynamic> json) => SendOTPResponse(
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
