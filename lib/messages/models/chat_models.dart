class ChatMessageApi {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String messageType;
  final String? fileUrl;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final String timestamp;
  final String status;
  final bool deletedForAll;

  ChatMessageApi({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.messageType,
    required this.timestamp,
    required this.status,
    required this.deletedForAll,
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.fileSize,
  });

  factory ChatMessageApi.fromJson(Map<String, dynamic> json) {
    return ChatMessageApi(
      id: (json['id'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      receiverId: (json['receiverId'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      messageType: (json['messageType'] ?? 'TEXT').toString(),
      fileUrl: json['fileUrl']?.toString(),
      fileName: json['fileName']?.toString(),
      fileType: json['fileType']?.toString(),
      fileSize: json['fileSize'] is num
          ? (json['fileSize'] as num).toInt()
          : int.tryParse(json['fileSize']?.toString() ?? ''),
      timestamp: (json['timestamp'] ?? '').toString(),
      status: (json['status'] ?? 'SENT').toString(),
      deletedForAll: json['deletedForAll'] == true,
    );
  }
}

class ConversationApi {
  final String otherUserId;
  final String otherUserName;
  final bool otherUserOnline;
  final String? otherUserLastSeen;
  final int unreadCount;
  final String? lastMessageContent;
  final String? lastMessageTime;

  ConversationApi({
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserOnline,
    this.otherUserLastSeen,
    required this.unreadCount,
    this.lastMessageContent,
    this.lastMessageTime,
  });

  factory ConversationApi.fromJson(Map<String, dynamic> json) {
    return ConversationApi(
      otherUserId: (json['otherUserId'] ?? '').toString(),
      otherUserName: (json['otherUserName'] ?? '').toString(),
      otherUserOnline: json['otherUserOnline'] == true,
      otherUserLastSeen: json['otherUserLastSeen']?.toString(),
      unreadCount: json['unreadCount'] is num
          ? (json['unreadCount'] as num).toInt()
          : int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0,
      lastMessageContent: json['lastMessageContent']?.toString(),
      lastMessageTime: json['lastMessageTime']?.toString(),
    );
  }
}
