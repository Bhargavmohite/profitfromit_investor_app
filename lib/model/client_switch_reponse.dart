import 'dart:convert';

ClientSwitchResponse clientSwitchResponseFromJson(String str) =>
    ClientSwitchResponse.fromJson(json.decode(str));

class ClientSwitchResponse {
  int? status;
  String? message;
  ClientSwitchData? data;

  ClientSwitchResponse({this.status, this.message, this.data});

  factory ClientSwitchResponse.fromJson(Map<String, dynamic> json) =>
      ClientSwitchResponse(
        status: json["status"],
        message: json["message"]?.toString(),
        data: json["data"] == null
            ? null
            : ClientSwitchData.fromJson(json["data"]),
      );
}

class ClientSwitchData {
  int? masterClientId;
  String? masterClientName;
  int? activeClientId;
  String? activeClientName;
  bool isClientImpersonating;
  bool canSwitchClients;

  ClientSwitchData({
    this.masterClientId,
    this.masterClientName,
    this.activeClientId,
    this.activeClientName,
    this.isClientImpersonating = false,
    this.canSwitchClients = false,
  });

  static bool _toBool(dynamic value) {
    return value == true ||
        value?.toString() == "1" ||
        value?.toString().toLowerCase() == "true";
  }

  factory ClientSwitchData.fromJson(
    Map<String, dynamic> json,
  ) => ClientSwitchData(
    masterClientId: int.tryParse(json["master_client_id"]?.toString() ?? ""),
    masterClientName: json["master_client_name"]?.toString(),
    activeClientId: int.tryParse(json["active_client_id"]?.toString() ?? ""),
    activeClientName: json["active_client_name"]?.toString(),
    isClientImpersonating: _toBool(json["is_client_impersonating"]),
    canSwitchClients: _toBool(json["can_switch_clients"]),
  );
}
