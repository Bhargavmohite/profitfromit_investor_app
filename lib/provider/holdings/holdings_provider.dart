import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:profit_from_it_investors/model/holdings_detail_response.dart';
import 'package:profit_from_it_investors/network/http_request.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/constant.dart';

class HoldingsProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  HoldingsDetailResponse? holdingsResponse;

  List<Holding> holdings = [];

  String totalInvested = '0';

  Future<bool> getHoldings({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        _isLoading = true;
        notifyListeners();
      }
      Response? response = await httpGet(CMD.holdings);

      if (response == null) {
        return false;
      }

      if (response.statusCode == 200) {
        holdingsResponse = holdingsDetailResponseFromJson(response.body);
        holdings = holdingsResponse?.data?.holdings ?? [];
        totalInvested = holdingsResponse?.data?.totalInvested ?? '0';
        notifyListeners();
        return true;
      } else {
        showError("Something went wrong. Please try again.");
        return false;
      }
    } catch (e) {
      debugPrint('Holdings API Error : $e');

      if (e is SocketException) {
        showError("No internet connection. Please check your network.");
      } else {
        showError("Something went wrong. Please try again.");
      }

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
