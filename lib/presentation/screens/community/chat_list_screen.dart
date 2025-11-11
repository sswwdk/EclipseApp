import 'package:flutter/material.dart';
import 'package:characters/characters.dart';
import 'chat_screen.dart';
import '../../../data/services/chat_service.dart';
import '../../../shared/helpers/token_manager.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  late Future<List<Map<String, dynamic>>> _messagesFuture;

  @override
  void initState() {
    super.initState();
    _messagesFuture = _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '내 쪽지함',
          style: TextStyle(
            color: Color(0xFFFF8126),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {
              // 더보기 메뉴
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFFF8126),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _messagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final messages = snapshot.data ?? [];

          if (messages.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _refreshMessages,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageCard(message);
              },
            ),
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadMessages() async {
    final userId = TokenManager.userId;
    if (userId == null || userId.isEmpty) {
      throw Exception('로그인이 필요합니다.');
    }

    final response = await ChatService.getChatList();
    final rawThreads = _extractThreadList(response);
    final normalized = rawThreads
        .map((raw) => _normalizeThread(raw, userId))
        .whereType<Map<String, dynamic>>()
        .toList()
        ..removeWhere(
          (thread) => thread['otherUserId']?.toString() == userId,
        );

    final merged = <String, Map<String, dynamic>>{};
    for (final thread in normalized) {
      final key = thread['otherUserId']?.toString().isNotEmpty == true
          ? thread['otherUserId'].toString()
          : thread['threadId']?.toString() ?? thread.hashCode.toString();

      final existing = merged[key];
      if (existing == null) {
        merged[key] = thread;
      } else {
        final existingTime = existing['updatedAt'] as DateTime?;
        final newTime = thread['updatedAt'] as DateTime?;
        if (newTime != null &&
            (existingTime == null || newTime.isAfter(existingTime))) {
          merged[key] = thread;
        }
      }
    }

    final threads = merged.values.toList();

    threads.sort((a, b) {
      final aTime = a['updatedAt'] as DateTime?;
      final bTime = b['updatedAt'] as DateTime?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return threads;
  }

  Future<void> _refreshMessages() async {
    final future = _loadMessages();
    setState(() {
      _messagesFuture = future;
    });
    await future;
  }

  List<Map<String, dynamic>> _extractThreadList(dynamic payload) {
    if (payload == null) return [];

    if (payload is List) {
      final result = <Map<String, dynamic>>[];
      for (final item in payload) {
        if (item is Map<String, dynamic>) {
          result.add(item);
        } else {
          result.addAll(_extractThreadList(item));
        }
      }
      return result;
    }

    if (payload is Map<String, dynamic>) {
      if (payload.containsKey('received_messages') ||
          payload.containsKey('send_messages')) {
        final result = <Map<String, dynamic>>[];

        void addMessages(dynamic source, String direction) {
          if (source is List) {
            for (final item in source) {
              if (item == null) continue;
              Map<String, dynamic> message;
              if (item is Map<String, dynamic>) {
                message = item;
              } else if (item is Map) {
                message = Map<String, dynamic>.from(item);
              } else {
                message = {'message': item};
              }
              result.add({
                '__type': 'simple_message',
                '__direction': direction,
                '__payload': message,
              });
            }
          }
        }

        addMessages(payload['received_messages'], 'received');
        addMessages(payload['send_messages'], 'sent');

        if (result.isNotEmpty) {
          return result;
        }
      }

      if (_looksLikeThread(payload)) {
        return [payload];
      }

      final aggregated = <Map<String, dynamic>>[];
      for (final entry in payload.entries) {
        aggregated.addAll(_extractThreadList(entry.value));
      }

      if (aggregated.isNotEmpty) {
        return aggregated;
      }
    }

    return [];
  }

  bool _looksLikeThread(Map<String, dynamic> raw) {
    final messageKeys = [
      'message',
      'content',
      'text',
      'lastMessage',
      'last_message',
      'recentMessage',
      'preview',
    ];
    final hasMessage = messageKeys.any(
      (key) => raw[key] != null && raw[key].toString().trim().isNotEmpty,
    );

    final userKeys = [
      'otherUser',
      'partner',
      'recipient',
      'receiver',
      'sender',
      'user',
      'member',
      'opponent',
      'friend',
    ];
    final hasUser = userKeys.any((key) => raw[key] != null);

    final idKeys = [
      'threadId',
      'thread_id',
      'chatId',
      'chat_id',
      'conversationId',
      'conversation_id',
      'otherUserId',
      'other_user_id',
      'sender_id',
      'receiver_id',
      'id',
    ];
    final hasIds = idKeys.any((key) => raw[key] != null);

    return hasMessage && (hasUser || hasIds);
  }

  Map<String, dynamic>? _normalizeThread(
    Map<String, dynamic> raw,
    String currentUserId,
  ) {
    if (raw['__type'] == 'simple_message') {
      final direction = raw['__direction']?.toString();
      final payload = raw['__payload'];

      Map<String, dynamic> message;
      if (payload is Map<String, dynamic>) {
        message = payload;
      } else if (payload is Map) {
        message = Map<String, dynamic>.from(payload);
      } else {
        message = {'message': payload};
      }

      final sender = _firstNonEmptyString([
        message['sender'],
        message['sender_name'],
        message['from'],
        message['from_user'],
        message['user'],
      ]);

      final receiver = _firstNonEmptyString([
        message['receiver'],
        message['receiver_name'],
        message['to'],
        message['to_user'],
        message['target'],
      ]);

      final otherUserId = direction == 'sent'
          ? (receiver ?? sender)
          : sender;

      if (otherUserId == null || otherUserId.isEmpty) {
        return null;
      }

      final displayName = _firstNonEmptyString([
            message['nickname'],
            message['nickName'],
            message['name'],
            message['userName'],
            message['memberName'],
          ]) ??
          otherUserId;

      final updatedAt = _parseDateTime(
            message['create_at'] ??
                message['created_at'] ??
                message['createdAt'] ??
                message['timestamp'],
          ) ??
          DateTime.now();

      final lastMessage = _extractMessageText(message) ??
          (direction == 'sent' ? '보낸 쪽지' : '받은 쪽지');

      return {
        'threadId': '${direction ?? 'message'}:$otherUserId',
        'otherUserId': otherUserId,
        'nickname': displayName,
        'lastMessage': lastMessage,
        'updatedAt': updatedAt,
        'timeLabel': _formatTimeAgo(updatedAt),
        'unreadCount': 0,
        'post': null,
        'profileImageUrl': _firstNonEmptyString([
          message['profileImageUrl'],
          message['profile_image_url'],
          message['avatarUrl'],
        ]),
        'raw': message,
        'direction': direction,
      };
    }

    final senderId = _firstNonEmptyString([
      raw['sender_id'],
      raw['senderId'],
      raw['fromUserId'],
    ]);
    final receiverId = _firstNonEmptyString([
      raw['receiver_id'],
      raw['receiverId'],
      raw['toUserId'],
    ]);

    final otherUserId = _resolveOtherUserId(raw, currentUserId) ??
        (senderId != currentUserId ? senderId : null) ??
        (receiverId != currentUserId ? receiverId : null);

    if (otherUserId == null) {
      return null;
    }

    final otherUser = _resolveOtherUser(raw, currentUserId);
    final nickname = _firstNonEmptyString([
          otherUser?['nickname'],
          otherUser?['nickName'],
          otherUser?['userName'],
          otherUser?['name'],
          raw['otherUserName'],
          raw['partnerName'],
          raw['receiverName'],
          raw['senderName'],
          raw['nickname'],
        ]) ??
        '익명 사용자';

    final profileImageUrl = _firstNonEmptyString([
      otherUser?['profileImageUrl'],
      otherUser?['profile_image_url'],
      otherUser?['avatarUrl'],
      raw['profileImageUrl'],
      raw['profile_image_url'],
    ]);

    final lastMessageRaw =
        raw['lastMessage'] ?? raw['recentMessage'] ?? raw['message'];

    final lastMessage = _extractMessageText(lastMessageRaw) ??
        _firstNonEmptyString([
          raw['lastMessageText'],
          raw['lastMessageContent'],
          raw['lastMessageBody'],
          raw['content'],
          raw['text'],
        ]) ??
        '';

    final updatedAtRaw = raw['updatedAt'] ??
        raw['updated_at'] ??
        raw['lastMessageAt'] ??
        raw['last_message_at'] ??
        (lastMessageRaw is Map<String, dynamic>
            ? lastMessageRaw['createdAt'] ?? lastMessageRaw['timestamp']
            : null);

    final updatedAt = _parseDateTime(updatedAtRaw);

    final postData = _resolvePostData(raw);

    return {
      'threadId': _firstNonEmptyString([
        raw['threadId'],
        raw['thread_id'],
        raw['chatId'],
        raw['chat_id'],
        raw['conversationId'],
        raw['conversation_id'],
        raw['id'],
      ]),
      'otherUserId': otherUserId,
      'nickname': nickname,
      'lastMessage': lastMessage,
      'updatedAt': updatedAt,
      'timeLabel': _formatTimeAgo(updatedAt),
      'unreadCount': 0,
      'post': postData,
      'profileImageUrl': profileImageUrl,
      'raw': raw,
      'direction': senderId == currentUserId ? 'sent' : 'received',
    };
  }

  Map<String, dynamic>? _resolveOtherUser(
    Map<String, dynamic> raw,
    String currentUserId,
  ) {
    final candidateKeys = [
      'otherUser',
      'partner',
      'opponent',
      'recipient',
      'receiver',
      'sender',
      'targetUser',
      'user',
      'member',
      'participant',
      'friend',
    ];

    for (final key in candidateKeys) {
      final value = raw[key];
      if (value is Map<String, dynamic>) {
        final userId = _firstNonEmptyString([
          value['id'],
          value['userId'],
          value['user_id'],
        ]);
        if (userId == null) continue;
        if (userId == currentUserId && key == 'sender') {
          continue;
        }
        if (userId != currentUserId) {
          return value;
        }
      } else if (value is List) {
        for (final item in value.whereType<Map<String, dynamic>>()) {
          final userId = _firstNonEmptyString([
            item['id'],
            item['userId'],
            item['user_id'],
          ]);
          if (userId != null && userId != currentUserId) {
            return item;
          }
        }
      }
    }

    final participants = raw['participants'];
    if (participants is List) {
      for (final item in participants.whereType<Map<String, dynamic>>()) {
        final userId = _firstNonEmptyString([
          item['id'],
          item['userId'],
          item['user_id'],
        ]);
        if (userId != null && userId != currentUserId) {
          return item;
        }
      }
    }

    return null;
  }

  String? _resolveOtherUserId(Map<String, dynamic> raw, String currentUserId) {
    final candidates = [
      raw['otherUserId'],
      raw['other_user_id'],
      raw['partnerId'],
      raw['partner_id'],
      raw['participantId'],
      raw['participant_id'],
      raw['receiver_id'],
      raw['receiverId'],
      raw['sender_id'],
      raw['senderId'],
      raw['user_id'],
      raw['userId'],
    ];

    for (final candidate in candidates) {
      final id = _firstNonEmptyString([candidate]);
      if (id != null && id != currentUserId) {
        return id;
      }
    }

    final otherUser = _resolveOtherUser(raw, currentUserId);
    if (otherUser != null) {
      final id = _firstNonEmptyString([
        otherUser['id'],
        otherUser['userId'],
        otherUser['user_id'],
      ]);
      if (id != null && id != currentUserId) {
        return id;
      }
    }

    return null;
  }

  Map<String, dynamic>? _resolvePostData(Map<String, dynamic> raw) {
    final candidate = raw['post'] ??
        raw['postInfo'] ??
        raw['post_data'] ??
        raw['relatedPost'] ??
        raw['postDetail'];

    if (candidate is Map<String, dynamic>) {
      final title = _firstNonEmptyString([
        candidate['title'],
        candidate['postTitle'],
        candidate['subject'],
        candidate['headline'],
      ]);
      final content = _firstNonEmptyString([
        candidate['content'],
        candidate['body'],
        candidate['description'],
      ]);
      final postId = _firstNonEmptyString([
        candidate['postId'],
        candidate['post_id'],
        candidate['id'],
      ]);

      final result = <String, dynamic>{};
      if (postId != null) result['postId'] = postId;
      if (title != null) result['title'] = title;
      if (content != null) result['content'] = content;

      return result.isEmpty ? null : result;
    }

    final title = _firstNonEmptyString([
      raw['postTitle'],
      raw['title'],
    ]);
    final content = _firstNonEmptyString([
      raw['postContent'],
      raw['postDescription'],
    ]);

    if (title == null && content == null) {
      return null;
    }

    final result = <String, dynamic>{};
    if (title != null) result['title'] = title;
    if (content != null) result['content'] = content;
    return result;
  }

  String? _extractMessageText(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (value is Map<String, dynamic>) {
      return _firstNonEmptyString([
        value['message'],
        value['content'],
        value['text'],
        value['body'],
      ]);
    }

    return value.toString();
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

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      if (value.toString().length == 13) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }

    if (value is String) {
      if (value.isEmpty) return null;
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
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

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) {
      return '방금 전';
    }

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return '방금 전';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    }
    if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()}주 전';
    }
    if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()}개월 전';
    }
    return '${(diff.inDays / 365).floor()}년 전';
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.grey[500],
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              '쪽지를 불러오지 못했습니다.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _refreshMessages(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '받은 쪽지가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 사용자들과 소통해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    final nickname = message['nickname']?.toString() ?? '익명 사용자';
    final lastMessage = message['lastMessage']?.toString() ?? '';
    final timeLabel = message['timeLabel']?.toString() ?? '';
    final post = message['post'] as Map<String, dynamic>?;
    final isSent = message['direction'] == 'sent';

    return Container(
      color: Colors.white,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  user: {
                    'nickname': nickname,
                    'profileImageUrl': message['profileImageUrl'],
                  },
                  post: post,
                  otherUserId: message['otherUserId']?.toString(),
                  conversationId: message['threadId']?.toString(),
                ),
              ),
            );
            if (!mounted) return;
            await _refreshMessages();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFEDEDED),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // 프로필 이미지
                _buildProfileAvatar(
                  message['profileImageUrl']?.toString(),
                  nickname,
                  radius: 25,
                ),
                const SizedBox(width: 12),
                
                // 쪽지 내용
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            nickname,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
  Text(
    lastMessage,
    style: TextStyle(
      fontSize: 14,
      color: Colors.grey[700],
                          fontWeight: isSent ? FontWeight.w500 : FontWeight.w500,
    ),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  ),
                      const SizedBox(height: 6),
                      // 게시물 정보
                      if (post != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8126).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFFF8126).withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.article,
                                color: const Color(0xFFFF8126),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  message['post']['title'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFFF8126),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 화살표 아이콘
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
