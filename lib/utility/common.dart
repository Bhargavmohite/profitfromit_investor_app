import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:profit_from_it_investors/utility/constant.dart';
import 'package:profit_from_it_investors/utility/style.dart';
import 'package:url_launcher/url_launcher.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<dynamic> nextRoute(Route page, {bool isClearBackRoutes = false, dynamic arguments}) async {
  debugPrint("called navigation");
  if (isClearBackRoutes) {
    return await Navigator.pushAndRemoveUntil(navigatorKey.currentContext!, page, (route) => false);
  } else {
    return await Navigator.push(navigatorKey.currentContext!, page);
  }
}

void backRoute({dynamic arguments}) {
  navigatorKey.currentState!.pop(arguments);
}

void showError(String message) {
  final snackBar = SnackBar(
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(Constants.appName, style: mediumBold.copyWith(color: AppColor.white)),
        SizedBox(height: 4),
        Text(message, style: medium.copyWith(color: AppColor.white)),
      ],
    ),
    backgroundColor: AppColor.red,
    duration: const Duration(milliseconds: 2500),
    behavior: SnackBarBehavior.fixed,
  );
  rootScaffoldMessengerKey.currentState?.showSnackBar(snackBar);
}

void showSuccess(String message) {
  final snackBar = SnackBar(
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(Constants.appName, style: mediumBold.copyWith(color: AppColor.white)),
        SizedBox(height: 4),
        Text(message, style: medium.copyWith(color: AppColor.white)),
      ],
    ),
    backgroundColor: AppColor.green,
    duration: const Duration(milliseconds: 2500),
    behavior: SnackBarBehavior.fixed,
  );
  rootScaffoldMessengerKey.currentState?.showSnackBar(snackBar);
}

Widget buildInfoTile(IconData icon, String title, String? value) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    leading: Icon(icon, color: AppColor.primary, size: 28),
    title: Text(title, style: large.copyWith(color: AppColor.grey600)),
    subtitle: Text(value?.isNotEmpty == true ? value! : "N/A", style: medium.copyWith(color: AppColor.black)),
  );
}

// Launch phone call
Future<void> makeCall(String number) async {
  final Uri uri = Uri(scheme: "tel", path: number);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

// Launch WhatsApp chat
Future<void> openWhatsApp(String number) async {
  final Uri uri = Uri.parse("https://wa.me/$number");
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> openGoogleMaps({required double sourceLat, required double sourceLng, required double destLat, required double destLng}) async {
  final Uri url = Uri.parse('https://www.google.com/maps/dir/?api=1&origin=$sourceLat,$sourceLng&destination=$destLat,$destLng&travelmode=driving');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch Google Maps';
  }
}

// Launch external app to open file
Future<void> openWithExternalApp(Uri uri) async {
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not open file');
  }
}

String formattedDate(DateTime selectedDateTime) {
  final dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  String day = dayNames[selectedDateTime.weekday % 7];

  return "${_twoDigits(selectedDateTime.day)}/${_twoDigits(selectedDateTime.month)}/${selectedDateTime.year} ($day)";
}

String formattedTime(DateTime selectedDateTime) {
  final hour = selectedDateTime.hour;
  final minute = selectedDateTime.minute;

  final period = hour >= 12 ? "pm" : "am";
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;

  return "${_twoDigits(displayHour)}:${_twoDigits(minute)} $period";
}

String _twoDigits(int n) => n.toString().padLeft(2, '0');

Widget label(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: smallBold),
  );
}

String getMonthName(int month) {
  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  return months[month - 1];
}

String getMonthRange(String? month) {
  if (month == null) return "";

  try {
    DateFormat format = DateFormat('MMMM');
    DateTime parsed = format.parse(month);
    final firstDay = DateTime(parsed.year, parsed.month, 1);
    final lastDay = DateTime(parsed.year, parsed.month + 1, 0);

    return "${formatDateTime(firstDay)} - ${formatDateTime(lastDay)}";
  } catch (e) {
    return "error";
  }
}

String formatDateTime(DateTime d) {
  return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}";
}

double parseAmount(String? value) {
  if (value == null || value.isEmpty) return 0;
  return double.tryParse(value.replaceAll(",", "")) ?? 0;
}

class Common {
  static String formatDateYYYYMMDD(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return "$year-$month-$day";
  }

  static void showToast(String message) {
    Fluttertoast.showToast(msg: message, backgroundColor: Colors.black87, textColor: Colors.white, gravity: ToastGravity.BOTTOM);
  }

  static DateTime parseDate(String date) {
    try {
      final parts = date.split("-");
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (_) {
      return DateTime.now();
    }
  }

  static String getDayName(DateTime date) {
    const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    return days[date.weekday % 7];
  }
}

class CropAspectRatioPresetCustom implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (2, 3);

  @override
  String get name => '2x3 (customized)';
}

extension HexColorExtension on String? {
  Color toColor() {
    try {
      if (this == null || this!.isEmpty) {
        return AppColor.primary;
      }

      String hex = this!.replaceAll('#', '');

      if (hex.length == 6) {
        hex = 'FF$hex';
      }

      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return AppColor.primary;
    }
  }
}

extension AmountParsingExtension on String? {
  double toAmount() {
    if (this == null || this!.trim().isEmpty) {
      return 0.0;
    }
    final cleanedValue = this!.replaceAll('₹', '').replaceAll('%', '').replaceAll(',', '').replaceAll(' ', '').trim();
    return double.tryParse(cleanedValue) ?? 0.0;
  }
}

String getInitials(String company) {
  final words = company.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();

  if (words.isEmpty) return '';

  if (words.length == 1) {
    return words.first.length >= 2 ? words.first.substring(0, 2).toUpperCase() : words.first.toUpperCase();
  }

  if (words.length == 2) {
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  return (words[0][0] + words[1][0] + words[2][0]).toUpperCase();
}

class AmountUtils {
  /// Converts "₹-31,389.22" -> -31389.22
  static double parseAmount(String? amount) {
    if (amount == null || amount.trim().isEmpty) {
      return 0.0;
    }

    final cleanedAmount = amount
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .trim();

    return double.tryParse(cleanedAmount) ?? 0.0;
  }

  /// Returns true if amount is negative.
  static bool isNegative(String? amount) {
    return parseAmount(amount) < 0;
  }

  /// Returns true if amount is positive.
  static bool isPositive(String? amount) {
    return parseAmount(amount) > 0;
  }

  /// Returns true if amount is zero.
  static bool isZero(String? amount) {
    return parseAmount(amount) == 0;
  }
}