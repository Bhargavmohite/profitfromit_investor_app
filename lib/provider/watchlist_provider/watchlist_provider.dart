
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:profit_from_it_investors/model/watchlist_response.dart';
import 'package:profit_from_it_investors/network/http_request.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/constant.dart';

class WatchlistProvider extends ChangeNotifier {

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  WatchlistResponse? watchlistResponse;

  Future<bool> getTopMovers({bool showLoader = true}) async {
    try {
      if (showLoader) {
        _isLoading = true;
        notifyListeners();
      }

      Response? response = await httpGet(CMD.topMovers);

      if (response == null) {
        return false;
      }

      watchlistResponse = watchlistResponseFromJson(response.body);
      notifyListeners();
      if(watchlistResponse != null && watchlistResponse?.status == 200) {
        return true;
      } else {
        showError(watchlistResponse?.message ?? "Something went wrong");
        return false;
      }
    } catch(e) {
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

  Future<void> refresh() async {
    await getTopMovers(showLoader: false);
  }
}

enum TopMoverType {
  gainers,
  losers,
  highestYielding,
  lowestYielding,
}