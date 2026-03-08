import 'dart:async';
import '../models/chat_models.dart';
import '../chat_service.dart';
import '../chat_socket.dart';

/// Service to handle message seen status functionality
/// Matches the web implementation behavior exactly
class SeenStatusService {
  static final SeenStatusService _instance = SeenStatusService._internal();
  factory SeenStatusService() => _instance;
  SeenStatusService._internal();

  final Map<String, StreamController<int>> _unreadCountControllers = {};
  final Map<String, int> _unreadCounts = {};

  /// Get unread count stream for a specific conversation
  Stream<int> getUnreadCountStream(String conversationId) {
    if (!_unreadCountControllers.containsKey(conversationId)) {
      _unreadCountControllers[conversationId] =
          StreamController<int>.broadcast();
    }
    return _unreadCountControllers[conversationId]!.stream;
  }

  /// Update unread count for a conversation
  void updateUnreadCount(String conversationId, int count) {
    _unreadCounts[conversationId] = count;
    if (_unreadCountControllers.containsKey(conversationId)) {
      _unreadCountControllers[conversationId]!.add(count);
    }
  }

  /// Get current unread count for a conversation
  int getUnreadCount(String conversationId) {
    return _unreadCounts[conversationId] ?? 0;
  }

  /// Mark messages as seen (matches web implementation)
  Future<bool> markMessagesSeen({
    required String conversationId,
    required String currentUserId,
    ChatSocket? socket,
  }) async {
    try {
      // Use both WebSocket and HTTP API for reliability (like web)
      socket?.markSeen(conversationId);
      final success = await ChatService.markMessagesSeen(conversationId);

      if (success) {
        // Update local unread count
        updateUnreadCount(conversationId, 0);

        // Notify status update via WebSocket
        socket?.publish(
          destination: '/app/chat.status.update',
          body: conversationId,
        );
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  /// Process incoming message and update unread count
  void processIncomingMessage({
    required ChatMessageApi message,
    required String currentUserId,
    required String activeConversationId,
  }) {
    final conversationId = message.senderId == currentUserId
        ? message.receiverId
        : message.senderId;

    // Only increment unread count if:
    // 1. Message is from another user
    // 2. Message status is not already SEEN
    // 3. This conversation is not currently active (auto-mark as seen if active)
    if (message.senderId != currentUserId &&
        message.status != MessageStatus.seen) {
      if (conversationId == activeConversationId) {
        // Auto-mark as seen if this conversation is currently active
        markMessagesSeen(
          conversationId: conversationId,
          currentUserId: currentUserId,
        );
      } else {
        // Increment unread count for inactive conversations
        final currentCount = getUnreadCount(conversationId);
        updateUnreadCount(conversationId, currentCount + 1);
      }
    }
  }

  /// Process status update from WebSocket
  void processStatusUpdate({
    required Map<String, dynamic> statusData,
    required String conversationId,
  }) {
    // Handle status updates that might affect seen status
    final messageId = statusData['messageId']?.toString();
    final newStatus = statusData['status']?.toString();

    if (messageId != null && newStatus?.toUpperCase() == 'SEEN') {
      // A message was marked as seen, potentially update unread count
      final currentCount = getUnreadCount(conversationId);
      if (currentCount > 0) {
        updateUnreadCount(conversationId, currentCount - 1);
      }
    }
  }

  /// Calculate unread count from message list
  int calculateUnreadCount({
    required List<ChatMessageApi> messages,
    required String currentUserId,
  }) {
    return messages
        .where(
          (m) => m.senderId != currentUserId && m.status != MessageStatus.seen,
        )
        .length;
  }

  /// Dispose resources for a conversation
  void disposeConversation(String conversationId) {
    _unreadCountControllers[conversationId]?.close();
    _unreadCountControllers.remove(conversationId);
    _unreadCounts.remove(conversationId);
  }

  /// Dispose all resources
  void dispose() {
    for (final controller in _unreadCountControllers.values) {
      controller.close();
    }
    _unreadCountControllers.clear();
    _unreadCounts.clear();
  }
}
