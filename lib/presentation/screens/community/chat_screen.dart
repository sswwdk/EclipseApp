import 'package:flutter/material.dart';
import 'package:characters/characters.dart';
import '../../widgets/dialogs/common_dialogs.dart';
import '../../../data/services/chat_service.dart';
import '../../../shared/helpers/token_manager.dart';
import 'report_reason_screen.dart' show ReportReasonDialog;

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String? otherUserId;
  final String? conversationId;

  const ChatScreen({
    super.key,
    required this.user,
    this.otherUserId,
    this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  bool _hasUpdates = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleMessageChanged);
    _initializeChat();
  }

  void _initializeChat() {
    final otherUserId = widget.otherUserId;

    if (otherUserId == null || otherUserId.isEmpty) {
      _isLoading = false;
      _errorMessage = '대상 사용자를 찾을 수 없습니다.';
      return;
    }

    _reloadMessages(showLoader: true);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.user['nickname']?.toString() ?? '익명 사용자';

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasUpdates);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(_hasUpdates),
          ),
          title: Row(
            children: [
              _buildProfileAvatar(
                widget.user['profileImageUrl']?.toString(),
                displayName,
                radius: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
              onPressed: _showChatMenu,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: const Color(0xFFFF8126)),
          ),
        ),
        body: Column(
          children: [
            Expanded(child: _buildMessagesView()),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorView(_errorMessage!);
    }

    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.grey[500], size: 48),
            const SizedBox(height: 12),
            const Text(
              '채팅을 불러오지 못했습니다.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _reloadMessages(showLoader: true),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              '아직 대화가 없습니다.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '첫 메시지를 보내 대화를 시작해보세요.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['isMe'] as bool? ?? false;
    final isSystemMessage = message['isSystemMessage'] as bool? ?? false;

    if (isSystemMessage) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message['text']?.toString() ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    final timestamp = message['timestamp'] as DateTime?;
    final timeLabel =
        message['time']?.toString() ?? _formatTime(timestamp ?? DateTime.now());

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildProfileAvatar(
              widget.user['profileImageUrl']?.toString(),
              widget.user['nickname']?.toString() ?? '익명 사용자',
              radius: 16,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFFF8126) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['text']?.toString() ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeLabel,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildProfileAvatar(
              null,
              TokenManager.userName ?? '나',
              radius: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final canSend = !_isSending && widget.otherUserId != null;
    final hasText = _messageController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _messageController,
                enabled: canSend,
                decoration: InputDecoration(
                  hintText: canSend ? '메시지를 입력하세요...' : '대상을 선택할 수 없습니다.',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: canSend
                    ? (text) {
                        if (text.trim().isNotEmpty) {
                          _sendMessage(text.trim());
                        }
                      }
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: canSend && hasText
                ? () => _sendMessage(_messageController.text.trim())
                : null,
            child: Opacity(
              opacity: canSend && hasText ? 1 : 0.4,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF8126),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (!_canAttemptSend(text)) {
      return;
    }

    final otherUserId = widget.otherUserId!;
    final messageText = text.trim();

    setState(() {
      _isSending = true;
    });

    try {
      await ChatService.sendChat(otherUserId, messageText);
      _messageController.clear();
      _hasUpdates = true;
      await _reloadMessages();
    } catch (e) {
      _showSnackBar('메시지 전송에 실패했습니다. 다시 시도해주세요.');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  bool _canAttemptSend(String text) {
    return !_isSending &&
        widget.otherUserId != null &&
        widget.otherUserId!.isNotEmpty &&
        text.trim().isNotEmpty;
  }

  Future<void> _reloadMessages({bool showLoader = false}) async {
    final currentUserId = TokenManager.userId;
    final otherUserId = widget.otherUserId;

    if (otherUserId == null || otherUserId.isEmpty) {
      return;
    }

    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await ChatService.getChat(otherUserId);
      final rawMessages = _extractMessageList(response);
      final normalized = rawMessages
          .map((raw) => _normalizeMessage(raw, currentUserId))
          .whereType<Map<String, dynamic>>()
          .toList();

      normalized.sort((a, b) {
        final aTime = a['timestamp'] as DateTime?;
        final bTime = b['timestamp'] as DateTime?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return -1;
        if (bTime == null) return 1;
        return aTime.compareTo(bTime);
      });

      if (!mounted) return;

      setState(() {
        _messages = normalized;
        _isLoading = false;
        _errorMessage = null;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = '채팅을 불러오지 못했습니다.';
      });

      _showSnackBar('채팅을 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  List<Map<String, dynamic>> _extractMessageList(dynamic payload) {
    if (payload is List) {
      return payload.whereType<Map<String, dynamic>>().toList();
    }

    if (payload is Map<String, dynamic>) {
      final keys = [
        'messages',
        'data',
        'results',
        'items',
        'content',
        'rows',
        'list',
        'chat',
        'conversation',
      ];

      for (final key in keys) {
        if (!payload.containsKey(key)) continue;
        final value = payload[key];
        final extracted = _extractMessageList(value);
        if (extracted.isNotEmpty) {
          return extracted;
        }
      }
    }

    return [];
  }

  Map<String, dynamic>? _normalizeMessage(
    Map<String, dynamic> raw,
    String? currentUserId,
  ) {
    final text = _extractMessageText(raw);
    if (text == null) {
      return null;
    }

    // send_receive 필드 확인 (백엔드 DTO 기준)
    bool isMe;
    if (raw.containsKey('send_receive')) {
      isMe = raw['send_receive'] == true;
    } else if (raw.containsKey('sendReceive')) {
      isMe = raw['sendReceive'] == true;
    } else {
      // fallback: sender_id 기반 판단
      final senderId = _firstNonEmptyString([
        raw['sender_id'],
        raw['senderId'],
        raw['fromUserId'],
        raw['from_id'],
        raw['user_id'],
        raw['userId'],
      ]);
      isMe =
          currentUserId != null &&
          senderId != null &&
          senderId == currentUserId;
    }

    final senderId = _firstNonEmptyString([
      raw['sender_id'],
      raw['senderId'],
      raw['fromUserId'],
      raw['from_id'],
      raw['user_id'],
      raw['userId'],
    ]);

    final timestamp =
        _parseDateTime(
          raw['createdAt'] ??
              raw['created_at'] ??
              raw['create_at'] ?? // DTO에서 사용하는 필드명 추가
              raw['timestamp'] ??
              raw['sentAt'] ??
              raw['sent_at'] ??
              raw['time'] ??
              raw['date'],
        ) ??
        DateTime.now();

    final isSystem =
        raw['isSystem'] == true ||
        (raw['type'] is String &&
            raw['type'].toString().toLowerCase() == 'system') ||
        (raw['messageType'] is String &&
            raw['messageType'].toString().toLowerCase() == 'system');

    return {
      'id':
          _firstNonEmptyString([
            raw['id'],
            raw['messageId'],
            raw['message_id'],
            raw['uuid'],
          ]) ??
          '${timestamp.millisecondsSinceEpoch}-${senderId ?? 'unknown'}',
      'text': text,
      'isMe': isMe,
      'timestamp': timestamp,
      'isSystemMessage': isSystem,
    };
  }

  String? _extractMessageText(Map<String, dynamic> raw) {
    final candidates = [
      raw['message'],
      raw['content'],
      raw['text'],
      raw['body'],
      raw['comment'],
    ];

    for (final candidate in candidates) {
      if (candidate == null) continue;
      if (candidate is String) {
        final trimmed = candidate.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      } else if (candidate is Map<String, dynamic>) {
        final nested = _extractMessageText(candidate);
        if (nested != null) {
          return nested;
        }
      } else {
        final asString = candidate.toString().trim();
        if (asString.isNotEmpty) {
          return asString;
        }
      }
    }
    return null;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is int) {
      final text = value.toString();
      if (text.length == 13) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }

    if (value is String) {
      if (value.isEmpty) return null;
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
      if (value.contains(' ')) {
        final sanitized = value.replaceAll(' ', 'T');
        final secondParsed = DateTime.tryParse(sanitized);
        if (secondParsed != null) {
          return secondParsed;
        }
      }
    }

    return null;
  }

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showChatMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('사용자 차단'),
              onTap: () {
                Navigator.pop(context);
                _showBlockDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red, size: 20),
              title: const Text('사용자 신고'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog() {
    CommonDialogs.showBlockConfirmation(
      context: context,
      title: '사용자 차단',
      content: '${widget.user['nickname']}님을 차단하시겠습니까?',
      onConfirm: () {
        CommonDialogs.showSuccess(
          context: context,
          message: '${widget.user['nickname']}님을 차단했습니다',
        );
      },
    );
  }

  void _showReportDialog() async {
    final otherUserId = widget.otherUserId;
    if (otherUserId == null || otherUserId.isEmpty) {
      _showSnackBar('사용자 정보를 찾을 수 없습니다.');
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => ReportReasonDialog(
        targetType: 'user',
        targetId: otherUserId,
        targetName: widget.user['nickname']?.toString() ?? '사용자',
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleMessageChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleMessageChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Widget _buildProfileAvatar(
    String? profileImageUrl,
    String nickname, {
    double radius = 20,
  }) {
    if (profileImageUrl != null &&
        profileImageUrl.isNotEmpty &&
        profileImageUrl != 'null') {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE0E0E0),
        backgroundImage: NetworkImage(profileImageUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    final trimmed = nickname.trim();
    final initial =
        trimmed.isNotEmpty ? trimmed.characters.first.toUpperCase() : '?';
    final colors = _avatarColorsFor(initial);

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.background,
      child: Text(
        initial,
        style: TextStyle(
          color: colors.foreground,
          fontWeight: FontWeight.bold,
          fontSize: radius,
        ),
      ),
    );
  }

  _AvatarColors _avatarColorsFor(String initial) {
    if (initial.isEmpty) {
      return _avatarColorPalettes.first;
    }
    final rune = initial.runes.first;
    final index = rune.abs() % _avatarColorPalettes.length;
    return _avatarColorPalettes[index];
  }
}

class _AvatarColors {
  final Color background;
  final Color foreground;

  const _AvatarColors(this.background, this.foreground);
}

const List<_AvatarColors> _avatarColorPalettes = [
  _AvatarColors(Color(0xFFFFE5E0), Color(0xFFFF6B57)),
  _AvatarColors(Color(0xFFE3F2FD), Color(0xFF1565C0)),
  _AvatarColors(Color(0xFFF1F8E9), Color(0xFF2E7D32)),
  _AvatarColors(Color(0xFFEDE7F6), Color(0xFF5E35B1)),
  _AvatarColors(Color(0xFFFFF3E0), Color(0xFFEF6C00)),
  _AvatarColors(Color(0xFFE0F2F1), Color(0xFF00897B)),
  _AvatarColors(Color(0xFFFFEBEE), Color(0xFFD81B60)),
  _AvatarColors(Color(0xFFF3E5F5), Color(0xFF8E24AA)),
];
