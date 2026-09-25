import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:profit_from_it_investors/model/net_contribution_response.dart';
import 'package:profit_from_it_investors/network/http_request.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/constant.dart';

class NetContributionProvider extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  NetContributionResponse? netContributionResponse;

  NetContributionData? get data => netContributionResponse?.data;

  List<ContributionEntry> get payIn => data?.payIn ?? [];

  List<ContributionEntry> get payOut => data?.payOut ?? [];

  List<ContributionEntry> get buyback => data?.buyback ?? [];

  Future<bool> getNetContributionDetails({bool showLoader = true}) async {
    try {
      if (showLoader) {
        _isLoading = true;
        notifyListeners();
      }

      Response? response = await httpPost(CMD.netContributionDetails, {});

      if (response == null) {
        return false;
      }

      netContributionResponse = netContributionResponseFromJson(response.body);

      if (response.statusCode == 200 &&
          netContributionResponse?.status == 200 &&
          netContributionResponse?.data != null) {
        notifyListeners();
        return true;
      }

      showError(
        netContributionResponse?.message ??
            'Unable to load net contribution details.',
      );

      return false;
    } catch (e) {
      debugPrint('net contribution details api error =====> ${e.toString()}');

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

  Future<void> refreshNetContributionDetails() async {
    await getNetContributionDetails(showLoader: false);
  }

  void clearData() {
    netContributionResponse = null;
    notifyListeners();
  }
}
