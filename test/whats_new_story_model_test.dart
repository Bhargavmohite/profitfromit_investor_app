import 'package:flutter_test/flutter_test.dart';
import 'package:profit_from_it_investors/model/whats_new_story.dart';

void main() {
  test('Parses active uploaded video payload from Laravel', () {
    final parsed = WhatsNewStory.fromJson({
      'id': 12,
      'title': 'Welcome to the new portfolio',
      'description': 'Latest updates',
      'video_source': 'file',
      'video_url': 'https://investors.profitfromit.co.in/storage/stories/a.mp4',
      'duration_seconds': 42,
      'likes_count': 136,
      'is_liked': true,
      'viewed_today': false,
    });
    expect(parsed, isNotNull);
    final story = parsed!;
    expect(story.id, 12);
    expect(story.isVimeo, false);
    expect(story.durationSeconds, 42);
    expect(story.likesCount, 136);
    expect(story.isLiked, true);
    expect(story.viewedToday, false);
  });

  test('Vimeo unlisted videos retain private hash for embedding', () {
    final story = WhatsNewStory.fromJson({
      'id': 2,
      'title': 'Important changes',
      'video_source': 'vimeo',
      'video_url': 'https://vimeo.com/123456789/abcdef1234',
      'video_embed_url': 'https://player.vimeo.com/video/123456789?h=abcdef1234',
      'likes_count': 9,
      'is_liked': false,
      'viewed_today': true,
    });
    expect(story?.isVimeo, true);
    expect(story?.viewedToday, true);
    expect(story?.safeVimeoEmbedUri?.queryParameters['h'], 'abcdef1234');
  });

  test('Accepts direct Vimeo player URL when embed field is not supplied', () {
    final story = WhatsNewStory.fromJson({
      'id': 3,
      'title': 'Watch the product demo',
      'video_source': 'vimeo',
      'video_url': 'https://player.vimeo.com/video/123456789?h=abcdef1234',
    });
    expect(story?.safeVimeoEmbedUri?.host, 'player.vimeo.com');
  });

  test('Rejects external iframe host even when API flags source as Vimeo', () {
    final story = WhatsNewStory.fromJson({
      'id': 2,
      'title': 'Suspicious embed',
      'video_source': 'vimeo',
      'video_url': 'https://untrusted.invalid/a',
      'video_embed_url': 'https://untrusted.invalid/embed',
    });
    expect(story?.safeVimeoEmbedUri, null);
  });

  test('Rejects empty/incomplete story', () {
    expect(WhatsNewStory.fromJson({'id': 1, 'title': 'No video'}), null);
  });
}
