import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/message_model.dart';

/// A single chat bubble — sender (right, primary color) or
/// receiver (left, surface variant), WhatsApp-style tail radius,
/// reply quote, emoji reactions, and read-receipt ticks.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.highlighted = false,
    this.onLongPress,
  });

  final MessageModel message;
  final bool isMe;
  final bool highlighted;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (message.isDeletedForEveryone) {
      return _DeletedBubble(isMe: isMe);
    }

    final bubbleColor = isMe
        ? (isDark ? AppColors.senderBubbleDark : AppColors.senderBubble)
        : (isDark ? AppColors.receiverBubbleDark : AppColors.receiverBubble);

    final textColor = isMe
        ? (isDark ? AppColors.senderTextDark : AppColors.senderText)
        : (isDark ? AppColors.receiverTextDark : AppColors.receiverText);

    final timeColor = isMe
        ? Colors.white.withValues(alpha: .75)
        : (isDark ? AppColors.textHintDark : AppColors.textHint);

    final hasReply =
        message.replyToText != null && message.replyToText!.isNotEmpty;
    final reactionEmojis = message.reactions.values.toSet().toList();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * .78,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: highlighted
                      ? AppColors.primary.withValues(alpha: .25)
                      : bubbleColor,
                  borderRadius: isMe
                      ? AppRadius.senderBubble
                      : AppRadius.receiverBubble,
                  boxShadow: AppShadows.chatBubble,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasReply)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (isMe ? Colors.white : AppColors.primary)
                              .withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: isMe ? Colors.white : AppColors.primary,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.replyToSenderName ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isMe ? Colors.white : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message.replyToText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      message.text,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15.5,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppFormatters.messageTime(message.timestamp),
                          style: TextStyle(fontSize: 10.5, color: timeColor),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _StatusIcon(status: message.status),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (reactionEmojis.isNotEmpty)
                Positioned(
                  bottom: -10,
                  right: isMe ? 8 : null,
                  left: isMe ? null : 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surface,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: AppShadows.chatBubble,
                    ),
                    child: Text(
                      reactionEmojis.take(3).join(),
                      style: const TextStyle(fontSize: 12),
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

/// Renders the 4-state message status: Sending (clock) → Sent
/// (single tick) → Delivered (grey double tick) → Read (blue
/// double tick).
class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.white.withValues(alpha: .75),
          ),
        );
      case MessageStatus.sent:
        return Icon(
          Icons.done_rounded,
          size: 15,
          color: Colors.white.withValues(alpha: .75),
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all_rounded,
          size: 15,
          color: Colors.white.withValues(alpha: .75),
        );
      case MessageStatus.read:
        return Icon(
          Icons.done_all_rounded,
          size: 15,
          color: AppColors.seen,
        );
    }
  }
}

class _DeletedBubble extends StatelessWidget {
  const _DeletedBubble({required this.isMe});

  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariant,
          borderRadius: isMe
              ? AppRadius.senderBubble
              : AppRadius.receiverBubble,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block_rounded,
              size: 15,
              color: isDark ? AppColors.textHintDark : AppColors.textHint,
            ),
            const SizedBox(width: 6),
            Text(
              'This message was deleted',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: isDark ? AppColors.textHintDark : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
