class WhatsNewConfig {
  const WhatsNewConfig._();

  /// TESTING ONLY:
  /// Keep this true while reviewing the What's New experience.
  /// Set it to false before the production release.
  static const bool forceWhatsNewForTesting = true;

  /// Preview label shown in the professional What's New UI.
  /// Change this to your actual upcoming app version when needed.
  static const String previewVersion = '1.1.8';

  static const String releaseTitle = 'A smarter investor experience';
  static const String releaseDateLabel = 'Latest update';

  /// Add either a Vimeo video ID or full Vimeo URL here.
  ///
  /// Examples:
  ///   '123456789'
  ///   'https://vimeo.com/123456789'
  ///   'https://vimeo.com/123456789/abcdef1234'  // unlisted/private hash
  ///
  /// Keep it empty until your Vimeo video is ready.
  static const String supportMessagesVimeoVideo = '';
}
