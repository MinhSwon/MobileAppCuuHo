import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';
import 'package:mobile_flutter/features/chat/presentation/request_chat_screen.dart';
import 'package:mobile_flutter/features/rescue/utils/rescue_team_helpers.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({
    super.key,
    required this.api,
    required this.user,
    required this.profile,
    required this.data,
    required this.onChanged,
  });

  final ApiClient api;
  final Map<String, dynamic> user;
  final Map<String, dynamic>? profile;
  final AppData data;
  final Future<void> Function() onChanged;

  bool get isRescue =>
      ['RESCUE_LEADER', 'RESCUE_MEMBER'].contains(valueOf(user, 'role'));
  bool get isAdmin =>
      ['ADMIN', 'SUPER_ADMIN', 'DISPATCHER'].contains(valueOf(user, 'role'));

  List<Map<String, dynamic>> get visibleRequests {
    final userId = valueOf(user, 'id');
    final phone = valueOf(user, 'phone');

    if (isRescue) {
      final team = currentRescueTeam(user, data);
      final teamId = valueOf(team, 'id');
      final missionRequestIds = data.missions
          .where((mission) => valueOf(mission, 'rescue_team_id') == teamId)
          .map((mission) => valueOf(mission, 'rescue_request_id'))
          .where((id) => id.isNotEmpty)
          .toSet();

      return data.requests.where((request) {
        return valueOf(request, 'assigned_team_id') == teamId ||
            missionRequestIds.contains(valueOf(request, 'id'));
      }).toList();
    }

    if (isAdmin) {
      return data.requests;
    }

    return data.requests.where((request) {
      final isOwner =
          valueOf(request, 'user_id') == userId ||
          valueOf(request, 'created_by_user_id') == userId ||
          (phone.isNotEmpty && valueOf(request, 'phone') == phone);
      return isOwner && valueOf(request, 'assigned_team_id').isNotEmpty;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final requests = visibleRequests.toList();
    requests.sort(
      (a, b) => valueOf(b, 'created_at').compareTo(valueOf(a, 'created_at')),
    );

    return AppList(
      children: [
        const PageTitle(
          'Tin nhắn cứu hộ',
          'Trao đổi với đội cứu hộ sau khi được admin phân công',
        ),
        if (requests.isEmpty)
          const EmptyCard(
            icon: Icons.chat_bubble_outline,
            message: 'Chưa có yêu cầu nào để nhắn tin',
          )
        else
          ...requests.map((request) {
            final requestId = valueOf(request, 'id');
            final isAssigned = valueOf(request, 'assigned_team_id').isNotEmpty;
            final messages = data.chatMessages
                .where((message) => valueOf(message, 'request_id') == requestId)
                .toList();
            messages.sort(
              (a, b) =>
                  valueOf(b, 'created_at').compareTo(valueOf(a, 'created_at')),
            );
            final latest = messages.isEmpty ? null : messages.first;

            return CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Palette.accent.withValues(alpha: .14),
                        child: const Icon(Icons.chat, color: Palette.accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              valueOf(
                                request,
                                'full_name',
                                fallback: 'Yêu cầu cứu hộ',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              valueOf(request, 'assigned_team_id').isEmpty
                                  ? 'Trung tâm điều phối'
                                  : valueOf(
                                      request,
                                      'assigned_team_name',
                                      fallback: valueOf(request, 'area_name'),
                                    ),
                              style: const TextStyle(color: Palette.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (latest == null)
                    const Text(
                      'Chưa có tin nhắn',
                      style: TextStyle(color: Palette.muted),
                    )
                  else
                    Text(
                      '${valueOf(latest, 'sender_name')}: ${valueOf(latest, 'message')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: !isAssigned
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RequestChatScreen(
                                  api: api,
                                  user: user,
                                  request: request,
                                  initialMessages: messages.reversed.toList(),
                                  onChanged: onChanged,
                                ),
                              ),
                            ),
                      icon: Icon(isAssigned ? Icons.open_in_new : Icons.lock),
                      label: Text(isAssigned ? 'Mở chat' : 'Chờ phân công'),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
