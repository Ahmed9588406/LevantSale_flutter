class Message {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isSentByMe;
  final bool isRead;

  Message({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isSentByMe,
    this.isRead = false,
  });
}

class ChatConversation {
  final String id;
  final String userName;
  final String userAvatar;
  final String productTitle;
  final String productPrice;
  final String productImage;
  final Message lastMessage;
  final int unreadCount;
  final bool isRead;

  ChatConversation({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.productTitle,
    required this.productPrice,
    required this.productImage,
    required this.lastMessage,
    this.unreadCount = 0,
    this.isRead = false,
  });
}
