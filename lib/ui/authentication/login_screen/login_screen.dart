// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:profit_from_it_investors/provider/authentication/auth_provider.dart';
import 'package:profit_from_it_investors/ui/authentication/otp_verification_screen/otp_verification_screen.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:profit_from_it_investors/utility/app_images.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/constant.dart';
import 'package:profit_from_it_investors/utility/style.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _login(BuildContext context, AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await authProvider.login();

    if (success) {
      if (authProvider.loginResponse != null &&
          authProvider.loginResponse!.data != null) {
        authProvider.setConfirmationValue(0);

        nextRoute(
          MaterialPageRoute(
            builder: (context) {
              return OTPVerificationScreen();
            },
          ),
          isClearBackRoutes: false,
        );
      } else {
        showError(
          authProvider.loginResponse?.message.toString() ??
              'Unable to continue. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (BuildContext context, AuthProvider authProvider, Widget? child) {
        return ModalProgressHUD(
          inAsyncCall: authProvider.loginLoading,
          opacity: 0.55,
          child: Scaffold(
            backgroundColor: const Color(0xFFF6F7FB),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 42,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFDCE1EA),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Keep the existing / old Profit From It logo.
                                  Center(
                                    child: Image.asset(
                                      AppImages.newLogo,
                                      width: 172,
                                      height: 64,
                                      fit: BoxFit.contain,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColor.primary.withValues(
                                          alpha: .07,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColor.primary.withValues(
                                            alpha: .14,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 5,
                                            height: 5,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF00A67A),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'SEBI RIA INA000020651',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF27364B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  Center(
                                    child: Text(
                                      'Welcome Back',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColor.textPrimary,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Text(
                                        'Enter your registered mobile number or email to access your investor portfolio.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          height: 1.45,
                                          color: AppColor.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  Text(
                                    'Email or Mobile Number',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColor.textPrimary,
                                    ),
                                  ),

                                  const SizedBox(height: 7),

                                  TextFormField(
                                    controller: authProvider.mobileController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) {
                                      if (!authProvider.isLoading) {
                                        _login(context, authProvider);
                                      }
                                    },
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppColor.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Enter email address or mobile number',
                                      hintStyle: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: const Color(0xFFAAB3C2),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.contact_mail_outlined,
                                        size: 19,
                                        color: Color(0xFF7A8799),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFFBFCFE),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 13,
                                            vertical: 15,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD8DEE8),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppColor.primary,
                                          width: 1.3,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppColor.red,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppColor.red,
                                          width: 1.3,
                                        ),
                                      ),
                                    ),
                                    validator:
                                        authProvider.validateEmailOrPhone,
                                  ),

                                  const SizedBox(height: 11),

                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE9F8F3),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.verified_user_outlined,
                                          size: 13,
                                          color: Color(0xFF008A68),
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Text(
                                          'We will send a 6-digit one-time password (OTP) for secure verification.',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            height: 1.4,
                                            color: AppColor.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 18),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: authProvider.isLoading
                                          ? null
                                          : () => _login(context, authProvider),
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        backgroundColor: const Color(
                                          0xFF082D59,
                                        ),
                                        disabledBackgroundColor: const Color(
                                          0xFF9BA7B6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Sign In with OTP',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 7),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 17,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Text(
                            Constants.copyRightMessage,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showApproveDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Confirm Logout',
                style: largeBold.copyWith(color: AppColor.black),
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppColor.black),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          content: Text(
            'You are logged in in other device. Are you sure you want to logout from your previous device?',
            style: medium.copyWith(color: AppColor.black),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.red,
                foregroundColor: AppColor.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: medium.copyWith(color: AppColor.white),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: AppColor.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                authProvider.setConfirmationValue(1);

                nextRoute(
                  MaterialPageRoute(
                    builder: (context) {
                      return OTPVerificationScreen();
                    },
                  ),
                  isClearBackRoutes: false,
                );
              },
              child: Text(
                'Confirm',
                style: medium.copyWith(color: AppColor.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
