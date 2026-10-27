import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'common_wigdets/app_toast.dart';
import 'constants/app_config.dart';
import 'constants/brand_theme.dart';
import 'features/splash/splash_screen.dart';
import 'helpers/navigation_service.dart';
import 'networks/api_client.dart';
import 'provider/auth_provider.dart';
import 'provider/cart_provider.dart';
import 'provider/session_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const MedivilaApp());
}

typedef BrandSourceApp = MedivilaApp;

class MedivilaApp extends StatelessWidget {
  const MedivilaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => NotificationBadge()),
      ],
      child: const _SessionBridge(
        child: _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, _) => GetMaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        themeMode: ThemeMode.light,
        navigatorKey: NavigationService.navigatorKey,
        home: const SplashScreen(),
        builder: EasyLoading.init(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.of(context).textScaler.clamp(maxScaleFactor: 1.2),
            ),
            child: child!,
          ),
        ),
      ),
    );
  }
}

/// Wires login/logout to wishlist + notification badge, and handles an
/// expired session (refresh token rejected) from the API client.
class _SessionBridge extends StatefulWidget {
  const _SessionBridge({required this.child});
  final Widget child;

  @override
  State<_SessionBridge> createState() => _SessionBridgeState();
}

class _SessionBridgeState extends State<_SessionBridge> with WidgetsBindingObserver {
  bool? _wasLoggedIn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final auth = context.read<AuthProvider>();
    ApiClient.instance.onSessionExpired = () {
      if (!auth.loggedIn) return;
      auth.expire();
      AppToast.info('আপনার সেশন শেষ হয়ে গেছে। অনুগ্রহ করে আবার সাইন ইন করুন।');
    };
    auth.addListener(_onAuth);
  }

  void _onAuth() {
    final auth = context.read<AuthProvider>();
    if (_wasLoggedIn == auth.loggedIn) return;
    _wasLoggedIn = auth.loggedIn;
    if (auth.loggedIn) {
      if (!auth.isSeller) context.read<WishlistProvider>().load();
      context.read<NotificationBadge>().start();
    } else {
      context.read<WishlistProvider>().reset();
      context.read<NotificationBadge>().stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && context.read<AuthProvider>().loggedIn) {
      context.read<NotificationBadge>().refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
