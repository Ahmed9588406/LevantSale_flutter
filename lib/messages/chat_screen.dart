import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'models/message_model.dart';
import 'models/chat_models.dart';
import 'widgets/report_bottom_sheet.dart';
import 'widgets/phone_dialog.dart';
import 'chat_service.dart';
import 'chat_socket.dart';
import '../api/auth/auth_config.dart';

class ChatScreen extends StatefulWidget {
  final ChatConversation conversation;
  final ChatAdData? adData;

  const ChatScreen({Key? key, required this.conversation, this.adData})
    : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> messages = [];

  String? _currentUserId;
  ChatSocket? _socket;
  bool _loading = false;
  bool _sending = false;
  int _currentPage = 0;
  bool _hasMore = true;
  int _unreadCount = 0;

  // File selection
  File? _selectedFile;
  String? _selectedFileName;
  bool _isImage = false;

  // Context menu
  String? _contextMenuMessageId;
  Offset? _contextMenuPosition;
  bool _showContextMenu = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when scrolled to top
    if (_scrollController.position.pixels <= 100 && !_loading && _hasMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _initializeChat() async {
    _currentUserId = await ChatService.getCurrentUserId();
    await _loadMessages();
    await _connectWebSocket();
    _markMessagesAsSeen();
  }

  Future<void> _connectWebSocket() async {
    final token = await ChatService.getToken();
    if (token == null) return;

    _socket = ChatSocket(
      token: token,
      onMessage: (apiMessage) {
        if (!mounted) return;
        // Check if message belongs to this conversation
        if (apiMessage.senderId == widget.conversation.id ||
            apiMessage.receiverId == widget.conversation.id) {
          setState(() {
            // Check if we already have this message (optimistic update)
            final existingIdx = messages.indexWhere(
              (m) =>
                  m.id.startsWith('temp-') &&
                  m.text == apiMessage.content &&
                  m.isSentByMe == (apiMessage.senderId == _currentUserId),
            );

            if (existingIdx >= 0) {
              // Replace temp message with real one
              messages[existingIdx] = Message.fromApi(
                apiMessage,
                _currentUserId ?? '',
              );
            } else {
              // Add new message
              messages.add(Message.fromApi(apiMessage, _currentUserId ?? ''));
              if (apiMessage.senderId != _currentUserId) {
                _unreadCount++;
              }
            }
          });
          _scrollToBottom();

          // Mark as seen if from other user
          if (apiMessage.senderId != _currentUserId) {
            _markMessagesAsSeen();
          }
        }
      },
      onStatus: (data) {
        if (!mounted) return;
        // Update message statuses
        _loadMessages();
      },
      onPresence: (data) {
        // Handle presence updates if needed
      },
    );
    _socket?.connect();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final items = await ChatService.fetchMessages(
        widget.conversation.id,
        page: 0,
        size: 50,
      );
      final mapped = items
          .map((m) => Message.fromApi(m, _currentUserId ?? ''))
          .toList()
          .reversed
          .toList();

      // Count unread messages
      final unread = mapped
          .where((m) => !m.isSentByMe && m.status != MessageStatus.SEEN)
          .length;

      setState(() {
        messages.clear();
        messages.addAll(mapped);
        _currentPage = 0;
        _hasMore = items.length >= 50;
        _unreadCount = unread;
      });

      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToBottom(animate: false),
      );
    } catch (e) {
      debugPrint('Error loading messages: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final nextPage = _currentPage + 1;
      final items = await ChatService.fetchMessages(
        widget.conversation.id,
        page: nextPage,
        size: 50,
      );
      final mapped = items
          .map((m) => Message.fromApi(m, _currentUserId ?? ''))
          .toList()
          .reversed
          .toList();

      setState(() {
        messages.insertAll(0, mapped);
        _currentPage = nextPage;
        _hasMore = items.length >= 50;
      });
    } catch (e) {
      debugPrint('Error loading more messages: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _markMessagesAsSeen() {
    _socket?.markSeen(widget.conversation.id);
    setState(() => _unreadCount = 0);
  }

  void _scrollToBottom({bool animate = true}) {
    if (_scrollController.hasClients) {
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'jpg',
        'jpeg',
        'png',
        'mp4',
        'mov',
      ],
    );
    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      setState(() {
        _selectedFile = File(file.path!);
        _selectedFileName = file.name;
        _isImage = [
          'jpg',
          'jpeg',
          'png',
          'gif',
        ].contains(file.extension?.toLowerCase());
      });
    }
  }

  void _clearSelectedFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
      _isImage = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedFile == null) return;
    if (_socket == null || !_socket!.isConnected) return;

    setState(() => _sending = true);

    try {
      Map<String, dynamic>? fileMeta;

      // Upload file if selected
      if (_selectedFile != null) {
        final bytes = await _selectedFile!.readAsBytes();
        fileMeta = await ChatService.uploadChatFile(
          fileName: _selectedFileName ?? 'file',
          bytes: bytes,
        );
      }

      // Create optimistic message
      final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
      final tempMessage = Message(
        id: tempId,
        text: text,
        timestamp: DateTime.now(),
        isSentByMe: true,
        messageType: fileMeta != null
            ? _parseMessageType(fileMeta['messageType'])
            : MessageType.TEXT,
        fileUrl: fileMeta?['fileUrl'],
        fileName: fileMeta?['fileName'],
        status: MessageStatus.SENT,
      );

      setState(() {
        messages.add(tempMessage);
      });
      _scrollToBottom();
      _messageController.clear();
      _clearSelectedFile();

      // Send via WebSocket
      _socket!.sendMessage(
        receiverId: widget.conversation.id,
        content: text,
        messageType: tempMessage.messageType,
        fileUrl: fileMeta?['fileUrl'],
        fileName: fileMeta?['fileName'],
        fileType: fileMeta?['fileType'],
        fileSize: fileMeta?['fileSize'],
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إرسال الرسالة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  MessageType _parseMessageType(String? type) {
    switch (type?.toUpperCase()) {
      case 'IMAGE':
        return MessageType.IMAGE;
      case 'VIDEO':
        return MessageType.VIDEO;
      case 'FILE':
        return MessageType.FILE;
      default:
        return MessageType.TEXT;
    }
  }

  Future<void> _deleteMessageForMe(String messageId) async {
    final success = await ChatService.deleteMessageForMe(messageId);
    if (success) {
      setState(() {
        final idx = messages.indexWhere((m) => m.id == messageId);
        if (idx >= 0) {
          messages[idx] = messages[idx].copyWith(deletedForAll: true);
        }
      });
    }
  }

  Future<void> _deleteMessageForEveryone(String messageId) async {
    final success = await ChatService.deleteMessageForEveryone(messageId);
    if (success) {
      setState(() {
        final idx = messages.indexWhere((m) => m.id == messageId);
        if (idx >= 0) {
          messages[idx] = messages[idx].copyWith(deletedForAll: true);
        }
      });
    }
  }

  void _showMessageContextMenu(Message message, Offset position) {
    setState(() {
      _contextMenuMessageId = message.id;
      _contextMenuPosition = position;
      _showContextMenu = true;
    });
  }

  void _hideContextMenu() {
    setState(() {
      _contextMenuMessageId = null;
      _contextMenuPosition = null;
      _showContextMenu = false;
    });
  }

  Future<void> _showPhoneDialog() async {
    String? phone = widget.conversation.phone;

    // Fetch phone if not available
    if (phone == null || phone.isEmpty) {
      final userDetails = await ChatService.fetchUserDetails(
        widget.conversation.id,
      );
      phone = userDetails?['phone'] ?? userDetails?['phoneNumber'];
    }

    if (mounted && phone != null && phone.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => PhoneDialog(phoneNumber: phone!),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رقم الهاتف غير متوفر'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hideContextMenu,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(),
          body: Stack(
            children: [
              Column(
                children: [
                  if (widget.adData != null) _buildAdPreview(),
                  if (_unreadCount > 0) _buildUnreadBanner(),
                  Expanded(child: _buildMessagesList()),
                  if (_selectedFile != null) _buildFilePreview(),
                  _buildMessageInput(),
                ],
              ),
              if (_showContextMenu && _contextMenuPosition != null)
                _buildContextMenu(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF1DAF52).withOpacity(0.1),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF1DAF52),
                  size: 24,
                ),
              ),
              if (widget.conversation.isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.userName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.conversation.isOnline
                      ? 'متصل الآن'
                      : _formatLastSeen(widget.conversation.lastSeen),
                  style: TextStyle(
                    color: widget.conversation.isOnline
                        ? const Color(0xFF1DAF52)
                        : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.flag_outlined, color: Colors.black),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => ReportBottomSheet(
                userName: widget.conversation.userName,
                userId: widget.conversation.id,
                listingId: widget.adData?.id,
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.phone_outlined, color: Colors.black),
          onPressed: _showPhoneDialog,
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildAdPreview() {
    final ad = widget.adData!;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F4),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: const Color(0xFF1DAF52), width: 4),
        ),
      ),
      child: Row(
        children: [
          if (ad.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ad.imageUrl!.startsWith('http')
                    ? ad.imageUrl!
                    : '${AuthConfig.baseUrl}${ad.imageUrl}',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad.title ?? 'منتج',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ad.price != null)
                  Text(
                    '${ad.price} ${ad.currency ?? ''}',
                    style: const TextStyle(
                      color: Color(0xFF1DAF52),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnreadBanner() {
    return GestureDetector(
      onTap: _markMessagesAsSeen,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1DAF52),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$_unreadCount رسالة غير مقروءة',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '(انقر للقراءة)',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_loading && messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1DAF52)),
      );
    }

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: Color(0xFF1DAF52),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.adData != null
                  ? 'ابدأ المحادثة الآن!'
                  : 'لا توجد رسائل بعد',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            if (widget.adData != null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'اسأل البائع عن هذا المنتج',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        _hideContextMenu();
        if (_unreadCount > 0) _markMessagesAsSeen();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: messages.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (_hasMore && index == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _loading
                    ? const CircularProgressIndicator(color: Color(0xFF1DAF52))
                    : TextButton(
                        onPressed: _loadMoreMessages,
                        child: const Text(
                          'تحميل رسائل أقدم',
                          style: TextStyle(color: Color(0xFF1DAF52)),
                        ),
                      ),
              ),
            );
          }
          final messageIndex = _hasMore ? index - 1 : index;
          final message = messages[messageIndex];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    if (message.deletedForAll) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: message.isSentByMe
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'تم حذف هذه الرسالة',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPressStart: (details) {
        _showMessageContextMenu(message, details.globalPosition);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: message.isSentByMe
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: Container(
            margin: message.isSentByMe
                ? const EdgeInsets.only(right: 50)
                : const EdgeInsets.only(left: 50),
            child: Column(
              crossAxisAlignment: message.isSentByMe
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                // Image/Video/File content
                if (message.messageType == MessageType.IMAGE &&
                    message.fileUrl != null)
                  _buildImageMessage(message),
                if (message.messageType == MessageType.VIDEO &&
                    message.fileUrl != null)
                  _buildVideoMessage(message),
                if (message.messageType == MessageType.FILE &&
                    message.fileUrl != null)
                  _buildFileMessage(message),

                // Text content
                if (message.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: message.isSentByMe
                          ? const Color(0xFF1DAF52)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: message.isSentByMe
                            ? const Radius.circular(12)
                            : const Radius.circular(2),
                        bottomRight: message.isSentByMe
                            ? const Radius.circular(2)
                            : const Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: message.isSentByMe
                            ? Colors.white
                            : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),

                // Timestamp and status
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.isSentByMe) ...[
                      Icon(
                        message.status == MessageStatus.SEEN
                            ? Icons.done_all
                            : message.status == MessageStatus.DELIVERED
                            ? Icons.done_all
                            : Icons.done,
                        size: 16,
                        color: message.status == MessageStatus.SEEN
                            ? const Color(0xFF1DAF52)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      _formatTime(message.timestamp),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageMessage(Message message) {
    final url = message.fileUrl!.startsWith('http')
        ? message.fileUrl!
        : '${AuthConfig.baseUrl}${message.fileUrl}';
    return GestureDetector(
      onTap: () => _showImageViewer(url, message.fileName),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        constraints: const BoxConstraints(maxWidth: 250, maxHeight: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                width: 200,
                height: 150,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1DAF52)),
                ),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              width: 200,
              height: 150,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoMessage(Message message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam, color: Colors.red),
          const SizedBox(width: 8),
          Text(
            message.fileName ?? 'فيديو',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFileMessage(Message message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            message.fileType?.contains('pdf') == true
                ? Icons.picture_as_pdf
                : Icons.insert_drive_file,
            color: message.fileType?.contains('pdf') == true
                ? Colors.red
                : Colors.blue,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.fileName ?? 'ملف',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (message.fileSize != null)
                Text(
                  '${(message.fileSize! / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.download, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  void _showImageViewer(String url, String? name) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black87),
            ),
            Center(child: InteractiveViewer(child: Image.network(url))),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (name != null)
              Positioned(
                bottom: 40,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          if (_isImage && _selectedFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _selectedFile!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.insert_drive_file, color: Colors.grey),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedFileName ?? 'ملف',
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _clearSelectedFile,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالة...',
                  hintStyle: TextStyle(color: Color(0xFFBDBDBD)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                style: const TextStyle(fontSize: 14),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.attach_file,
                color: Color(0xFF1DAF52),
                size: 20,
              ),
              onPressed: _pickFile,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF1DAF52),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextMenu() {
    final message = messages.firstWhere(
      (m) => m.id == _contextMenuMessageId,
      orElse: () => messages.first,
    );

    return Positioned(
      left: _contextMenuPosition!.dx - 80,
      top: _contextMenuPosition!.dy - 100,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  _hideContextMenu();
                  _deleteMessageForMe(_contextMenuMessageId!);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('حذف لي', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              if (message.isSentByMe)
                InkWell(
                  onTap: () {
                    _hideContextMenu();
                    _deleteMessageForEveryone(_contextMenuMessageId!);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.delete_forever, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'حذف للجميع',
                          style: TextStyle(fontSize: 14, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
