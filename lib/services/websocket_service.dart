// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/services/notification_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  String? _userId;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _reconnectDelay = Duration(seconds: 5);

  // 이벤트 스트림 컨트롤러들
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<List<String>> _onlineUsersController =
      StreamController<List<String>>.broadcast();

  // 공개 스트림
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<List<String>> get onlineUsersStream => _onlineUsersController.stream;

  bool get isConnected => _isConnected;
  String? get userId => _userId;

  // 🔌 웹소켓 연결
  Future<void> connect(String userId) async {
    if (_isConnected && _userId == userId) {
      debugPrint('⚠️ 이미 연결되어 있습니다: $userId');
      return;
    }

    _userId = userId;
    _shouldReconnect = true;
    _reconnectAttempts = 0;

    await _doConnect();
  }

  // 실제 연결 수행
  Future<void> _doConnect() async {
    try {
      await disconnect(); // 기존 연결 정리

      final wsUrl = 'ws://13.236.152.239:3002/friend/ws';
      debugPrint('🔌 웹소켓 연결 시도: $wsUrl');

      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: ['chat'], // 프로토콜 지정 (선택사항)
      );

      // 연결 확인을 위한 타임아웃
      await _channel!.ready.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('웹소켓 연결 타임아웃', const Duration(seconds: 10));
        },
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionController.add(true);

      debugPrint('✅ 웹소켓 연결 성공');

      // 사용자 등록
      _sendMessage({
        'type': 'register',
        'userId': _userId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // 메시지 수신 리스너 설정
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      // 하트비트 시작
      _startHeartbeat();
    } catch (e) {
      debugPrint('❌ 웹소켓 연결 실패: $e');
      _isConnected = false;
      _connectionController.add(false);

      if (_shouldReconnect) {
        _scheduleReconnect();
      }
    }
  }

  // 📨 메시지 수신 처리
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      debugPrint('📨 웹소켓 메시지 수신: ${data['type']}');

      // 메시지 타입별 처리
      switch (data['type']) {
        case 'registered':
          debugPrint('✅ 서버 등록 완료: ${data['message']}');
          break;

        case 'heartbeat':
          _sendMessage({
            'type': 'heartbeat_response',
            'timestamp': DateTime.now().toIso8601String(),
          });
          break;

        case 'heartbeat_response':
          debugPrint('💓 하트비트 응답 수신');
          break;

        case 'online_users_update':
          final onlineUsers = List<String>.from(data['onlineUsers'] ?? []);
          _onlineUsersController.add(onlineUsers);
          debugPrint('👥 온라인 사용자 업데이트: ${onlineUsers.length}명');
          break;

        case 'new_friend_request':
          _handleNewFriendRequest(data);
          break;

        case 'friend_request_accepted':
          _handleFriendRequestAccepted(data);
          break;

        case 'friend_request_rejected':
          _handleFriendRequestRejected(data);
          break;

        case 'friend_deleted':
          _handleFriendDeleted(data);
          break;

        case 'friend_status_change':
          _handleFriendStatusChange(data);
          break;

        default:
          debugPrint('⚠️ 알 수 없는 메시지 타입: ${data['type']}');
      }

      // 모든 메시지를 스트림으로 전달
      _messageController.add(data);
    } catch (e) {
      debugPrint('❌ 메시지 파싱 오류: $e');
    }
  }

  // 🔔 새로운 친구 요청 처리
  void _handleNewFriendRequest(Map<String, dynamic> data) {
    final fromUserName = data['fromUserName'] ?? '알 수 없는 사용자';
    debugPrint('🔔 새로운 친구 요청: $fromUserName');

    // 로컬 알림 표시
    NotificationService.showFriendRequestNotification(
      fromUserName,
      data['message'] ?? '새로운 친구 요청이 도착했습니다.',
    );
  }

  // ✅ 친구 요청 수락 처리
  void _handleFriendRequestAccepted(Map<String, dynamic> data) {
    final accepterUserName = data['accepterUserName'] ?? '알 수 없는 사용자';
    debugPrint('✅ 친구 요청 수락됨: $accepterUserName');

    NotificationService.showFriendAcceptedNotification(
      accepterUserName,
      data['message'] ?? '친구 요청이 수락되었습니다.',
    );
  }

  // ❌ 친구 요청 거절 처리
  void _handleFriendRequestRejected(Map<String, dynamic> data) {
    debugPrint('❌ 친구 요청 거절됨');

    NotificationService.showFriendRejectedNotification('친구 요청이 거절되었습니다.');
  }

  // 🗑️ 친구 삭제 처리
  void _handleFriendDeleted(Map<String, dynamic> data) {
    final deleterUserName = data['deleterUserName'] ?? '알 수 없는 사용자';
    debugPrint('🗑️ 친구 삭제됨: $deleterUserName');

    NotificationService.showFriendDeletedNotification(
      deleterUserName,
      data['message'] ?? '친구 관계가 해제되었습니다.',
    );
  }

  // 📶 친구 상태 변경 처리
  void _handleFriendStatusChange(Map<String, dynamic> data) {
    final userId = data['userId'];
    final isOnline = data['isOnline'] ?? false;
    debugPrint('📶 친구 상태 변경: $userId - ${isOnline ? '온라인' : '오프라인'}');

    // FriendsController에 상태 변경 알림
    // 이벤트 버스나 상태 관리를 통해 UI 업데이트
  }

  // 📤 메시지 전송
  void _sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(message));
        debugPrint('📤 메시지 전송: ${message['type']}');
      } catch (e) {
        debugPrint('❌ 메시지 전송 실패: $e');
      }
    } else {
      debugPrint('⚠️ 웹소켓 연결되지 않음 - 메시지 전송 실패');
    }
  }

  // 💓 하트비트 시작
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_isConnected) {
        _sendMessage({
          'type': 'heartbeat',
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        timer.cancel();
      }
    });
  }

  // ❌ 오류 처리
  void _handleError(error) {
    debugPrint('❌ 웹소켓 오류: $error');
    _isConnected = false;
    _connectionController.add(false);

    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  // 🔌 연결 해제 처리
  void _handleDisconnection() {
    debugPrint('🔌 웹소켓 연결 해제됨');
    _isConnected = false;
    _connectionController.add(false);

    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  // 🔄 재연결 스케줄링
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('🛑 최대 재연결 시도 횟수 초과');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(
      seconds: _reconnectDelay.inSeconds * _reconnectAttempts,
    );

    debugPrint(
      '🔄 ${delay.inSeconds}초 후 재연결 시도 ($_reconnectAttempts/$_maxReconnectAttempts)',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_shouldReconnect && !_isConnected) {
        _doConnect();
      }
    });
  }

  // 🔌 연결 해제
  Future<void> disconnect() async {
    debugPrint('🔌 웹소켓 연결 해제 중...');

    _shouldReconnect = false;
    _isConnected = false;

    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    await _subscription?.cancel();
    await _channel?.sink.close(status.goingAway);

    _subscription = null;
    _channel = null;

    _connectionController.add(false);
    debugPrint('✅ 웹소켓 연결 해제 완료');
  }

  // 🧹 리소스 정리
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
    _onlineUsersController.close();
  }
}
