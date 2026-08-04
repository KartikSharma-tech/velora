import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat_requests/presentation/providers/chat_request_provider.dart';
import '../../../user/data/models/user_model.dart';
import '../../../user/presentation/providers/user_provider.dart';

/// Shown when messaging [target] requires a Chat Request first
/// (their "Who can message me" is Contacts + Accepted Requests and
/// the sender isn't a matched contact).
class SendRequestSheet extends ConsumerStatefulWidget {
  const SendRequestSheet({super.key, required this.target});

  final UserModel target;

  @override
  ConsumerState<SendRequestSheet> createState() => _SendRequestSheetState();
}

class _SendRequestSheetState extends ConsumerState<SendRequestSheet> {
  final _messageController = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    setState(() => _sending = true);

    final myUser = await ref.read(userRepositoryProvider).getUser(currentUserId);

    await ref.read(chatRequestRepositoryProvider).sendRequest(
          fromUserId: currentUserId,
          fromUserName: myUser?.name ?? '',
          fromUserPhoto: myUser?.photoUrl ?? '',
          toUserId: widget.target.uid,
          toUserName: widget.target.name,
          toUserPhoto: widget.target.photoUrl,
          message: _messageController.text.trim(),
        );

    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _sent
            ? [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.online, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Request sent to ${widget.target.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  "You'll be able to chat once they accept.",
                  style: TextStyle(color: AppColors.textHint),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
              ]
            : [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.avatarBackground,
                      backgroundImage: widget.target.photoUrl.isNotEmpty
                          ? NetworkImage(widget.target.photoUrl)
                          : null,
                      child: widget.target.photoUrl.isEmpty
                          ? Text(widget.target.name.isEmpty
                              ? '?'
                              : widget.target.name[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.target.name,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            "${widget.target.name} only accepts messages from "
                            "contacts or accepted requests.",
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _messageController,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText: "Say why you'd like to connect (optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Send Chat Request'),
                  ),
                ),
              ],
      ),
    );
  }
}
