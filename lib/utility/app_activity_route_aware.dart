import 'package:flutter/material.dart';
import 'package:profit_from_it_investors/network/app_activity_service.dart';

/// Shares a single route observer across the entire Investor App.
/// RouteAware avoids logging duplicate screen views on widget rebuilds and
/// restores the previous page when the user returns via Back.
final RouteObserver<PageRoute<dynamic>> appActivityRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

mixin AppActivityRouteAware<T extends StatefulWidget> on State<T>
    implements RouteAware {
  PageRoute<dynamic>? _activityRoute;

  String get activityScreenKey;

  void reportActivityScreen() {
    AppActivityService.instance.reportScreen(activityScreenKey);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && _activityRoute != route) {
      appActivityRouteObserver.unsubscribe(this);
      _activityRoute = route;
      appActivityRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPush() => reportActivityScreen();

  @override
  void didPopNext() => reportActivityScreen();

  @override
  void didPop() {}

  @override
  void didPushNext() {}

  @override
  void dispose() {
    appActivityRouteObserver.unsubscribe(this);
    super.dispose();
  }
}
