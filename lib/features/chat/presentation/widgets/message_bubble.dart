import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/message_model.dart';

/// A single chat bubble — sender (right, primary color) or
/// receiver (left, surface variant), WhatsApp-style tail radius,
/// timestamp + read-receipt ticks baked into the bottom-right corner.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  final MessageModel message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleColor = isMe
        ? (isDark ? AppColors.senderBubbleDark : AppColors.senderBubble)
        : (isDark ? AppColors.receiverBubbleDark : AppColors.receiverBubble);

    final textColor = isMe
        ? (isDark ? AppColors.senderTextDark : AppColors.senderText)
        : (isDark ? AppColors.receiverTextDark : AppColors.receiverText);

    final timeColor = isMe
        ? Colors.white.withValues(alpha: .75)
        : (isDark ? AppColors.textHintDark : AppColors.textHint);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * .78,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius:
                isMe ? AppRadius.senderBubble : AppRadius.receiverBubble,
            boxShadow: AppShadows.chatBubble,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.text,
                style: TextStyle(color: textColor, fontSize: 15.5, height: 1.3),
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
                    Icon(
                      message.isSeen ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 15,
                      color: message.isSeen
                          ? AppColors.seen
                          : Colors.white.withValues(alpha: .75),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
