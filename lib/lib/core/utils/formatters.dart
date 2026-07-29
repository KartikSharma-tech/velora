import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// ===========================================================
/// Velora
/// App Formatters
/// -----------------------------------------------------------
///
/// Shared date / time formatting helpers used across the app
/// (chat bubbles, chat list, presence text, etc).
///
/// ===========================================================

@immutable
final class AppFormatters {
  const AppFormatters._();

  /// 24h -> "hh:mm a" e.g. "09:41 PM" — used inside message bubbles.
  static String messageTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  /// Chat list "last message" time.
  /// Today -> "09:41 PM"
  /// Yesterday -> "Yesterday"
  /// Older -> "12/07/25"
  static String chatListTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);
    final difference = today.difference(date).inDays;

    if (difference == 0) return DateFormat('hh:mm a').format(time);
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return DateFormat('EEEE').format(time);
    return DateFormat('dd/MM/yy').format(time);
  }

  /// Date separator chip inside a chat thread.
  /// Today -> "Today"
  /// Yesterday -> "Yesterday"
  /// Older -> "12 July 2025"
  static String dateSeparator(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);
    final difference = today.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat('d MMMM yyyy').format(time);
  }

  /// Presence text shown under the receiver's name in the chat app bar.
  static String presence({required bool isOnline, DateTime? lastSeen}) {
    if (isOnline) return 'Online';

    if (lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(lastSeen.year, lastSeen.month, lastSeen.day);
    final difference = today.difference(date).inDays;

    final time = DateFormat('hh:mm a').format(lastSeen);

    if (difference == 0) return 'Last seen today at $time';
    if (difference == 1) return 'Last seen yesterday at $time';
    return 'Last seen ${DateFormat('d MMM').format(lastSeen)} at $time';
  }

  /// Whether two timestamps fall on different calendar days —
  /// used to decide when to insert a date separator.
  static bool isDifferentDay(DateTime a, DateTime b) {
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }
}
