import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String format(dynamic value) {
    if (value == null) return "₹0.00";

    try {
      double number;

      if (value is String) {
        if (value.trim().isEmpty) return "₹0.00";

        final cleaned = value.replaceAll(",", "");
        number = double.parse(cleaned);
      } else if (value is int) {
        number = value.toDouble();
      } else if (value is double) {
        number = value;
      } else {
        return "₹0.00";
      }

      return _formatter.format(number);
    } catch (e) {
      return "₹0.00";
    }
  }
}