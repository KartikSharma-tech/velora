import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/message_model.dart';
import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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
  ConsumerState<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState
    extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    final senderId =
        ref.read(currentUserIdProvider);

    if (senderId == null) return;

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
    );

    await ref
        .read(chatRepositoryProvider)
        .sendMessage(message);

    _messageController.clear();

    await Future.delayed(
      const Duration(milliseconds: 150),
    );

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(messagesProvider(widget.roomId));

    final currentUserId =
        ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
      ),
      body:messagesAsync.when(
  data: (messages) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];

              final isMe =
                  message.senderId == currentUserId;

              return Align(
                alignment: isMe
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.of(context).size.width *
                            .75,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                        : Colors.grey.shade300,
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              12,
              8,
              12,
              12,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textCapitalization:
                        TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(30),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),

                const SizedBox(width: 10),

                CircleAvatar(
                  radius: 25,
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(
                      Icons.send_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  },
  loading: () => const Center(
    child: CircularProgressIndicator(),
  ),
  error: (error, stackTrace) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        error.toString(),
        textAlign: TextAlign.center,
      ),
    ),
  ),
),    );
  }
}