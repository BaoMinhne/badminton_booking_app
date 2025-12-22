import 'package:badminton_booking_app/pages/court/court_manager.dart';
import 'package:badminton_booking_app/pages/court/favorite_court_manager.dart';
import 'package:badminton_booking_app/pages/nav_bar_page.dart';
import 'package:badminton_booking_app/pages/social/social_manager.dart';
import 'package:badminton_booking_app/pages/user/user_manager.dart';
import 'package:badminton_booking_app/pages/manager/manager_nav_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:badminton_booking_app/pages/auth/login_page.dart';
import 'package:badminton_booking_app/pages/auth/auth_manager.dart';
import 'package:badminton_booking_app/themes/main_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('vi_VN');
  _configureStripe();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthManager()),
        ChangeNotifierProvider(create: (_) => UserManager()),
        ChangeNotifierProvider(create: (_) => CourtManager()),
        ChangeNotifierProvider(create: (_) => FavoriteCourtManager()),
        ChangeNotifierProvider(create: (_) => SocialManager()),
      ],
      child: const MyApp(),
    ),
  );
}

void _configureStripe() {
  final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
  if (publishableKey == null || publishableKey.isEmpty) {
    throw StateError('Missing STRIPE_PUBLISHABLE_KEY in .env');
  }
  Stripe.publishableKey = publishableKey;
  final merchantIdentifier = dotenv.env['STRIPE_MERCHANT_IDENTIFIER'];
  if (merchantIdentifier != null && merchantIdentifier.isNotEmpty) {
    Stripe.merchantIdentifier = merchantIdentifier;
  }
  Stripe.instance.applySettings();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: mainTheme,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('en'),
        Locale('vi'),
      ],
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
          if (authManager.user?.role == 'manager') {
            return const ManagerNavPage();
          }
          return const NavBarPage();
        }

        return const LoginPage();
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _logoReady = false;
  bool _logoFailed = false;

  @override
  void initState() {
    super.initState();
    _precacheLogo();
  }

  Future<void> _precacheLogo() async {
    try {
      await precacheImage(
        const AssetImage("assets/images/logo_splash.png"),
        context,
      );
      if (mounted) {
        setState(() => _logoReady = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _logoFailed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.45;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.95),
              colorScheme.primary.withOpacity(0.75)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _logoFailed
                        ? _LogoFallback(logoSize: logoSize)
                        : Image.asset(
                            "assets/images/logo_splash.png",
                            key: const ValueKey("splash-logo"),
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.cover,
                            frameBuilder: (
                              context,
                              child,
                              frame,
                              wasSynchronouslyLoaded,
                            ) {
                              if (frame != null && !_logoReady && mounted) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) setState(() => _logoReady = true);
                                });
                              }
                              if (frame == null && !_logoReady) {
                                return _LogoFallback(logoSize: logoSize);
                              }
                              return child;
                            },
                            errorBuilder: (context, error, stackTrace) {
                              if (!_logoFailed && mounted) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted) setState(() => _logoFailed = true);
                                });
                              }
                              return _LogoFallback(logoSize: logoSize);
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "C O U R T I F Y",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({required this.logoSize});

  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey("splash-fallback"),
      width: logoSize,
      height: logoSize,
      color: Colors.white.withOpacity(0.1),
      child: Icon(
        Icons.sports_tennis,
        color: Colors.white.withOpacity(0.8),
        size: logoSize * 0.45,
      ),
    );
  }
}
