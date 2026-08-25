import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:profit_from_it_investors/model/stock_detail_response.dart';
import 'package:profit_from_it_investors/network/http_request.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/constant.dart';

class StockDetailProvider extends ChangeNotifier {
  bool _isLoading = false;

  StockDetailResponse? stockDetailResponse;

  bool get isLoading => _isLoading;

  Data? get stockData => stockDetailResponse?.data;

  Summary? get summary => stockDetailResponse?.data?.summary;

  List<Transaction> get transactions => stockDetailResponse?.data?.transactions ?? [];

  Future<bool> getStockDetail(BuildContext context, {required String stockId, bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        _isLoading = true;
        notifyListeners();
      }

      Response? response = await httpPost(CMD.stockDetail, {"id": stockId});

      if (response == null) {
        return false;
      }

      if (response.statusCode == 200) {
        stockDetailResponse = stockDetailResponseFromJson(response.body);
        notifyListeners();
        return true;
      } else {
        showError(stockDetailResponse?.message ?? "Something went wrong");
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

  Future<void> refreshStockDetail(BuildContext context, {required String stockId}) async {
    await getStockDetail(context, stockId: stockId, isRefresh: true);
  }
}
