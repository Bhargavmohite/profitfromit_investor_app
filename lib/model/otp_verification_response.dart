// To parse this JSON data, do
//
//     final otpVerificationResponse = otpVerificationResponseFromJson(jsonString);

import 'dart:convert';

OtpVerificationResponse otpVerificationResponseFromJson(String str) => OtpVerificationResponse.fromJson(json.decode(str));

String otpVerificationResponseToJson(OtpVerificationResponse data) => json.encode(data.toJson());

class OtpVerificationResponse {
  int? status;
  String? message;
  Data? data;

  OtpVerificationResponse({
    this.status,
    this.message,
    this.data,
  });

  factory OtpVerificationResponse.fromJson(Map<String, dynamic> json) => OtpVerificationResponse(
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
  String? code;
  String? email;
  String? mobile;
  String? address;
  String? status;
  String? panNo;
  String? gender;
  String? dob;
  String? maritalStatus;
  String? occupation;
  String? ckycId;
  String? incomeBracket;
  String? emergencyName;
  String? emergencyContact;
  String? token;
  String? defaultLoginId;

  Data({
    this.name,
    this.code,
    this.email,
    this.mobile,
    this.address,
    this.status,
    this.panNo,
    this.gender,
    this.dob,
    this.maritalStatus,
    this.occupation,
    this.ckycId,
    this.incomeBracket,
    this.emergencyName,
    this.emergencyContact,
    this.token,
    this.defaultLoginId,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    name: json["name"],
    code: json["code"],
    email: json["email"],
    mobile: json["mobile"],
    address: json["address"],
    status: json["status"],
    panNo: json["pan_no"],
    gender: json["gender"],
    dob: json["dob"],
    maritalStatus: json["marital_status"],
    occupation: json["occupation"],
    ckycId: json["ckyc_id"],
    incomeBracket: json["income_bracket"],
    emergencyName: json["emergency_name"],
    emergencyContact: json["emergency_Contact"],
    token: json["token"],
    defaultLoginId: json["default_login_id"].toString(),
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "code": code,
    "email": email,
    "mobile": mobile,
    "address": address,
    "status": status,
    "pan_no": panNo,
    "gender": gender,
    "dob": dob,
    "marital_status": maritalStatus,
    "occupation": occupation,
    "ckyc_id": ckycId,
    "income_bracket": incomeBracket,
    "emergency_name": emergencyName,
    "emergency_Contact": emergencyContact,
    "token": token,
    "default_login_id": defaultLoginId,
  };
}
