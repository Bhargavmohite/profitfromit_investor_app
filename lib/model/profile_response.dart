import 'dart:convert';

ProfileResponse profileResponseFromJson(String str) => ProfileResponse.fromJson(json.decode(str));

String profileResponseToJson(ProfileResponse data) => json.encode(data.toJson());

class ProfileResponse {
  int? status;
  String? message;
  Data? data;

  ProfileResponse({
    this.status,
    this.message,
    this.data,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) => ProfileResponse(
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
  int? id;
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
  List<BankAccount>? bankAccounts;
  List<Nominee>? nominees;

  Data({
    this.id,
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
    this.bankAccounts,
    this.nominees,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    id: json["id"],
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
    bankAccounts: json["bank_accounts"] == null ? [] : List<BankAccount>.from(json["bank_accounts"]!.map((x) => BankAccount.fromJson(x))),
    nominees: json["nominees"] == null ? [] : List<Nominee>.from(json["nominees"]!.map((x) => Nominee.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
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
    "bank_accounts": bankAccounts == null ? [] : List<dynamic>.from(bankAccounts!.map((x) => x.toJson())),
    "nominees": nominees == null ? [] : List<dynamic>.from(nominees!.map((x) => x.toJson())),
  };
}

class BankAccount {
  String? bankName;
  String? accountNumber;
  String? status;

  BankAccount({
    this.bankName,
    this.accountNumber,
    this.status,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
    bankName: json["bank_name"],
    accountNumber: json["account_number"],
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "bank_name": bankName,
    "account_number": accountNumber,
    "status": status,
  };
}

class Nominee {
  String? name;
  String? relation;
  String? share;

  Nominee({
    this.name,
    this.relation,
    this.share,
  });

  factory Nominee.fromJson(Map<String, dynamic> json) => Nominee(
    name: json["name"],
    relation: json["relation"],
    share: json["share"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "relation": relation,
    "share": share,
  };
}