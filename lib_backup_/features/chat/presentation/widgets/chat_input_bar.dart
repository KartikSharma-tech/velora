import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/message_model.dart';

/// Bottom message-composer bar: optional reply preview, emoji +
/// attach icons, growable text field, and a send button that only
/// lights up once there's text.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.hasText,
    this.onChanged,
    this.onAttachTap,
    this.replyingTo,
    this.onCancelReply,
    this.enabled = true,
    this.disabledHint,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool hasText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onAttachTap;
  final MessageModel? replyingTo;
  final VoidCallback? onCancelReply;
  final bool enabled;
  final String? disabledHint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.inputFillDark : AppColors.surfaceVariant;

    if (!enabled) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.dividerDark : AppColors.divider,
                width: .6,
              ),
            ),
          ),
          child: Text(
            disabledHint ?? "You can't reply to this conversation",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textHintDark : AppColors.textHint,
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.dividerDark : AppColors.divider,
              width: .6,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyingTo != null)
              Container(
                margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: const BorderSide(color: AppColors.primary, width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Replying to ${replyingTo!.replyToSenderName ?? ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            replyingTo!.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: onCancelReply,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      padding: const EdgeInsets.only(left: 6, right: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'Emoji',
                            icon: Icon(
                              Icons.emoji_emotions_outlined,
                              color: isDark
                                  ? AppColors.iconSecondaryDark
                                  : AppColors.iconSecondary,
                            ),
                            onPressed: () {},
                          ),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              textCapitalization: TextCapitalization.sentences,
                              minLines: 1,
                              maxLines: 5,
                              style: const TextStyle(fontSize: 15.5),
                              decoration: const InputDecoration(
                                hintText: 'Message',
                                border: InputBorder.none,
                                isCollapsed: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 14),
                              ),
                              onChanged: onChanged,
                              onSubmitted: (_) => onSend(),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Attach',
                            icon: Icon(
                              Icons.attach_file_rounded,
                              color: isDark
                                  ? AppColors.iconSecondaryDark
                                  : AppColors.iconSecondary,
                            ),
                            onPressed: onAttachTap ?? () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: CircleAvatar(
                      key: ValueKey(hasText),
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      child: IconButton(
                        onPressed: hasText ? onSend : () {},
                        icon: Icon(
                          hasText ? Icons.send_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
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
}
