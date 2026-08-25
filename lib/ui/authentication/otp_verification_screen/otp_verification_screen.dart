import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:profit_from_it_investors/provider/authentication/auth_provider.dart';
import 'package:profit_from_it_investors/ui/dashboard_screen/dashboard_screen.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/style.dart';
import 'package:provider/provider.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  List<TextEditingController?> otpControllers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      AuthProvider provider = Provider.of<AuthProvider>(context, listen: false);
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
            appBar: AppBar(
              backgroundColor: AppColor.primary,
              centerTitle: false,
              leading: IconButton(
                onPressed: () {
                  provider.clearSharedPreference();
                  Navigator.pop(context);
                },
                icon: Icon(Icons.arrow_back, color: AppColor.white),
              ),
              title: Text("OTP Verification", style: medium.copyWith(color: AppColor.white)),
            ),
            body: Container(
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              color: AppColor.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 40),
                  // Note: We have sent an OTP to your email.
                  Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.only(left: 20, right: 20),
                    child: Text("Note: We have sent an OTP to your email.", style: largeBold.copyWith(color: AppColor.primary)),
                  ),
                  SizedBox(height: 20),
                  OtpTextField(
                    numberOfFields: 6,
                    borderColor: AppColor.primary,
                    fillColor: AppColor.primary,
                    cursorColor: AppColor.primary,
                    focusedBorderColor: AppColor.primary,
                    contentPadding: EdgeInsets.zero,
                    textStyle: mediumBold.copyWith(color: AppColor.primary),
                    showFieldAsBox: true,
                    handleControllers: (List<TextEditingController?> controllers) {
                      otpControllers = controllers; // ✅ Store controllers globally
                      // provider.setOTPControllers(controllers);
                    },
                    onCodeChanged: (String code) {},
                    onSubmit: (String verificationCode) {
                      provider.updateOTP(verificationCode);
                    },
                  ),

                  const SizedBox(height: 40),

                  // Sign In Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    margin: EdgeInsets.only(left: 20, right: 20),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: provider.isLoading ? null : () => _otpVerification(context, provider),
                      child: Text("Verify OTP", style: extraLarge.copyWith(color: AppColor.white)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 32, 0, 0),
                    child: Text("Haven't received the verification code?", style: medium.copyWith(color: AppColor.black)),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 10, 0, 20),
                    child: provider.showButton
                        ? InkWell(
                            onTap: () {
                              for (var controller in otpControllers) {
                                controller?.clear();
                              }
                              provider.reSendOTP();
                            },
                            child: Text('Resend', style: mediumBold.copyWith(color: AppColor.primary)),
                          )
                        : Text('00:${provider.formattedSeconds}', style: mediumBold.copyWith(color: AppColor.primary)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _otpVerification(BuildContext context, AuthProvider authProvider) async {
    if (authProvider.otp.isEmpty) {
      showError("Please provide OTP");
    } else {
      bool success = await authProvider.otpVerification(context);

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
        showError("Invalid OTP!");
      }
    }
  }
}
