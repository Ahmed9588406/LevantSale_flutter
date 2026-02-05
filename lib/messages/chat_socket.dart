import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../api/auth/auth_config.dart';
import 'models/chat_models.dart';

class ChatSocket {
  final String token;
  final void Function(ChatMessageApi message)? onMessage;
  final void Function(Map<String, dynamic> status)? onStatus;
  final void Function(Map<String, dynamic> presence)? onPresence;
  final void Function()? onConnected;
  final void Function()? onDisconnected;
  final void Function(dynamic error)? onError;

  StompClient? _client;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  ChatSocket({
    required this.token,
    this.onMessage,
    this.onStatus,
    this.onPresence,
    this.onConnected,
    this.onDisconnected,
    this.onError,
  });

  String get _sockJsUrl {
    // SockJS endpoint used by the backend
    return '${AuthConfig.baseUrl}/ws';
  }

  void connect() {
    if (_client?.connected == true) return;
    _client = StompClient(
      config: StompConfig.SockJS(
        url: _sockJsUrl,
        stompConnectHeaders: {
          'Authorization': token.startsWith('Bearer') ? token : 'Bearer $token',
        },
        webSocketConnectHeaders: {
          'Authorization': token.startsWith('Bearer') ? token : 'Bearer $token',
        },
        onConnect: (frame) {
          _isConnected = true;
          _subscribe();
          onConnected?.call();
        },
        onWebSocketError: (err) {
          _isConnected = false;
          onError?.call(err);
        },
        onStompError: (frame) {
          _isConnected = false;
          onError?.call(frame);
        },
        onDisconnect: (frame) {
          _isConnected = false;
          onDisconnected?.call();
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client?.activate();
  }

  void _subscribe() {
    final c = _client;
    if (c == null || c.connected == false) return;

    c.subscribe(
      destination: '/user/queue/messages',
      callback: (StompFrame f) {
        try {
          final data = jsonDecode(f.body ?? '{}') as Map<String, dynamic>;
          final message = ChatMessageApi.fromJson(data);
          onMessage?.call(message);
        } catch (_) {}
      },
    );

    c.subscribe(
      destination: '/user/queue/status',
      callback: (StompFrame f) {
        try {
          final data = jsonDecode(f.body ?? '{}') as Map<String, dynamic>;
          onStatus?.call(data);
        } catch (_) {}
      },
    );

    c.subscribe(
      destination: '/topic/presence',
      callback: (StompFrame f) {
        try {
          final data = jsonDecode(f.body ?? '{}') as Map<String, dynamic>;
          onPresence?.call(data);
        } catch (_) {}
      },
    );

    // announce presence
    publish(destination: '/app/presence.online', body: '');
  }

  void publish({required String destination, String body = ''}) {
    final c = _client;
    if (c == null || c.connected == false) return;
    c.send(destination: destination, body: body);
  }

  /// Send a chat message with full payload support
  void sendMessage({
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.TEXT,
    String? fileUrl,
    String? fileName,
    String? fileType,
    int? fileSize,
  }) {
    final payload = {
      'receiverId': receiverId,
      'content': content,
      'messageType': messageType.name,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileType != null) 'fileType': fileType,
      if (fileSize != null) 'fileSize': fileSize,
    };
    publish(destination: '/app/chat.send', body: jsonEncode(payload));
  }

  void markSeen(String userId) {
    publish(destination: '/app/chat.seen', body: jsonEncode(userId));
  }

  void disconnect() {
    // announce offline presence
    if (_isConnected) {
      publish(destination: '/app/presence.offline', body: '');
    }
    _isConnected = false;
    _client?.deactivate();
    _client = null;
  }
}
