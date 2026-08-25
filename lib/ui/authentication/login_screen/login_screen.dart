// ignore_for_file: unused_element

import 'package:flutter/material.dart';
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

    bool success = await authProvider.login();

    if (success) {
      if (authProvider.loginResponse != null && authProvider.loginResponse!.data != null) {
        // if(authProvider.loginResponse!.data!.alreadyLogged == 1) {
        //   _showApproveDialog(context, authProvider);
        // } else {
        authProvider.setConfirmationValue(0);
        nextRoute(
          MaterialPageRoute(
            builder: (context) {
              return OTPVerificationScreen();
            },
          ),
          isClearBackRoutes: false,
        );
        // }
      } else {
        showError(authProvider.loginResponse!.message.toString());
      }
    } else {
      // showError(authProvider.loginResponse!.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (BuildContext context, AuthProvider authProvider, Widget? child) {
        return ModalProgressHUD(
          inAsyncCall: authProvider.loginLoading,
          opacity: 0.6,
          child: Scaffold(
            backgroundColor: Colors.white,
            // appBar: AppBar(backgroundColor: AppColor.white, elevation: 0),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            alignment: Alignment.topCenter,
                            decoration: const BoxDecoration(color: Colors.white),
                            child: Image.asset(AppImages.newLogo, fit: BoxFit.fitWidth, width: 220),
                          ),
                          const SizedBox(height: 30),

                          // Form
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: authProvider.mobileController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: "Email/Phone",
                                    prefixIcon: Icon(Icons.email, color: AppColor.primary),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  validator: authProvider.validateEmailOrPhone,
                                ),
                                const SizedBox(height: 20),

                                // Sign In Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColor.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: authProvider.isLoading ? null : () => _login(context, authProvider),
                                    child: Text("Sign in", style: extraLarge.copyWith(color: AppColor.white)),
                                  ),
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0, top: 16.0, right: 12.0, left: 12.0),
                    child: Text(
                      Constants.copyRightMessage,
                      textAlign: TextAlign.center,
                      style: medium.copyWith(color: Colors.black54, fontSize: 12),
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

  void _showApproveDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Confirm Logout", style: largeBold.copyWith(color: AppColor.black)),
              IconButton(
                icon: Icon(Icons.close, color: AppColor.black),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          content: Text("You are logged in in other device. Are you sure you want to logout from your previous device?", style: medium.copyWith(color: AppColor.black)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.red,
                foregroundColor: AppColor.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel", style: medium.copyWith(color: AppColor.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: AppColor.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              child: Text("Confirm", style: medium.copyWith(color: AppColor.white)),
            ),
          ],
        );
      },
    );
  }
}
