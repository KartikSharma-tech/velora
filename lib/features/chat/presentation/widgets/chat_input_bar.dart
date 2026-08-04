import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/message_model.dart';

/// Bottom message-composer bar: optional reply preview, emoji +
/// attach icons, growable text field, and a send button that only
/// lights up once there's text.
///
/// BUG FIX (blue border / unprofessional look): the inner `TextField`
/// only set `border: InputBorder.none`. In Flutter, `border` is just
/// the *fallback* — `enabledBorder` / `focusedBorder` / `errorBorder`
/// each independently fall back to the app's global
/// `InputDecorationTheme` when not set on the widget itself. This
/// app's theme defines a blue `focusedBorder`, so the instant the
/// field gained focus, a rectangular blue outline rendered *inside*
/// the rounded pill container around it. All border variants are now
/// explicitly set to `InputBorder.none` so nothing from the theme can
/// leak through.
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
    this.onEmojiTap,
    this.emojiPickerOpen = false,
    this.focusNode,
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
  final VoidCallback? onEmojiTap;
  final bool emojiPickerOpen;
  final FocusNode? focusNode;

  static const _noBorder = InputBorder.none;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        isDark ? AppColors.inputFillDark : AppColors.surfaceVariant;

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
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'Emoji',
                            splashRadius: 22,
                            icon: Icon(
                              emojiPickerOpen
                                  ? Icons.keyboard_alt_outlined
                                  : Icons.emoji_emotions_outlined,
                              color: emojiPickerOpen
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.iconSecondaryDark
                                      : AppColors.iconSecondary),
                            ),
                            onPressed: onEmojiTap,
                          ),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              focusNode: focusNode,
                              textCapitalization: TextCapitalization.sentences,
                              minLines: 1,
                              maxLines: 5,
                              style: const TextStyle(fontSize: 15.5),
                              cursorColor: AppColors.primary,
                              decoration: const InputDecoration(
                                hintText: 'Message',
                                isCollapsed: true,
                                filled: false,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 14),
                                border: _noBorder,
                                enabledBorder: _noBorder,
                                focusedBorder: _noBorder,
                                disabledBorder: _noBorder,
                                errorBorder: _noBorder,
                                focusedErrorBorder: _noBorder,
                              ),
                              onChanged: onChanged,
                              onSubmitted: (_) => onSend(),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Attach',
                            splashRadius: 22,
                            icon: Icon(
                              Icons.attach_file_rounded,
                              color: isDark
                                  ? AppColors.iconSecondaryDark
                                  : AppColors.iconSecondary,
                            ),
                            onPressed: onAttachTap ?? () {},
                          ),
                          const SizedBox(width: 2),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: SizedBox(
                      key: ValueKey(hasText),
                      width: 48,
                      height: 48,
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary,
                        child: IconButton(
                          splashRadius: 22,
                          onPressed: hasText ? onSend : () {},
                          icon: Icon(
                            hasText ? Icons.send_rounded : Icons.mic_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
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
