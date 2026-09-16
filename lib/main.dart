import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'utils/theme.dart';
import 'providers/expense_provider.dart';
import 'providers/lending_provider.dart';
import 'providers/theme_provider.dart';
import 'utils/notification_service.dart';
import 'screens/main_screen.dart';
import 'widgets/splash_widget.dart';
import 'providers/security_provider.dart';
import 'screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await NotificationService.instance.init();
  await NotificationService.instance.scheduleDailyReminder();
  runApp(const SpendWiseApp());
}

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => LendingProvider()),
        ChangeNotifierProvider(create: (_) => SecurityProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'SpendWise',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            home: const _AppLoader(),
          );
        },
      ),
    );
  }
}

class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([
      context.read<ExpenseProvider>().init(),
      context.read<LendingProvider>().loadAll(),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    // Check if user has enabled the lock
    final isSecure = context.watch<SecurityProvider>().isSecure;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: !_ready 
          ? const SplashWidget() 
          : (isSecure ? const LockScreen() : const MainScreen()), 
    );
  }
}