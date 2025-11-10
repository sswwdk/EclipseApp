import 'package:flutter/material.dart';
import '../../widgets/bottom_navigation_widget.dart';
import 'choose_schedule_screen.dart';
import 'post_detail_screen.dart';
import 'chat_list_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/community_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _selectedIndex = 2; // 커뮤니티 버튼이 활성화되도록 설정
  late Future<List<Map<String, dynamic>>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 🔥 흰색 배경으로 변경 (네비게이션 바 주변)
      extendBody: true, // 🔥 body를 네비게이션 바 아래까지 확장
      appBar: AppBar(
        backgroundColor: Colors.white, // 🔥 흰색으로 변경
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          '커뮤니티',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Transform.rotate(
            angle: -0.5, // 오른쪽 위를 가리키도록 회전
            child: IconButton(
              icon: Icon(
                Icons.send,
                color: AppTheme.textSecondaryColor,
                size: 20,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MessageScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _refreshPosts,
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 120),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: posts.length,
              separatorBuilder: (context, index) => _buildDivider(),
              itemBuilder: (context, index) {
                final post = posts[index];
                return _buildPostCard(post);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TodoListScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(
          Icons.edit,
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: _selectedIndex,
        fromScreen: 'community',
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadPosts() async {
    final response = await CommunityService.getAllPosts();
    final rawPosts = _extractPosts(response);
    return rawPosts.map(_normalizePost).toList();
  }

  Future<void> _refreshPosts() async {
    final future = _loadPosts();
    setState(() {
      _postsFuture = future;
    });
    await future;
  }

  List<Map<String, dynamic>> _extractPosts(dynamic response) {
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList();
    }

    if (response is Map<String, dynamic>) {
      final keys = [
        'posts',
        'data',
        'content',
        'results',
        'items',
        'list',
        'rows',
      ];

      for (final key in keys) {
        if (!response.containsKey(key)) continue;
        final value = response[key];
        final extracted = _extractPosts(value);
        if (extracted.isNotEmpty) {
          return extracted;
        }
      }
    }

    return [];
  }

  Map<String, dynamic> _normalizePost(Map<String, dynamic> raw) {
    final userData = raw['user'] ??
        raw['author'] ??
        raw['writer'] ??
        raw['member'] ??
        raw['owner'];

    String? nickname = _firstNonEmptyString([
      raw['user_nickname'],
      raw['userNickname'],
      raw['nickname'],
      raw['nickName'],
      raw['userName'],
      raw['username'],
      if (userData is Map<String, dynamic>) ...[
        userData['user_nickname'],
        userData['userNickname'],
        userData['nickname'],
        userData['nickName'],
        userData['name'],
        userData['username'],
      ],
    ]);

    nickname ??= '익명 사용자';

    final title = _firstNonEmptyString([
          raw['title'],
          raw['postTitle'],
          raw['subject'],
          raw['headline'],
        ]) ??
        '';

    final content = _firstNonEmptyString([
          raw['content'],
          raw['body'],
          raw['description'],
          raw['postContent'],
          raw['merge_history_name'],
        ]) ??
        '';

    final createdAt = raw['createdAt'] ??
        raw['created_at'] ??
        raw['createdTime'] ??
        raw['created_time'] ??
        raw['registerDate'] ??
        raw['regDate'] ??
        raw['uploaded_at'];

    final timeDisplay = _firstNonEmptyString([
          raw['timeAgo'],
          raw['time_ago'],
          raw['displayTime'],
          raw['time'],
        ]) ??
        _formatTimeAgo(createdAt);

    return {
      'postId': _firstNonEmptyString([
        raw['id']?.toString(),
        raw['postId']?.toString(),
        raw['post_id']?.toString(),
        raw['uuid']?.toString(),
      ]),
      'nickname': nickname,
      'timeAgo': timeDisplay,
      'title': title,
      'content': content,
      'schedule': raw['schedule'],
      'profileImageUrl': _firstNonEmptyString([
        raw['profileImageUrl'],
        raw['profile_image_url'],
        raw['profileImage'],
        raw['avatarUrl'],
      ]),
      'raw': raw,
    };
  }

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value is String ? value.trim() : value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  String _formatTimeAgo(dynamic time) {
    DateTime? parsed;

    if (time is String) {
      parsed = DateTime.tryParse(time);
      if (parsed == null && time.contains(' ')) {
        final sanitized = time.replaceAll(' ', 'T');
        parsed = DateTime.tryParse(sanitized);
      }
    } else if (time is int) {
      if (time.toString().length == 13) {
        parsed = DateTime.fromMillisecondsSinceEpoch(time);
      } else {
        parsed = DateTime.fromMillisecondsSinceEpoch(time * 1000);
      }
    } else if (time is DateTime) {
      parsed = time;
    }

    if (parsed == null) {
      return '방금 전';
    }

    final diff = DateTime.now().difference(parsed);

    if (diff.inMinutes < 1) {
      return '방금 전';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()}주 전';
    } else if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()}개월 전';
    } else {
      return '${(diff.inDays / 365).floor()}년 전';
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
      ),
    );
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
              color: AppTheme.primaryColor,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              '게시글을 불러오지 못했습니다.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _postsFuture = _loadPosts();
                });
              },
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: AppTheme.textSecondaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              '등록된 게시글이 없습니다.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '첫 번째 게시글을 작성해보세요!',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final nickname = post['nickname'] as String? ?? '익명 사용자';
    final timeAgo = post['timeAgo'] as String? ?? '';
    final title = post['title'] as String? ?? '';
    final content = post['content'] as String? ?? '';
    Map<String, dynamic>? schedule;
    final scheduleData = post['schedule'];
    if (scheduleData is Map<String, dynamic>) {
      schedule = scheduleData;
    }
    final profileImageUrl = post['profileImageUrl'] as String?;
    final scheduleTitle = schedule?['title']?.toString();

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                post: {
                  'postId': post['postId'],
                  'profileImage': Icons.person,
                  'profileImageUrl': profileImageUrl,
                  'nickname': nickname,
                  'timeAgo': timeAgo,
                  'title': title,
                  'content': content,
                  'schedule': schedule,
                  'raw': post['raw'],
                },
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보
          Row(
            children: [
              // 프로필 이미지
              _buildProfileAvatar(profileImageUrl, nickname),
              const SizedBox(width: 12),
              // 닉네임과 위치, 시간
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeAgo.isEmpty ? '방금 전' : timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 포스트 제목
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          
          // 포스트 내용
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          // 일정표 정보 (있는 경우에만 표시)
          if (schedule != null) ...[
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColorWithOpacity10,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColorWithOpacity20,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      scheduleTitle ?? '일정',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // 댓글 버튼
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                '댓글',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(String? profileImageUrl, String nickname) {
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppTheme.dividerColor,
        backgroundImage: NetworkImage(profileImageUrl),
      );
    }

    final initial = nickname.trim().isNotEmpty
        ? nickname.characters.first.toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 20,
      backgroundColor: AppTheme.primaryColorWithOpacity10,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppTheme.dividerColor,
    );
  }
}

