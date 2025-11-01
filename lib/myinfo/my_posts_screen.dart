import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../community/post_detail_screen.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({Key? key}) : super(key: key);

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  bool _loading = true;
  String? _errorMessage;
  List<MyPostItem> _posts = const [];

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

    // 하드코딩된 샘플 데이터
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    setState(() {
      _posts = [
        MyPostItem(
          id: '1',
          title: '고기 맛있겠다',
          content: '고기 먹으러 가고싶은데 친구가 없어요. 같이 가실 분 구합니다. 평일 저녁이나 주말 오후에 같이 맛있는 고기를 먹으러 가실 분 있으면 좋겠어요. 특히 삼겹살이나 갈비를 좋아하는데 같이 가서 맛있게 먹고 싶습니다.',
          commentCount: 6,
          dateText: '04/22',
        ),
      ];
      _loading = false;
    });
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
                'title': post.title,
                'content': post.content,
                'comment_count': post.commentCount,
                'created_at': post.dateText,
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
}

class MyPostItem {
  final String id;
  final String title;
  final String content;
  final int commentCount;
  final String dateText;

  const MyPostItem({
    required this.id,
    required this.title,
    required this.content,
    required this.commentCount,
    required this.dateText,
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
      final int commentCount = (m['comment_count'] ?? m['commentCount'] ?? m['comments'] ?? 0) as int;
      final String date = (m['created_at'] ?? m['createdAt'] ?? m['date'] ?? '').toString();

      return MyPostItem(
        id: id.isEmpty ? DateTime.now().microsecondsSinceEpoch.toString() : id,
        title: title.isEmpty ? '제목 없음' : title,
        content: content,
        commentCount: commentCount,
        dateText: _formatDate(date),
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
}

