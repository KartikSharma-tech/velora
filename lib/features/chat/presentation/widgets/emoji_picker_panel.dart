import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// A lightweight, dependency-free emoji panel (no emoji_picker_flutter
/// package in this project). Slides up under the input bar, WhatsApp
/// style, and inserts the tapped emoji at the current cursor position.
///
/// BUG FIX: the emoji icon in the composer had an empty
/// `onPressed: () {}` — visually present but did nothing when tapped.
class EmojiPickerPanel extends StatelessWidget {
  const EmojiPickerPanel({super.key, required this.onEmojiSelected});

  final ValueChanged<String> onEmojiSelected;

  static const _emojis = [
    '😀', '😁', '😂', '🤣', '😊', '😍', '😘', '😜',
    '🤔', '😎', '😢', '😭', '😡', '😱', '🥳', '🤩',
    '👍', '👎', '👏', '🙏', '💪', '👌', '✌️', '🤝',
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '💔',
    '🔥', '✨', '🎉', '🎂', '🎁', '🌹', '⭐', '☀️',
    '😴', '🤗', '🤭', '😉', '😅', '🙄', '😇', '🥰',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.divider,
            width: .6,
          ),
        ),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
        ),
        itemCount: _emojis.length,
        itemBuilder: (context, index) {
          final emoji = _emojis[index];
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onEmojiSelected(emoji),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          );
        },
      ),
    );
  }
}
