/// Message types matching the backend API
enum MessageType { text, image, video, file, adCard }

/// Message status matching the backend API
enum MessageStatus { sent, delivered, seen }

class ChatMessageApi {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType messageType;
  final String? fileUrl;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final DateTime timestamp;
  final MessageStatus status;
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
    final fileUrl = json['fileUrl']?.toString();
    final fileName = json['fileName']?.toString();
    final fileType = json['fileType']?.toString();
    final rawMessageType = json['messageType']?.toString();

    // Parse message type with fallback to file extension detection
    MessageType messageType = _parseMessageType(rawMessageType);

    // If messageType is FILE but it's actually an image, correct it
    if (messageType == MessageType.file && fileUrl != null) {
      if (_isImageFile(fileUrl) ||
          _isImageFile(fileName) ||
          _isImageMimeType(fileType)) {
        messageType = MessageType.image;
      } else if (_isVideoFile(fileUrl) ||
          _isVideoFile(fileName) ||
          _isVideoMimeType(fileType)) {
        messageType = MessageType.video;
      }
    }

    return ChatMessageApi(
      id: (json['id'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      receiverId: (json['receiverId'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      messageType: messageType,
      fileUrl: fileUrl,
      fileName: fileName,
      fileType: fileType,
      fileSize: json['fileSize'] is num
          ? (json['fileSize'] as num).toInt()
          : int.tryParse(json['fileSize']?.toString() ?? ''),
      timestamp: _parseTimestamp(json['timestamp']),
      status: _parseMessageStatus(json['status']?.toString()),
      deletedForAll: json['deletedForAll'] == true,
    );
  }

  static bool _isImageFile(String? file) {
    if (file == null || file.isEmpty) return false;
    final lower = file.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp');
  }

  static bool _isVideoFile(String? file) {
    if (file == null || file.isEmpty) return false;
    final lower = file.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm');
  }

  static bool _isImageMimeType(String? mimeType) {
    if (mimeType == null || mimeType.isEmpty) return false;
    return mimeType.toLowerCase().startsWith('image/');
  }

  static bool _isVideoMimeType(String? mimeType) {
    if (mimeType == null || mimeType.isEmpty) return false;
    return mimeType.toLowerCase().startsWith('video/');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'messageType': messageType.name,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'deletedForAll': deletedForAll,
    };
  }

  ChatMessageApi copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? messageType,
    String? fileUrl,
    String? fileName,
    String? fileType,
    int? fileSize,
    DateTime? timestamp,
    MessageStatus? status,
    bool? deletedForAll,
  }) {
    return ChatMessageApi(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      deletedForAll: deletedForAll ?? this.deletedForAll,
    );
  }

  static MessageType _parseMessageType(String? type) {
    switch (type?.toUpperCase()) {
      case 'IMAGE':
        return MessageType.image;
      case 'VIDEO':
        return MessageType.video;
      case 'FILE':
        return MessageType.file;
      case 'AD_CARD':
      case 'ADCARD':
      case 'LISTING':
        return MessageType.adCard;
      default:
        return MessageType.text;
    }
  }

  static MessageStatus _parseMessageStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'DELIVERED':
        return MessageStatus.delivered;
      case 'SEEN':
        return MessageStatus.seen;
      default:
        return MessageStatus.sent;
    }
  }

  static DateTime _parseTimestamp(dynamic ts) {
    if (ts == null) return DateTime.now();
    if (ts is DateTime) return ts;
    try {
      return DateTime.parse(ts.toString());
    } catch (_) {
      return DateTime.now();
    }
  }
}

class ConversationApi {
  final String otherUserId;
  final String otherUserName;
  final bool otherUserOnline;
  final String? otherUserLastSeen;
  final String? otherUserPhone;
  final String? listingId; // Add listing ID
  int unreadCount;
  String? lastMessageContent;
  String? lastMessageTime;

  ConversationApi({
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserOnline,
    this.otherUserLastSeen,
    this.otherUserPhone,
    this.listingId,
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
      otherUserPhone:
          json['otherUserPhone']?.toString() ?? json['phone']?.toString(),
      listingId: json['listingId']?.toString(),
      unreadCount: json['unreadCount'] is num
          ? (json['unreadCount'] as num).toInt()
          : int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0,
      lastMessageContent: json['lastMessageContent']?.toString(),
      lastMessageTime: json['lastMessageTime']?.toString(),
    );
  }

  ConversationApi copyWith({
    String? otherUserId,
    String? otherUserName,
    bool? otherUserOnline,
    String? otherUserLastSeen,
    String? otherUserPhone,
    String? listingId,
    int? unreadCount,
    String? lastMessageContent,
    String? lastMessageTime,
  }) {
    return ConversationApi(
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserOnline: otherUserOnline ?? this.otherUserOnline,
      otherUserLastSeen: otherUserLastSeen ?? this.otherUserLastSeen,
      otherUserPhone: otherUserPhone ?? this.otherUserPhone,
      listingId: listingId ?? this.listingId,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
}

/// Ad data for chat context (when starting a chat from a listing)
class ChatAdData {
  final String? id;
  final String? title;
  final String? price;
  final String? currency;
  final String? imageUrl;
  final String? description;
  final String? location;

  ChatAdData({
    this.id,
    this.title,
    this.price,
    this.currency,
    this.imageUrl,
    this.description,
    this.location,
  });

  factory ChatAdData.fromJson(Map<String, dynamic> json) {
    return ChatAdData(
      id: json['id']?.toString(),
      title: json['title']?.toString(),
      price: json['price']?.toString(),
      currency:
          json['currency']?.toString() ?? json['currencySymbol']?.toString(),
      imageUrl:
          json['imageUrl']?.toString() ??
          (json['imageUrls'] is List && (json['imageUrls'] as List).isNotEmpty
              ? (json['imageUrls'] as List).first.toString()
              : null),
      description: json['description']?.toString(),
      location: json['location']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'currency': currency,
      'imageUrl': imageUrl,
      'description': description,
      'location': location,
    };
  }
}
