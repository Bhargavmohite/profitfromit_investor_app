import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Diwali 2026 greeting, visually matched to the Profit From It HTML/CSS demo.
///
/// Place directly around the Login and Dashboard screen widgets, not around
/// MaterialApp: this limits the celebration to the two intended screens and
/// leaves Splash, OTP and other routes unaffected.
///
/// Production: shows once per installation between 5–13 Nov 2026 (IST).
/// Development ONLY: flutter run --dart-define=DIWALI_PREVIEW=true
class DiwaliGreetingGate extends StatefulWidget {
  const DiwaliGreetingGate({super.key, required this.child});

  final Widget child;

  @override
  State<DiwaliGreetingGate> createState() => _DiwaliGreetingGateState();
}

class _DiwaliGreetingGateState extends State<DiwaliGreetingGate>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const String _seenKey = 'profit_from_it_diwali_2026_seen_v2';
  static const bool _previewFlag = bool.fromEnvironment('DIWALI_PREVIEW');
  static const int _firstDay = 20261105;
  static const int _lastDay = 20261113;

  bool get _preview => kDebugMode && _previewFlag;

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  late final AnimationController _showtime = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6650),
  )..addStatusListener(_onShowtimeStatus);

  Timer? _openTimer;
  Timer? _midnightTimer;
  int _requestToken = 0;
  bool _isOpen = false;
  bool _launched = false;

  static DateTime _nowInIst() {
    // UTC+05:30 is fixed year-round; no DST in India.
    return DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  }

  static bool _isInCampaignWindow() {
    final ist = _nowInIst();
    final date = ist.year * 10000 + ist.month * 100 + ist.day;
    return date >= _firstDay && date <= _lastDay;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightReview();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleOpening();
    });
  }

  void _scheduleMidnightReview() {
    _midnightTimer?.cancel();
    if (_preview) return;
    final ist = _nowInIst();
    final nextMidnight = DateTime.utc(ist.year, ist.month, ist.day + 1);
    final remaining = nextMidnight.difference(ist);
    _midnightTimer = Timer(remaining + const Duration(seconds: 1), () {
      if (!mounted) return;
      if (!_isInCampaignWindow() && _isOpen) _dismiss(markSeen: false);
      _scheduleOpening();
      _scheduleMidnightReview();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!_preview && !_isInCampaignWindow() && _isOpen) {
      _dismiss(markSeen: false);
    }
    _scheduleOpening();
    _scheduleMidnightReview();
  }

  void _scheduleOpening() {
    _openTimer?.cancel();
    final token = ++_requestToken;
    if (!_preview && !_isInCampaignWindow()) return;
    if (_isOpen) return;

    // Let Login/Dashboard, their theme, and first frame settle first.
    _openTimer = Timer(const Duration(milliseconds: 850), () async {
      if (!mounted || _isOpen || token != _requestToken) return;
      if (!_preview && !_isInCampaignWindow()) return;
      if (!_preview) {
        try {
          final prefs = await SharedPreferences.getInstance();
          if (prefs.getBool(_seenKey) ?? false) return;
        } catch (error) {
          debugPrint('Diwali greeting: preferences unavailable ($error)');
        }
      }
      if (!mounted || _isOpen || token != _requestToken) return;
      if (!_preview && !_isInCampaignWindow()) return;
      setState(() {
        _isOpen = true;
        _launched = false;
      });
      _ambient.repeat();
      _setSystemBars(light: true);
    });
  }

  static void _setSystemBars({required bool light}) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: light ? Brightness.light : Brightness.dark,
        statusBarBrightness: light ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: light
            ? const Color(0xFF0A1022)
            : const Color(0xFF000000),
        systemNavigationBarIconBrightness:
            light ? Brightness.light : Brightness.dark,
      ),
    );
  }

  Future<void> _rememberDismissal() async {
    if (_preview) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seenKey, true);
    } catch (error) {
      debugPrint('Diwali greeting: unable to save dismissal ($error)');
    }
  }

  void _launch() {
    if (!_isOpen || _launched) return;
    setState(() => _launched = true);
    unawaited(_rememberDismissal());
    _showtime.forward(from: 0);
  }

  void _onShowtimeStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _dismiss(markSeen: true);
  }

  void _dismiss({required bool markSeen}) {
    if (!_isOpen) return;
    if (markSeen) unawaited(_rememberDismissal());
    ++_requestToken;
    _openTimer?.cancel();
    _ambient.stop();
    _showtime.stop();
    _setSystemBars(light: false);
    if (!mounted) return;
    setState(() {
      _isOpen = false;
      _launched = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ++_requestToken;
    _openTimer?.cancel();
    _midnightTimer?.cancel();
    if (_isOpen) _setSystemBars(light: false);
    _ambient.dispose();
    _showtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Prevent Android back-press from navigating away behind the modal.
    return PopScope(
      canPop: !_isOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isOpen) _dismiss(markSeen: true);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_isOpen) Positioned.fill(child: _festivalOverlay()),
        ],
      ),
    );
  }

  Widget _festivalOverlay() {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -.30),
                radius: 1.18,
                stops: [0, .60, 1],
                colors: [
                  Color(0xFF34253F),
                  Color(0xFF161B34),
                  Color(0xFF090E21),
                ],
              ),
            ),
          ),
          // Animated starfield + ambient fireworks + rocket/bloom particles.
          AnimatedBuilder(
            animation: Listenable.merge([_ambient, _showtime]),
            builder: (context, child) => RepaintBoundary(
              child: CustomPaint(
                painter: _DiwaliFireworksPainter(
                  ambientTime: _ambient.value * 12,
                  launchTime: _showtime.value * 6.65,
                  launching: _launched,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          // Gentle vignette, transparent in the center.
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.15,
                  colors: [Colors.transparent, const Color(0x9B030718)],
                  stops: const [.48, 1],
                ),
              ),
            ),
          ),
          IgnorePointer(
            ignoring: _launched,
            child: AnimatedOpacity(
              opacity: _launched ? 0 : 1,
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              child: AnimatedScale(
                scale: _launched ? .94 : 1,
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                child: _festivalCard(),
              ),
            ),
          ),
          if (_launched)
            AnimatedBuilder(
              animation: _showtime,
              builder: (context, child) {
                final t = _showtime.value * 6.65;
                final fadeIn = ((t - 2.15) / .72).clamp(0.0, 1.0);
                final fadeOut = ((6.55 - t) / .45).clamp(0.0, 1.0);
                return IgnorePointer(
                  child: Opacity(
                    opacity: math.min(fadeIn, fadeOut),
                    child: Transform.scale(
                      scale: .92 + fadeIn * .08,
                      child: child,
                    ),
                  ),
                );
              },
              child: _finalGreeting(),
            ),
        ],
      ),
    );
  }

  Widget _festivalCard() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 670;
          final narrow = constraints.maxWidth < 360;
          final horizontalPadding = narrow ? 20.0 : 27.0;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 490),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0x66EAC18D), width: 1),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF37273E),
                          Color(0xFF1D2038),
                          Color(0xFF251D32),
                        ],
                        stops: [0, .52, 1],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x9A000000),
                          blurRadius: 64,
                          spreadRadius: 3,
                          offset: Offset(0, 22),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Padding(
                              padding: const EdgeInsets.all(9),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(19),
                                  border: Border.all(color: const Color(0x25EEC68C)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            compact ? 18 : 26,
                            horizontalPadding,
                            compact ? 16 : 24,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const _GoldLine(width: 16),
                                    const SizedBox(width: 10),
                                    const Flexible(
                                      child: Text(
                                        'THE FESTIVAL OF LIGHTS',
                                        maxLines: 1,
                                        overflow: TextOverflow.fade,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 8,
                                          letterSpacing: 1.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFE9C494),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const _GoldLine(width: 16),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                              AnimatedBuilder(
                                animation: _ambient,
                                builder: (context, child) => Transform.translate(
                                  offset: Offset(0, -2.8 * math.sin(_ambient.value * math.pi * 2)),
                                  child: child,
                                ),
                                child: SizedBox(
                                  width: 200,
                                  height: compact ? 117 : 141,
                                  child: CustomPaint(
                                    painter: const _DiwaliDiyaPainter(),
                                  ),
                                ),
                              ),
                              SizedBox(height: compact ? 0 : 5),
                              const Text(
                                'A SEASON OF NEW BEGINNINGS',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 9,
                                  letterSpacing: 1.9,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFDAAF81),
                                ),
                              ),
                              const SizedBox(height: 7),
                              const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Happy ',
                                        style: TextStyle(color: Color(0xFFFFF7E8)),
                                      ),
                                      TextSpan(
                                        text: 'Diwali',
                                        style: TextStyle(
                                          color: Color(0xFFF7C77F),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: 'serif',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 52,
                                    height: 1.15,
                                    letterSpacing: -2.1,
                                  ),
                                ),
                              ),
                              SizedBox(height: compact ? 6 : 11),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _GoldLine(width: 44),
                                  SizedBox(width: 10),
                                  Icon(Icons.auto_awesome_rounded,
                                      size: 12, color: Color(0xFFEBC58D)),
                                  SizedBox(width: 10),
                                  _GoldLine(width: 44),
                                ],
                              ),
                              SizedBox(height: compact ? 8 : 13),
                              const Text(
                                'Wishing you and your family a Diwali filled with light, happiness, and prosperity.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFEAD7C8),
                                  fontSize: 13.2,
                                  height: 1.65,
                                ),
                              ),
                              SizedBox(height: compact ? 10 : 14),
                              const Text.rich(
                                TextSpan(children: [
                                  TextSpan(
                                    text: 'With warm wishes from ',
                                    style: TextStyle(color: Color(0xFFBBA9AC)),
                                  ),
                                  TextSpan(
                                    text: 'Profit From It',
                                    style: TextStyle(
                                      color: Color(0xFFF5D39F),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ]),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11.5, height: 1.5),
                              ),
                              SizedBox(height: compact ? 16 : 23),
                              _launchButton(),
                              const SizedBox(height: 12),
                              const Text(
                                'A little celebration awaits.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xA8CBB8AE),
                                  fontSize: 10,
                                  letterSpacing: .3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 13,
                          child: Semantics(
                            button: true,
                            label: 'Close Diwali greeting',
                            child: Material(
                              color: const Color(0x1AFFFFFF),
                              shape: CircleBorder(
                                side: BorderSide(color: const Color(0x28FFFFFF)),
                              ),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => _dismiss(markSeen: true),
                                child: const SizedBox(
                                  width: 34,
                                  height: 34,
                                  child: Icon(Icons.close_rounded,
                                      color: Color(0xFFECDAC6), size: 20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _launchButton() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 325),
      child: Semantics(
        button: true,
        label: 'Light up the sky and launch Diwali fireworks',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _launch,
            borderRadius: BorderRadius.circular(13),
            child: Ink(
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFFFE6AD), width: 1.3),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [0, .43, .82, 1],
                  colors: [
                    Color(0xFFDB9E50),
                    Color(0xFFFFECAF),
                    Color(0xFFF1BE75),
                    Color(0xFFDF9F57),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x65E4AA62), blurRadius: 22, offset: Offset(0, 8)),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rocket_launch_outlined, color: Color(0xFF49301E), size: 19),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'LIGHT UP THE SKY',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF42291E),
                        fontWeight: FontWeight.w900,
                        fontSize: 10.5,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(width: 13),
                  Icon(Icons.north_east_rounded, color: Color(0xFF49301E), size: 19),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _finalGreeting() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFFFDDA0), size: 27),
              const SizedBox(height: 16),
              const Text(
                'WITH LOVE & LIGHT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 3,
                  color: Color(0xFFFFD99D),
                ),
              ),
              const SizedBox(height: 11),
              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'Happy ', style: TextStyle(color: Color(0xFFFFF7E8))),
                    TextSpan(
                      text: 'Diwali',
                      style: TextStyle(color: Color(0xFFF7C77F), fontStyle: FontStyle.italic),
                    ),
                  ]),
                  style: TextStyle(fontFamily: 'serif', fontSize: 70, letterSpacing: -3),
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'To you and your family',
                style: TextStyle(
                  color: Color(0xFFFFE9C8),
                  fontFamily: 'serif',
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 29),
              const Text(
                'PROFIT FROM IT',
                style: TextStyle(
                  color: Color(0xFFF4C78A),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldLine extends StatelessWidget {
  const _GoldLine({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: 1, color: const Color(0x8CDDAD79));
  }
}

/// Hand-painted diya, traced to match the website's SVG: layered golden flame,
/// metallic copper bowl, soft halo, and fine golden decorative strokes.
class _DiwaliDiyaPainter extends CustomPainter {
  const _DiwaliDiyaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate((size.width - 200) / 2, 0);
    canvas.scale(200 / 220, size.height / 170);

    final halo = const Offset(110, 89);
    canvas.drawCircle(
      halo,
      80,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x50FFD59B), Color(0x1CD37E56), Color(0x00D37E56)],
          stops: [0, .43, 1],
        ).createShader(Rect.fromCircle(center: halo, radius: 80)),
    );
    canvas.drawOval(
      const Rect.fromLTWH(43, 134, 134, 18),
      Paint()..color = const Color(0x26EBAF70),
    );
    final flame = Path()
      ..moveTo(111, 30)
      ..cubicTo(91, 57, 97, 70, 110, 88)
      ..cubicTo(127, 72, 129, 53, 111, 30)
      ..close();
    canvas.drawPath(
      flame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFCE7), Color(0xFFFFE09A), Color(0xFFFA9E50)],
        ).createShader(const Rect.fromLTWH(91, 30, 38, 60)),
    );
    final innerFlame = Path()
      ..moveTo(111, 50)
      ..cubicTo(102, 67, 105, 74, 111, 81)
      ..cubicTo(119, 71, 118, 61, 111, 50)
      ..close();
    canvas.drawPath(innerFlame, Paint()..color = const Color(0xFFFFF8D6));

    final bowl = Path()
      ..moveTo(46, 113)
      ..cubicTo(67, 141, 151, 141, 174, 113)
      ..cubicTo(162, 145, 148, 152, 110, 154)
      ..cubicTo(70, 152, 57, 145, 46, 113)
      ..close();
    canvas.drawPath(
      bowl,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF8C432F), Color(0xFFDB9753), Color(0xFFF0BF78), Color(0xFF7D342C)],
          stops: [0, .43, .68, 1],
        ).createShader(const Rect.fromLTWH(46, 113, 128, 42)),
    );
    canvas.drawPath(
      bowl,
      Paint()
        ..color = const Color(0xFFF9D395)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final rim = Path()
      ..moveTo(44, 113)
      ..cubicTo(66, 101, 153, 101, 176, 113)
      ..cubicTo(155, 123, 66, 124, 44, 113)
      ..close();
    canvas.drawPath(rim, Paint()..color = const Color(0xFFC47D48));
    canvas.drawPath(
      rim,
      Paint()
        ..color = const Color(0xFFFFD79A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final highlight = Path()
      ..moveTo(70, 130)
      ..cubicTo(92, 139, 127, 141, 153, 131);
    canvas.drawPath(
      highlight,
      Paint()
        ..color = const Color(0x88FDE2AC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    final rayPaint = Paint()
      ..color = const Color(0xBFFFDE94)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const raySegments = <(Offset, Offset)>[
      (Offset(110, 19), Offset(110, 9)),
      (Offset(77, 32), Offset(68, 22)),
      (Offset(143, 32), Offset(152, 22)),
      (Offset(64, 66), Offset(52, 63)),
      (Offset(156, 66), Offset(168, 63)),
    ];
    for (final segment in raySegments) {
      canvas.drawLine(segment.$1, segment.$2, rayPaint);
    }
    for (final point in <Offset>[
      const Offset(110, 15),
      const Offset(58, 42),
      const Offset(162, 42),
    ]) {
      canvas.drawCircle(point, 2, Paint()..color = const Color(0xFFFFDFA4));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DiwaliDiyaPainter oldDelegate) => false;
}

class _DiwaliFireworksPainter extends CustomPainter {
  const _DiwaliFireworksPainter({
    required this.ambientTime,
    required this.launchTime,
    required this.launching,
  });

  final double ambientTime;
  final double launchTime;
  final bool launching;

  static double _hash(int n) {
    final raw = math.sin(n * 127.1 + 74.7) * 43758.5453;
    return raw - raw.floor();
  }

  static double _ease(double x) =>
      1 - math.pow(1 - x.clamp(0.0, 1.0), 3).toDouble();

  static const List<List<Color>> _palettes = <List<Color>>[
    [Color(0xFFFFF4C6), Color(0xFFF3C978), Color(0xFFD99766)],
    [Color(0xFFFFF7DA), Color(0xFFF6B5B0), Color(0xFFD985B9)],
    [Color(0xFFE6FFFF), Color(0xFF88D3CE), Color(0xFFC5A6F4)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Do not tint the card. All fireworks are painted only behind it.
    for (int i = 0; i < 54; i++) {
      final position = Offset(_hash(i + 12) * size.width, _hash(i + 222) * size.height);
      final flicker = .17 +
          (.5 + .5 * math.sin(ambientTime * (1 + _hash(i + 50)) + i)) * .41;
      canvas.drawCircle(
        position,
        .5 + _hash(i + 99) * 1.3,
        Paint()..color = const Color(0xFFFFDCA3).withValues(alpha: flicker),
      );
    }
    _burst(canvas, Offset(size.width * .13, size.height * .24), 50,
        (ambientTime + 3.4) % 5.2, 2.25, 0, .28, 42);
    _burst(canvas, Offset(size.width * .86, size.height * .36), 61,
        (ambientTime + .8) % 5.2, 2.25, 1, .29, 48);

    if (!launching) return;
    final top = math.max(size.height * .25, 104.0);
    if (launchTime < 1.89) _rocket(canvas, size, launchTime, top);
    if (launchTime >= 1.72) {
      _burst(canvas, Offset(size.width * .5, top),
          math.min(math.min(size.width * .44, size.height * .29), 275),
          launchTime - 1.72, 3.5, 0, 1, 150);
    }
    if (launchTime >= 2.22) {
      _burst(canvas, Offset(size.width * .27, size.height * .27),
          math.min(size.width * .27, 150), launchTime - 2.22, 2.7, 1, .91, 95);
    }
    if (launchTime >= 2.58) {
      _burst(canvas, Offset(size.width * .74, size.height * .22),
          math.min(size.width * .27, 150), launchTime - 2.58, 2.7, 2, .92, 95);
    }
    if (launchTime >= 3.17) {
      _burst(canvas, Offset(size.width * .5, size.height * .16),
          math.min(size.width * .18, 95), launchTime - 3.17, 2.15, 0, .8, 80);
    }
  }

  void _burst(Canvas canvas, Offset center, double maxRadius,
      double age, double duration, int paletteId, double opacity, int count) {
    if (age < 0 || age > duration) return;
    final progress = (age / duration).clamp(0.0, 1.0);
    final radius = maxRadius * _ease(progress);
    final fade = opacity * math.pow(1 - progress, .7).toDouble();
    final shades = _palettes[paletteId % _palettes.length];
    _glow(canvas, center, 40 * (1 - progress) + 10,
        const Color(0xFFFFDDA1), fade * .29);
    for (int i = 0; i < count; i++) {
      final theta = i / count * math.pi * 2 + _hash(i + 21) * .07;
      final direction = Offset(math.cos(theta), math.sin(theta));
      final travel = radius * (.77 + _hash(i * 11 + 18) * .37);
      final pos = center + direction * travel + Offset(0, 16 * progress * progress);
      final tail = (4 + _hash(i * 7) * 9) * (1 - progress);
      final particleOpacity =
          (fade * (.5 + _hash(i + 300) * .5)).clamp(0.0, 1.0);
      canvas.drawLine(
        pos - direction * tail,
        pos,
        Paint()
          ..color = shades[i % shades.length].withValues(alpha: particleOpacity)
          ..strokeWidth = i % 6 == 0 ? 2 : 1,
      );
      if (i % 5 == 0) {
        canvas.drawCircle(
          pos,
          1.9 * (1 - progress) + .25,
          Paint()..color = const Color(0xFFFFFBE3).withValues(alpha: fade.clamp(0.0, 1.0)),
        );
      }
    }
  }

  void _rocket(Canvas canvas, Size size, double seconds, double top) {
    final progress = (seconds / 1.82).clamp(0.0, 1.0);
    for (int i = 26; i >= 1; i--) {
      final earlier = math.max(0.0, progress - i * .008);
      if (earlier == 0 && progress < i * .008) continue;
      final point = _rocketPosition(size, earlier, top);
      final alpha = (1 - i / 27) * math.min(seconds * 2.3, 1);
      canvas.drawCircle(
        point,
        .6 + alpha * (2.1 + _hash(i) * 1.5),
        Paint()
          ..color = (i % 5 == 0 ? const Color(0xFFFFF6CB) : const Color(0xFFFFAA54))
              .withValues(alpha: alpha.clamp(0.0, 1.0)),
      );
    }
    final point = _rocketPosition(size, progress, top);
    _glow(canvas, point, 52, const Color(0xFFFFD380), .52);
    _glow(canvas, point, 21, const Color(0xFFFFF7DA), .72);
    canvas.drawCircle(point, 4.1, Paint()..color = const Color(0xFFFFFCE7));
  }

  Offset _rocketPosition(Size size, double progress, double top) {
    final eased = _ease(progress);
    return Offset(
      size.width * .5 + math.sin(progress * math.pi * 1.5) * math.min(size.width * .045, 17),
      size.height * .94 - (size.height * .94 - top) * eased,
    );
  }

  void _glow(Canvas canvas, Offset center, double radius, Color color, double opacity) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity.clamp(0.0, 1.0)),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _DiwaliFireworksPainter oldDelegate) {
    return ambientTime != oldDelegate.ambientTime ||
        launchTime != oldDelegate.launchTime ||
        launching != oldDelegate.launching;
  }
}
