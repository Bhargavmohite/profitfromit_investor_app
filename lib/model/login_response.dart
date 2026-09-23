import 'dart:convert';

LoginResponse loginResponseFromJson(String str) =>
    LoginResponse.fromJson(json.decode(str));

String loginResponseToJson(LoginResponse data) => json.encode(data.toJson());

class LoginResponse {
  int? status;
  String? message;
  LoginData? data;

  LoginResponse({this.status, this.message, this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    status: json["status"],
    message: json["message"],
    data: json["data"] == null ? null : LoginData.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class LoginData {
  String? token;
  int? familyId;
  int? isFamilyMaster;
  bool? canSelectFamily;

  int? masterClientId;
  int? activeClientId;
  bool? isClientImpersonating;
  int? isReadonlyAdmin;
  bool? canSwitchClients;
  List<LoginClientList> clientList;

  LoginData({
    this.token,
    this.familyId,
    this.isFamilyMaster,
    this.canSelectFamily,
    this.masterClientId,
    this.activeClientId,
    this.isClientImpersonating,
    this.isReadonlyAdmin,
    this.canSwitchClients,
    this.clientList = const [],
  });

  static bool _toBool(dynamic value) {
    return value == true ||
        value?.toString() == "1" ||
        value?.toString().toLowerCase() == "true";
  }

  factory LoginData.fromJson(Map<String, dynamic> json) => LoginData(
    token: json["token"]?.toString(),
    familyId: json["family_id"] == null
        ? null
        : int.tryParse(json["family_id"].toString()),
    isFamilyMaster:
        int.tryParse(json["is_family_master"]?.toString() ?? "0") ?? 0,
    canSelectFamily: _toBool(json["can_select_family"]),
    masterClientId: json["master_client_id"] == null
        ? null
        : int.tryParse(json["master_client_id"].toString()),
    activeClientId: json["active_client_id"] == null
        ? null
        : int.tryParse(json["active_client_id"].toString()),
    isClientImpersonating: _toBool(json["is_client_impersonating"]),
    isReadonlyAdmin:
        int.tryParse(json["is_readonly_admin"]?.toString() ?? "0") ?? 0,
    canSwitchClients: _toBool(json["can_switch_clients"]),
    clientList: json["client_list"] is List
        ? List<LoginClientList>.from(
            json["client_list"].map((x) => LoginClientList.fromJson(x)),
          )
        : <LoginClientList>[],
  );

  Map<String, dynamic> toJson() => {
    "token": token,
    "family_id": familyId,
    "is_family_master": isFamilyMaster,
    "can_select_family": canSelectFamily,
    "master_client_id": masterClientId,
    "active_client_id": activeClientId,
    "is_client_impersonating": isClientImpersonating,
    "is_readonly_admin": isReadonlyAdmin,
    "can_switch_clients": canSwitchClients,
    "client_list": clientList.map((x) => x.toJson()).toList(),
  };
}

class LoginClientList {
  int? id;
  String? name;
  bool isCurrent;

  LoginClientList({this.id, this.name, this.isCurrent = false});

  factory LoginClientList.fromJson(Map<String, dynamic> json) =>
      LoginClientList(
        id: int.tryParse(json["id"]?.toString() ?? ""),
        name: json["name"]?.toString(),
        isCurrent:
            json["is_current"] == true ||
            json["is_current"]?.toString() == "1" ||
            json["is_current"]?.toString().toLowerCase() == "true",
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "is_current": isCurrent,
  };
}
