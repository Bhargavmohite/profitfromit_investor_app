import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:profit_from_it_investors/model/taxometer_response.dart';
import 'package:profit_from_it_investors/network/http_request.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/constant.dart';

class TaxometerProvider extends ChangeNotifier {
  // ============================================================
  // LOADING
  // ============================================================

  bool _taxometerLoading = false;

  bool get taxometerLoading => _taxometerLoading;

  // ============================================================
  // API RESPONSE
  // ============================================================

  TaxometerResponse? taxometerResponse;

  TaxometerData? get taxometerData => taxometerResponse?.data;

  TaxData? get taxData => taxometerResponse?.data?.taxData;

  TaxometerClient? get client => taxometerResponse?.data?.client;

  // ============================================================
  // FINANCIAL YEAR
  // ============================================================

  String selectedFinancialYear = '';

  List<String> get financialYears =>
      taxometerResponse?.data?.financialYears ?? [];

  // ============================================================
  // GET TAXOMETER DATA
  // ============================================================

  Future<bool> getTaxometer(
    BuildContext context, {
    bool isRefresh = false,
  }) async {
    try {
      // --------------------------------------------------------
      // Show loader only during normal loading.
      // Pull-to-refresh can use isRefresh = true.
      // --------------------------------------------------------

      if (!isRefresh) {
        _taxometerLoading = true;
        notifyListeners();
      }

      // --------------------------------------------------------
      // REQUEST BODY
      //
      // If no FY is selected yet, send an empty body.
      // Backend will automatically use the current FY.
      // --------------------------------------------------------

      final Map<String, dynamic> body = {};

      if (selectedFinancialYear.isNotEmpty) {
        body["financial_year"] = selectedFinancialYear;
      }

      // --------------------------------------------------------
      // API CALL
      //
      // httpPost already sends:
      //
      // Authorization
      // user-id
      // Content-Type
      // Accept
      // --------------------------------------------------------

      Response? response = await httpPost(CMD.taxometer, body);

      if (response == null) {
        return false;
      }

      // --------------------------------------------------------
      // PARSE RESPONSE
      // --------------------------------------------------------

      taxometerResponse = taxometerResponseFromJson(response.body);

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      if (response.statusCode == 200 &&
          taxometerResponse != null &&
          taxometerResponse!.status == 200 &&
          taxometerResponse!.data != null) {
        // Backend tells us which FY was actually used.
        selectedFinancialYear =
            taxometerResponse?.data?.financialYear ?? selectedFinancialYear;

        notifyListeners();

        return true;
      }

      // --------------------------------------------------------
      // API ERROR
      // --------------------------------------------------------

      showError(taxometerResponse?.message ?? "Something went wrong");

      return false;
    } catch (e) {
      debugPrint("Taxometer API Error ========> ${e.toString()}");

      if (e is SocketException) {
        showError("No internet connection. Please check your network.");
      } else {
        showError("Something went wrong. Please try again.");
      }

      return false;
    } finally {
      _taxometerLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // CHANGE FINANCIAL YEAR
  // ============================================================

  Future<bool> changeFinancialYear(
    BuildContext context,
    String financialYear,
  ) async {
    final String year = financialYear.trim();

    if (year.isEmpty) {
      return false;
    }

    // No need to call API again if same FY is already loaded.
    if (selectedFinancialYear == year && taxometerResponse != null) {
      return true;
    }

    selectedFinancialYear = year;

    notifyListeners();

    return await getTaxometer(context);
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<bool> refreshTaxometer(BuildContext context) async {
    return await getTaxometer(context, isRefresh: true);
  }
}
