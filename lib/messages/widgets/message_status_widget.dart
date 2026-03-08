import 'package:flutter/material.dart';
import '../models/chat_models.dart';

class MessageStatusWidget extends StatelessWidget {
  final MessageStatus status;
  final bool isSentByMe;
  final DateTime timestamp;

  const MessageStatusWidget({
    Key? key,
    required this.status,
    required this.isSentByMe,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSentByMe) ...[
          // Status indicator matching web version exactly
          Text(
            status == MessageStatus.seen
                ? '✓✓'
                : status == MessageStatus.delivered
                ? '✓✓'
                : '✓',
            style: TextStyle(
              fontSize: 14,
              color: status == MessageStatus.seen
                  ? const Color(0xFF1DAF52) // Green for seen (matches web)
                  : status == MessageStatus.delivered
                  ? const Color(0xFF9E9E9E) // Grey for delivered
                  : const Color(0xFF9E9E9E), // Grey for sent
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          _formatTime(timestamp),
          style: TextStyle(
            fontSize: 11,
            color: isSentByMe
                ? (status == MessageStatus.seen
                      ? const Color(0xFF1DAF52).withOpacity(0.7)
                      : const Color(0xFF757575))
                : const Color(0xFF757575),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
