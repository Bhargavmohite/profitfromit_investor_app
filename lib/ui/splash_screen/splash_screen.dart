// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/provider/authentication/user_provider.dart';
import 'package:profit_from_it_investors/ui/authentication/login_screen/login_screen.dart';
import 'package:profit_from_it_investors/ui/dashboard_screen/dashboard_screen.dart';
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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
                child: Image.asset(AppImages.newLogo, fit: BoxFit.fitWidth, width: 220),
              ),

              const Spacer(flex: 2),

              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      'Smart Investments',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                    ),
                    Text(
                      'Better Tomorrow',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColor.primary),
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

    final accessToken = await LocalStorage.getAccessToken();

    final userId = await LocalStorage.getId();

    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // User is considered logged in only after OTP
    // verification has successfully stored BOTH values.
    final isVerifiedLogin = accessToken.isNotEmpty && userId.isNotEmpty;

    if (isVerifiedLogin) {
      await userProvider.loadUserInfo();

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
