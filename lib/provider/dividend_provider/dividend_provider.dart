import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:profit_from_it_investors/model/dividend_response.dart';
import 'package:profit_from_it_investors/network/http_request.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/constant.dart';

class DividendProvider extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  DividendResponse? dividendResponse;

  DividendData? get data => dividendResponse?.data;

  List<DividendEntry> get dividends => data?.dividends ?? [];

  Future<bool> getDividendDetails({bool showLoader = true}) async {
    try {
      if (showLoader) {
        _isLoading = true;
        notifyListeners();
      }

      // Existing httpPost() automatically sends:
      // - Authorization Bearer token
      // - current SessionManager.userId as "user-id"
      //
      // Therefore the selected Family / Readonly Admin / Partner
      // client is respected automatically.
      Response? response = await httpPost(CMD.dividendDetails, {});

      if (response == null) {
        return false;
      }

      dividendResponse = dividendResponseFromJson(response.body);

      if (response.statusCode == 200 &&
          dividendResponse?.status == 200 &&
          dividendResponse?.data != null) {
        notifyListeners();
        return true;
      }

      showError(
        dividendResponse?.message ?? 'Unable to load dividend details.',
      );

      return false;
    } catch (e) {
      debugPrint('dividend details api error =====> ${e.toString()}');

      if (e is SocketException) {
        showError('No internet connection. Please check your network.');
      } else {
        showError('Something went wrong. Please try again.');
      }

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDividendDetails() async {
    await getDividendDetails(showLoader: false);
  }

  void clearData() {
    dividendResponse = null;
    notifyListeners();
  }
}
