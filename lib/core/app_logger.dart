// lib/core/app_logger.dart - 수정된 버전 (Result 충돌 해결)
import 'package:flutter/foundation.dart';

/// 🔥 로그 레벨 enum (클래스 외부로 이동)
enum LogLevel {
  debug(0, '🐛', 'DEBUG'),
  info(1, 'ℹ️', 'INFO'),
  warning(2, '⚠️', 'WARN'),
  error(3, '❌', 'ERROR'),
  critical(4, '🚨', 'CRITICAL');
  
  const LogLevel(this.value, this.emoji, this.name);
  final int value;
  final String emoji;
  final String name;
}

/// 🔥 통합 로깅 시스템
class AppLogger {
  static const String _appName = 'WoosongMap';
  static bool _isEnabled = true;
  static LogLevel _minimumLevel = LogLevel.debug;
  
  /// 로깅 설정
  static void configure({
    bool enabled = true,
    LogLevel minimumLevel = LogLevel.debug,
  }) {
    _isEnabled = enabled;
    _minimumLevel = minimumLevel;
  }
  
  /// 디버그 로그
  static void debug(String message, {String? tag, Object? extra}) {
    _log(LogLevel.debug, message, tag: tag, extra: extra);
  }
  
  /// 정보 로그
  static void info(String message, {String? tag, Object? extra}) {
    _log(LogLevel.info, message, tag: tag, extra: extra);
  }
  
  /// 경고 로그
  static void warning(String message, {String? tag, Object? extra}) {
    _log(LogLevel.warning, message, tag: tag, extra: extra);
  }
  
  /// 에러 로그
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, extra: error);
    if (stackTrace != null && kDebugMode) {
      debugPrint('📍 Stack Trace: $stackTrace');
    }
  }
  
  /// 크리티컬 로그
  static void critical(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.critical, message, tag: tag, extra: error);
    if (stackTrace != null && kDebugMode) {
      debugPrint('📍 Stack Trace: $stackTrace');
    }
  }
  
  /// 메인 로그 메서드
  static void _log(LogLevel level, String message, {String? tag, Object? extra}) {
    if (!_isEnabled || level.value < _minimumLevel.value) {
      return;
    }
    
    final timestamp = DateTime.now().toIso8601String();
    final tagStr = tag != null ? '[$tag]' : '';
    final extraStr = extra != null ? ' | Extra: $extra' : '';
    
    final logMessage = '${level.emoji} $_appName ${level.name} $timestamp $tagStr $message$extraStr';
    
    if (kDebugMode) {
      debugPrint(logMessage);
    }
    
    // 프로덕션에서는 외부 로깅 서비스로 전송 가능
    if (kReleaseMode && (level == LogLevel.error || level == LogLevel.critical)) {
      _sendToRemoteLogging(level, message, tag, extra);
    }
  }
  
  /// 원격 로깅 (프로덕션용)
  static void _sendToRemoteLogging(LogLevel level, String message, String? tag, Object? extra) {
    // Firebase Crashlytics, Sentry 등으로 전송
    // 현재는 구현하지 않음
  }
  
  /// Result<T> 전용 로깅 메서드들 (동적 타입 사용)
  static void logResult<T>(dynamic result, {String? tag, String? context}) {
    if (result != null) {
      final resultStr = result.toString();
      if (resultStr.contains('Success')) {
        info('${context ?? 'Operation'} 성공', tag: tag);
      } else if (resultStr.contains('Failure')) {
        error('${context ?? 'Operation'} 실패', tag: tag);
      }
    }
  }
  
  /// 비동기 Result 로깅
  static Future<T> logAsyncResult<T>(
    Future<T> futureResult, {
    String? tag,
    String? context,
  }) async {
    try {
      final result = await futureResult;
      logResult(result, tag: tag, context: context);
      return result;
    } catch (e, stackTrace) {
      error(
        '${context ?? 'Async operation'} 예외 발생: $e',
        tag: tag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

/// 🔥 도메인별 로거들
class MapLogger {
  static const String _tag = 'MAP';
  
  static void debug(String message, {Object? extra}) =>
      AppLogger.debug(message, tag: _tag, extra: extra);
  
  static void info(String message, {Object? extra}) =>
      AppLogger.info(message, tag: _tag, extra: extra);
  
  static void warning(String message, {Object? extra}) =>
      AppLogger.warning(message, tag: _tag, extra: extra);
  
  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      AppLogger.error(message, tag: _tag, error: error, stackTrace: stackTrace);
  
  static void markerAdded(String markerType, int count) =>
      info('마커 추가: $markerType ($count개)');
  
  static void cameraMove(double lat, double lng, double zoom) =>
      debug('카메라 이동: ($lat, $lng) zoom: $zoom');
  
  static void overlayOperation(String operation, String overlayId, bool success) =>
      success 
          ? debug('오버레이 $operation 성공: $overlayId')
          : error('오버레이 $operation 실패: $overlayId');
}

class ApiLogger {
  static const String _tag = 'API';
  
  static void debug(String message, {Object? extra}) =>
      AppLogger.debug(message, tag: _tag, extra: extra);
  
  static void info(String message, {Object? extra}) =>
      AppLogger.info(message, tag: _tag, extra: extra);
  
  static void warning(String message, {Object? extra}) =>
      AppLogger.warning(message, tag: _tag, extra: extra);
  
  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      AppLogger.error(message, tag: _tag, error: error, stackTrace: stackTrace);
  
  static void request(String method, String url, {Map<String, dynamic>? params}) =>
      debug('$method $url', extra: params);
  
  static void response(String url, int statusCode, {Object? data}) =>
      statusCode >= 200 && statusCode < 300
          ? debug('응답 성공: $url ($statusCode)')
          : error('응답 실패: $url ($statusCode)', error: data);
  
  static void timeout(String url, Duration duration) =>
      warning('API 타임아웃: $url (${duration.inSeconds}초)');
}

class CategoryLogger {
  static const String _tag = 'CATEGORY';
  
  static void debug(String message, {Object? extra}) =>
      AppLogger.debug(message, tag: _tag, extra: extra);
  
  static void info(String message, {Object? extra}) =>
      AppLogger.info(message, tag: _tag, extra: extra);
  
  static void warning(String message, {Object? extra}) =>
      AppLogger.warning(message, tag: _tag, extra: extra);
  
  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      AppLogger.error(message, tag: _tag, error: error, stackTrace: stackTrace);
  
  static void selection(String category, int buildingCount) =>
      info('카테고리 선택: $category (건물: ${buildingCount}개)');
  
  static void iconGeneration(String category, bool success) =>
      success
          ? debug('카테고리 아이콘 생성 성공: $category')
          : error('카테고리 아이콘 생성 실패: $category');
}

class SearchLogger {
  static const String _tag = 'SEARCH';
  
  static void debug(String message, {Object? extra}) =>
      AppLogger.debug(message, tag: _tag, extra: extra);
  
  static void info(String message, {Object? extra}) =>
      AppLogger.info(message, tag: _tag, extra: extra);
  
  static void warning(String message, {Object? extra}) =>
      AppLogger.warning(message, tag: _tag, extra: extra);
  
  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      AppLogger.error(message, tag: _tag, error: error, stackTrace: stackTrace);
  
  static void query(String query, int resultCount, Duration duration) =>
      info('검색 완료: "$query" (결과: ${resultCount}개, ${duration.inMilliseconds}ms)');
  
  static void indexBuild(int buildingCount, Duration duration) =>
      info('검색 인덱스 구축: ${buildingCount}개 건물 (${duration.inMilliseconds}ms)');
}

/// 🔥 Result와 Logger를 결합한 헬퍼 (동적 타입으로 처리)
extension ResultLogging on dynamic {
  dynamic log({String? tag, String? context}) {
    AppLogger.logResult(this, tag: tag, context: context);
    return this;
  }
  
  dynamic logOnFailure({String? tag, String? context}) {
    if (toString().contains('Failure')) {
      AppLogger.error(
        '${context ?? 'Operation'} 실패',
        tag: tag,
      );
    }
    return this;
  }
  
  dynamic logOnSuccess({String? tag, String? context}) {
    if (toString().contains('Success')) {
      AppLogger.info(
        '${context ?? 'Operation'} 성공',
        tag: tag,
      );
    }
    return this;
  }
}

/// 🔥 성능 측정 헬퍼
class PerformanceLogger {
  static const String _tag = 'PERF';
  
  /// 함수 실행 시간 측정
  static Future<T> measureAsync<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      AppLogger.info(
        '$operationName 완료 (${stopwatch.elapsedMilliseconds}ms)',
        tag: _tag,
      );
      return result;
    } catch (e) {
      stopwatch.stop();
      AppLogger.error(
        '$operationName 실패 (${stopwatch.elapsedMilliseconds}ms): $e',
        tag: _tag,
        error: e,
      );
      rethrow;
    }
  }
  
  /// 동기 함수 실행 시간 측정
  static T measure<T>(
    String operationName,
    T Function() operation,
  ) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = operation();
      stopwatch.stop();
      AppLogger.info(
        '$operationName 완료 (${stopwatch.elapsedMilliseconds}ms)',
        tag: _tag,
      );
      return result;
    } catch (e) {
      stopwatch.stop();
      AppLogger.error(
        '$operationName 실패 (${stopwatch.elapsedMilliseconds}ms): $e',
        tag: _tag,
        error: e,
      );
      rethrow;
    }
  }
}