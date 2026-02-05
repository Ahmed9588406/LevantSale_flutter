import 'chat_models.dart';

class Message {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isSentByMe;
  final bool isRead;
  final MessageType messageType;
  final String? fileUrl;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final MessageStatus status;
  final bool deletedForAll;

  Message({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isSentByMe,
    this.isRead = false,
    this.messageType = MessageType.TEXT,
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.fileSize,
    this.status = MessageStatus.SENT,
    this.deletedForAll = false,
  });

  /// Create from API model
  factory Message.fromApi(ChatMessageApi api, String currentUserId) {
    return Message(
      id: api.id,
      text: api.content,
      timestamp: api.timestamp,
      isSentByMe: api.senderId == currentUserId,
      isRead: api.status == MessageStatus.SEEN,
      messageType: api.messageType,
      fileUrl: api.fileUrl,
      fileName: api.fileName,
      fileType: api.fileType,
      fileSize: api.fileSize,
      status: api.status,
      deletedForAll: api.deletedForAll,
    );
  }

  Message copyWith({
    String? id,
    String? text,
    DateTime? timestamp,
    bool? isSentByMe,
    bool? isRead,
    MessageType? messageType,
    String? fileUrl,
    String? fileName,
    String? fileType,
    int? fileSize,
    MessageStatus? status,
    bool? deletedForAll,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isSentByMe: isSentByMe ?? this.isSentByMe,
      isRead: isRead ?? this.isRead,
      messageType: messageType ?? this.messageType,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      deletedForAll: deletedForAll ?? this.deletedForAll,
    );
  }
}

class ChatConversation {
  final String id;
  final String userName;
  final String userAvatar;
  final String productTitle;
  final String productPrice;
  final String productImage;
  final Message lastMessage;
  int unreadCount;
  final bool isRead;
  final bool isOnline;
  final String? lastSeen;
  final String? phone;

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
    this.isOnline = false,
    this.lastSeen,
    this.phone,
  });

  /// Create from API model
  factory ChatConversation.fromApi(ConversationApi api) {
    final lastTime = api.lastMessageTime != null
        ? DateTime.tryParse(api.lastMessageTime!) ?? DateTime.now()
        : DateTime.now();
    return ChatConversation(
      id: api.otherUserId,
      userName: api.otherUserName,
      userAvatar: '',
      productTitle: '',
      productPrice: '',
      productImage: '',
      lastMessage: Message(
        id: 'last',
        text: api.lastMessageContent ?? '',
        timestamp: lastTime,
        isSentByMe: false,
        isRead: api.unreadCount == 0,
      ),
      unreadCount: api.unreadCount,
      isRead: api.unreadCount == 0,
      isOnline: api.otherUserOnline,
      lastSeen: api.otherUserLastSeen,
      phone: api.otherUserPhone,
    );
  }

  ChatConversation copyWith({
    String? id,
    String? userName,
    String? userAvatar,
    String? productTitle,
    String? productPrice,
    String? productImage,
    Message? lastMessage,
    int? unreadCount,
    bool? isRead,
    bool? isOnline,
    String? lastSeen,
    String? phone,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      productTitle: productTitle ?? this.productTitle,
      productPrice: productPrice ?? this.productPrice,
      productImage: productImage ?? this.productImage,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isRead: isRead ?? this.isRead,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      phone: phone ?? this.phone,
    );
  }
}
