import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'models/message_model.dart';
import 'models/chat_models.dart';
import 'widgets/report_bottom_sheet.dart';
import 'widgets/phone_dialog.dart';
import 'widgets/message_status_widget.dart';
import 'widgets/unread_banner_widget.dart';
import 'chat_service.dart';
import 'chat_socket.dart';
import '../api/auth/auth_config.dart';
import '../category/product_details_screen.dart';

class ChatScreen extends StatefulWidget {
  final ChatConversation conversation;
  final ChatAdData? adData;

  const ChatScreen({Key? key, required this.conversation, this.adData})
    : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
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

  // Ad data - can be fetched or passed
  ChatAdData? _adData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _adData = widget.adData; // Use provided ad data if available
    _initializeChat();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Mark messages as seen when app becomes active (like web version)
    if (state == AppLifecycleState.resumed && _unreadCount > 0) {
      _markMessagesAsSeen();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mark messages as seen when screen becomes visible
    if (_unreadCount > 0) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _markMessagesAsSeen();
        }
      });
    }
  }

  @override
  void dispose() {
    // Mark messages as seen one final time before disposing
    if (_currentUserId != null && _unreadCount > 0) {
      _markMessagesAsSeen();
    }

    WidgetsBinding.instance.removeObserver(this);
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

    // Fetch ad data if not provided but conversation has listingId
    if (_adData == null && widget.conversation.listingId != null) {
      _fetchAdData(widget.conversation.listingId!);
    }

    await _loadMessages();
    await _connectWebSocket();

    // Mark messages as seen immediately after loading (like web version)
    if (mounted && _unreadCount > 0) {
      // Use a short delay to ensure WebSocket is connected
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _markMessagesAsSeen();
        }
      });
    }

    // Send ad card as first message if provided and no messages exist
    if (_adData != null && messages.isEmpty && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _sendAdCard();
    }
  }

  Future<void> _sendAdCard() async {
    if (_adData == null || _socket == null) return;

    try {
      // Create ad message content similar to web version
      final priceInfo = _adData!.price != null && _adData!.currency != null
          ? ' - ${_adData!.price} ${_adData!.currency}'
          : '';
      final adLink = _adData!.id != null
          ? '\n🔗 /categories/product/${_adData!.id}'
          : '';
      final content =
          'مرحباً، أنا مهتم بهذا الإعلان:\n📦 ${_adData!.title ?? 'منتج'}$priceInfo$adLink';

      // Create optimistic message
      final tempId = 'temp-ad-${DateTime.now().millisecondsSinceEpoch}';
      final tempMessage = Message(
        id: tempId,
        text: content,
        timestamp: DateTime.now(),
        isSentByMe: true,
        messageType: MessageType
            .text, // Use TEXT type so it gets processed as ad message
        status: MessageStatus.sent,
      );

      setState(() {
        messages.add(tempMessage);
      });
      _scrollToBottom();

      // Send via WebSocket
      _socket!.sendMessage(
        receiverId: widget.conversation.id,
        content: content,
        messageType: MessageType.text,
      );
    } catch (e) {
      debugPrint('Error sending ad card: $e');
    }
  }

  Future<void> _fetchAdData(String listingId) async {
    try {
      final adData = await ChatService.fetchListingDetails(listingId);
      if (mounted && adData != null) {
        setState(() {
          _adData = adData;
        });
      }
    } catch (e) {
      debugPrint('Error fetching ad data: $e');
    }
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
              final newMessage = Message.fromApi(
                apiMessage,
                _currentUserId ?? '',
              );
              messages.add(newMessage);

              // Update unread count only for messages from other user
              if (apiMessage.senderId != _currentUserId &&
                  apiMessage.status != MessageStatus.seen) {
                _unreadCount++;
              }
            }
          });
          _scrollToBottom();

          // Mark as seen if from other user (matching web behavior)
          if (apiMessage.senderId != _currentUserId) {
            // Mark immediately without delay for better real-time sync
            _markMessagesAsSeen();
          }
        }
      },
      onStatus: (data) {
        if (!mounted) return;
        // Update message statuses when status updates are received (like web)
        debugPrint('Status update received: $data');

        // Update local message statuses based on the status update
        setState(() {
          for (int i = 0; i < messages.length; i++) {
            if (messages[i].isSentByMe) {
              // Update sent message status if this is a status update for our messages
              final messageId = data['messageId']?.toString();
              final newStatus = data['status']?.toString();

              if (messageId != null &&
                  messages[i].id == messageId &&
                  newStatus != null) {
                final parsedStatus = _parseMessageStatus(newStatus);
                messages[i] = messages[i].copyWith(status: parsedStatus);
              }
            }
          }
        });

        // Also reload messages to get updated statuses from server
        if (_currentUserId != null) {
          _loadMessages();
        }
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
          .where((m) => !m.isSentByMe && m.status != MessageStatus.seen)
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

  void _markMessagesAsSeen() async {
    if (_currentUserId == null || _unreadCount == 0) return;

    debugPrint(
      '📖 Marking messages as seen for conversation: ${widget.conversation.id}',
    );
    debugPrint('📖 Current unread count: $_unreadCount');

    try {
      // Use both WebSocket and HTTP API for better reliability (like web version)
      if (_socket?.isConnected == true) {
        _socket?.markSeen(widget.conversation.id);
        debugPrint('📖 Sent WebSocket markSeen message');
      } else {
        debugPrint('⚠️ WebSocket not connected, skipping WebSocket markSeen');
      }

      final httpSuccess = await ChatService.markMessagesSeen(
        widget.conversation.id,
      );
      debugPrint('📖 HTTP markSeen result: $httpSuccess');

      // Update local state immediately for better UX (matching web behavior)
      setState(() {
        _unreadCount = 0;
        // Update message statuses to SEEN for messages from other user
        for (int i = 0; i < messages.length; i++) {
          if (!messages[i].isSentByMe &&
              messages[i].status != MessageStatus.seen) {
            messages[i] = messages[i].copyWith(
              status: MessageStatus.seen,
              isRead: true,
            );
          }
        }
      });

      debugPrint('✅ Messages marked as seen successfully');

      // Notify other parts of the app about the status change
      _socket?.publish(
        destination: '/app/chat.status.update',
        body: widget.conversation.id,
      );
    } catch (e) {
      debugPrint('❌ Error marking messages as seen: $e');
    }
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
            : MessageType.text,
        fileUrl: fileMeta?['fileUrl'],
        fileName: fileMeta?['fileName'],
        status: MessageStatus.sent,
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
        return MessageType.image;
      case 'VIDEO':
        return MessageType.video;
      case 'FILE':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  MessageStatus _parseMessageStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'DELIVERED':
        return MessageStatus.delivered;
      case 'SEEN':
        return MessageStatus.seen;
      default:
        return MessageStatus.sent;
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
                  if (_adData != null) _buildAdPreview(),
                  if (_unreadCount > 0)
                    UnreadBannerWidget(
                      unreadCount: _unreadCount,
                      onTap: _markMessagesAsSeen,
                    ),
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
                listingId: _adData?.id,
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
    final ad = _adData!;
    return GestureDetector(
      onTap: () {
        // Navigate to product details when tapped
        if (ad.id != null && ad.id!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(listingId: ad.id!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1DAF52), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1DAF52).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image
            if (ad.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ad.imageUrl!.startsWith('http')
                      ? ad.imageUrl!
                      : '${AuthConfig.baseUrl}${ad.imageUrl}',
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        size: 16,
                        color: Color(0xFF1DAF52),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'المنتج المعروض',
                        style: TextStyle(
                          color: Color(0xFF1DAF52),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ad.title ?? 'منتج',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF2B2B2A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (ad.price != null)
                    Text(
                      '${ad.price} ${ad.currency ?? ''}',
                      style: const TextStyle(
                        color: Color(0xFF1DAF52),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            // Arrow icon
            const Icon(
              Icons.arrow_back_ios,
              size: 16,
              color: Color(0xFF1DAF52),
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
              _adData != null ? 'ابدأ المحادثة الآن!' : 'لا توجد رسائل بعد',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            if (_adData != null)
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
        // Mark messages as seen when user taps on messages area
        if (_unreadCount > 0) {
          _markMessagesAsSeen();
        }
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
              ? Alignment.centerRight
              : Alignment.centerLeft,
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

    // Debug: Print message type
    debugPrint(
      'Message ${message.id}: type=${message.messageType}, fileUrl=${message.fileUrl}, text=${message.text}',
    );

    return GestureDetector(
      onLongPressStart: (details) {
        _showMessageContextMenu(message, details.globalPosition);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: message.isSentByMe
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            margin: message.isSentByMe
                ? const EdgeInsets.only(left: 50)
                : const EdgeInsets.only(right: 50),
            child: Column(
              crossAxisAlignment: message.isSentByMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Ad Card content
                if (message.messageType == MessageType.adCard &&
                    message.adData != null)
                  _buildAdCardMessage(message),

                // Image content - check both messageType and file extension
                if ((message.messageType == MessageType.image ||
                        _isImageFile(message.fileUrl)) &&
                    message.fileUrl != null &&
                    message.fileUrl!.isNotEmpty)
                  _buildImageMessage(message),

                // Video content
                if (message.messageType == MessageType.video &&
                    message.fileUrl != null &&
                    message.fileUrl!.isNotEmpty)
                  _buildVideoMessage(message),

                // File content - but not if it's an image
                if (message.messageType == MessageType.file &&
                    message.fileUrl != null &&
                    message.fileUrl!.isNotEmpty &&
                    !_isImageFile(message.fileUrl))
                  _buildFileMessage(message),

                // Text content - check if it's an ad message first
                if (message.text.isNotEmpty &&
                    message.messageType != MessageType.image &&
                    message.messageType != MessageType.adCard)
                  _buildTextOrAdMessage(message),

                // Timestamp and status using the new widget
                const SizedBox(height: 4),
                MessageStatusWidget(
                  status: message.status,
                  isSentByMe: message.isSentByMe,
                  timestamp: message.timestamp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to check if a file is an image based on extension
  bool _isImageFile(String? fileUrl) {
    if (fileUrl == null || fileUrl.isEmpty) return false;
    final lowerUrl = fileUrl.toLowerCase();
    return lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp') ||
        lowerUrl.endsWith('.bmp');
  }

  Widget _buildImageMessage(Message message) {
    String url = message.fileUrl ?? '';

    // Handle URL resolution
    if (url.isEmpty) {
      debugPrint('Empty image URL for message ${message.id}');
      return _buildErrorImagePlaceholder('رابط الصورة غير متوفر');
    }

    // Resolve relative URLs
    if (!url.startsWith('http')) {
      if (url.startsWith('/')) {
        url = '${AuthConfig.baseUrl}$url';
      } else {
        url = '${AuthConfig.baseUrl}/$url';
      }
    }

    debugPrint('Loading image from: $url');

    return GestureDetector(
      onTap: () => _showImageViewer(url, message.fileName),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        constraints: const BoxConstraints(
          maxWidth: 250,
          maxHeight: 300,
          minWidth: 150,
          minHeight: 100,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  final percent = progress.expectedTotalBytes != null
                      ? (progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes! *
                                100)
                            .toStringAsFixed(0)
                      : null;
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey[200],
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF1DAF52),
                            strokeWidth: 2,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            percent != null ? '$percent%' : 'جاري التحميل...',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading image: $error');
                  return _buildErrorImagePlaceholder('فشل تحميل الصورة');
                },
              ),
              // Zoom indicator overlay
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorImagePlaceholder(String message) {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, color: Colors.grey, size: 40),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdCardMessage(Message message) {
    final ad = message.adData!;
    return GestureDetector(
      onTap: () {
        if (ad.id != null && ad.id!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(listingId: ad.id!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1DAF52), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (ad.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: Image.network(
                  ad.imageUrl!.startsWith('http')
                      ? ad.imageUrl!
                      : '${AuthConfig.baseUrl}${ad.imageUrl}',
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DAF52),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'إعلان',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_back_ios,
                        size: 14,
                        color: Color(0xFF1DAF52),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ad.title ?? 'منتج',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF2B2B2A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ad.price != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${ad.price} ${ad.currency ?? ''}',
                      style: const TextStyle(
                        color: Color(0xFF1DAF52),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  if (ad.location != null && ad.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ad.location!,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 14,
                          color: Color(0xFF1DAF52),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'اضغط لعرض التفاصيل',
                          style: TextStyle(
                            color: Color(0xFF1DAF52),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background tap to close
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
            // Image viewer
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF1DAF52),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            progress.expectedTotalBytes != null
                                ? '${((progress.cumulativeBytesLoaded / progress.expectedTotalBytes!) * 100).toStringAsFixed(0)}%'
                                : 'جاري التحميل...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image, color: Colors.white, size: 60),
                        SizedBox(height: 16),
                        Text(
                          'فشل تحميل الصورة',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 40,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            // File name at bottom
            if (name != null && name.isNotEmpty)
              Positioned(
                bottom: 40,
                left: 16,
                right: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            // Zoom hint
            Positioned(
              bottom: name != null && name.isNotEmpty ? 90 : 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'اضغط مرتين للتكبير',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
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

  Widget _buildTextOrAdMessage(Message message) {
    // Check if this is an ad message by looking for ad patterns
    final isAdMessage = _isAdMessage(message.text);

    if (isAdMessage) {
      // Extract listing ID from the message
      final listingId = _extractListingId(message.text);

      if (listingId != null) {
        // Try to get ad data from cache or fetch it
        return FutureBuilder<ChatAdData?>(
          future: _getAdDataForMessage(listingId),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return _buildAdCardFromData(snapshot.data!, listingId);
            } else {
              // Show loading or fallback to text
              return _buildTextMessage(message);
            }
          },
        );
      }
    }

    return _buildTextMessage(message);
  }

  bool _isAdMessage(String text) {
    return text.contains('📦') &&
        (text.contains('مهتم بهذا الإعلان') ||
            text.contains("I'm interested in this ad") ||
            text.contains('categories/product/'));
  }

  String? _extractListingId(String text) {
    // Extract listing ID from URL pattern
    final regex = RegExp(r'categories/product/([a-f0-9-]+)');
    final match = regex.firstMatch(text);
    return match?.group(1);
  }

  Future<ChatAdData?> _getAdDataForMessage(String listingId) async {
    try {
      return await ChatService.fetchListingDetails(listingId);
    } catch (e) {
      debugPrint('Error fetching ad data for message: $e');
      return null;
    }
  }

  Widget _buildAdCardFromData(ChatAdData adData, String listingId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(listingId: listingId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1DAF52), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (adData.imageUrl != null && adData.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: Image.network(
                  adData.imageUrl!.startsWith('http')
                      ? adData.imageUrl!
                      : '${AuthConfig.baseUrl}${adData.imageUrl}',
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DAF52),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '📋 بخصوص إعلان',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_back_ios,
                        size: 14,
                        color: Color(0xFF1DAF52),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    adData.title ?? 'منتج',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF2B2B2A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (adData.price != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${adData.price} ${adData.currency ?? ''}',
                      style: const TextStyle(
                        color: Color(0xFF1DAF52),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'مرحباً، أنا مهتم بهذا الإعلان',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextMessage(Message message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: message.isSentByMe
            ? const Color(0xFF1DAF52)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: message.isSentByMe
              ? const Radius.circular(2)
              : const Radius.circular(12),
          bottomRight: message.isSentByMe
              ? const Radius.circular(12)
              : const Radius.circular(2),
        ),
      ),
      child: Text(
        message.text,
        style: TextStyle(
          fontSize: 14,
          color: message.isSentByMe ? Colors.white : Colors.black87,
          height: 1.4,
        ),
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
