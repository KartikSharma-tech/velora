import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/message_model.dart';
import '../../domain/repositories/chat_repository.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/chat_date_separator.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/emoji_picker_panel.dart';
import '../widgets/message_bubble.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';

const _quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.roomId,
    required this.receiverId,
    required this.receiverName,
  });

  final String roomId;
  final String receiverId;
  final String receiverName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _hasText = false;
  bool _isSearching = false;
  String _searchQuery = '';
  MessageModel? _replyingTo;

  Timer? _typingTimer;
  bool _iAmTyping = false;
  bool _showEmojiPicker = false;

  // BUG FIX: `dispose()` used to call `_setTyping(false)`, which
  // internally did `ref.read(...)`. Riverpod throws
  // `StateError: Cannot use "ref" after the widget was disposed`
  // the moment any teardown work touches `ref` inside/after
  // dispose(). Both of these are captured *eagerly* in initState()
  // (while `ref` is still valid) so cleanup never needs to read a
  // provider again — note these are plain fields assigned in
  // initState, not `late final ... = ref.read(...)`, because a
  // lazy `late` initializer would only run on first access, and if
  // that first access happened to be inside dispose() itself
  // (e.g. the user never typed anything) it would hit the exact
  // same disposed-ref crash.
  String? _currentUserId;
  late ChatRepository _chatRepository;

  @override
  void initState() {
    super.initState();
    _currentUserId = ref.read(currentUserIdProvider);
    _chatRepository = ref.read(chatRepositoryProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _markSeen());
    // BUG FIX: nothing ever flipped a message's isSeen to true or
    // the room's lastMessageSeen flag, so the double-tick / unread
    // dot never updated. Mark seen once on open, and again every
    // time a new message streams in while the thread is open.
    ref.listenManual(messagesProvider(widget.roomId), (previous, next) {
      next.whenData((_) => _markSeen());
    });
  }

  Future<void> _markSeen() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final repo = ref.read(chatRepositoryProvider);
    await repo.markLastMessageSeen(widget.roomId);
    await repo.markMessagesSeen(roomId: widget.roomId, currentUserId: userId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    // Uses the cached repository/userId from above — never `ref`.
    if (_iAmTyping && _currentUserId != null) {
      _chatRepository.setTyping(
        roomId: widget.roomId,
        userId: _currentUserId!,
        isTyping: false,
      );
    }
    super.dispose();
  }

  // ============================================================
  // Emoji picker
  // ============================================================

  void _toggleEmojiPicker() {
    FocusScope.of(context).unfocus();
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;

    final cursor = selection.start >= 0 ? selection.start : text.length;

    final newText = text.replaceRange(cursor, cursor, emoji);

    _messageController.value = _messageController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + emoji.length),
    );

    _onTextChanged(newText);
  }

  // ============================================================
  // Typing indicator
  // ============================================================

  void _onTextChanged(String value) {
    final hasText = value.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);

    if (!_iAmTyping) _setTyping(true);

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () => _setTyping(false));
  }

  void _setTyping(bool isTyping) {
    final userId = _currentUserId;
    if (userId == null || _iAmTyping == isTyping) return;
    _iAmTyping = isTyping;
    _chatRepository.setTyping(
      roomId: widget.roomId,
      userId: userId,
      isTyping: isTyping,
    );
  }

  // ============================================================
  // Send
  // ============================================================

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final senderId = ref.read(currentUserIdProvider);
    if (senderId == null) return;

    final replyTo = _replyingTo;

    final message = MessageModel(
      id: const Uuid().v4(),
      chatRoomId: widget.roomId,
      senderId: senderId,
      receiverId: widget.receiverId,
      text: text,
      type: 'text',
      timestamp: DateTime.now(),
      isSeen: false,
      imageUrl: null,
      replyToId: replyTo?.id,
      replyToText: replyTo?.text,
      replyToSenderName: replyTo == null
          ? null
          : (replyTo.senderId == senderId ? 'You' : widget.receiverName),
    );

    _messageController.clear();
    _typingTimer?.cancel();
    _setTyping(false);
    setState(() {
      _hasText = false;
      _replyingTo = null;
    });

    await ref.read(chatRepositoryProvider).sendMessage(message);

    await Future.delayed(const Duration(milliseconds: 150));

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ============================================================
  // Message actions (long press)
  // ============================================================

  void _openMessageActions(MessageModel message, bool isMe) {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _quickReactions.map((emoji) {
                  final isSelected = message.reactions[currentUserId] == emoji;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(chatRepositoryProvider).toggleReaction(
                            roomId: widget.roomId,
                            messageId: message.id,
                            userId: currentUserId,
                            emoji: isSelected ? null : emoji,
                          );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: .15)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
              const Divider(height: 20),
              ListTile(
                leading: const Icon(Icons.reply_rounded),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _replyingTo = message.copyWith(
                      replyToSenderName:
                          message.senderId == currentUserId ? 'You' : widget.receiverName,
                    );
                  });
                },
              ),
              if (message.text.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.copy_rounded),
                  title: const Text('Copy'),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: message.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: Text(
                  'Delete for me',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(chatRepositoryProvider).deleteMessageForMe(
                        roomId: widget.roomId,
                        messageId: message.id,
                        userId: currentUserId,
                      );
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                  title: Text(
                    'Delete for everyone',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(chatRepositoryProvider).deleteMessageForEveryone(
                          roomId: widget.roomId,
                          messageId: message.id,
                        );
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // Block / Unblock
  // ============================================================

  Future<void> _toggleBlock(bool currentlyBlocked) async {
    final myId = ref.read(currentUserIdProvider);
    if (myId == null) return;

    final repo = ref.read(userRepositoryProvider);

    if (currentlyBlocked) {
      await repo.unblockUser(uid: myId, blockedUid: widget.receiverId);
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Block user?'),
          content: Text(
            "You won't be able to send or receive messages from ${widget.receiverName}.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Block'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await repo.blockUser(uid: myId, blockedUid: widget.receiverId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.roomId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final myUserAsync = currentUserId == null
        ? const AsyncValue<dynamic>.data(null)
        : ref.watch(currentUserProvider(currentUserId));
    final receiverUserAsync = ref.watch(currentUserProvider(widget.receiverId));

    final iHaveBlockedThem = myUserAsync.maybeWhen(
      data: (user) => user?.blockedUsers.contains(widget.receiverId) ?? false,
      orElse: () => false,
    );
    final theyHaveBlockedMe = receiverUserAsync.maybeWhen(
      data: (user) => user?.blockedUsers.contains(currentUserId) ?? false,
      orElse: () => false,
    );

    return PopScope(
      canPop: context.canPop(),
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.go(AppRouter.home);
      },
      child: Scaffold(
      appBar: _isSearching
          ? AppBar(
              titleSpacing: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                }),
              ),
              title: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search messages',
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _searchQuery = value.trim()),
              ),
            )
          : ChatAppBar(
              roomId: widget.roomId,
              receiverId: widget.receiverId,
              receiverName: widget.receiverName,
              isBlocked: iHaveBlockedThem,
              onToggleBlock: () => _toggleBlock(iHaveBlockedThem),
              onSearchTap: () => setState(() => _isSearching = true),
            ),
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      body: messagesAsync.when(
        data: (allMessages) {
          final messages = currentUserId == null
              ? allMessages
              : allMessages.where((m) => m.isVisibleTo(currentUserId)).toList();

          final visibleMessages = _searchQuery.isEmpty
              ? messages
              : messages
                  .where((m) => m.text
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
                  .toList();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_searchQuery.isEmpty && _scrollController.hasClients) {
              _scrollController.jumpTo(
                _scrollController.position.maxScrollExtent,
              );
            }
          });

          final inputBar = ChatInputBar(
            controller: _messageController,
            onSend: _sendMessage,
            hasText: _hasText,
            onChanged: _onTextChanged,
            replyingTo: _replyingTo,
            onCancelReply: () => setState(() => _replyingTo = null),
            enabled: !iHaveBlockedThem && !theyHaveBlockedMe,
            disabledHint: iHaveBlockedThem
                ? 'You have blocked this user'
                : "You can't message this user",
            onEmojiTap: _toggleEmojiPicker,
            emojiPickerOpen: _showEmojiPicker,
            onAttachTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
            },
          );

          final emojiPanel = _showEmojiPicker
              ? EmojiPickerPanel(onEmojiSelected: _insertEmoji)
              : const SizedBox.shrink();

          if (visibleMessages.isEmpty) {
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty
                                ? Icons.search_off_rounded
                                : Icons.chat_bubble_outline_rounded,
                            size: 56,
                            color: AppColors.primary.withValues(alpha: .5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No messages found'
                                : 'Say hi to ${widget.receiverName} 👋',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                inputBar,
                emojiPanel,
              ],
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  itemCount: visibleMessages.length,
                  itemBuilder: (context, index) {
                    final message = visibleMessages[index];
                    final isMe = message.senderId == currentUserId;

                    final showDateSeparator = _searchQuery.isEmpty &&
                        (index == 0 ||
                            AppFormatters.isDifferentDay(
                              visibleMessages[index - 1].timestamp,
                              message.timestamp,
                            ));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDateSeparator)
                          ChatDateSeparator(date: message.timestamp),
                        MessageBubble(
                          message: message,
                          isMe: isMe,
                          highlighted: _searchQuery.isNotEmpty,
                          onLongPress: message.isDeletedForEveryone
                              ? null
                              : () => _openMessageActions(message, isMe),
                        ),
                      ],
                    );
                  },
                ),
              ),
              inputBar,
              emojiPanel,
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
      ),
      ),
    );
  }
}
