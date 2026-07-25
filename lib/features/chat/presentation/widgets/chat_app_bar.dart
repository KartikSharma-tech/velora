import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../user/presentation/providers/user_provider.dart';

/// Chat screen app bar — receiver's avatar (with live online dot),
/// name, and a "Online" / "Last seen ..." presence line driven by
/// the existing [currentUserProvider] stream.
class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ChatAppBar({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  final String receiverId;
  final String receiverName;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiverAsync = ref.watch(currentUserProvider(receiverId));

    return AppBar(
      titleSpacing: 0,
      title: receiverAsync.when(
        data: (user) {
          final photoUrl = user?.photoUrl ?? '';
          final isOnline = user?.isOnline ?? false;

          return Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: AppColors.avatarBackground,
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl.isEmpty
                        ? Text(
                            receiverName.isEmpty
                                ? '?'
                                : receiverName[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          )
                        : null,
                  ),
                  if (isOnline)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: AppColors.online,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).appBarTheme.backgroundColor ??
                                Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receiverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      AppFormatters.presence(
                        isOnline: isOnline,
                        lastSeen: user?.lastSeen,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isOnline
                            ? AppColors.online
                            : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: AppColors.avatarBackground,
              child: Text(
                receiverName.isEmpty ? '?' : receiverName[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              receiverName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        error: (_, _) => Text(receiverName),
      ),
      actions: [
        IconButton(
          tooltip: 'Voice call',
          icon: const Icon(Icons.call_outlined),
          onPressed: () => _comingSoon(context),
        ),
        IconButton(
          tooltip: 'Video call',
          icon: const Icon(Icons.videocam_outlined),
          onPressed: () => _comingSoon(context),
        ),
      ],
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }
}
