import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkCheck {
  static Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return false;

    // Verify actual internet connection by pinging a known reliable server
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } on SocketException {
      return false;
    }
  }
}