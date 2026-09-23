// ignore_for_file: unused_import

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' hide read;
import 'package:profit_from_it_investors/model/dashboard_response.dart';
import 'package:profit_from_it_investors/model/logout_response.dart' hide Data;
import 'package:profit_from_it_investors/model/portfolio_chart_response.dart';
import 'package:profit_from_it_investors/network/http_request.dart';
import 'package:profit_from_it_investors/provider/client_switch/client_switch_provider.dart';
import 'package:profit_from_it_investors/provider/family/family_provider.dart';
import 'package:profit_from_it_investors/ui/authentication/login_screen/login_screen.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/constant.dart';
import 'package:profit_from_it_investors/utility/local_storage.dart';
import 'package:profit_from_it_investors/utility/session_manager.dart';
import 'package:provider/provider.dart';

class HomeProvider extends ChangeNotifier {
  bool _dashboardLoading = false;

  bool get dashboardLoading => _dashboardLoading;

  final bool _isLoading = false;

  bool get isLoading => _isLoading;

  bool _portfolioChartLoading = false;

  bool get portfolioChartLoading => _portfolioChartLoading;

  DashboardResponse? dashboardResponse;

  Data? get dashboardData => dashboardResponse?.data;

  List<TopHolding> get topHoldings =>
      dashboardResponse?.data?.topHoldings ?? [];

  String chartType = "1M";
  PortfolioChartResponse? portfolioChartResponse;

  Future<bool> getDashboard(
    BuildContext context, {
    bool isRefresh = false,
  }) async {
    try {
      if (!isRefresh) {
        _dashboardLoading = true;
        notifyListeners();
      }
      Response? response = await httpPost(CMD.dashboard, {});
      if (response == null) {
        return false;
      }
      dashboardResponse = dashboardResponseFromJson(response.body);

      if (response.statusCode == 200 &&
          dashboardResponse != null &&
          dashboardResponse!.status == 200 &&
          dashboardResponse!.data != null) {
        if (context.mounted) {
          // await context.read<FamilyProvider>().setFamilyList(dashboardResponse?.data?.familyList ?? []);
          context.read<FamilyProvider>().setFamilyList(
            dashboardResponse?.data?.familyList ?? [],
          );

          context.read<ClientSwitchProvider>().syncFromDashboard(
            dashboardResponse?.data,
          );
        }
        notifyListeners();
        return true;
      } else {
        showError(dashboardResponse?.message ?? "Something went wrong");

        return false;
      }
    } catch (e) {
      debugPrint("error when dashboard api ========> ${e.toString()}");
      if (e is SocketException) {
        showError("No internet connection. Please check your network.");
      } else {
        showError("Something went wrong. Please try again.");
      }
      return false;
    } finally {
      _dashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard(
    BuildContext context, {
    required bool isRefresh,
  }) async {
    await getDashboard(context, isRefresh: isRefresh);
    await getPortfolioChart(context, isRefresh: isRefresh);
  }

  /// Updates only the selected chart period without making an API call.
  /// Used by the NAV chart because full NAV history already comes from
  /// the Dashboard API and can be filtered locally in HomeScreen.
  void updateChartTypeLocally(String period) {
    chartType = period;
    notifyListeners();
  }

  Future<void> updateChartType(BuildContext context, String period) async {
    chartType = period;
    notifyListeners();

    await getPortfolioChart(context);
  }

  Future<bool> getPortfolioChart(
    BuildContext context, {
    bool isRefresh = false,
  }) async {
    try {
      if (!isRefresh) {
        _portfolioChartLoading = true;
        notifyListeners();
      }

      var body = {"chart_type": chartType, "start_date": "", "end_date": ""};

      Response? response = await httpPost(CMD.portfolioChart, body);
      if (response == null) {
        return false;
      }
      portfolioChartResponse = portfolioChartResponseFromJson(response.body);

      if (response.statusCode == 200 &&
          portfolioChartResponse != null &&
          portfolioChartResponse!.status == 200 &&
          portfolioChartResponse!.data != null) {
        notifyListeners();
        return true;
      } else {
        showError(portfolioChartResponse?.message ?? "Something went wrong");

        return false;
      }
    } catch (e) {
      debugPrint("error when dashboard api ========> ${e.toString()}");
      if (e is SocketException) {
        showError("No internet connection. Please check your network.");
      } else {
        showError("Something went wrong. Please try again.");
      }
      return false;
    } finally {
      _portfolioChartLoading = false;
      notifyListeners();
    }
  }

}
