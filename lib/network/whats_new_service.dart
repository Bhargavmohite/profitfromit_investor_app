import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:profit_from_it_investors/model/whats_new_response.dart';
import 'package:profit_from_it_investors/network/http_request.dart';
import 'package:profit_from_it_investors/utility/constant.dart';
import 'package:profit_from_it_investors/utility/local_storage.dart';

class WhatsNewDecision {
  final bool shouldShow;
  final String currentVersion;
  final String currentBuild;
  final WhatsNewRelease? release;

  const WhatsNewDecision({
    required this.shouldShow,
    required this.currentVersion,
    required this.currentBuild,
    required this.release,
  });

  String get currentSignature => '$currentVersion+$currentBuild';
}

class WhatsNewService {
  const WhatsNewService._();

  /// Checks whether this installed app build is newer than the build that was
  /// previously completed on this device.
  ///
  /// First install:
  /// - stores the current app signature
  /// - does NOT show What's New
  ///
  /// App update:
  /// - current signature differs from stored signature
  /// - fetches the backend release
  /// - shows What's New only when backend version matches the installed app
  ///
  /// Network/API failure:
  /// - does not mark the new version complete
  /// - retries on a later launch
  static Future<WhatsNewDecision> checkAfterAppUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();

    final currentVersion = packageInfo.version.trim();
    final currentBuild = packageInfo.buildNumber.trim();
    final currentSignature = '$currentVersion+$currentBuild';

    final previousSignature =
        await LocalStorage.getWhatsNewCompletedAppSignature();

    // No What's New signature exists yet.
    // - If there is no existing app state, treat this as a fresh installation
    //   and establish a baseline without showing What's New.
    // - If app state already exists, this is an existing installation receiving
    //   the first release that contains this feature, so continue to the API
    //   check and allow the release notes to be shown once.
    if (previousSignature.isEmpty) {
      final hasExistingAppState =
          await LocalStorage.hasExistingAppStateForWhatsNew();

      if (!hasExistingAppState) {
        await LocalStorage.saveWhatsNewCompletedAppSignature(currentSignature);

        return WhatsNewDecision(
          shouldShow: false,
          currentVersion: currentVersion,
          currentBuild: currentBuild,
          release: null,
        );
      }
    }

    // Same installed build: already handled.
    if (previousSignature == currentSignature) {
      return WhatsNewDecision(
        shouldShow: false,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
        release: null,
      );
    }

    try {
      // Always request the latest controller payload for a new app build.
      // The timestamp prevents an intermediary/proxy from serving stale
      // What's New JSON after WhatsNewAPIController.php is edited.
      final requestUrl =
          '${CMD.whatsNew}?app_version=${Uri.encodeQueryComponent(currentVersion)}'
          '&build=${Uri.encodeQueryComponent(currentBuild)}'
          '&_ts=${DateTime.now().millisecondsSinceEpoch}';

      final response = await httpGet(
        requestUrl,
        headers: const {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      );

      if (response == null || response.statusCode != 200) {
        return WhatsNewDecision(
          shouldShow: false,
          currentVersion: currentVersion,
          currentBuild: currentBuild,
          release: null,
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return WhatsNewDecision(
          shouldShow: false,
          currentVersion: currentVersion,
          currentBuild: currentBuild,
          release: null,
        );
      }

      final parsed = WhatsNewResponse.fromJson(decoded);
      final release = parsed.data;

      debugPrint(
        '[WHATS NEW] API status=${response.statusCode} '
        '| app=$currentVersion+$currentBuild '
        '| apiVersion=${release?.version ?? '-'} '
        '| items=${release?.items.length ?? 0}',
      );

      if (release == null) {
        return WhatsNewDecision(
          shouldShow: false,
          currentVersion: currentVersion,
          currentBuild: currentBuild,
          release: null,
        );
      }

      // Backend intentionally disabled What's New for this exact release.
      if (!release.enabled && release.version == currentVersion) {
        await LocalStorage.saveWhatsNewCompletedAppSignature(currentSignature);

        return WhatsNewDecision(
          shouldShow: false,
          currentVersion: currentVersion,
          currentBuild: currentBuild,
          release: release,
        );
      }

      // Prevent stale release notes from being shown for a newer app.
      if (release.version != currentVersion) {
        debugPrint(
          '[WHATS NEW] App version=$currentVersion, '
          'API version=${release.version}. Waiting for matching release.',
        );

        return WhatsNewDecision(
          shouldShow: false,
          currentVersion: currentVersion,
          currentBuild: currentBuild,
          release: release,
        );
      }

      // Matching release but no cards: nothing to show, so complete the version.
      if (release.items.isEmpty) {
        await LocalStorage.saveWhatsNewCompletedAppSignature(currentSignature);

        return WhatsNewDecision(
          shouldShow: false,
          currentVersion: currentVersion,
          currentBuild: currentBuild,
          release: release,
        );
      }

      return WhatsNewDecision(
        shouldShow: true,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
        release: release,
      );
    } catch (error, stackTrace) {
      debugPrint('[WHATS NEW] Check failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      // Fail open: never block app startup.
      // Do not save the new signature, so we can retry later.
      return WhatsNewDecision(
        shouldShow: false,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
        release: null,
      );
    }
  }

  /// Fetches the latest What's New payload directly from the backend.
  ///
  /// This method intentionally does not check or modify the local
  /// "already seen" app signature. It is used while the What's New screen
  /// is already open so backend content edits can refresh automatically.
  static Future<WhatsNewRelease?> fetchLatestRelease({
    required String version,
    required String build,
  }) async {
    try {
      final requestUrl =
          '${CMD.whatsNew}?app_version=${Uri.encodeQueryComponent(version)}'
          '&build=${Uri.encodeQueryComponent(build)}'
          '&_ts=${DateTime.now().millisecondsSinceEpoch}';

      final response = await httpGet(
        requestUrl,
        headers: const {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      );

      if (response == null || response.statusCode != 200) {
        debugPrint(
          '[WHATS NEW] Auto-refresh failed: status=${response?.statusCode}',
        );
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final parsed = WhatsNewResponse.fromJson(decoded);
      final release = parsed.data;

      if (release == null) return null;

      // Never replace the current screen with release notes for another
      // app version. This protects users from a controller being prepared
      // early for the next Play Store/App Store release.
      if (release.version != version) {
        debugPrint(
          '[WHATS NEW] Auto-refresh ignored: app=$version, '
          'api=${release.version}',
        );
        return null;
      }

      debugPrint(
        '[WHATS NEW] Auto-refresh success: '
        'version=${release.version}, items=${release.items.length}',
      );

      return release;
    } catch (error, stackTrace) {
      debugPrint('[WHATS NEW] Auto-refresh error: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  static Future<void> markCompleted({
    required String version,
    required String build,
  }) async {
    await LocalStorage.saveWhatsNewCompletedAppSignature('$version+$build');
  }
}
