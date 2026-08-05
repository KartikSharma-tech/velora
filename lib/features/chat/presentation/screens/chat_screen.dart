import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _imagePicker = ImagePicker();

bool _isUploadingImage = false;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  bool _hasText = false;
  bool _isSearching = false;
  bool _showEmojiPicker = false;
  String _searchQuery = '';
  MessageModel? _replyingTo;

  Timer? _typingTimer;
  bool _iAmTyping = false;

  // BUG FIX: dispose() used to call `_setTyping(false)`, which did
  // `ref.read(...)` — Riverpod throws once a widget is disposed.
  // These are captured eagerly in initState() (while `ref` is
  // guaranteed valid) so cleanup never has to touch `ref` again.
  // (Plain fields assigned in initState, not `late final ... =
  // ref.read(...)`, because a *lazy* `late` initializer would only
  // run on first access — and if that first access happened to be
  // inside dispose() itself, it would hit the same crash.)
  String? _currentUserId;
  late ChatRepository _chatRepository;

  // Messages we've sent locally but haven't been confirmed by
  // Firestore yet — rendered as an optimistic "Sending…" bubble
  // (clock icon) so the UI never feels like it swallowed a tap.
  final List<MessageModel> _pendingMessages = [];

  @override
  void initState() {
    super.initState();
    _currentUserId = ref.read(currentUserIdProvider);
    _chatRepository = ref.read(chatRepositoryProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) => _markSeen());

    // BUG FIX: message status (delivered/seen ticks) was wired up
    // in a `_updateMessageStatus` method that was never actually
    // called — the only call site was commented out. This listener
    // is the real trigger: every time the message stream emits
    // (chat opened, or a new message arrives while it's open), any
    // pending Sending/Sent messages addressed to us get marked
    // delivered, and — since we're actively viewing the thread —
    // seen too.
    ref.listenManual(messagesProvider(widget.roomId), (previous, next) {
      next.whenData((messages) {
        _reconcilePendingMessages(messages);
        _markSeen();
        _updateIncomingMessageStatus(messages);
      });
    });
  }

  /// Drops any locally-optimistic message once the real one shows
  /// up in the Firestore-backed stream (same id), so it isn't
  /// rendered twice.
  void _reconcilePendingMessages(List<MessageModel> messages) {
    if (_pendingMessages.isEmpty) return;
    final confirmedIds = messages.map((m) => m.id).toSet();
    final before = _pendingMessages.length;
    _pendingMessages.removeWhere((m) => confirmedIds.contains(m.id));
    if (_pendingMessages.length != before && mounted) setState(() {});
  }

  Future<void> _updateIncomingMessageStatus(List<MessageModel> messages) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    for (final message in messages) {
      if (message.receiverId != currentUserId) continue;

      if (!message.isDelivered) {
        await _chatRepository.markMessageDelivered(
          roomId: widget.roomId,
          messageId: message.id,
        );
      }

      if (!message.isSeen) {
        await _chatRepository.markMessageSeen(
          roomId: widget.roomId,
          messageId: message.id,
        );
      }
    }
  }

  Future<void> _markSeen() async {
    await _chatRepository.markLastMessageSeen(widget.roomId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _typingTimer?.cancel();
    // Uses the cached repository/userId from initState — never `ref`.
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
  // Emoji picker
  // ============================================================

  void _toggleEmojiPicker() {
    if (!_showEmojiPicker) _messageFocusNode.unfocus();
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
  // Send
  
  Future<void> _showAttachmentOptions() async {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _pickImage(ImageSource source) async {
  final pickedFile = await _imagePicker.pickImage(
    source: source,
    imageQuality: 80,
  );

  if (pickedFile == null) return;

  final senderId = _currentUserId;
  if (senderId == null) return;

  setState(() {
    _isUploadingImage = true;
  });

  try {
    final messageId = const Uuid().v4();

    final imageUrl = await _chatRepository.uploadChatImage(
      imageFile: File(pickedFile.path),
      roomId: widget.roomId,
      messageId: messageId,
    );

    final message = MessageModel(
      id: messageId,
      chatRoomId: widget.roomId,
      senderId: senderId,
      receiverId: widget.receiverId,
      text: '',
      type: 'image',
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      isSeen: false,
      replyToId: _replyingTo?.id,
      replyToText: _replyingTo?.text,
      replyToSenderName: _replyingTo == null
          ? null
          : (_replyingTo!.senderId == senderId
              ? 'You'
              : widget.receiverName),
    );

    await _chatRepository.sendImageMessage(message);

    setState(() {
      _replyingTo = null;
    });

    _scrollToBottom();
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image upload failed\n$e'),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }
}
  // ============================================================

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final senderId = _currentUserId;
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
      // Optimistic bubble: shows instantly with a "Sending…" clock
      // icon instead of waiting on the Firestore round-trip.
      _pendingMessages.add(message.copyWith(isPending: true));
    });

    _scrollToBottom();

    try {
      await _chatRepository.sendMessage(message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _pendingMessages.removeWhere((m) => m.id == message.id);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Message failed to send')));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ============================================================
  // Message actions (long press)
  // ============================================================

  void _openMessageActions(MessageModel message, bool isMe) {
    final currentUserId = _currentUserId;
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
                      _chatRepository.toggleReaction(
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
                      replyToSenderName: message.senderId == currentUserId
                          ? 'You'
                          : widget.receiverName,
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
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                title: Text(
                  'Delete for me',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _chatRepository.deleteMessageForMe(
                    roomId: widget.roomId,
                    messageId: message.id,
                    userId: currentUserId,
                  );
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever_rounded,
                    color: AppColors.error,
                  ),
                  title: Text(
                    'Delete for everyone',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _chatRepository.deleteMessageForEveryone(
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
    final myId = _currentUserId;
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

    // BUG FIX (back navigation): if there's nothing to pop back to
    // (e.g. this screen was deep-linked directly), fall back to
    // Home instead of leaving "back" stuck doing nothing / letting
    // the OS decide.
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
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.trim()),
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
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.background,
        body: messagesAsync.when(
          data: (streamMessages) {
            final allMessages = [...streamMessages, ..._pendingMessages]
              ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

            final messages = currentUserId == null
                ? allMessages
                : allMessages
                      .where((m) => m.isVisibleTo(currentUserId))
                      .toList();

            final visibleMessages = _searchQuery.isEmpty
                ? messages
                : messages
                      .where(
                        (m) => m.text.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      )
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
              focusNode: _messageFocusNode,
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
             onAttachTap: _showAttachmentOptions,
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

                      final showDateSeparator =
                          _searchQuery.isEmpty &&
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
                            onLongPress:
                                message.isDeletedForEveryone ||
                                    message.isPending
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
