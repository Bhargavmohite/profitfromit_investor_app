import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:profit_from_it_investors/provider/authentication/auth_provider.dart';
import 'package:profit_from_it_investors/ui/dashboard_screen/dashboard_screen.dart';
import 'package:profit_from_it_investors/utility/common.dart';

import 'package:provider/provider.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  List<TextEditingController?> otpControllers = [];
  int _enteredDigits = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AuthProvider>(context, listen: false);

      provider.startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (BuildContext context, AuthProvider provider, Widget? child) {
        return ModalProgressHUD(
          inAsyncCall: provider.isLoading,
          opacity: 0.6,
          child: Scaffold(
            backgroundColor: const Color(0xFFF7F8FC),
            appBar: AppBar(
              backgroundColor: const Color(0xFFF7F8FC),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              leading: IconButton(
                onPressed: () {
                  provider.clearSharedPreference();
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF152238),
                ),
              ),
              title: Text(
                'Verify Authentication',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF152238),
                ),
              ),
            ),
            body: SafeArea(
              top: false,
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                    sliver: SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'We have sent a 6-digit verification code to your registered contact.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              height: 1.45,
                              color: const Color(0xFF647086),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            'Enter 6-Digit Secure Code',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF27364B),
                            ),
                          ),

                          const SizedBox(height: 8),

                          OtpTextField(
                            numberOfFields: 6,
                            fieldWidth: 43,
                            borderRadius: BorderRadius.circular(9),
                            borderWidth: 1.2,
                            borderColor: const Color(0xFFD6DDE8),
                            enabledBorderColor: const Color(0xFFD6DDE8),
                            focusedBorderColor: const Color(0xFF082D59),
                            cursorColor: const Color(0xFF082D59),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.zero,
                            textStyle: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10213A),
                            ),
                            showFieldAsBox: true,
                            handleControllers:
                                (List<TextEditingController?> controllers) {
                                  otpControllers = controllers;
                                },
                            onCodeChanged: (String code) {
                              if (!mounted) return;

                              setState(() {
                                _enteredDigits = code.length.clamp(0, 6);
                              });
                            },
                            onSubmit: (String verificationCode) {
                              provider.updateOTP(verificationCode);

                              if (mounted) {
                                setState(() {
                                  _enteredDigits = 6;
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE9F8F3),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Icon(
                                  Icons.verified_outlined,
                                  size: 12,
                                  color: Color(0xFF008A68),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Secure OTP verification',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF647086),
                                  ),
                                ),
                              ),
                              Text(
                                'Slot ${_enteredDigits.clamp(0, 6)} of 6',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF647086),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFDCE2EC),
                              ),
                            ),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Haven't received the verification code?",
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFF647086),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.refresh_rounded,
                                      size: 16,
                                      color: Color(0xFF0D3CCF),
                                    ),
                                    const SizedBox(width: 5),

                                    if (!provider.showButton)
                                      Text(
                                        'Resend code in 00:${provider.formattedSeconds}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF27364B),
                                        ),
                                      )
                                    else
                                      Text(
                                        'Code can be resent now',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF27364B),
                                        ),
                                      ),

                                    const Spacer(),

                                    InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: provider.showButton
                                          ? () async {
                                              for (final controller
                                                  in otpControllers) {
                                                controller?.clear();
                                              }

                                              provider.updateOTP('');

                                              if (mounted) {
                                                setState(() {
                                                  _enteredDigits = 0;
                                                });
                                              }

                                              await provider.reSendOTP();
                                            }
                                          : null,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 3,
                                        ),
                                        child: Text(
                                          'Resend OTP',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: provider.showButton
                                                ? const Color(0xFF0D3CCF)
                                                : const Color(0xFFAAB3C2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: provider.isLoading
                                  ? null
                                  : () => _otpVerification(context, provider),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: const Color(0xFF082D59),
                                disabledBackgroundColor: const Color(
                                  0xFF9BA7B6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Verify OTP & Continue',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _otpVerification(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    if (authProvider.otp.isEmpty) {
      showError('Please provide OTP');
      return;
    }

    final success = await authProvider.otpVerification(context);

    if (success) {
      nextRoute(
        MaterialPageRoute(
          builder: (context) {
            return DashboardScreen();
          },
        ),
        isClearBackRoutes: true,
      );
    } else {
      showError('Invalid OTP!');
    }
  }
}
