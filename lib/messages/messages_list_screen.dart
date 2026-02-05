import 'package:flutter/material.dart';
import 'models/message_model.dart';
import 'models/chat_models.dart';
import 'chat_screen.dart';
import 'chat_service.dart';
import 'chat_socket.dart';

class MessagesListScreen extends StatefulWidget {
  /// Optional initial seller ID to open chat with
  final String? initialSellerId;

  /// Optional ad data for context
  final ChatAdData? adData;

  const MessagesListScreen({Key? key, this.initialSellerId, this.adData})
    : super(key: key);

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  String selectedFilter = 'الكل';
  bool _loading = false;
  List<ChatConversation> conversations = [];
  int _currentPage = 0;
  bool _hasMore = true;
  String? _currentUserId;
  ChatSocket? _socket;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loading &&
        _hasMore) {
      _loadMoreConversations();
    }
  }

  Future<void> _initializeChat() async {
    _currentUserId = await ChatService.getCurrentUserId();
    await _loadConversations();
    await _connectWebSocket();

    // Handle initial seller if provided
    if (widget.initialSellerId != null && mounted) {
      _handleInitialSeller();
    }
  }

  Future<void> _connectWebSocket() async {
    final token = await ChatService.getToken();
    if (token == null) return;

    _socket = ChatSocket(
      token: token,
      onMessage: (message) {
        if (!mounted) return;
        // Update conversation list when new message arrives
        setState(() {
          final idx = conversations.indexWhere(
            (c) => c.id == message.senderId || c.id == message.receiverId,
          );
          if (idx >= 0) {
            final conv = conversations[idx];
            conversations[idx] = conv.copyWith(
              lastMessage: Message.fromApi(message, _currentUserId ?? ''),
              unreadCount: message.senderId != _currentUserId
                  ? conv.unreadCount + 1
                  : conv.unreadCount,
            );
            // Move to top
            final updated = conversations.removeAt(idx);
            conversations.insert(0, updated);
          } else {
            // Reload conversations to get the new one
            _loadConversations();
          }
        });
      },
      onPresence: (data) {
        if (!mounted) return;
        final userId = data['userId']?.toString();
        final online = data['online'] == true;
        final lastSeen = data['lastSeen']?.toString();
        setState(() {
          conversations = conversations.map((c) {
            if (c.id == userId) {
              return c.copyWith(isOnline: online, lastSeen: lastSeen);
            }
            return c;
          }).toList();
        });
      },
    );
    _socket?.connect();
  }

  Future<void> _handleInitialSeller() async {
    final sellerId = widget.initialSellerId!;
    final exists = conversations.any((c) => c.id == sellerId);

    if (!exists) {
      // Get or create conversation
      final conv = await ChatService.getOrCreateConversation(sellerId);
      if (conv != null && mounted) {
        final newConv = ChatConversation.fromApi(conv);
        setState(() {
          conversations.insert(0, newConv);
        });
        _openChat(newConv);
      }
    } else {
      final conv = conversations.firstWhere((c) => c.id == sellerId);
      _openChat(conv);
    }
  }

  Future<void> _loadConversations() async {
    setState(() => _loading = true);
    try {
      final items = await ChatService.fetchConversations(page: 0, size: 20);
      final mapped = items.map((c) => ChatConversation.fromApi(c)).toList();
      setState(() {
        conversations = mapped;
        _currentPage = 0;
        _hasMore = items.length >= 20;
      });
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMoreConversations() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final nextPage = _currentPage + 1;
      final items = await ChatService.fetchConversations(
        page: nextPage,
        size: 20,
      );
      final mapped = items.map((c) => ChatConversation.fromApi(c)).toList();
      setState(() {
        // Deduplicate
        final existingIds = conversations.map((c) => c.id).toSet();
        final newConvs = mapped
            .where((c) => !existingIds.contains(c.id))
            .toList();
        conversations.addAll(newConvs);
        _currentPage = nextPage;
        _hasMore = items.length >= 20;
      });
    } catch (e) {
      debugPrint('Error loading more conversations: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openChat(ChatConversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatScreen(conversation: conversation, adData: widget.adData),
      ),
    ).then((_) {
      // Refresh on return
      _loadConversations();
    });
  }

  List<ChatConversation> _filtered() {
    switch (selectedFilter) {
      case 'مقروء':
        return conversations.where((c) => c.unreadCount == 0).toList();
      case 'غير مقروء':
        return conversations.where((c) => c.unreadCount > 0).toList();
      default:
        return conversations;
    }
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'الرسائل',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildFilterTabs(),
            Expanded(
              child: _loading && conversations.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1DAF52),
                      ),
                    )
                  : _filtered().isEmpty
                  ? _buildEmptyState()
                  : _buildConversationsList(_filtered()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildFilterChip('غير مقروء'),
          const SizedBox(width: 8),
          _buildFilterChip('مقروء'),
          const SizedBox(width: 8),
          _buildFilterChip('الكل'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1DAF52) : Colors.white,
          border: Border.all(color: const Color(0xFF1DAF52), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF757575),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 40,
              color: Color(0xFF1DAF52),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا يوجد محادثات',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList(List<ChatConversation> list) {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: const Color(0xFF1DAF52),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: list.length + (_hasMore && _loading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= list.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Color(0xFF1DAF52)),
              ),
            );
          }
          final conversation = list[index];
          return _buildConversationItem(conversation);
        },
      ),
    );
  }

  Widget _buildConversationItem(ChatConversation conversation) {
    return InkWell(
      onTap: () => _openChat(conversation),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: conversation.unreadCount > 0
              ? const Color(0xFFF0FDF4)
              : Colors.white,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1),
          ),
        ),
        child: Row(
          children: [
            // Avatar with online/unread indicators
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF1DAF52).withOpacity(0.1),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF1DAF52),
                    size: 28,
                  ),
                ),
                // Unread badge
                if (conversation.unreadCount > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DAF52),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        conversation.unreadCount > 9
                            ? '9+'
                            : conversation.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Online indicator
                if (conversation.isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.userName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(conversation.lastMessage.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage.text.isNotEmpty
                        ? conversation.lastMessage.text
                        : (conversation.isOnline
                              ? 'متصل الآن'
                              : _formatLastSeen(conversation.lastSeen)),
                    style: TextStyle(
                      fontSize: 14,
                      color: conversation.unreadCount > 0
                          ? Colors.black87
                          : const Color(0xFF757575),
                      fontWeight: conversation.unreadCount > 0
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
