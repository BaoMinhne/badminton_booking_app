import 'package:badminton_booking_app/pages/auth/auth_manager.dart';
import 'package:badminton_booking_app/pages/auth/login_page.dart';
import 'package:badminton_booking_app/pages/court/court_manager.dart';
import 'package:badminton_booking_app/pages/nav_bar_page.dart';
import 'package:badminton_booking_app/pages/user/onboarding_page.dart';
import 'package:badminton_booking_app/pages/user/user_manager.dart';
import 'package:badminton_booking_app/themes/main_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => AuthManager(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => UserManager(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => CourtManager(),
        ),
      ],
      child: Consumer<AuthManager>(
        builder: (ctx, authManager, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: mainTheme,
            home: const AppHome(),
          );
        },
      ),
    );
  }
}

class AppHome extends StatelessWidget {
  const AppHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthManager>(
      builder: (ctx, authManager, _) {
        if (authManager.isAuth) {
          return const _OnboardingGate();
        }

        return FutureBuilder<bool>(
          future: authManager.tryAutoLogin(),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.data == true) {
              return const _OnboardingGate();
            }

            return const LoginPage();
          },
        );
      },
    );
  }
}

class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate({super.key});

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  late Future<bool> _future;
  UserManager? _userManager;

  @override
  void initState() {
    super.initState();
    final manager = context.read<UserManager>();
    _userManager = manager;
    _future = manager.hasCompletedOnboarding();
    manager.addListener(_handleUserManagerChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final manager = Provider.of<UserManager>(context);
    if (!identical(manager, _userManager)) {
      _userManager?.removeListener(_handleUserManagerChange);
      _userManager = manager;
      _future = manager.hasCompletedOnboarding();
      manager.addListener(_handleUserManagerChange);
    }
  }

  @override
  void dispose() {
    _userManager?.removeListener(_handleUserManagerChange);
    super.dispose();
  }

  void _handleUserManagerChange() {
    if (!mounted || _userManager == null) return;
    setState(() {
      _future = _userManager!.hasCompletedOnboarding();
    });
  }

  void _retry() {
    setState(() {
      _future = (_userManager ?? context.read<UserManager>())
          .hasCompletedOnboarding();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _future,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Không thể tải thông tin người dùng.'),
                  const SizedBox(height: 12),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _retry,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          return const NavBarPage();
        }

        return const OnboardingPage();
      },
    );
  }
}
