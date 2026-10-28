import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:profit_from_it_investors/model/whats_new_response.dart';
import 'package:profit_from_it_investors/network/whats_new_service.dart';
import 'package:profit_from_it_investors/ui/authentication/login_screen/login_screen.dart';
import 'package:profit_from_it_investors/ui/dashboard_screen/dashboard_screen.dart';
import 'package:profit_from_it_investors/ui/notifications/notifications_screen.dart';
import 'package:profit_from_it_investors/ui/support_messages/support_messages_screen.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';

class WhatsNewScreen extends StatefulWidget {
  final WhatsNewRelease release;
  final String currentVersion;
  final String currentBuild;
  final bool isLoggedIn;
  final bool manualMode;

  const WhatsNewScreen({
    super.key,
    required this.release,
    required this.currentVersion,
    required this.currentBuild,
    required this.isLoggedIn,
    this.manualMode = false,
  });

  @override
  State<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends State<WhatsNewScreen>
    with WidgetsBindingObserver {
  bool _isContinuing = false;
  bool _isRefreshing = false;
  Timer? _refreshTimer;
  late WhatsNewRelease _release;

  @override
  void initState() {
    super.initState();

    _release = widget.release;
    WidgetsBinding.instance.addObserver(this);

    // Pull fresh backend content immediately, then keep checking while this
    // page remains visible. No app rebuild/restart is required.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFromBackend();
    });

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshFromBackend(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshFromBackend();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refreshFromBackend() async {
    if (_isRefreshing || _isContinuing || !mounted) return;

    _isRefreshing = true;

    try {
      final latest = await WhatsNewService.fetchLatestRelease(
        version: widget.currentVersion,
        build: widget.currentBuild,
      );

      if (!mounted || latest == null) return;

      // If the backend disables this release while the page is already open,
      // immediately mark the current app build as handled and leave What's New.
      if (!latest.enabled && !widget.manualMode) {
        debugPrint(
          '[WHATS NEW] Backend release disabled. Closing What\'s New.',
        );

        await WhatsNewService.markCompleted(
          version: widget.currentVersion,
          build: widget.currentBuild,
        );

        if (!mounted) return;

        _refreshTimer?.cancel();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => widget.isLoggedIn
                ? const DashboardScreen()
                : const LoginScreen(),
          ),
          (route) => false,
        );
        return;
      }

      if (_releaseChanged(_release, latest)) {
        setState(() {
          _release = latest;
        });

        debugPrint('[WHATS NEW] UI refreshed from backend changes.');
      }
    } finally {
      _isRefreshing = false;
    }
  }

  bool _releaseChanged(WhatsNewRelease current, WhatsNewRelease latest) {
    if (current.enabled != latest.enabled ||
        current.version != latest.version ||
        current.items.length != latest.items.length) {
      return true;
    }

    for (int i = 0; i < current.items.length; i++) {
      final a = current.items[i];
      final b = latest.items[i];

      if (a.tag != b.tag ||
          a.title != b.title ||
          a.para != b.para ||
          a.video != b.video ||
          a.explorePath != b.explorePath) {
        return true;
      }
    }

    return false;
  }

  Future<void> _continueToApp() async {
    if (_isContinuing) return;

    if (widget.manualMode) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isContinuing = true;
    });

    await WhatsNewService.markCompleted(
      version: widget.currentVersion,
      build: widget.currentBuild,
    );

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            widget.isLoggedIn ? const DashboardScreen() : const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _openExplorePath(String rawPath) async {
    final path = rawPath.trim();

    if (path.isEmpty) return;

    // Full web URL supplied by backend.
    if (path.startsWith('https://') || path.startsWith('http://')) {
      final uri = Uri.tryParse(path);

      if (uri == null) {
        _showUnknownPath(path);
        return;
      }

      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && mounted) {
        _showUnknownPath(path);
      }

      return;
    }

    // Protected app screens should only be opened for logged-in users.
    if (!widget.isLoggedIn) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in first to explore this feature.'),
        ),
      );
      return;
    }

    Widget? destination;

    switch (path.toLowerCase()) {
      case 'support_messages':
      case '/support-messages':
      case 'support-messages':
        destination = const SupportMessagesScreen();
        break;

      case 'notifications':
      case '/notifications':
        destination = const NotificationsScreen();
        break;

      case 'dashboard':
      case '/dashboard':
      case 'home':
      case '/home':
        destination = const DashboardScreen();
        break;
    }

    if (destination == null) {
      _showUnknownPath(path);
      return;
    }

    if (!mounted) return;

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => destination!));
  }

  void _showUnknownPath(String path) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('This feature path is not available yet: $path')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final updates = _release.items;

    return PopScope(
      canPop: widget.manualMode,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
                  children: [
                    _HeaderCard(versionLabel: widget.currentVersion),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'What’s new',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            '${updates.length} ${updates.length == 1 ? 'highlight' : 'highlights'}',
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColor.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A quick look at the latest improvements.',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: AppColor.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (int index = 0; index < updates.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _UpdateCard(
                          item: updates[index],
                          style: _CardStyle.forIndex(index),
                          onExplore: updates[index].explorePath.isEmpty
                              ? null
                              : () => _openExplorePath(
                                  updates[index].explorePath,
                                ),
                        ),
                      ),
                  ],
                ),
              ),
              _ContinueBar(
                isLoading: _isContinuing,
                onContinue: _continueToApp,
                buttonText: widget.manualMode
                    ? 'Back to App'
                    : 'Continue to App',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String versionLabel;

  const _HeaderCard({required this.versionLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B2DAA), Color(0xFF1649D8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D3CCF).withValues(alpha: .18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -45,
            child: Container(
              width: 135,
              height: 135,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .07),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'NEW UPDATE',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'v$versionLabel',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: .78),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'What’s New',
                style: GoogleFonts.poppins(
                  fontSize: 29,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A smarter investor experience',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: .88),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Explore the latest features and improvements',
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: .88),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  final WhatsNewItemData item;
  final _CardStyle style;
  final VoidCallback? onExplore;

  const _UpdateCard({
    required this.item,
    required this.style,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    final vimeoId = _extractVimeoId(item.video);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EBF2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: .035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: style.soft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(style.icon, color: style.accent, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.tag.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: style.soft,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      item.tag.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        letterSpacing: .45,
                        fontWeight: FontWeight.w800,
                        color: style.accent,
                      ),
                    ),
                  ),
                if (item.tag.isNotEmpty) const SizedBox(height: 7),
                Text(
                  item.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.para,
                  style: GoogleFonts.poppins(
                    fontSize: 10.6,
                    height: 1.6,
                    color: AppColor.textSecondary,
                  ),
                ),
                if (vimeoId != null) ...[
                  const SizedBox(height: 14),
                  _VimeoEmbedPlayer(
                    videoId: vimeoId,
                    accent: style.accent,
                    title: item.title,
                  ),
                ],
                if (onExplore != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: onExplore,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: style.soft,
                        foregroundColor: style.accent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Explore',
                        style: GoogleFonts.poppins(
                          fontSize: 9.7,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String? _extractVimeoId(String value) {
    final input = value.trim();

    if (input.isEmpty) return null;

    if (RegExp(r'^\d+$').hasMatch(input)) {
      return input;
    }

    final uri = Uri.tryParse(input);
    if (uri == null) return null;

    for (final segment in uri.pathSegments.reversed) {
      if (RegExp(r'^\d+$').hasMatch(segment)) {
        return segment;
      }
    }

    return null;
  }
}

class _VimeoEmbedPlayer extends StatefulWidget {
  final String videoId;
  final Color accent;
  final String title;

  const _VimeoEmbedPlayer({
    required this.videoId,
    required this.accent,
    required this.title,
  });

  @override
  State<_VimeoEmbedPlayer> createState() => _VimeoEmbedPlayerState();
}

class _VimeoEmbedPlayerState extends State<_VimeoEmbedPlayer> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    final playerUrl = Uri.parse(
      'https://player.vimeo.com/video/${widget.videoId}'
      '?title=0&byline=0&portrait=0&dnt=1&playsinline=1',
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) return;

            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
        ),
      )
      ..loadRequest(playerUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (_hasError)
                  ColoredBox(
                    color: const Color(0xFF0F172A),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _hasError = false;
                          });
                          _controller.reload();
                        },
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Retry video',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    size: 18,
                    color: widget.accent,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Watch ${widget.title}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 9.8,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onContinue;
  final String buttonText;

  const _ContinueBar({
    required this.isLoading,
    required this.onContinue,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE6EBF2))),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: .05),
            blurRadius: 16,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isLoading ? null : onContinue,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CardStyle {
  final Color accent;
  final Color soft;
  final IconData icon;

  const _CardStyle({
    required this.accent,
    required this.soft,
    required this.icon,
  });

  static _CardStyle forIndex(int index) {
    const styles = [
      _CardStyle(
        accent: Color(0xFF2563EB),
        soft: Color(0xFFEFF6FF),
        icon: Icons.forum_rounded,
      ),
      _CardStyle(
        accent: Color(0xFF7C3AED),
        soft: Color(0xFFF5F3FF),
        icon: Icons.notifications_active_rounded,
      ),
      _CardStyle(
        accent: Color(0xFFEA580C),
        soft: Color(0xFFFFF7ED),
        icon: Icons.auto_awesome_rounded,
      ),
      _CardStyle(
        accent: Color(0xFF059669),
        soft: Color(0xFFECFDF5),
        icon: Icons.trending_up_rounded,
      ),
    ];

    return styles[index % styles.length];
  }
}
