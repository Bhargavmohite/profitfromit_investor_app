import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:profit_from_it_investors/provider/app_update_provider/app_update_provider.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';

class AppUpdatePrompt {
  const AppUpdatePrompt._();

  /// Optional update:
  /// - user can choose "Maybe Later"
  /// - user can choose "Update Now"
  static Future<void> showOptional(BuildContext context) async {
    final provider = context.read<AppUpdateProvider>();
    final ui = provider.uiConfig;
    final config = provider.currentPlatformConfig;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 390),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .12),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _UpdateIcon(mandatory: false),
                const SizedBox(height: 16),

                Text(
                  ui?.optionalTitle ?? 'New Update Available',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  ui?.optionalMessage ??
                      'A newer version of the app is available.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    height: 1.55,
                    color: AppColor.textSecondary,
                  ),
                ),

                const SizedBox(height: 18),

                _VersionComparisonCard(
                  installedVersion: provider.installedVersion,
                  installedBuild: provider.installedBuild,
                  latestVersion: config?.latestVersion ?? '-',
                  latestBuild: config?.latestBuild ?? 0,
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final opened = await provider.openStore();

                      if (!dialogContext.mounted) {
                        return;
                      }

                      if (!opened) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.lastError ??
                                  'Unable to open the app store.',
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      ui?.updateButton ?? 'Update Now',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Mandatory update:
  /// Pushes a full-screen blocking page.
  ///
  /// There is intentionally:
  /// - no Cancel button
  /// - no "Later" button
  /// - no back navigation
  ///
  /// The only action is Update Now.
  static Future<void> showMandatory(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AppUpdateRequiredScreen()),
    );
  }
}

class AppUpdateRequiredScreen extends StatelessWidget {
  const AppUpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppUpdateProvider>();

    final ui = provider.uiConfig;
    final config = provider.currentPlatformConfig;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColor.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 430),
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFE7ECF3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .07),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _UpdateIcon(mandatory: true),

                    const SizedBox(height: 20),

                    Text(
                      ui?.mandatoryTitle ?? 'Update Required',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Text(
                      ui?.mandatoryMessage ??
                          'A new version is available. Please update to continue using the app.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.6,
                        color: AppColor.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 22),

                    _VersionComparisonCard(
                      installedVersion: provider.installedVersion,
                      installedBuild: provider.installedBuild,
                      latestVersion: config?.latestVersion ?? '-',
                      latestBuild: config?.latestBuild ?? 0,
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final opened = await provider.openStore();

                          if (!context.mounted) {
                            return;
                          }

                          if (!opened) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.lastError ??
                                      'Unable to open the app store.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.system_update_alt_rounded,
                          size: 19,
                        ),
                        label: Text(
                          ui?.updateButton ?? 'Update Now',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      'Please install the latest version to continue.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w400,
                        color: AppColor.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateIcon extends StatelessWidget {
  final bool mandatory;

  const _UpdateIcon({required this.mandatory});

  @override
  Widget build(BuildContext context) {
    final background = mandatory
        ? AppColor.warning.withValues(alpha: .10)
        : AppColor.primary.withValues(alpha: .08);

    final foreground = mandatory ? AppColor.warning : AppColor.primary;

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: foreground.withValues(alpha: .10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          mandatory ? Icons.system_update_rounded : Icons.auto_awesome_rounded,
          size: 27,
          color: foreground,
        ),
      ),
    );
  }
}

class _VersionComparisonCard extends StatelessWidget {
  final String installedVersion;
  final int installedBuild;
  final String latestVersion;
  final int latestBuild;

  const _VersionComparisonCard({
    required this.installedVersion,
    required this.installedBuild,
    required this.latestVersion,
    required this.latestBuild,
  });

  @override
  Widget build(BuildContext context) {
    final currentText = installedBuild > 0
        ? '$installedVersion  ($installedBuild)'
        : installedVersion;

    final latestText = latestBuild > 0
        ? '$latestVersion  ($latestBuild)'
        : latestVersion;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Column(
        children: [
          _VersionRow(label: 'Current Version', value: currentText),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 9),
            child: Divider(height: 1, color: Color(0xFFE7ECF3)),
          ),
          _VersionRow(
            label: 'Latest Version',
            value: latestText,
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _VersionRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              color: AppColor.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: highlight ? AppColor.primary : AppColor.textPrimary,
          ),
        ),
      ],
    );
  }
}
