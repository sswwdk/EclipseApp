import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/community_service.dart';
import '../../../shared/helpers/token_manager.dart';
import '../community/post_detail_screen.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({Key? key}) : super(key: key);

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  bool _loading = true;
  String? _errorMessage;
  List<MyPostItem> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final userId = TokenManager.userId ?? '';
    if (userId.isEmpty) {
      setState(() {
        _loading = false;
        _errorMessage = '로그인이 필요합니다.';
        _posts = [];
      });
      return;
    }

    try {
      final response = await CommunityService.getMyPosts(userId);
      final parsed = MyPostItem.parseList(response);
      if (!mounted) return;
      setState(() {
        _posts = parsed;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          '내가 쓴 게시글',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        color: AppTheme.primaryColor,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPosts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '작성한 게시글이 없습니다.',
            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _buildPostCard(post);
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _posts.length,
    );
  }

  Widget _buildPostCard(MyPostItem post) {
    return InkWell(
      onTap: () {
        // 게시글 상세 화면으로 이동
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(
              post: {
                'id': post.id,
                'postId': post.id,
                'title': post.title,
                'content': post.content,
                'comment_count': post.commentCount,
                'created_at': post.raw?['created_at'] ??
                    post.raw?['createdAt'] ??
                    post.dateText,
                'nickname': post.nickname,
                'profileImageUrl': post.profileImageUrl,
                'raw': post.raw,
              },
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Text(
              post.title,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // 내용
            Text(
              post.content,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (post.schedulePlaces.isNotEmpty ||
                post.scheduleTitle != null) ...[
              const SizedBox(height: 8),
              _buildScheduleFlow(post),
            ],
            const SizedBox(height: 8),
            // 메타데이터 (댓글 수, 날짜)
            Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.commentCount}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  post.dateText,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleFlow(MyPostItem post) {
    final hasTitle =
        post.scheduleTitle != null && post.scheduleTitle!.trim().isNotEmpty;
    final hasPlaces = post.schedulePlaces.isNotEmpty;

    const textStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFFFF8126),
    );

    final routeWidgets = <Widget>[];
    if (hasPlaces) {
      for (var i = 0; i < post.schedulePlaces.length; i++) {
        routeWidgets.add(Text(post.schedulePlaces[i], style: textStyle));
        if (i < post.schedulePlaces.length - 1) {
          routeWidgets.add(const Text(' → ', style: textStyle));
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFA86C).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTitle) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.article,
                  size: 16,
                  color: Color(0xFFFF8126),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    post.scheduleTitle!,
                    style: textStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (routeWidgets.isNotEmpty) const SizedBox(height: 6),
          ],
          if (routeWidgets.isNotEmpty)
            Wrap(
              spacing: 2,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: routeWidgets,
            )
          else if (!hasTitle)
            const Text(
              '일정 정보가 없습니다.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFFF8126),
              ),
            ),
        ],
      ),
    );
  }
}

class MyPostItem {
  final String id;
  final String title;
  final String content;
  final int commentCount;
  final String dateText;
  final String nickname;
  final String? profileImageUrl;
  final Map<String, dynamic>? raw;
  final String? scheduleTitle;
  final List<String> schedulePlaces;

  const MyPostItem({
    required this.id,
    required this.title,
    required this.content,
    required this.commentCount,
    required this.dateText,
    required this.nickname,
    required this.profileImageUrl,
    required this.raw,
    required this.scheduleTitle,
    required this.schedulePlaces,
  });

  static List<MyPostItem> parseList(dynamic response) {
    List<dynamic> items;
    if (response is List) {
      items = response;
    } else if (response is Map<String, dynamic>) {
      final dynamic data = response['data'] ?? response['posts'] ?? response['items'] ?? response['body'];
      if (data is List) {
        items = data;
      } else {
        items = [];
      }
    } else {
      items = [];
    }

    return items.whereType<Map<String, dynamic>>().map((m) {
      final String id = (m['id'] ?? m['post_id'] ?? '').toString();
      final String title = (m['title'] ?? m['content'] ?? '').toString();
      final String content = (m['content'] ?? m['text'] ?? '').toString();

      final dynamic commentValue =
          m['comment_count'] ?? m['commentCount'] ?? m['comments'] ?? 0;
      final int commentCount = commentValue is int
          ? commentValue
          : int.tryParse(commentValue.toString()) ?? 0;

      final String date =
          (m['created_at'] ?? m['createdAt'] ?? m['date'] ?? '').toString();

      final nickname = (m['nickname'] ??
              m['user_nickname'] ??
              m['userName'] ??
              m['writerName'] ??
              m['memberName'])
          ?.toString() ??
          '익명 사용자';

      final profileImageUrl = (m['profileImageUrl'] ??
              m['profile_image_url'] ??
              m['profileImage'] ??
              (m['user'] is Map ? (m['user']['profileImageUrl'] ?? m['user']['profileImage']) : null))
          ?.toString();

      return MyPostItem(
        id: id.isEmpty ? DateTime.now().microsecondsSinceEpoch.toString() : id,
        title: title.isEmpty ? '제목 없음' : title,
        content: content,
        commentCount: commentCount,
        dateText: _formatDate(date),
        nickname: nickname,
        profileImageUrl: profileImageUrl,
        raw: m,
        scheduleTitle: _extractScheduleTitle(m),
        schedulePlaces: _extractSchedulePlaces(m),
      );
    }).toList();
  }

  static String _formatDate(String dateString) {
    if (dateString.isEmpty) return '날짜 없음';
    
    try {
      // 다양한 날짜 형식 처리
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return '오늘';
      } else if (difference.inDays == 1) {
        return '어제';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}일 전';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()}주 전';
      } else {
        return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      // 파싱 실패 시 원본 문자열 반환 (이미 포맷된 경우)
      return dateString.length > 10 ? dateString.substring(0, 10) : dateString;
    }
  }

  static String? _extractScheduleTitle(Map<String, dynamic> raw) {
    if (raw.containsKey('schedule_title')) {
      final value = raw['schedule_title']?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    final schedule = raw['schedule'];
    if (schedule is Map<String, dynamic>) {
      final candidates = [
        schedule['title'],
        schedule['name'],
        schedule['label'],
      ];
      for (final candidate in candidates) {
        if (candidate == null) continue;
        final text = candidate.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    }
    return null;
  }

  static List<String> _extractSchedulePlaces(Map<String, dynamic> raw) {
    final schedule = raw['schedule'];
    if (schedule == null) {
      return const [];
    }

    List<String> places = [];

    void extract(dynamic node) {
      if (node == null) return;
      if (node is List) {
        for (final item in node) {
          extract(item);
        }
      } else if (node is Map) {
        final map = Map<String, dynamic>.from(node);
        final place = map['place'] ?? map['placeName'] ?? map['name'];
        if (place != null) {
          final text = place.toString().trim();
          if (text.isNotEmpty) {
            places.add(text);
          }
        }
        extract(map['places']);
        extract(map['schedule']);
        extract(map['routes']);
        extract(map['steps']);
        extract(map['items']);
        extract(map['children']);
      } else if (node is String) {
        final trimmed = node.trim();
        if (trimmed.contains('→')) {
          places.addAll(
            trimmed
                .split('→')
                .map((segment) => segment.trim())
                .where((segment) => segment.isNotEmpty),
          );
        } else if (trimmed.isNotEmpty) {
          places.add(trimmed);
        }
      }
    }

    extract(schedule);

    // 중복 제거
    final seen = <String>{};
    final deduped = <String>[];
    for (final place in places) {
      if (seen.add(place)) {
        deduped.add(place);
      }
    }
    return deduped;
  }
}

