import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../data/models/chat_request_model.dart';
import '../providers/chat_request_provider.dart';

class ChatRequestsScreen extends ConsumerStatefulWidget {
  const ChatRequestsScreen({super.key});

  @override
  ConsumerState<ChatRequestsScreen> createState() => _ChatRequestsScreenState();
}

class _ChatRequestsScreenState extends ConsumerState<ChatRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _respond(ChatRequestModel request, bool accept) async {
    await ref.read(chatRequestRepositoryProvider).respondToRequest(
          requestId: request.id,
          accept: accept,
        );

    if (accept) {
      await ref.read(chatRepositoryProvider).createChatRoom(
        participants: [request.fromUserId, request.toUserId],
      );

      if (mounted) {
        context.push(
          AppRouter.chat,
          extra: {
            'roomId': ([request.fromUserId, request.toUserId]..sort()).join('_'),
            'receiverId': request.fromUserId,
            'receiverName': request.fromUserName,
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: context.canPop(),
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.go(AppRouter.home);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chat Requests'),
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => AppRouter.backOrHome(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Incoming'),
              Tab(text: 'Sent'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _IncomingList(userId: currentUserId, onRespond: _respond),
            _OutgoingList(userId: currentUserId),
          ],
        ),
      ),
    );
  }
}

class _IncomingList extends ConsumerWidget {
  const _IncomingList({required this.userId, required this.onRespond});

  final String userId;
  final void Function(ChatRequestModel request, bool accept) onRespond;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(incomingChatRequestsProvider(userId));

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (requests) {
        if (requests.isEmpty) {
          return const Center(child: Text('No pending requests'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.avatarBackground,
                          backgroundImage: request.fromUserPhoto.isNotEmpty
                              ? NetworkImage(request.fromUserPhoto)
                              : null,
                          child: request.fromUserPhoto.isEmpty
                              ? Text(request.fromUserName.isEmpty
                                  ? '?'
                                  : request.fromUserName[0].toUpperCase())
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(request.fromUserName,
                                  style:
                                      const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                AppFormatters.chatListTime(request.createdAt),
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textHint),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (request.message.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(request.message),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => onRespond(request, false),
                            child: const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => onRespond(request, true),
                            child: const Text('Accept'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OutgoingList extends ConsumerWidget {
  const _OutgoingList({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(outgoingChatRequestsProvider(userId));

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (requests) {
        if (requests.isEmpty) {
          return const Center(child: Text('No sent requests'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];

            final Color statusColor;
            switch (request.status) {
              case ChatRequestStatus.pending:
                statusColor = AppColors.textHint;
                break;
              case ChatRequestStatus.accepted:
                statusColor = AppColors.online;
                break;
              case ChatRequestStatus.declined:
                statusColor = AppColors.error;
                break;
            }

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.avatarBackground,
                backgroundImage: request.toUserPhoto.isNotEmpty
                    ? NetworkImage(request.toUserPhoto)
                    : null,
                child: request.toUserPhoto.isEmpty
                    ? Text(request.toUserName.isEmpty
                        ? '?'
                        : request.toUserName[0].toUpperCase())
                    : null,
              ),
              title: Text(
                request.toUserName.isEmpty ? request.toUserId : request.toUserName,
              ),
              subtitle: Text(AppFormatters.chatListTime(request.createdAt)),
              trailing: Chip(
                label: Text(
                  request.status.name[0].toUpperCase() +
                      request.status.name.substring(1),
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
                backgroundColor: statusColor.withValues(alpha: .1),
              ),
            );
          },
        );
      },
    );
  }
}
