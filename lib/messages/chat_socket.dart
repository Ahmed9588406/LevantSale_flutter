import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../api/auth/auth_config.dart';

class ChatSocket {
  final String token;
  final void Function(Map<String, dynamic> message)? onMessage;
  final void Function(Map<String, dynamic> status)? onStatus;
  final void Function(Map<String, dynamic> presence)? onPresence;

  StompClient? _client;

  ChatSocket({
    required this.token,
    this.onMessage,
    this.onStatus,
    this.onPresence,
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
          _subscribe();
        },
        onWebSocketError: (err) {
          // ignore
        },
        onStompError: (frame) {
          // ignore
        },
        onDisconnect: (frame) {},
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
          onMessage?.call(data);
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

  void sendMessage(Map<String, dynamic> payload) {
    publish(destination: '/app/chat.send', body: jsonEncode(payload));
  }

  void markSeen(String userId) {
    publish(destination: '/app/chat.seen', body: jsonEncode(userId));
  }

  void disconnect() {
    // announce offline presence
    publish(destination: '/app/presence.offline', body: '');
    _client?.deactivate();
    _client = null;
  }
}
