import 'package:flutter/material.dart';
import '../models/message_model.dart';

class ConversationListItem extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;

  const ConversationListItem({
    Key? key,
    required this.conversation,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: conversation.unreadCount > 0
              ? const Color(0xFFF8FFF9) // Light green background for unread
              : Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF1DAF52).withOpacity(0.1),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF1DAF52),
                    size: 28,
                  ),
                ),
                if (conversation.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Conversation details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and timestamp row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.userName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: conversation.unreadCount > 0
                                ? const Color(0xFF1DAF52)
                                : const Color(0xFF2B2B2A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(conversation.lastMessage.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: conversation.unreadCount > 0
                              ? const Color(0xFF1DAF52)
                              : Colors.grey.shade600,
                          fontWeight: conversation.unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Last message and unread count row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage.text.isNotEmpty
                              ? conversation.lastMessage.text
                              : 'رسالة',
                          style: TextStyle(
                            fontSize: 14,
                            color: conversation.unreadCount > 0
                                ? const Color(0xFF2B2B2A)
                                : Colors.grey.shade600,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Unread count badge (matching web design)
                      if (conversation.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1DAF52),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : conversation.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Online status
                  if (!conversation.isOnline && conversation.lastSeen != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _formatLastSeen(conversation.lastSeen),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Seen indicator for sent messages (like web)
            if (conversation.lastMessage.isSentByMe)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  conversation.unreadCount == 0
                      ? Icons
                            .done_all // Double check for seen
                      : Icons.done, // Single check for sent/delivered
                  size: 16,
                  color: conversation.unreadCount == 0
                      ? const Color(0xFF1DAF52) // Green for seen
                      : Colors.grey.shade500, // Grey for sent/delivered
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return '${diff.inMinutes}د';
    if (diff.inHours < 24) return '${diff.inHours}س';
    if (diff.inDays < 7) return '${diff.inDays}ي';
    return '${timestamp.day}/${timestamp.month}';
  }

  String _formatLastSeen(String? lastSeen) {
    if (lastSeen == null) return 'غير متصل';
    try {
      final date = DateTime.parse(lastSeen);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'آخر ظهور الآن';
      if (diff.inMinutes < 60) return 'آخر ظهور قبل ${diff.inMinutes}د';
      if (diff.inHours < 24) return 'آخر ظهور قبل ${diff.inHours}س';
      return 'آخر ظهور ${date.day}/${date.month}';
    } catch (_) {
      return 'غير متصل';
    }
  }
}
