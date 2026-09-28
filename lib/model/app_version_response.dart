import 'dart:convert';

AppVersionResponse appVersionResponseFromJson(String str) =>
    AppVersionResponse.fromJson(json.decode(str));

String appVersionResponseToJson(AppVersionResponse data) =>
    json.encode(data.toJson());

class AppVersionResponse {
  int? status;
  String? message;
  AppVersionData? data;

  AppVersionResponse({this.status, this.message, this.data});

  factory AppVersionResponse.fromJson(Map<String, dynamic> json) =>
      AppVersionResponse(
        status: _toInt(json['status']),
        message: json['message']?.toString(),
        data: json['data'] is Map<String, dynamic>
            ? AppVersionData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data?.toJson(),
  };
}

class AppVersionData {
  PlatformUpdateConfig? android;
  PlatformUpdateConfig? ios;
  UpdateUiConfig? ui;

  AppVersionData({this.android, this.ios, this.ui});

  factory AppVersionData.fromJson(Map<String, dynamic> json) => AppVersionData(
    android: json['android'] is Map<String, dynamic>
        ? PlatformUpdateConfig.fromJson(json['android'] as Map<String, dynamic>)
        : null,
    ios: json['ios'] is Map<String, dynamic>
        ? PlatformUpdateConfig.fromJson(json['ios'] as Map<String, dynamic>)
        : null,
    ui: json['ui'] is Map<String, dynamic>
        ? UpdateUiConfig.fromJson(json['ui'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'android': android?.toJson(),
    'ios': ios?.toJson(),
    'ui': ui?.toJson(),
  };
}

class PlatformUpdateConfig {
  String latestVersion;
  String minimumVersion;
  int latestBuild;
  int minimumBuild;
  String storeUrl;

  PlatformUpdateConfig({
    this.latestVersion = '0.0.0',
    this.minimumVersion = '0.0.0',
    this.latestBuild = 0,
    this.minimumBuild = 0,
    this.storeUrl = '',
  });

  factory PlatformUpdateConfig.fromJson(Map<String, dynamic> json) =>
      PlatformUpdateConfig(
        latestVersion: json['latest_version']?.toString() ?? '0.0.0',
        minimumVersion: json['minimum_version']?.toString() ?? '0.0.0',
        latestBuild: _toInt(json['latest_build']),
        minimumBuild: _toInt(json['minimum_build']),
        storeUrl: json['store_url']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
    'latest_version': latestVersion,
    'minimum_version': minimumVersion,
    'latest_build': latestBuild,
    'minimum_build': minimumBuild,
    'store_url': storeUrl,
  };
}

class UpdateUiConfig {
  String mandatoryTitle;
  String mandatoryMessage;
  String optionalTitle;
  String optionalMessage;
  String updateButton;
  String laterButton;

  UpdateUiConfig({
    this.mandatoryTitle = 'Update Required',
    this.mandatoryMessage =
        'A new version is available. Please update to continue.',
    this.optionalTitle = 'New Update Available',
    this.optionalMessage = 'A newer version is available.',
    this.updateButton = 'Update Now',
    this.laterButton = 'Maybe Later',
  });

  factory UpdateUiConfig.fromJson(Map<String, dynamic> json) => UpdateUiConfig(
    mandatoryTitle: json['mandatory_title']?.toString() ?? 'Update Required',
    mandatoryMessage:
        json['mandatory_message']?.toString() ??
        'A new version is available. Please update to continue.',
    optionalTitle: json['optional_title']?.toString() ?? 'New Update Available',
    optionalMessage:
        json['optional_message']?.toString() ?? 'A newer version is available.',
    updateButton: json['update_button']?.toString() ?? 'Update Now',
    laterButton: json['later_button']?.toString() ?? 'Maybe Later',
  );

  Map<String, dynamic> toJson() => {
    'mandatory_title': mandatoryTitle,
    'mandatory_message': mandatoryMessage,
    'optional_title': optionalTitle,
    'optional_message': optionalMessage,
    'update_button': updateButton,
    'later_button': laterButton,
  };
}

int _toInt(dynamic value) {
  if (value == null) {
    return 0;
  }

  return int.tryParse(value.toString()) ?? 0;
}
