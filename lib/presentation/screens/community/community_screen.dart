import 'package:flutter/material.dart';
import '../../widgets/bottom_navigation_widget.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/app_title_widget.dart';
import '../../widgets/dialogs/common_dialogs.dart';
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
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _posts = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialPosts();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldPop = await CommonDialogs.showConfirmation(
          context: context,
          title: '앱 종료',
          content: '앱을 종료하시겠습니까?',
          confirmText: '종료',
          cancelText: '취소',
        );

        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white, // 🔥 흰색 배경으로 변경 (네비게이션 바 주변)
        extendBody: true, // 🔥 body를 네비게이션 바 아래까지 확장
        appBar: AppBar(
          backgroundColor: Colors.white, // 🔥 흰색으로 변경
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const AppTitleWidget('커뮤니티'),
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
            child: Container(height: 1, color: AppTheme.primaryColor),
          ),
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const TodoListScreen()),
            );
          },
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.edit, color: Colors.white),
        ),
        bottomNavigationBar: BottomNavigationWidget(
          currentIndex: _selectedIndex,
          fromScreen: 'community',
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null && _posts.isEmpty) {
      return _buildErrorState(_errorMessage!);
    }

    if (_posts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 120),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        separatorBuilder: (context, index) {
          if (_hasMore && index == _posts.length) {
            return const SizedBox.shrink();
          }
          return _buildDivider();
        },
        itemBuilder: (context, index) {
          if (_hasMore && index == _posts.length) {
            return _buildLoadMoreIndicator();
          }
          final post = _posts[index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  Future<void> _refreshPosts() async {
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    await _fetchPosts(page: 1, replace: true);
  }

  Future<void> _loadInitialPosts() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMore = true;
      _posts.clear();
    });
    await _fetchPosts(page: 1, replace: true);
    setState(() {
      _isInitialLoading = false;
    });
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore) return;
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;
    final nextPage = _currentPage + 1;
    await _fetchPosts(page: nextPage);
  }

  Future<void> _fetchPosts({required int page, bool replace = false}) async {
    if (_isLoadingMore) return;
    setState(() {
      if (!replace) {
        _isLoadingMore = true;
      }
    });

    try {
      final response = await CommunityService.getAllPosts(page: page);
      final rawPosts = _extractPosts(response);
      final normalized = rawPosts.map(_normalizePost).toList();

      setState(() {
        if (replace) {
          _posts
            ..clear()
            ..addAll(normalized);
        } else {
          _mergePosts(normalized);
        }
        _currentPage = page;
        _hasMore = normalized.isNotEmpty;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _hasMore = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _mergePosts(List<Map<String, dynamic>> incoming) {
    final existingIds = _posts
        .map((post) => post['postId']?.toString())
        .whereType<String>()
        .toSet();

    for (final post in incoming) {
      final key = post['postId']?.toString();
      if (key != null) {
        if (!existingIds.contains(key)) {
          _posts.add(post);
          existingIds.add(key);
        } else {
          final index = _posts.indexWhere(
            (existing) => existing['postId']?.toString() == key,
          );
          if (index != -1) {
            _posts[index] = post;
          }
        }
      } else {
        _posts.add(post);
      }
    }
  }

  Widget _buildLoadMoreIndicator() {
    if (_isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );
    }
    return const SizedBox(height: 24);
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
    final userData =
        raw['user'] ??
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

    final title =
        _firstNonEmptyString([
          raw['title'],
          raw['postTitle'],
          raw['subject'],
          raw['headline'],
        ]) ??
        '';

    final content =
        _firstNonEmptyString([
          raw['content'],
          raw['body'],
          raw['description'],
          raw['postContent'],
          raw['merge_history_name'],
        ]) ??
        '';

    final createdAt =
        raw['createdAt'] ??
        raw['created_at'] ??
        raw['createdTime'] ??
        raw['created_time'] ??
        raw['registerDate'] ??
        raw['regDate'] ??
        raw['uploaded_at'];

    final timeDisplay =
        _firstNonEmptyString([
          raw['timeAgo'],
          raw['time_ago'],
          raw['displayTime'],
          raw['time'],
        ]) ??
        _formatTimeAgo(createdAt);

    final userId = _firstNonEmptyString([
      raw['user_id'],
      raw['userId'],
      raw['author_id'],
      raw['authorId'],
      raw['writer_id'],
      raw['writerId'],
      if (userData is Map<String, dynamic>) ...[
        userData['id'],
        userData['userId'],
        userData['user_id'],
      ],
    ]);

    Map<String, dynamic>? schedule;
    final scheduleData = raw['schedule'];
    if (scheduleData is Map<String, dynamic>) {
      schedule = Map<String, dynamic>.from(scheduleData);
    }
    final mergeHistory = _firstNonEmptyString([
      raw['merge_history_name'],
      raw['mergeHistoryName'],
      if (raw['merge_history'] is Map<String, dynamic>)
        (raw['merge_history'] as Map<String, dynamic>)['name'],
    ]);
    final scheduleTitle = _extractScheduleTitle(schedule);
    final schedulePlaces = _extractSchedulePlaces(schedule, mergeHistory);
    final scheduleTime = _extractScheduleTime(raw, schedule);

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
      'schedule': schedule,
      'profileImageUrl': _firstNonEmptyString([
        raw['profileImageUrl'],
        raw['profile_image_url'],
        raw['profileImage'],
        raw['avatarUrl'],
      ]),
      'userId': userId,
      'raw': raw,
      'scheduleTitle': scheduleTitle,
      'schedulePlaces': schedulePlaces,
      'scheduleTime': scheduleTime,
      'mergeHistory': mergeHistory,
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
            Icon(Icons.error_outline, color: AppTheme.primaryColor, size: 48),
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
              onPressed: () => _loadInitialPosts(),
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
    final scheduleTitle = post['scheduleTitle'] as String?;
    final schedulePlaces =
        (post['schedulePlaces'] as List?)?.cast<String>() ?? const [];
    final scheduleTime = post['scheduleTime'] as String?;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(
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
                  'userId': post['userId'],
                  'raw': post['raw'],
                  'scheduleTitle': scheduleTitle,
                  'schedulePlaces': schedulePlaces,
                  'scheduleTime': scheduleTime,
                },
              ),
            ),
          );
          if (!mounted) return;
          if (result == true) {
            await _refreshPosts();
          }
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
                  UserAvatar(
                    imageUrl: profileImageUrl,
                    displayName: nickname,
                    radius: 20,
                  ),
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
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              if (scheduleTitle != null ||
                  schedulePlaces.isNotEmpty ||
                  scheduleTime != null) ...[
                const SizedBox(height: 12),
                _buildSchedulePreview(
                  title: scheduleTitle,
                  places: schedulePlaces,
                  timeText: scheduleTime,
                ),
                const SizedBox(height: 12),
              ] else
                const SizedBox(height: 12),

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

  Widget _buildSchedulePreview({
    String? title,
    List<String>? places,
    String? timeText,
  }) {
    const textStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFFFF8126),
    );

    final routeWidgets = <Widget>[];
    final safePlaces = places ?? const [];
    for (var i = 0; i < safePlaces.length; i++) {
      routeWidgets.add(Text(safePlaces[i], style: textStyle));
      if (i < safePlaces.length - 1) {
        routeWidgets.add(const Text(' → ', style: textStyle));
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
          if (title != null && title.trim().isNotEmpty) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.article, size: 16, color: Color(0xFFFF8126)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: textStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (routeWidgets.isNotEmpty || timeText != null)
              const SizedBox(height: 6),
          ],
          if (timeText != null)
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: Color(0xFFFF8126)),
                const SizedBox(width: 4),
                Text(timeText, style: textStyle),
              ],
            ),
          if (routeWidgets.isNotEmpty)
            Wrap(
              spacing: 2,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: routeWidgets,
            )
          else if (title == null || title.trim().isEmpty)
            const Text(
              '일정 정보가 없습니다.',
              style: TextStyle(fontSize: 12, color: Color(0xFFFF8126)),
            ),
        ],
      ),
    );
  }

  List<String> _extractSchedulePlaces(
    Map<String, dynamic>? schedule,
    String? mergeHistory,
  ) {
    final results = <String>[];

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
            results.add(text);
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
          results.addAll(
            trimmed
                .split('→')
                .map((segment) => segment.trim())
                .where((segment) => segment.isNotEmpty),
          );
        } else if (trimmed.isNotEmpty) {
          results.add(trimmed);
        }
      }
    }

    extract(schedule);

    if (mergeHistory != null && mergeHistory.contains('→')) {
      results.addAll(
        mergeHistory
            .split('→')
            .map((segment) => segment.trim())
            .where((segment) => segment.isNotEmpty),
      );
    }

    final seen = <String>{};
    final deduped = <String>[];
    for (final place in results) {
      if (seen.add(place)) {
        deduped.add(place);
      }
    }
    return deduped;
  }

  String? _extractScheduleTime(
    Map<String, dynamic> raw,
    Map<String, dynamic>? schedule,
  ) {
    final candidates = <String?>[
      raw['schedule_time']?.toString(),
      raw['scheduleTime']?.toString(),
      raw['time']?.toString(),
      if (raw['merge_history_time'] != null)
        raw['merge_history_time'].toString(),
      if (raw['merge_history'] is Map<String, dynamic>)
        (raw['merge_history'] as Map<String, dynamic>)['time']?.toString(),
      _firstNonEmptyString([
        schedule?['time'],
        schedule?['startTime'],
        schedule?['start_time'],
        schedule?['scheduleTime'],
      ]),
    ];

    for (final candidate in candidates) {
      if (candidate == null) continue;
      final trimmed = candidate.trim();
      if (trimmed.isEmpty) continue;
      final formatted = _formatTimeText(trimmed);
      if (formatted != null) {
        return formatted;
      }
    }
    return null;
  }

  String? _formatTimeText(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      final hour = parts[0].padLeft(2, '0');
      final minute = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
      return '$hour:$minute';
    }
    if (trimmed.length == 4 && int.tryParse(trimmed) != null) {
      final hour = trimmed.substring(0, 2);
      final minute = trimmed.substring(2, 4);
      return '$hour:$minute';
    }
    return trimmed;
  }

  Widget _buildDivider() {
    return Container(height: 1, color: AppTheme.dividerColor);
  }

  String? _extractScheduleTitle(Map<String, dynamic>? schedule) {
    if (schedule == null) return null;
    final candidates = [
      schedule['title'],
      schedule['name'],
      schedule['label'],
      schedule['scheduleTitle'],
    ];
    for (final candidate in candidates) {
      if (candidate == null) continue;
      final text = candidate.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }
}
