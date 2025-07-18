// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/managers/location_manager.dart';
import 'package:flutter_application_1/map/map_screen.dart';
import 'package:flutter_application_1/welcome_view.dart';
import 'package:flutter_application_1/selection/auth_selection_view.dart';
import 'package:flutter_application_1/map/widgets/directions_screen.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'auth/user_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/app_localizations.dart';
import 'providers/app_language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FlutterNaverMap().init(
      clientId: 'a7hukqhx2a',
      onAuthFailed: (ex) => debugPrint('NaverMap 인증 실패: $ex'),
    );
    debugPrint('✅ 네이버 지도 초기화 성공');
  } catch (e) {
    debugPrint('❌ 네이버 지도 초기화 오류: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserAuth()),
        ChangeNotifierProvider(create: (_) => AppLanguageProvider()),
        ChangeNotifierProvider(create: (_) => LocationManager()),
      ],
      child: const CampusNavigatorApp(),
    ),
  );
}

class CampusNavigatorApp extends StatefulWidget {
  const CampusNavigatorApp({super.key});

  @override
  State<CampusNavigatorApp> createState() => _CampusNavigatorAppState();
}

/// 앱 생명주기 모니터링
class _CampusNavigatorAppState extends State<CampusNavigatorApp>
    with WidgetsBindingObserver {
  bool _isInitialized = false;

  late final UserAuth _userAuth;
  late final LocationManager _locationManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // provider 인스턴스 캐싱
    _userAuth = Provider.of<UserAuth>(context, listen: false);
    _locationManager = Provider.of<LocationManager>(context, listen: false);

    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ---------- 앱 생명주기 콜백 ----------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('📱 앱 포그라운드 복귀');
        _handleAppResumed();
        break;

      case AppLifecycleState.paused:
        debugPrint('📱 앱 백그라운드 이동');
        _handleAppPausedOrDetached();
        break;

      case AppLifecycleState.detached:
        debugPrint('📱 앱 종료(detached)');
        _handleAppPausedOrDetached();
        break;

      default:
        break;
    }
  }

  // ---------- 상태별 처리 ----------
  /// 포그라운드 복귀
  Future<void> _handleAppResumed() async {
    if (!_userAuth.isLoggedIn || _userAuth.userId == 'guest') return;

    try {
      // rememberMe 저장돼 있으면 서버 재로그인
      if (await _userAuth.hasSavedLoginInfo()) {
        await _userAuth.autoLoginToServer();
      }

      // 🔥 위치 전송 재시작 (userId 전달)
      if (_userAuth.userId != null) {
        _locationManager.startPeriodicLocationSending(
          userId: _userAuth.userId!,
        );
      }
    } catch (e) {
      debugPrint('❌ 포그라운드 복귀 처리 오류: $e');
    }
  }

  /// 백그라운드 이동 ‑ 또는 프로세스가 종료 직전(detached)
  Future<void> _handleAppPausedOrDetached() async {
    if (!_userAuth.isLoggedIn || _userAuth.userId == 'guest') return;

    try {
      // 주기적 위치 전송 중지
      _locationManager.stopPeriodicLocationSending();

      // 서버에만 is_login false 처리 (토큰/로컬 세션 유지)
      await _userAuth.logoutServerOnly();
    } catch (e) {
      debugPrint('❌ 백그라운드/종료 처리 오류: $e');
    }
  }

  // ---------- 앱 초기화 ----------
  Future<void> _initializeApp() async {
    try {
      debugPrint('=== 앱 초기화 시작 ===');
      await _userAuth.initialize();

      // 이미 로그인돼 있으면 서버에 세션 알림 + 위치 전송 시작
      if (_userAuth.isLoggedIn &&
          _userAuth.userId != 'guest' &&
          _userAuth.userId != null) {
        await _userAuth.autoLoginToServer();

        // 🔥 위치 전송 시작 (userId 전달)
        _locationManager.startPeriodicLocationSending(
          userId: _userAuth.userId!,
        );
      }

      debugPrint('=== 앱 초기화 완료 ===');
    } catch (e) {
      debugPrint('❌ 앱 초기화 오류: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Consumer<AppLanguageProvider>(
      builder: (_, langProvider, __) {
        return MaterialApp(
          title: 'Campus Navigator',
          theme: ThemeData(
            primarySwatch: createMaterialColor(const Color(0xFF1E3A8A)),
            fontFamily: 'Pretendard',
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          locale: langProvider.locale,
          supportedLocales: const [Locale('ko'), Locale('en'), Locale('zh')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routes: {
            '/directions': (context) {
              final args =
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;
              return DirectionsScreen(roomData: args);
            },
          },
          home: _isInitialized
              ? Consumer<UserAuth>(
                  builder: (_, auth, __) {
                    if (auth.isFirstLaunch) {
                      return const WelcomeView();
                    } else if (auth.isLoggedIn) {
                      return const MapScreen();
                    } else {
                      return const AuthSelectionView();
                    }
                  },
                )
              : _buildLoadingScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.school, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 32),
              const Text(
                '우송대학교',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '캠퍼스 네비게이터',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '초기화 중...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
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

// ---------- 색상 유틸 ----------
MaterialColor createMaterialColor(Color color) {
  final strengths = <double>[.05];
  final swatch = <int, Color>{};
  final r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) strengths.add(0.1 * i);

  for (var strength in strengths) {
    final ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}
