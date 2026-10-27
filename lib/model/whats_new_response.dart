import 'dart:convert';

WhatsNewResponse whatsNewResponseFromJson(String source) =>
    WhatsNewResponse.fromJson(json.decode(source) as Map<String, dynamic>);

class WhatsNewResponse {
  final int status;
  final String message;
  final WhatsNewRelease? data;

  const WhatsNewResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory WhatsNewResponse.fromJson(Map<String, dynamic> json) {
    return WhatsNewResponse(
      status: int.tryParse(json['status']?.toString() ?? '') ?? 0,
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? WhatsNewRelease.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class WhatsNewRelease {
  final bool enabled;
  final String version;
  final List<WhatsNewItemData> items;

  const WhatsNewRelease({
    required this.enabled,
    required this.version,
    required this.items,
  });

  factory WhatsNewRelease.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    return WhatsNewRelease(
      enabled: json['enabled'] == true ||
          json['enabled']?.toString() == '1' ||
          json['enabled']?.toString().toLowerCase() == 'true',
      version: json['version']?.toString().trim() ?? '',
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(WhatsNewItemData.fromJson)
              .where((item) => item.title.isNotEmpty && item.para.isNotEmpty)
              .toList(growable: false)
          : const [],
    );
  }
}

class WhatsNewItemData {
  final String tag;
  final String title;
  final String para;
  final String video;
  final String explorePath;

  const WhatsNewItemData({
    required this.tag,
    required this.title,
    required this.para,
    required this.video,
    required this.explorePath,
  });

  factory WhatsNewItemData.fromJson(Map<String, dynamic> json) {
    return WhatsNewItemData(
      tag: json['tag']?.toString().trim() ?? '',
      title: json['title']?.toString().trim() ?? '',
      para: json['para']?.toString().trim() ?? '',
      video: json['video']?.toString().trim() ?? '',
      explorePath: json['explore_path']?.toString().trim() ?? '',
    );
  }
}
