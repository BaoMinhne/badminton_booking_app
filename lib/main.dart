import 'package:badminton_booking_app/pages/court/court_manager.dart';
import 'package:badminton_booking_app/pages/nav_bar_page.dart';
import 'package:badminton_booking_app/pages/user/user_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:badminton_booking_app/pages/auth/login_page.dart';
import 'package:badminton_booking_app/pages/auth/auth_manager.dart';
import 'package:badminton_booking_app/themes/main_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('vi_VN');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthManager()),
        ChangeNotifierProvider(create: (_) => UserManager()),
        ChangeNotifierProvider(create: (_) => CourtManager()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: mainTheme,
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthManager>(
      builder: (_, authManager, __) {
        if (authManager.isChecking) {
          return const SplashScreen();
        }

        if (authManager.isAuth) {
          return const NavBarPage();
        }

        return const LoginPage();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.5;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "assets/images/logo_splash.png",
              width: logoSize,
              height: logoSize,
            ),
            Text(
              "C O U R T I F Y",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
