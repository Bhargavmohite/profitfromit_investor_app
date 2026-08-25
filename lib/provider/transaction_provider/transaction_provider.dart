import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:profit_from_it_investors/model/transaction_response.dart';
import 'package:profit_from_it_investors/network/http_request.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/constant.dart';

class TransactionProvider extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  TransactionResponse? transactionResponse;

  List<Transaction> transactions = [];

  /// Dynamic filter list
  List<String> get transactionTypes {
    final types = transactions.map((e) => e.type ?? '').where((e) => e.isNotEmpty).toSet().toList();

    return ['All', ...types];
  }

  /// Filtered transactions
  List<Transaction> filteredTransactions(String filter) {
    if (filter == 'All') {
      return transactions;
    }

    return transactions.where((element) => element.type == filter).toList();
  }

  Future<bool> getTransactions({bool showLoader = true}) async {
    try {
      if (showLoader) {
        _isLoading = true;
        notifyListeners();
      }

      var body = {
        "type": "all"
      };

      Response? response = await httpPost(CMD.transactions, body);
      if (response == null) {
        return false;
      }
      if (response.statusCode == 200) {
        transactionResponse = transactionResponseFromJson(response.body);
        transactions = transactionResponse?.data?.transactions ?? [];
        notifyListeners();
        return true;
      } else {
        showError(transactionResponse?.message ?? "Something went wrong");
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

  Future<void> refreshTransactions() async {
    await getTransactions(showLoader: false);
  }

  void clearData() {
    transactionResponse = null;
    notifyListeners();
  }
}