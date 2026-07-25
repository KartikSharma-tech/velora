import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Bottom message-composer bar: emoji + attach icons, growable text
/// field, and a send button that only lights up once there's text.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.hasText,
    this.onAttachTap,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool hasText;
  final VoidCallback? onAttachTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.inputFillDark : AppColors.surfaceVariant;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.dividerDark : AppColors.divider,
              width: .6,
            ),
          ),
        ),
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
    );
  }
}
