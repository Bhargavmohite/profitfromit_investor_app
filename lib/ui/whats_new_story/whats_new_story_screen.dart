import 'dart:async';
import 'package:profit_from_it_investors/utility/app_activity_route_aware.dart';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/model/whats_new_story.dart';
import 'package:profit_from_it_investors/network/whats_new_story_service.dart';
import 'package:profit_from_it_investors/ui/dashboard_screen/dashboard_screen.dart';
import 'package:profit_from_it_investors/ui/whats_new/whats_new_feature_hub.dart';
import 'package:profit_from_it_investors/utility/constant.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Full-screen, once-a-day investor story, controlled by the Laravel admin.
/// Uses video_player for uploaded MP4/MOV and the Vimeo Player JS API for Vimeo.
class WhatsNewStoryScreen extends StatefulWidget {
  const WhatsNewStoryScreen({super.key, required this.story});

  final WhatsNewStory story;

  @override
  State<WhatsNewStoryScreen> createState() => _WhatsNewStoryScreenState();
}

class _WhatsNewStoryScreenState extends State<WhatsNewStoryScreen>
    with WidgetsBindingObserver, AppActivityRouteAware<WhatsNewStoryScreen> {
  @override
  String get activityScreenKey => 'whats_new_story';

  static const _navy = Color(0xFF070F20);
  static const _blue = Color(0xFF61A5FF);

  Timer? _skipTimer;
  Timer? _likesTimer;
  Timer? _loadTimeout;
  VideoPlayerController? _videoController;
  WebViewController? _webController;

  int _skipSeconds = 3;
  late int _likesCount;
  late bool _isLiked;
  bool _likeBusy = false;
  bool _likesBusy = false;
  bool _mediaLoading = true;
  bool _mediaPlaying = false;
  bool _vimeoNeedsTap = false;
  bool _vimeoMuted = true;
  bool _leaving = false;
  bool _appInForeground = true;
  String? _mediaError;
  double _progress = 0;
  bool _resumeAfterBackground = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.story.likesCount;
    _isLiked = widget.story.isLiked;
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _navy,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // An opened story counts as a view, even when the investor skips it.
    unawaited(WhatsNewStoryService.recordOpened(widget.story.id));
    _skipTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (!_appInForeground) return;
      if (_skipSeconds > 0) setState(() => _skipSeconds--);
      if (_skipSeconds == 0) timer.cancel();
    });
    _likesTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_appInForeground) unawaited(_refreshLikes());
    });
    unawaited(_refreshLikes());
    _preparePlayer();
  }

  void _armLoadTimeout() {
    _loadTimeout?.cancel();
    _loadTimeout = Timer(const Duration(seconds: 14), () {
      if (mounted && _mediaLoading && !_leaving) {
        setState(() {
          _mediaLoading = false;
          _mediaError = 'Video is taking longer than expected to load.';
        });
      }
    });
  }

  void _preparePlayer() {
    _armLoadTimeout();
    if (widget.story.isVimeo) {
      unawaited(_prepareVimeo());
    } else {
      unawaited(_prepareUploadedVideo());
    }
  }

  Future<void> _prepareUploadedVideo() async {
    final uri = Uri.tryParse(widget.story.videoUrl);
    if (uri == null || uri.scheme != 'https') {
      _showVideoError('The uploaded video URL is invalid.');
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);
    _videoController = controller;
    controller.addListener(_onUploadedVideoChanged);
    try {
      await controller.initialize();
      if (!mounted || _leaving || _videoController != controller) return;
      await controller.setLooping(false);
      await controller.setVolume(1);
      setState(() {
        _mediaLoading = false;
        _mediaError = null;
      });
      _loadTimeout?.cancel();
      await controller.play();
    } catch (error) {
      if (mounted && _videoController == controller) {
        _showVideoError('Unable to play this video. Please retry.');
        debugPrint('[DAILY STORY] Uploaded video error: $error');
      }
    }
  }

  void _onUploadedVideoChanged() {
    final controller = _videoController;
    if (!mounted || _leaving || controller == null) return;
    final value = controller.value;
    if (value.hasError) {
      _showVideoError('Unable to play this video. Please retry.');
      return;
    }
    if (!value.isInitialized) return;
    if (value.isCompleted) {
      _finishStory();
      return;
    }
    final durationMs = value.duration.inMilliseconds;
    final fraction = durationMs > 0
        ? (value.position.inMilliseconds / durationMs)
              .clamp(0.0, 1.0)
              .toDouble()
        : 0.0;
    if ((_progress - fraction).abs() >= 0.006 ||
        _mediaPlaying != value.isPlaying) {
      setState(() {
        _progress = fraction;
        _mediaPlaying = value.isPlaying;
      });
    }
  }

  Future<void> _prepareVimeo() async {
    final embed = widget.story.safeVimeoEmbedUri;
    if (embed == null) {
      _showVideoError('The Vimeo video link is invalid.');
      return;
    }
    // Android and iOS generally require muted video for autoplay. Do not
    // remove the Vimeo privacy hash (h=...) when adding player parameters.
    final uri = embed.replace(
      queryParameters: {
        ...embed.queryParameters,
        'autoplay': '1',
        'muted': '1',
        'playsinline': '1',
        'title': '0',
        'byline': '0',
        'portrait': '0',
        'dnt': '1',
      },
    );
    final escapedUri = htmlEscape.convert(uri.toString());
    final html =
        '''<!doctype html>
<html><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,viewport-fit=cover"/>
<style>html,body{padding:0;margin:0;width:100%;height:100%;overflow:hidden;background:#070f20}
#vimeo{position:absolute;inset:0;width:100%;height:100%;border:0}</style></head>
<body><iframe id="vimeo" src="$escapedUri" allow="autoplay; fullscreen; picture-in-picture" allowfullscreen></iframe>
<script src="https://player.vimeo.com/api/player.js" onerror="window.StoryBridge && window.StoryBridge.postMessage(JSON.stringify({type:'player_error',name:'ScriptLoadError',detail:'Vimeo Player JS could not be downloaded'}))"></script>
<script>
(function(){
  function send(type, extra){
    var message = extra || {};
    message.type = type;
    if(window.StoryBridge){window.StoryBridge.postMessage(JSON.stringify(message));}
  }
  function details(error){
    return {
      name: (error && error.name) ? String(error.name) : 'PlayerError',
      detail: (error && error.message) ? String(error.message) : String(error || 'Unknown error')
    };
  }
  function report(type, error){send(type, details(error));}
  try {
    if(!window.Vimeo){report('player_error', {name:'ScriptLoadError', message:'Vimeo Player JS is unavailable'});return;}
    var player = new Vimeo.Player(document.getElementById('vimeo'));
    window.dailyStoryPlayer = player;
    window.dailyStoryPlay = function(){
      return player.play().catch(function(error){report('play_rejected',error);});
    };
    window.dailyStoryPause = function(){
      return player.pause().catch(function(error){report('player_error',error);});
    };
    window.dailyStorySetMuted = function(muted){
      return player.setMuted(muted)
        .then(function(){send('muted',{muted:muted});})
        .catch(function(error){report('sound_error',error);});
    };
    player.on('play', function(){send('play');});
    player.on('pause', function(){send('pause');});
    player.on('ended', function(){send('ended');});
    player.on('timeupdate', function(data){send('timeupdate', {seconds:data.seconds, duration:data.duration});});
    player.on('error', function(error){report('player_error',error);});
    player.ready().then(function(){
      send('ready');
      window.dailyStoryPlay();
    }).catch(function(error){report('player_error',error);});
  } catch(error) {report('player_error',error);}
})();
</script></body></html>''';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_navy)
      ..addJavaScriptChannel(
        'StoryBridge',
        onMessageReceived: (message) => _onVimeoMessage(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            debugPrint(
              '[DAILY STORY] Vimeo WebView error: '
              'code=${error.errorCode} description=${error.description} '
              'mainFrame=${error.isForMainFrame}',
            );
            // A failed image, tracking request, or iframe resource should not
            // automatically replace a working Vimeo player with an error.
            if (error.isForMainFrame == true) {
              _showVideoError('Unable to load the video player. Please retry.');
            }
          },
          onHttpError: (error) {
            debugPrint(
              '[DAILY STORY] Vimeo HTTP error: '
              'status=${error.response?.statusCode} '
              'host=${error.request?.uri.host}',
            );
          },
        ),
      );
    _webController = controller;

    try {
      // Set this before the first navigation. Otherwise the first autoplay
      // attempt may be denied by Android's default media-gesture policy.
      if (controller.platform is AndroidWebViewController) {
        await (controller.platform as AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(false);
      }
      if (!mounted || _leaving || _webController != controller) return;
      await controller.loadHtmlString(html, baseUrl: Constants.baseUrl);
    } catch (error) {
      debugPrint('[DAILY STORY] Vimeo WebView setup failed: $error');
      if (mounted && !_leaving && _webController == controller) {
        _showVideoError('Unable to initialize the Vimeo player.');
      }
    }
  }

  void _onVimeoMessage(String message) {
    if (!mounted || _leaving) return;
    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map<String, dynamic>) return;
      switch (decoded['type']) {
        case 'ready':
          _loadTimeout?.cancel();
          setState(() {
            _mediaLoading = false;
            _mediaError = null;
          });
          break;
        case 'play':
          _loadTimeout?.cancel();
          setState(() {
            _mediaLoading = false;
            _mediaError = null;
            _mediaPlaying = true;
            _vimeoNeedsTap = false;
          });
          break;
        case 'pause':
          setState(() => _mediaPlaying = false);
          break;
        case 'timeupdate':
          final seconds = (decoded['seconds'] as num?)?.toDouble() ?? 0;
          final duration = (decoded['duration'] as num?)?.toDouble() ?? 0;
          if (duration > 0) {
            final fraction = (seconds / duration).clamp(0.0, 1.0).toDouble();
            if ((_progress - fraction).abs() >= 0.006) {
              setState(() => _progress = fraction);
            }
          }
          break;
        case 'ended':
          _finishStory();
          break;
        case 'muted':
          setState(() => _vimeoMuted = decoded['muted'] == true);
          break;
        case 'sound_error':
          debugPrint(
            '[DAILY STORY] Vimeo sound error: '
            '${decoded['name']}: ${decoded['detail']}',
          );
          break;
        case 'play_rejected':
        case 'player_error':
          final name = (decoded['name'] ?? 'PlayerError').toString();
          final detail = (decoded['detail'] ?? '').toString();
          debugPrint(
            '[DAILY STORY] Vimeo ${decoded['type']} '
            'name=$name detail=$detail',
          );
          if (name == 'PrivacyError' || name == 'PasswordError') {
            _showVideoError(
              'Vimeo denied video access ($name). '
              'Check the embed permissions for this video.',
            );
          } else if (name == 'ScriptLoadError') {
            _showVideoError(
              'Could not load Vimeo Player JS. '
              'Check your internet connection.',
            );
          } else if (decoded['type'] == 'player_error' && name == 'TypeError') {
            _showVideoError('Vimeo player initialization failed ($name).');
          } else {
            // Playback rejection is not necessarily a privacy error.
            // Leave the iframe available and offer a manual play action.
            _loadTimeout?.cancel();
            setState(() {
              _mediaLoading = false;
              _mediaPlaying = false;
              _vimeoNeedsTap = true;
            });
          }
          break;
      }
    } catch (error) {
      debugPrint('[DAILY STORY] Vimeo event parsing failed: $error');
    }
  }

  void _showVideoError(String message) {
    if (!mounted || _leaving) return;
    _loadTimeout?.cancel();
    if (_mediaError == message && !_mediaLoading) return;
    setState(() {
      _mediaLoading = false;
      _mediaPlaying = false;
      _mediaError = message;
    });
  }

  Future<void> _playPause() => _setPlayback(!_mediaPlaying);

  Future<void> _setPlayback(bool shouldPlay) async {
    if (_mediaError != null || _mediaLoading || _leaving) return;
    try {
      if (widget.story.isVimeo) {
        // Vimeo's play()/pause() return promises. Wait for the player events
        // instead of assuming runJavaScript() means the video started.
        await _webController?.runJavaScript(
          'window.${shouldPlay ? 'dailyStoryPlay' : 'dailyStoryPause'} && '
          'window.${shouldPlay ? 'dailyStoryPlay' : 'dailyStoryPause'}();',
        );
      } else {
        if (shouldPlay) {
          await _videoController?.play();
        } else {
          await _videoController?.pause();
        }
      }
    } catch (error) {
      debugPrint('[DAILY STORY] Play/pause failed: $error');
    }
  }

  Future<void> _toggleVimeoSound() async {
    if (!widget.story.isVimeo ||
        _webController == null ||
        _mediaLoading ||
        _mediaError != null) {
      return;
    }
    final muted = !_vimeoMuted;
    try {
      // Flutter only updates its icon after the Vimeo player acknowledges.
      await _webController!.runJavaScript(
        'window.dailyStorySetMuted && window.dailyStorySetMuted(${muted ? 'true' : 'false'});',
      );
    } catch (error) {
      debugPrint('[DAILY STORY] Vimeo sound toggle failed: $error');
    }
  }

  Future<void> _retryVideo() async {
    if (!mounted || _leaving) return;
    setState(() {
      _mediaLoading = true;
      _mediaError = null;
      _progress = 0;
      _vimeoNeedsTap = false;
      _vimeoMuted = true;
    });
    _loadTimeout?.cancel();
    if (widget.story.isVimeo) {
      _webController = null;
      _preparePlayer();
    } else {
      final old = _videoController;
      _videoController = null;
      if (old != null) {
        old.removeListener(_onUploadedVideoChanged);
        await old.dispose();
      }
      if (mounted && !_leaving) _preparePlayer();
    }
  }

  Future<void> _refreshLikes() async {
    if (_likesBusy || _likeBusy || !mounted || _leaving) return;
    _likesBusy = true;
    try {
      final result = await WhatsNewStoryService.getLikes(widget.story.id);
      if (mounted && !_likeBusy && !_leaving && result != null) {
        setState(() {
          _likesCount = result.count;
          _isLiked = result.liked;
        });
      }
    } finally {
      _likesBusy = false;
    }
  }

  Future<void> _toggleLike() async {
    if (_likeBusy || _leaving) return;
    setState(() => _likeBusy = true);
    final result = await WhatsNewStoryService.setLike(
      widget.story.id,
      liked: !_isLiked,
    );
    if (!mounted) return;
    setState(() {
      _likeBusy = false;
      if (result != null) {
        _likesCount = result.count;
        _isLiked = result.liked;
      }
    });
    if (result == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update your like. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _stopVimeo() async {
    try {
      await _webController?.runJavaScript(
        'window.dailyStoryPause && window.dailyStoryPause();',
      );
    } catch (_) {
      // The WebView may already have been destroyed during navigation.
    }
  }

  void _finishStory() {
    if (_leaving || !mounted) return;
    _leaving = true;
    if (widget.story.isVimeo) unawaited(_stopVimeo());
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  /// Leave the story for the existing feature-details page. This deliberately
  /// does not open another video or reset today's view flag.
  void _openKnowMore() {
    if (_leaving || !mounted) return;
    _leaving = true;
    if (widget.story.isVimeo) {
      unawaited(_stopVimeo());
    } else {
      unawaited(_videoController?.pause() ?? Future<void>.value());
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const WhatsNewFeatureHub(openedFromStory: true),
      ),
      (route) => false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _leaving) return;
    if (state == AppLifecycleState.resumed) {
      _appInForeground = true;
      if (_resumeAfterBackground) {
        _resumeAfterBackground = false;
        unawaited(_setPlayback(true));
      }
      unawaited(_refreshLikes());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_appInForeground) {
        _resumeAfterBackground = _mediaPlaying;
        if (_mediaPlaying) unawaited(_setPlayback(false));
      }
      _appInForeground = false;
    }
  }

  @override
  void dispose() {
    _skipTimer?.cancel();
    _likesTimer?.cancel();
    _loadTimeout?.cancel();
    _videoController?.removeListener(_onUploadedVideoChanged);
    unawaited(_videoController?.dispose() ?? Future<void>.value());
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  Widget _videoLayer() {
    if (widget.story.isVimeo) {
      return _webController != null
          ? WebViewWidget(controller: _webController!)
          : const SizedBox.shrink();
    }
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    final size = controller.value.size;
    if (size.width <= 0 || size.height <= 0) return const SizedBox.shrink();
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _background() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: _navy),
        if (widget.story.thumbnailUrl != null)
          Image.network(
            widget.story.thumbnailUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        _videoLayer(),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.18, 0.48, 0.77, 1.0],
              colors: [
                Color(0xB9000716),
                Color(0x35000716),
                Color(0x00000716),
                Color(0x83000716),
                Color(0xF5000716),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _topArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 3.5,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: .27),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WHAT\'S NEW',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    Text(
                      'Profit From It  •  Investor updates',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _skipSeconds == 0 ? _finishStory : null,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    _skipSeconds > 0 ? 'Skip in ${_skipSeconds}s' : 'Skip  ✕',
                    style: GoogleFonts.poppins(
                      color: _skipSeconds > 0 ? Colors.white70 : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(23, 12, 20, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: .2),
              border: Border.all(color: _blue.withValues(alpha: .6)),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'LATEST UPDATE',
              style: GoogleFonts.poppins(
                color: const Color(0xFFBFDFFF),
                fontSize: 10,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 76),
            child: Text(
              widget.story.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 25,
                height: 1.16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (widget.story.description != null) ...[
            const SizedBox(height: 9),
            Padding(
              padding: const EdgeInsets.only(right: 72),
              child: Text(
                widget.story.description!,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: .86),
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 46,
            width: 182,
            child: FilledButton.icon(
              onPressed: _openKnowMore,
              icon: const Icon(Icons.arrow_forward_rounded, size: 19),
              label: Text(
                'Know More',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _navy,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 13),
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                color: Color(0xFFB5C8E9),
                size: 16,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'An update from Profit Finstock',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_mediaPlaying)
                const Icon(
                  Icons.graphic_eq_rounded,
                  color: Colors.white70,
                  size: 17,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _likeButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white.withValues(alpha: .17),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: _likeBusy ? null : _toggleLike,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 58,
              height: 58,
              child: _likeBusy
                  ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      _isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _isLiked ? const Color(0xFFFF5473) : Colors.white,
                      size: 31,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$_likesCount',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'likes',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _statusOverlay() {
    if (_mediaError != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _navy.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_outlined,
                color: Colors.white,
                size: 34,
              ),
              const SizedBox(height: 10),
              Text(
                _mediaError!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _retryVideo,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_mediaLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _skipSeconds == 0) _finishStory();
      },
      child: Scaffold(
        backgroundColor: _navy,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _background(),
            if (!widget.story.isVimeo && !_mediaLoading && _mediaError == null)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _playPause,
                  child: const SizedBox.expand(),
                ),
              ),
            _statusOverlay(),
            SafeArea(
              bottom: false,
              child: Align(alignment: Alignment.topCenter, child: _topArea()),
            ),
            Positioned(
              bottom: math.max(0.0, bottomInset),
              left: 0,
              right: 0,
              child: _bottomArea(),
            ),
            Positioned(
              bottom: math.max(0.0, bottomInset) + 142,
              right: 21,
              child: _likeButton(),
            ),
            if (widget.story.isVimeo && !_mediaLoading && _mediaError == null)
              Positioned(
                right: 25,
                bottom: math.max(0.0, bottomInset) + 254,
                child: Material(
                  color: Colors.black.withValues(alpha: .45),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: _vimeoMuted ? 'Enable sound' : 'Mute video',
                    onPressed: _toggleVimeoSound,
                    icon: Icon(
                      _vimeoMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (widget.story.isVimeo &&
                _vimeoNeedsTap &&
                !_mediaLoading &&
                _mediaError == null)
              Center(
                child: FilledButton.icon(
                  onPressed: () => unawaited(_setPlayback(true)),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Tap to play'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: _navy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            if (!_mediaLoading &&
                _mediaError == null &&
                !_mediaPlaying &&
                !(_vimeoNeedsTap && widget.story.isVimeo))
              IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
