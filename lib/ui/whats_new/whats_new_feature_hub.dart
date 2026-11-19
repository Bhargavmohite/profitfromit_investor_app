import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:profit_from_it_investors/model/whats_new_response.dart';
import 'package:profit_from_it_investors/network/whats_new_service.dart';
import 'package:profit_from_it_investors/ui/dashboard_screen/dashboard_screen.dart';
import 'package:profit_from_it_investors/ui/whats_new/whats_new_screen.dart';
import 'package:profit_from_it_investors/utility/app_activity_route_aware.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';

/// Shared entry point for the sidebar and the daily video's Know More CTA.
///
/// Feature cards come from the EXISTING app-release notes endpoint; the
/// daily video API controls the announcement and its once-a-day gate only.
/// Reusing this page avoids showing the video when the sidebar is opened.
class WhatsNewFeatureHub extends StatefulWidget {
  const WhatsNewFeatureHub({super.key, this.openedFromStory = false});

  /// The story replaces the splash route. In that case there is no dashboard
  /// underneath this screen, so Back must create a clean dashboard route.
  final bool openedFromStory;

  @override
  State<WhatsNewFeatureHub> createState() => _WhatsNewFeatureHubState();
}

class _WhatsNewFeatureHubState extends State<WhatsNewFeatureHub>
    with AppActivityRouteAware<WhatsNewFeatureHub> {
  @override
  String get activityScreenKey => 'whats_new_features';

  WhatsNewRelease? _release;
  String _version = '';
  String _build = '';
  bool _loading = true;
  bool _closing = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadRelease();
  }

  Future<void> _loadRelease() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
      _release = null;
    });
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      final build = info.buildNumber.trim();
      final release = await WhatsNewService.fetchLatestRelease(
        version: version,
        build: build,
      );
      if (!mounted || _closing) return;
      setState(() {
        _release = release;
        _version = version;
        _build = build;
        _loading = false;
        _loadFailed = release == null;
      });
    } catch (error) {
      debugPrint('[WHATS NEW] Feature hub load failed: $error');
      if (!mounted || _closing) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    if (widget.openedFromStory) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final release = _release;
    if (!_loading && release != null && release.items.isNotEmpty) {
      return WhatsNewScreen(
        release: release,
        currentVersion: _version,
        currentBuild: _build,
        isLoggedIn: true,
        manualMode: true,
        exitToDashboard: widget.openedFromStory,
      );
    }

    return PopScope(
      canPop: !widget.openedFromStory,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.openedFromStory) _close();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Back to dashboard',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _close,
          ),
          title: Text(
            'What’s New',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColor.textPrimary,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: _loading
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColor.primary),
                      SizedBox(height: 18),
                      Text('Loading the latest app improvements…'),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _loadFailed
                              ? Icons.wifi_off_rounded
                              : Icons.auto_awesome_rounded,
                          color: AppColor.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _loadFailed
                            ? 'Could not load feature updates'
                            : 'No feature details available yet',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: AppColor.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _loadFailed
                            ? 'Check your connection and try again.'
                            : 'New feature details will appear here when published for this app version.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: AppColor.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: _loadRelease,
                        icon: const Icon(Icons.refresh_rounded, size: 19),
                        label: const Text('Refresh updates'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _close,
                        child: const Text('Back to Dashboard'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
