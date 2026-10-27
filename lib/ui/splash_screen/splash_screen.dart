// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/provider/authentication/user_provider.dart';
import 'package:profit_from_it_investors/network/whats_new_service.dart';
import 'package:profit_from_it_investors/provider/app_update_provider/app_update_provider.dart';
import 'package:profit_from_it_investors/ui/app_update/app_update_prompt.dart';
import 'package:profit_from_it_investors/ui/authentication/login_screen/login_screen.dart';
import 'package:profit_from_it_investors/ui/dashboard_screen/dashboard_screen.dart';
import 'package:profit_from_it_investors/ui/whats_new/whats_new_screen.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:profit_from_it_investors/utility/app_images.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/local_storage.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    _navigateUser();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Column(
            children: [
              const Spacer(flex: 2),

              Container(
                alignment: Alignment.topCenter,
                decoration: const BoxDecoration(color: Colors.white),
                child: Image.asset(
                  AppImages.newLogo,
                  fit: BoxFit.fitWidth,
                  width: 220,
                ),
              ),

              const Spacer(flex: 2),

              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      'Smart Investments',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    Text(
                      'Better Tomorrow',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColor.primary,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final appUpdateProvider = Provider.of<AppUpdateProvider>(
      context,
      listen: false,
    );

    final accessToken = await LocalStorage.getAccessToken();
    final userId = await LocalStorage.getId();

    // Keep startup responsive while checking mandatory/optional updates.
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 800)),
      appUpdateProvider.checkForUpdate().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      ),
    ]);

    if (!mounted) return;

    // ---------------------------------------------------------------
    // Mandatory update
    // ---------------------------------------------------------------
    if (appUpdateProvider.isMandatoryUpdate) {
      nextRoute(
        MaterialPageRoute(
          builder: (context) => const AppUpdateRequiredScreen(),
        ),
        isClearBackRoutes: true,
      );
      return;
    }

    // ---------------------------------------------------------------
    // Optional update
    // ---------------------------------------------------------------
    if (appUpdateProvider.isOptionalUpdate) {
      await AppUpdatePrompt.showOptional(context);
      return;
    }

    final isVerifiedLogin = accessToken.isNotEmpty && userId.isNotEmpty;

    // ---------------------------------------------------------------
    // What's New
    // ---------------------------------------------------------------
    // First install: does not show.
    // App version/build changed: fetch backend release and show once.
    // API unavailable: continue normally and retry on a later launch.
    final whatsNewDecision = await WhatsNewService.checkAfterAppUpdate();

    if (!mounted) return;

    if (whatsNewDecision.shouldShow && whatsNewDecision.release != null) {
      nextRoute(
        MaterialPageRoute(
          builder: (context) => WhatsNewScreen(
            release: whatsNewDecision.release!,
            currentVersion: whatsNewDecision.currentVersion,
            currentBuild: whatsNewDecision.currentBuild,
            isLoggedIn: isVerifiedLogin,
          ),
        ),
        isClearBackRoutes: true,
      );
      return;
    }

    // ---------------------------------------------------------------
    // Normal authentication flow
    // ---------------------------------------------------------------
    if (isVerifiedLogin) {
      await userProvider.loadUserInfo();

      if (!mounted) return;

      nextRoute(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
        isClearBackRoutes: true,
      );
    } else {
      nextRoute(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        isClearBackRoutes: true,
      );
    }
  }
}
