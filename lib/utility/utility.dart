
import 'package:flutter/foundation.dart';

class Utility {

  static const String tag = "Utility";

  static void printLogs({required String tag, required String title, required dynamic msg}) {
    if(!kReleaseMode) {

    }
    debugPrint("$tag $title =========> $msg");
  }
}