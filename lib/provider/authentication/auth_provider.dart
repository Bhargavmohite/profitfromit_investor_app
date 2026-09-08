import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:profit_from_it_investors/model/login_response.dart';
import 'package:profit_from_it_investors/model/otp_verification_response.dart';
import 'package:profit_from_it_investors/model/send_otp_response.dart';
import 'package:profit_from_it_investors/network/http_request.dart';
import 'package:profit_from_it_investors/provider/authentication/user_provider.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/constant.dart';
import 'package:profit_from_it_investors/utility/local_storage.dart';
import 'package:profit_from_it_investors/utility/session_manager.dart';
import 'package:provider/provider.dart';

class AuthProvider extends ChangeNotifier {
  // Controllers
  final TextEditingController mobileController = TextEditingController();
  List<TextEditingController?> otpControllers = [];

  final FocusNode mobileFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _loginLoading = false;

  bool get obscurePassword => _obscurePassword;

  bool get isLoading => _isLoading;

  bool get loginLoading => _loginLoading;

  LoginResponse? loginResponse;

  // Temporary pre-OTP token.
// It exists only while the app is running.
String _pendingOtpToken = "";

  String otp = "";

  void updateOTP(String code) {
    otp = code;
    notifyListeners();
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  String? validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter email or phone number";
    }

    String trimmedValue = value.trim();
    bool isDigitsOnly = RegExp(r'^\d+$').hasMatch(trimmedValue);

    if (isDigitsOnly) {
      if (trimmedValue.length != 10) {
        return "Phone number must be 10 digits";
      }
    } else {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );

      if (!emailRegex.hasMatch(trimmedValue)) {
        return "Please enter valid email address";
      }
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter password";
    }
    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }
    return null;
  }

  // Login Function
 Future<bool> login() async {
  final mobile = mobileController.text.trim();

  _loginLoading = true;
  notifyListeners();

  try {
    // Start a fresh login attempt.
    _pendingOtpToken = "";

    var body = {
      "email": mobile,
    };

    // Login API should not use an old authenticated token.
    Response? response = await httpPost(
      CMD.login,
      body,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    );

    _loginLoading = false;
    notifyListeners();

    if (response == null) {
      return false;
    }

    loginResponse = LoginResponse.fromJson(
      jsonDecode(response.body),
    );

    if (loginResponse != null &&
        loginResponse!.status == 200) {
      
      final pendingToken =
          loginResponse!.data?.token?.trim() ?? "";

      if (pendingToken.isEmpty) {
        showError(
          "Unable to start OTP verification. Please try again.",
        );
        return false;
      }

      // IMPORTANT:
      // Do NOT save this in SharedPreferences.
      // User is still NOT logged in.
      _pendingOtpToken = pendingToken;

      return true;
    } else {
      showError(
        loginResponse?.message.toString() ?? "Login failed",
      );

      return false;
    }
  } catch (e) {
    debugPrint(
      "error when login =======> ${e.toString()}",
    );

    _loginLoading = false;
    notifyListeners();

    if (e is SocketException) {
      showError(
        "No internet connection. Please check your network.",
      );
    } else {
      showError(
        "Something went wrong. Please try again.",
      );
    }

    return false;
  }
}

Future<bool> otpVerification(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_pendingOtpToken.isEmpty) {
        _isLoading = false;
        notifyListeners();

        showError("Login session expired. Please login again.");

        return false;
      }

      var body = {"force_logout_previous": forceLogoutPrevious, "otp": otp};

      Response? response = await httpPost(
        CMD.otpVerification,
        body,
        headers: {
          "Authorization": "Bearer $_pendingOtpToken",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      _isLoading = false;
      notifyListeners();

      if (response == null) {
        return false;
      }

      OtpVerificationResponse verificationResponse =
          OtpVerificationResponse.fromJson(jsonDecode(response.body));

      if (verificationResponse.status == 200 &&
          verificationResponse.data != null) {
        final verifiedToken = verificationResponse.data!.token?.trim() ?? "";

        final verifiedUserId =
            verificationResponse.data!.defaultLoginId?.trim() ?? "";

        if (verifiedToken.isEmpty || verifiedUserId.isEmpty) {
          showError(
            "OTP verified, but login session data is missing. Please try again.",
          );

          return false;
        }

        // ONLY NOW is the user actually authenticated.

        await LocalStorage.saveOTPResponse(verificationResponse);

        await LocalStorage.saveId(verifiedUserId);

        await LocalStorage.saveCode(verificationResponse.data!.code.toString());

        await LocalStorage.saveName(verificationResponse.data!.name.toString());

        await LocalStorage.saveEmail(
          verificationResponse.data!.email.toString(),
        );

        await LocalStorage.saveMobile(
          verificationResponse.data!.mobile.toString(),
        );

        // Real authenticated token is saved ONLY after OTP.
        await LocalStorage.saveAccessToken(verifiedToken);

        SessionManager.changeUser(verifiedUserId);

        clearAllData();

        if (context.mounted) {
          Provider.of<UserProvider>(context, listen: false).updateUser(
            name: verificationResponse.data!.name.toString(),
            image: "",
            code: verificationResponse.data!.code.toString(),
            email: verificationResponse.data!.email.toString(),
            mobile: verificationResponse.data!.mobile.toString(),
          );

          notifyListeners();
        }

        return true;
      } else {
        showError(verificationResponse.message.toString());

        return false;
      }
    } catch (e) {
      debugPrint("error when OTP verification =======> ${e.toString()}");

      _isLoading = false;
      notifyListeners();

      if (e is SocketException) {
        showError("No internet connection. Please check your network.");
      } else {
        showError("Something went wrong. Please try again.");
      }

      return false;
    }
  }

  @override
  void dispose() {
    mobileController.dispose();
    if (_timer != null) {
      _timer!.cancel();
    }
    super.dispose();
  }

  bool _showButton = false;

  bool get showButton => _showButton;
  Timer? _timer;
  int _seconds = 60;

  int get seconds => _seconds;

  String get formattedSeconds => _seconds.toString().padLeft(2, '0');

  int forceLogoutPrevious = 0;

  void startTimer() {
    debugPrint("Start timer called");
    _showButton = false;
    _timer?.cancel();
    _seconds = 60;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        _seconds--;
      } else {
        _showButton = true;
        stopTimer();
      }
      notifyListeners();
    });
  }

  void stopTimer() {
    _timer?.cancel();
    notifyListeners();
  }

  Future<bool> reSendOTP() async {
    stopTimer();

    _isLoading = true;
    notifyListeners();

    try {
      if (_pendingOtpToken.isEmpty) {
        _isLoading = false;
        notifyListeners();

        showError("Login session expired. Please login again.");

        return false;
      }

      var body = {};

      Response? response = await httpPost(
        CMD.otpReSend,
        body,
        headers: {
          "Authorization": "Bearer $_pendingOtpToken",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      _isLoading = false;
      notifyListeners();

      if (response == null) {
        return false;
      }

      startTimer();

      SendOTPResponse otpResponse = SendOTPResponse.fromJson(
        jsonDecode(response.body),
      );

      if (otpResponse.status == 200) {
        showSuccess(otpResponse.message.toString());

        return true;
      } else {
        showError(otpResponse.message.toString());

        return false;
      }
    } catch (e) {
      debugPrint("error when resending OTP =======> ${e.toString()}");

      _isLoading = false;
      notifyListeners();

      if (e is SocketException) {
        showError("No internet connection. Please check your network.");
      } else {
        showError("Something went wrong. Please try again.");
      }

      return false;
    }
  }

  void setOTPControllers(List<TextEditingController?> controllers) {
    otpControllers = controllers;
    notifyListeners();
  }

  void clearAllData() {
    mobileController.clear();
    otp = "";
    _pendingOtpToken = "";
  }

  void clearSharedPreference() {
    _pendingOtpToken = "";
    LocalStorage.clearAll();
    notifyListeners();
  }

  void setConfirmationValue(int value) {
    forceLogoutPrevious = value;
    notifyListeners();
  }
}
