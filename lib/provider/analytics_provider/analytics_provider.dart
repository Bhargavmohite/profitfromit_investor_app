import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:profit_from_it_investors/model/analytics_response.dart';
import 'package:profit_from_it_investors/network/http_request.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/constant.dart';

class AnalyticsProvider extends ChangeNotifier {
  bool _isLoading = false;

  AnalyticsResponse? analyticsResponse;

  bool get isLoading => _isLoading;

  String totalValue = '0';

  List<MarketCap> sectors = [];

  List<MarketCap> marketCaps = [];

  Future<bool> getAnalytics({bool isRefresh = false}) async {
    try {
      if (!isRefresh) {
        _isLoading = true;
        notifyListeners();
      }

      Response? response = await httpGet(CMD.analytics);

      if (response == null) {
        return false;
      }
      if (response.statusCode == 200) {
        analyticsResponse = analyticsResponseFromJson(response.body);
        totalValue = analyticsResponse!.data!.totalValue ?? "0";
        sectors = analyticsResponse!.data!.sector ?? [];
        marketCaps = analyticsResponse!.data!.marketCap ?? [];

        notifyListeners();
        return true;
      } else {
        showError(analyticsResponse?.message ?? "Something went wrong");
        return false;
      }
    } catch (e) {
      debugPrint("stock detail api error =====> ${e.toString()}");
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
