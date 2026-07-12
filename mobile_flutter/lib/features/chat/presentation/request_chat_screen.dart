import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';

class RequestChatScreen extends StatefulWidget {
  const RequestChatScreen({
    super.key,
    required this.api,
    required this.user,
    required this.request,
    required this.initialMessages,
    required this.onChanged,
  });

  final ApiClient api;
  final Map<String, dynamic> user;
  final Map<String, dynamic> request;
  final List<Map<String, dynamic>> initialMessages;
  final Future<void> Function() onChanged;

  @override
  State<RequestChatScreen> createState() => _RequestChatScreenState();
}

class _RequestChatScreenState extends State<RequestChatScreen>
    with WidgetsBindingObserver {
  final message = TextEditingController();
  final _scrollController = ScrollController();
  late List<Map<String, dynamic>> messages;
  bool loading = true;
  bool sending = false;
  Timer? _autoRefreshTimer;
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    messages = [...widget.initialMessages];
    refresh();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      _autoRefreshTimer?.cancel();
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _silentRefresh(),
    );
  }

  Future<void> _silentRefresh() async {
    if (!mounted) return;
    try {
      final latest = await widget.api.fetchChatMessages(
        valueOf(widget.request, 'id'),
      );
      if (!mounted) return;
      final prevCount = messages.length;
      setState(() {
        messages = latest;
        _lastRefresh = DateTime.now();
      });
      // Cuộn xuống nếu có tin mới
      if (latest.length > prevCount) {
        _scrollToBottom();
      }
    } catch (_) {
      // Im lặng khi auto-refresh thất bại
    }
  }

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      final latest = await widget.api.fetchChatMessages(
        valueOf(widget.request, 'id'),
      );
      if (mounted) {
        setState(() {
          messages = latest;
          _lastRefresh = DateTime.now();
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted && messages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tải được tin nhắn')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> send() async {
    if (valueOf(widget.request, 'assigned_team_id').isEmpty) return;
    final text = message.text.trim();
    if (text.isEmpty) return;
    setState(() => sending = true);
    try {
      final sent = await widget.api.sendChatMessage(
        valueOf(widget.request, 'id'),
        text,
      );
      message.clear();
      setState(() {
        messages = [...messages, sent];
        _lastRefresh = DateTime.now();
      });
      _scrollToBottom();
      await widget.onChanged();
    } catch (err) {
      if (mounted) {
        final msg = err.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = valueOf(widget.user, 'id');
    final title = valueOf(
      widget.request,
      'full_name',
      fallback: 'Yêu cầu cứu hộ',
    );
    final requestStatus = valueOf(widget.request, 'status');
    final assignedTeamId = valueOf(widget.request, 'assigned_team_id');
    final isAssigned = assignedTeamId.isNotEmpty;
    final isClosed = [
      'RESCUED',
      'TRANSFERRED_SAFEZONE',
      'CANCELLED',
      'FALSE_ALARM',
      'SPAM',
    ].contains(requestStatus);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            if (_lastRefresh != null)
              Text(
                'Cập nhật lúc ${_lastRefresh!.hour.toString().padLeft(2, '0')}:${_lastRefresh!.minute.toString().padLeft(2, '0')}:${_lastRefresh!.second.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              onPressed: refresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Làm mới tin nhắn',
            ),
        ],
      ),
      body: Column(
        children: [
          // Banner trạng thái yêu cầu
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: statusColor(requestStatus).withValues(alpha: .12),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: statusColor(requestStatus),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Trạng thái: ${statusLabel(requestStatus)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: statusColor(requestStatus),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Tự làm mới 15s',
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor(requestStatus).withValues(alpha: .7),
                  ),
                ),
              ],
            ),
          ),
          // Banner cảnh báo khi chưa phân công hoặc đã kết thúc
          if (isClosed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: Palette.muted.withValues(alpha: .12),
              child: const Row(
                children: [
                  Icon(Icons.lock, size: 16, color: Palette.muted),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Yêu cầu đã kết thúc. Bạn không thể gửi thêm tin nhắn.',
                      style: TextStyle(fontSize: 12, color: Palette.muted),
                    ),
                  ),
                ],
              ),
            )
          else if (!isAssigned)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: Palette.warning.withValues(alpha: .12),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_empty, size: 16, color: Colors.orange),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Chưa được admin phân công đội cứu hộ. Bạn chỉ có thể nhắn tin sau khi có đội tiếp nhận.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: messages.isEmpty && loading
                ? const Center(
                    child: CircularProgressIndicator(color: Palette.accent),
                  )
                : messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Palette.muted,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Chưa có tin nhắn\nBắt đầu trao đổi ngay',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Palette.muted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final item = messages[index];
                      final mine = valueOf(item, 'sender_id') == currentUserId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.78,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: mine
                                    ? Palette.accent.withValues(alpha: .15)
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: Radius.circular(mine ? 12 : 2),
                                  bottomRight: Radius.circular(mine ? 2 : 12),
                                ),
                                border: Border.all(
                                  color: mine
                                      ? Palette.accent.withValues(alpha: .3)
                                      : Theme.of(context).dividerColor,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    valueOf(
                                      item,
                                      'sender_name',
                                      fallback: mine ? 'Tôi' : 'Người gửi',
                                    ),
                                    style: TextStyle(
                                      color: mine
                                          ? Palette.accent
                                          : Palette.secondary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    valueOf(item, 'message'),
                                    style: const TextStyle(height: 1.4),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatDate(valueOf(item, 'created_at')),
                                    style: const TextStyle(
                                      color: Palette.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: isClosed || !isAssigned
                ? Container(
                    padding: const EdgeInsets.all(14),
                    color: Theme.of(context).cardTheme.color,
                    child: Center(
                      child: Text(
                        isClosed
                            ? 'Cuộc hội thoại đã đóng'
                            : 'Chat sẽ mở sau khi admin phân công đội cứu hộ',
                        style: TextStyle(color: Palette.muted),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      border: Border(
                        top: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: message,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => sending ? null : send(),
                            decoration: InputDecoration(
                              hintText: isAssigned
                                  ? 'Nhập tin nhắn...'
                                  : 'Mô tả tình trạng hiện tại...',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: sending ? null : send,
                          icon: sending
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
