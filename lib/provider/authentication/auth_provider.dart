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
      var body = {"email": mobile};

      Response? response = await httpPost(CMD.login, body);
      _loginLoading = false;
      notifyListeners();
      if (response == null) return false;
      loginResponse = LoginResponse.fromJson(jsonDecode(response.body));

      if (loginResponse != null && loginResponse!.status == 200) {
        LocalStorage.saveAccessToken(loginResponse!.data!.token.toString());
        return true;
      } else {
        showError(loginResponse!.message.toString());
        return false;
      }
    } catch (e) {
      debugPrint("error when login =======> ${e.toString()}");
      _loginLoading = false;
      notifyListeners();
      if (e is SocketException) {
        showError("No internet connection. Please check your network.");
      } else {
        showError("Something went wrong. Please try again.");
      }

      return false;
    }
  }

  Future<bool> otpVerification(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    try {
      var body = {"force_logout_previous": forceLogoutPrevious, "otp": otp};

      Response? response = await httpPost(CMD.otpVerification, body);
      _isLoading = false;
      notifyListeners();
      if (response == null) return false;
      OtpVerificationResponse loginResponse = OtpVerificationResponse.fromJson(jsonDecode(response.body));
      LocalStorage.saveOTPResponse(loginResponse);
      if (loginResponse.status == 200) {
        clearAllData();
        LocalStorage.saveId(loginResponse.data!.defaultLoginId.toString());
        LocalStorage.saveAccessToken(loginResponse.data!.token.toString());
        LocalStorage.saveCode(loginResponse.data!.code.toString());
        LocalStorage.saveName(loginResponse.data!.name.toString());
        LocalStorage.saveEmail(loginResponse.data!.email.toString());
        LocalStorage.saveMobile(loginResponse.data!.mobile.toString());
        SessionManager.changeUser(loginResponse.data!.defaultLoginId.toString());
        if (context.mounted) {
          Provider.of<UserProvider>(context, listen: false).updateUser(name: loginResponse.data!.name.toString(), image: "", code: loginResponse.data!.code.toString(), email: loginResponse.data!.email.toString(), mobile: loginResponse.data!.mobile.toString());
          notifyListeners();
        }
        return true;
      } else {
        showError(loginResponse.message.toString());
        return false;
      }
    } catch (e) {
      debugPrint("error when login =======> ${e.toString()}");
      debugPrint("error when login =======> ${e.toString()}");
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
      var body = {};

      Response? response = await httpPost(CMD.otpReSend, body);
      _isLoading = false;
      notifyListeners();
      if (response == null) return false;
      startTimer();
      SendOTPResponse loginResponse = SendOTPResponse.fromJson(jsonDecode(response.body));
      if (loginResponse.status == 200) {
        showSuccess(loginResponse.message.toString());
        return true;
      } else {
        showError(loginResponse.message.toString());
        return false;
      }
    } catch (e) {
      debugPrint("error when login =======> ${e.toString()}");
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
  }

  void clearSharedPreference() {
    LocalStorage.clearAll();
    notifyListeners();
  }

  void setConfirmationValue(int value) {
    forceLogoutPrevious = value;
    notifyListeners();
  }
}
