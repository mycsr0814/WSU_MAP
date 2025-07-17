import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/managers/location_manager.dart';
import 'package:flutter_application_1/map/map_screen.dart';
import 'package:flutter_application_1/welcome_view.dart';
import 'package:flutter_application_1/selection/auth_selection_view.dart';
import 'package:flutter_application_1/map/widgets/directions_screen.dart'; // 🔥 추가
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'auth/user_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/app_localizations.dart';
import 'providers/app_language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FlutterNaverMap().init(
      clientId: 'gxa5mf6swg',
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
        ChangeNotifierProvider(create: (_) => LocationManager()), // 반드시 추가
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

class _CampusNavigatorAppState extends State<CampusNavigatorApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('=== 앱 초기화 시작 ===');
      final userAuth = Provider.of<UserAuth>(context, listen: false);
      await userAuth.initialize();
      debugPrint('=== 앱 초기화 완료 ===');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ 앱 초기화 오류: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLanguageProvider>(
      builder: (context, langProvider, _) {
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
          // 🔥 추가: 라우트 설정
          routes: {
            '/directions': (context) {
              // arguments로 방 정보를 받아서 DirectionsScreen에 전달
              final args =
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;

              if (args != null) {
                return DirectionsScreen(roomData: args);
              } else {
                return const DirectionsScreen();
              }
            },
          },
          home: _isInitialized
              ? Consumer<UserAuth>(
                  builder: (context, auth, _) {
                    if (auth.isFirstLaunch) {
                      return const WelcomeView(); // 파라미터 없이
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

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }

  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}
