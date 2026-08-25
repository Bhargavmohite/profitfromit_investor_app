import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:profit_from_it_investors/provider/analytics_provider/analytics_provider.dart';
import 'package:profit_from_it_investors/provider/authentication/auth_provider.dart';
import 'package:profit_from_it_investors/provider/authentication/profile_provider.dart';
import 'package:profit_from_it_investors/provider/authentication/user_provider.dart';
import 'package:profit_from_it_investors/provider/family/family_provider.dart';
import 'package:profit_from_it_investors/provider/holdings/holdings_provider.dart';
import 'package:profit_from_it_investors/provider/home/home_provider.dart';
import 'package:profit_from_it_investors/provider/stock_detail/stock_detail_provider.dart';
import 'package:profit_from_it_investors/provider/transaction_provider/transaction_provider.dart';
import 'package:profit_from_it_investors/provider/watchlist_provider/watchlist_provider.dart';
import 'package:profit_from_it_investors/theme/app_theme.dart';
import 'package:profit_from_it_investors/ui/splash_screen/splash_screen.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/constant.dart';
import 'package:profit_from_it_investors/utility/session_manager.dart';
import 'package:provider/provider.dart';

import 'package:timezone/data/latest.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await initializeDateFormatting();
  tz.initializeTimeZones();

  await SessionManager.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => StockDetailProvider()),
        ChangeNotifierProvider(create: (_) => HoldingsProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        title: Constants.appName,
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
