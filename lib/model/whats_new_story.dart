import 'dart:math' as math;

/// Video story managed from System Admin > What's New Stories.
/// Separate from the app-version release notes in whats_new_response.dart.
class WhatsNewStory {
  const WhatsNewStory({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.isVimeo,
    required this.likesCount,
    required this.isLiked,
    required this.viewedToday,
    this.description,
    this.thumbnailUrl,
    this.videoEmbedUrl,
    this.durationSeconds,
  });

  final int id;
  final String title;
  final String? description;
  final String videoUrl;
  final bool isVimeo;
  final String? videoEmbedUrl;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final int likesCount;
  final bool isLiked;
  final bool viewedToday;

  static WhatsNewStory? fromJson(Map<String, dynamic> data) {
    final id = _integer(data['id']);
    final title = (data['title'] ?? '').toString().trim();
    final videoUrl = (data['video_url'] ?? '').toString().trim();
    if (id == null || id <= 0 || title.isEmpty || videoUrl.isEmpty) {
      return null;
    }

    final source = (data['video_source'] ?? '').toString().toLowerCase();
    final isVimeo = source == 'vimeo' ||
        Uri.tryParse(videoUrl)?.host.toLowerCase() == 'vimeo.com' ||
        Uri.tryParse(videoUrl)?.host.toLowerCase() == 'www.vimeo.com' ||
        Uri.tryParse(videoUrl)?.host.toLowerCase() == 'player.vimeo.com';

    return WhatsNewStory(
      id: id,
      title: title,
      description: _optionalString(data['description']),
      videoUrl: videoUrl,
      isVimeo: isVimeo,
      videoEmbedUrl: _optionalString(data['video_embed_url']),
      thumbnailUrl: _optionalString(data['thumbnail_url']),
      durationSeconds: _integer(data['duration_seconds']),
      likesCount: math.max(0, _integer(data['likes_count']) ?? 0),
      isLiked: _boolean(data['is_liked']),
      viewedToday: _boolean(data['viewed_today']),
    );
  }

  /// Only permit a Vimeo player URL, never arbitrary HTML or external links.
  /// The API already provides this URL for both public and unlisted videos.
  Uri? get safeVimeoEmbedUri {
    if (!isVimeo) return null;

    final supplied = Uri.tryParse(videoEmbedUrl ?? videoUrl);
    if (_isSafePlayerUri(supplied)) return supplied;

    // Fallback for older API payloads using a regular Vimeo watch link.
    final watch = Uri.tryParse(videoUrl);
    if (watch == null || watch.scheme != 'https') return null;
    if (!{'vimeo.com', 'www.vimeo.com'}.contains(watch.host.toLowerCase())) {
      return null;
    }

    final match = RegExp(r'^/([1-9]\d*)(?:/([a-fA-F0-9]{6,}))?/?$')
        .firstMatch(watch.path);
    if (match == null) return null;
    final hash = match.group(2) ?? watch.queryParameters['h'];
    if (hash != null && !RegExp(r'^[a-fA-F0-9]{6,}$').hasMatch(hash)) {
      return null;
    }
    return Uri.https('player.vimeo.com', '/video/${match.group(1)}',
        hash == null ? null : {'h': hash});
  }

  static bool _isSafePlayerUri(Uri? uri) {
    if (uri == null || uri.scheme != 'https' || uri.hasPort ||
        uri.userInfo.isNotEmpty || uri.host.toLowerCase() != 'player.vimeo.com' ||
        !RegExp(r'^/video/[1-9]\d*/?$').hasMatch(uri.path)) {
      return false;
    }
    final hash = uri.queryParameters['h'];
    return hash == null || RegExp(r'^[a-fA-F0-9]{6,}$').hasMatch(hash);
  }

  static String? _optionalString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int? _integer(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static bool _boolean(dynamic value) =>
      value == true || value == 1 || value == '1';
}
