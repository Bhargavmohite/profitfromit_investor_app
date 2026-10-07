// ignore_for_file: unused_import

import 'dart:async';
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

  // Request generations prevent an older Dashboard/chart response from
  // overwriting data after the user has already switched to another client.
  int _dashboardRequestVersion = 0;
  int _portfolioChartRequestVersion = 0;

  Future<bool> getDashboard(
    BuildContext context, {
    bool isRefresh = false,
  }) async {
    final int requestVersion = ++_dashboardRequestVersion;
    final String requestedUserId = SessionManager.userId;

    try {
      if (!isRefresh) {
        _dashboardLoading = true;
        notifyListeners();
      }

      final previousActiveClientId = dashboardData?.activeClientId;

      final dashboardWatch = Stopwatch()..start();
      final Response? response = await httpPost(CMD.dashboard, {
        'skip_portfolio_curve': true,
      });
      final httpMs = dashboardWatch.elapsedMilliseconds;

      // A newer Dashboard request or a client switch superseded this request.
      if (requestVersion != _dashboardRequestVersion ||
          SessionManager.userId != requestedUserId) {
        debugPrint(
          '[HOME STALE] dashboard ignored | requestedUserId=$requestedUserId '
          '| currentUserId=${SessionManager.userId}',
        );
        return false;
      }

      if (response == null) {
        return false;
      }

      final parseWatch = Stopwatch()..start();
      final parsedDashboardResponse = dashboardResponseFromJson(response.body);
      final parseMs = parseWatch.elapsedMilliseconds;

      debugPrint(
        '[HOME PERF] dashboard | http=${httpMs}ms | parse=${parseMs}ms '
        '| total=${dashboardWatch.elapsedMilliseconds}ms | bytes=${response.body.length}',
      );

      if (response.statusCode == 200 &&
          parsedDashboardResponse.status == 200 &&
          parsedDashboardResponse.data != null) {
        final int? expectedClientId = int.tryParse(requestedUserId);
        final int? responseClientId =
            parsedDashboardResponse.data?.activeClientId;

        // The backend is the authority for the active client. Never publish a
        // Dashboard response that belongs to a different account than the one
        // that initiated this request.
        if (expectedClientId != null &&
            responseClientId != null &&
            expectedClientId != responseClientId) {
          debugPrint(
            '[HOME STALE] dashboard client mismatch ignored '
            '| expected=$expectedClientId | response=$responseClientId',
          );
          return false;
        }

        // Publish only after all stale/mismatch guards have passed. This keeps
        // the previous client's Dashboard intact if the new switch fails.
        dashboardResponse = parsedDashboardResponse;

        if (context.mounted) {
          context.read<FamilyProvider>().setFamilyList(
            parsedDashboardResponse.data?.familyList ?? [],
          );

          context.read<ClientSwitchProvider>().syncFromDashboard(
            parsedDashboardResponse.data,
          );
        }

        // Never show the previous client's chart while a newly selected
        // Family / Partner / Readonly-Admin account loads its own chart.
        final newActiveClientId = parsedDashboardResponse.data?.activeClientId;
        if (previousActiveClientId != null &&
            newActiveClientId != null &&
            previousActiveClientId != newActiveClientId) {
          portfolioChartResponse = null;
        }

        if (portfolioChartResponse == null) {
          _portfolioChartLoading = true;
        }

        notifyListeners();
        return true;
      }

      showError(parsedDashboardResponse.message ?? "Something went wrong");
      return false;
    } catch (e) {
      // Ignore errors from a request that became obsolete because another
      // client/request replaced it while it was in flight.
      if (requestVersion != _dashboardRequestVersion ||
          SessionManager.userId != requestedUserId) {
        debugPrint(
          '[HOME STALE] dashboard error ignored | requestedUserId=$requestedUserId '
          '| currentUserId=${SessionManager.userId} | error=$e',
        );
        return false;
      }

      debugPrint(
        '[HOME ERROR] DASHBOARD ========> ${e.runtimeType}: ${e.toString()}',
      );

      if (e is SocketException) {
        showError("No internet connection. Please check your network.");
      } else {
        showError("Something went wrong. Please try again.");
      }
      return false;
    } finally {
      // An older request must not clear the loading state of a newer request.
      if (requestVersion == _dashboardRequestVersion) {
        _dashboardLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> refreshDashboard(
    BuildContext context, {
    required bool isRefresh,
  }) async {
    final dashboardLoaded = await getDashboard(context, isRefresh: isRefresh);

    // The dashboard summary is the data the user needs first.
    // Do not keep the screen / pull-to-refresh waiting for the chart API.
    if (dashboardLoaded && context.mounted) {
      loadPortfolioChartInBackground(context, isRefresh: isRefresh);
    }

    return dashboardLoaded;
  }

  void loadPortfolioChartInBackground(
    BuildContext context, {
    bool isRefresh = false,
  }) {
    unawaited(getPortfolioChart(context, isRefresh: isRefresh));
  }

  /// Updates only the selected chart period without making another API call.
  /// The separate portfolio-chart endpoint returns full history once, and
  /// HomeScreen filters 1M / 3M / 1Y / MAX locally for both chart modes.
  void updateChartTypeLocally(String period) {
    chartType = period;
    notifyListeners();
  }

  Future<void> updateChartType(BuildContext context, String period) async {
    // Kept for compatibility with any existing caller. Full chart history is
    // already loaded by the background request, so period changes are local.
    updateChartTypeLocally(period);
  }

  Future<bool> getPortfolioChart(
    BuildContext context, {
    bool isRefresh = false,
  }) async {
    final int requestVersion = ++_portfolioChartRequestVersion;
    final String requestedUserId = SessionManager.userId;

    try {
      if (!isRefresh) {
        _portfolioChartLoading = true;
        notifyListeners();
      }

      final body = {"chart_type": chartType, "start_date": "", "end_date": ""};

      final Response? response = await httpPost(CMD.portfolioChartFull, body);

      // A client switch or a newer chart request superseded this response.
      if (requestVersion != _portfolioChartRequestVersion ||
          SessionManager.userId != requestedUserId) {
        debugPrint(
          '[HOME STALE] portfolio-chart-full ignored '
          '| requestedUserId=$requestedUserId '
          '| currentUserId=${SessionManager.userId}',
        );
        return false;
      }

      if (response == null) {
        return false;
      }

      final parsedChartResponse = portfolioChartResponseFromJson(response.body);

      if (response.statusCode == 200 &&
          parsedChartResponse.status == 200 &&
          parsedChartResponse.data != null) {
        final int? expectedClientId = int.tryParse(requestedUserId);
        final int? responseClientId = parsedChartResponse.data?.activeClientId;

        if (expectedClientId != null &&
            responseClientId != null &&
            expectedClientId != responseClientId) {
          debugPrint(
            '[HOME STALE] portfolio-chart-full client mismatch ignored '
            '| expected=$expectedClientId | response=$responseClientId',
          );
          return false;
        }

        portfolioChartResponse = parsedChartResponse;
        notifyListeners();
        return true;
      }

      showError(parsedChartResponse.message ?? "Something went wrong");
      return false;
    } catch (e) {
      if (requestVersion != _portfolioChartRequestVersion ||
          SessionManager.userId != requestedUserId) {
        debugPrint(
          '[HOME STALE] portfolio-chart-full error ignored '
          '| requestedUserId=$requestedUserId '
          '| currentUserId=${SessionManager.userId} | error=$e',
        );
        return false;
      }

      debugPrint(
        '[HOME ERROR] PORTFOLIO-CHART-FULL ========> '
        '${e.runtimeType}: ${e.toString()}',
      );

      if (e is SocketException) {
        showError("No internet connection. Please check your network.");
      } else {
        showError("Something went wrong. Please try again.");
      }
      return false;
    } finally {
      // A stale/older chart request must not stop the spinner for a newer one.
      if (requestVersion == _portfolioChartRequestVersion) {
        _portfolioChartLoading = false;
        notifyListeners();
      }
    }
  }
}
