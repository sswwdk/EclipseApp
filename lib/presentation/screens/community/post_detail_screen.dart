import 'package:flutter/material.dart';
import 'package:characters/characters.dart';
import 'chat_screen.dart';
import '../../widgets/common_dialogs.dart';
import '../../../data/services/community_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/helpers/token_manager.dart';

class _PostDetailData {
  final Map<String, dynamic> post;
  final List<Map<String, dynamic>> comments;

  const _PostDetailData({
    required this.post,
    required this.comments,
  });
}

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<_PostDetailData> _detailFuture;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  Map<String, dynamic>? _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = Map<String, dynamic>.from(widget.post);
    final initialPostId = _coerceToInt(_currentPost?['postId'] ?? _currentPost?['post_id'] ?? _currentPost?['id']);
    if (initialPostId != null) {
      _currentPost?['postId'] = initialPostId;
    }
    _detailFuture = _loadPostDetail();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
          '게시글',
          style: TextStyle(
            color: Color(0xFFFF8126),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (String value) {
              switch (value) {
                case 'delete':
                  _confirmDeletePost();
                  break;
                case 'report':
                  _showReportDialog();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              final isMyPost = _isMyPost();
              if (isMyPost) {
                return [
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('게시글 삭제하기'),
                      ],
                    ),
                  ),
                ];
              }

              return [
                const PopupMenuItem<String>(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.report, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('게시글 신고하기'),
                    ],
                  ),
                ),
              ];
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
      body: FutureBuilder<_PostDetailData>(
        future: _detailFuture,
        builder: (context, snapshot) {
          final Map<String, dynamic> postData =
              snapshot.data?.post ?? Map<String, dynamic>.from(widget.post);
          final List<Map<String, dynamic>>? comments = snapshot.data?.comments;
          final bool isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasError;
          final bool hasError = snapshot.hasError && !isLoading;
          final int? commentCount =
              comments?.length ?? _commentCountFromPost(postData);

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildMainPostCard(postData, commentCount),
                const Divider(height: 1),
                if (isLoading && comments == null)
                  _buildCommentsLoading()
                else if (hasError)
                  _buildCommentsError(snapshot.error.toString())
                else if (comments == null || comments.isEmpty)
                  _buildCommentsEmpty()
                else
                  _buildCommentsSection(comments),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildCommentInput(),
    );
  }

  Widget _buildMainPostCard(
    Map<String, dynamic> post,
    int? commentCount,
  ) {
    final rawData = post['raw'];
    Map<String, dynamic>? rawMap;
    if (rawData is Map<String, dynamic>) {
      rawMap = rawData;
    } else if (rawData is Map) {
      rawMap = rawData.cast<String, dynamic>();
    }

    final userData = rawMap?['user'];
    Map<String, dynamic>? rawUser;
    if (userData is Map<String, dynamic>) {
      rawUser = userData;
    } else if (userData is Map) {
      rawUser = userData.cast<String, dynamic>();
    }

    final otherUserId = _firstNonEmptyString([
      post['userId'],
      post['user_id'],
      rawMap?['userId'],
      rawMap?['user_id'],
      rawUser?['id'],
      rawUser?['userId'],
      rawUser?['user_id'],
    ]);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보
          Row(
            children: [
              // 프로필 이미지
              _buildProfileAvatar(
                (post['nickname'] ?? '익명 사용자').toString(),
                radius: 25,
                fontSize: 18,
              ), 
              const SizedBox(width: 12),
              // 닉네임과 시간
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (post['nickname'] ?? '익명 사용자').toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (post['timeAgo'] ?? '방금 전').toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isMyPost())
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          user: {
                            'nickname': post['nickname'],
                            'profileImage': post['profileImage'],
                          },
                          post: {
                            'title': post['title'],
                            'content': post['content'],
                            'schedule': post['schedule'],
                          },
                          otherUserId: otherUserId,
                        ),
                      ),
                    );
                  },
                  child: Transform.rotate(
                    angle: -0.5, // 오른쪽 위를 가리키도록 회전
                    child: Icon(
                      Icons.send,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 포스트 제목
          Text(
            (post['title'] ?? '').toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          // 포스트 내용
          Text(
            (post['content'] ?? '').toString(),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          
          // 일정표 정보 (있는 경우에만 표시)
          if (post['schedule'] != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8126).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF8126).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: const Color(0xFFFF8126),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '일정표가 뜰 예정입니다',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8126),
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // 액션 버튼들
          Row(
            children: [
              _buildActionButton(
                Icons.chat_bubble_outline,
                '댓글',
                commentCount,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, int? count) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          count == null ? label : '$label $count',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection(List<Map<String, dynamic>> comments) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '댓글 ${comments.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          ...comments.map((comment) => _buildCommentCard(comment)).toList(),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    final nickname = (comment['nickname'] ?? '익명 사용자').toString();
    final timeAgo = (comment['timeAgo'] ?? '방금 전').toString();
    final content = (comment['content'] ?? '').toString();
    final commentUserId = comment['userId']?.toString();
    final currentUserId = TokenManager.userId;
    final isOwnComment =
        currentUserId != null && commentUserId != null && commentUserId == currentUserId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 프로필 이미지
              _buildProfileAvatar(
                nickname,
                radius: 16,
                fontSize: 13,
              ),
              const SizedBox(width: 8),
              // 닉네임과 시간
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey[500],
                  size: 18,
                ),
                onSelected: (value) => _onCommentMenuSelected(value, comment),
                itemBuilder: (context) {
                  final items = <PopupMenuEntry<String>>[];

                  if (isOwnComment) {
                    items.add(
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('댓글 삭제하기'),
                      ),
                    );
                  } else {
                    items.add(
                      const PopupMenuItem<String>(
                        value: 'report',
                        child: Text('댓글 신고하기'),
                      ),
                    );
                  }

                  return items;
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // 프로필 이미지
      _buildProfileAvatar(
        TokenManager.userName ?? '유저',
        radius: 16,
        fontSize: 13,
      ),
          const SizedBox(width: 12),
          // 댓글 입력 필드
          Expanded(
            child: TextField(
              controller: _commentController,
              enabled: !_isSubmittingComment,
              decoration: InputDecoration(
                hintText: '댓글을 입력하세요...',
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFFF8126)),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 14),
              minLines: 1,
              maxLines: 3,
            ),
          ),
          const SizedBox(width: 8),
          // 전송 버튼
          InkWell(
            onTap: _isSubmittingComment ? null : _handleSubmitComment,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isSubmittingComment
                    ? const Color(0xFFFF8126).withOpacity(0.5)
                    : const Color(0xFFFF8126),
                shape: BoxShape.circle,
              ),
              child: _isSubmittingComment
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 16,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    CommonDialogs.showReportConfirmation(
      context: context,
      title: '게시글 신고하기',
      content: '이 게시글을 신고하시겠습니까?\n신고된 게시글은 검토 후 조치됩니다.',
      onConfirm: () {
        _showReportSuccess();
      },
    );
  }

  void _showReportSuccess() {
    CommonDialogs.showSuccess(
      context: context,
      message: '신고가 접수되었습니다. 검토 후 조치하겠습니다.',
    );
  }

  Future<void> _handleSubmitComment() async {
    final postId = _resolvePostId();
    final trimmed = _commentController.text.trim();

    if (_isSubmittingComment) {
      return;
    }

    if (postId == null) {
      _showSnackBar('게시글 정보를 찾을 수 없습니다.');
      return;
    }

    if (trimmed.isEmpty) {
      _showSnackBar('댓글을 입력해주세요.');
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      await CommunityService.createComment(postId, trimmed);
      _commentController.clear();
      FocusScope.of(context).unfocus();
      if (!mounted) return;
      setState(() {
        _detailFuture = _loadPostDetail();
      });
    } catch (e) {
      _showSnackBar('댓글 등록에 실패했습니다. 다시 시도해주세요.');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmittingComment = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<_PostDetailData> _loadPostDetail() async {
    final postId = _resolvePostId();
    if (postId == null) {
      return _PostDetailData(
        post: Map<String, dynamic>.from(widget.post),
        comments: const [],
      );
    }

    try {
      final response = await CommunityService.getSpecificPost(postId.toString());
      final normalizedPost =
          _normalizePostDetail(response, Map<String, dynamic>.from(widget.post))
            ..['postId'] = postId;
      final rawComments = _extractComments(response['comments'] ?? response);
      final comments = rawComments.map(_normalizeComment).toList();
      normalizedPost['commentCount'] = comments.length;
      _currentPost = normalizedPost;
      return _PostDetailData(
        post: normalizedPost,
        comments: comments,
      );
    } catch (e) {
      throw Exception('게시글 상세 조회 실패: $e');
    }
  }

  int? _resolvePostId() {
    final raw = widget.post;
    final rawData = raw['raw'];
    final candidates = [
      raw['postId'],
      raw['post_id'],
      raw['id'],
      if (rawData is Map<String, dynamic>) ...[
        rawData['id'],
        rawData['postId'],
        rawData['post_id'],
      ],
    ];

    for (final candidate in candidates) {
      final parsed = _coerceToInt(candidate);
      if (parsed != null) {
        return parsed;
      }
    }

    return _coerceToInt(_currentPost?['postId']);
  }

  bool _isMyPost() {
    final post = _latestPostData();
    final postUserId = post?['userId'] ?? post?['user_id'];
    final currentUserId = TokenManager.userId;
    if (postUserId == null || currentUserId == null) {
      return false;
    }
    return postUserId.toString() == currentUserId.toString();
  }

  Map<String, dynamic>? _latestPostData() {
    return _currentPost ?? widget.post;
  }

  int? _commentCountFromPost(Map<String, dynamic> post) {
    final rawCount = post['commentCount'] ??
        post['comment_count'] ??
        post['comments'] ??
        post['commentLength'];

    if (rawCount is List) {
      return rawCount.length;
    }
    if (rawCount is int) {
      return rawCount;
    }
    if (rawCount is String) {
      final parsed = int.tryParse(rawCount);
      if (parsed != null) return parsed;
    }
    return null;
  }

  Map<String, dynamic> _normalizePostDetail(
    Map<String, dynamic> raw,
    Map<String, dynamic> fallback,
  ) {
    final normalized = Map<String, dynamic>.from(fallback);

    normalized['raw'] = raw;
    final normalizedPostId = _firstValidInt([
      raw['id'],
      raw['post_id'],
      raw['postId'],
      fallback['postId'],
      fallback['id'],
    ]);
    if (normalizedPostId != null) {
      normalized['postId'] = normalizedPostId;
    } else {
      normalized.remove('postId');
    }

    normalized['nickname'] = _firstNonEmptyString([
          raw['user_nickname'],
          raw['userNickname'],
          fallback['nickname'],
          fallback['userName'],
        ]) ??
        '익명 사용자';

    normalized['title'] = _firstNonEmptyString([
          raw['title'],
          raw['subject'],
          raw['headline'],
          fallback['title'],
        ]) ??
        '';

    normalized['content'] = _firstNonEmptyString([
          raw['body'],
          raw['content'],
          raw['description'],
          fallback['content'],
        ]) ??
        '';

    final createdAt = raw['create_at'] ??
        raw['created_at'] ??
        raw['createdAt'] ??
        raw['created_time'] ??
        fallback['createdAt'];

    normalized['createdAt'] = createdAt;

    normalized['timeAgo'] = _firstNonEmptyString([
          raw['timeAgo'],
          raw['time_ago'],
          raw['displayTime'],
          fallback['timeAgo'],
        ]) ??
        _formatTimeAgo(createdAt);

    final userId = _firstNonEmptyString([
      raw['user_id'],
      raw['userId'],
      fallback['user_id'],
      fallback['userId'],
    ]);

    if (userId != null) {
      normalized['user_id'] = userId;
      normalized['userId'] = userId;
    }

    if (!normalized.containsKey('profileImageUrl')) {
      normalized['profileImageUrl'] = fallback['profileImageUrl'];
    }

    return normalized;
  }

  List<Map<String, dynamic>> _extractComments(dynamic response) {
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList();
    }

    if (response is Map<String, dynamic>) {
      final keys = [
        'comments',
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
        final extracted = _extractComments(value);
        if (extracted.isNotEmpty) {
          return extracted;
        }
      }
    }

    return [];
  }

  Map<String, dynamic> _normalizeComment(Map<String, dynamic> raw) {
    final userData = raw['user'] ??
        raw['author'] ??
        raw['writer'] ??
        raw['member'];

    final userId = _firstNonEmptyString([
      raw['user_id'],
      raw['userId'],
      raw['author_id'],
      raw['writer_id'],
      if (userData is Map<String, dynamic>) ...[
        userData['user_id'],
        userData['id'],
      ],
    ]);

    final nickname = _firstNonEmptyString([
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
        ]) ??
        '익명 사용자';

    final content = _firstNonEmptyString([
          raw['content'],
          raw['body'],
          raw['text'],
          raw['comment'],
        ]) ??
        '';

    final createdAt = raw['create_at'] ??
        raw['createdAt'] ??
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

    final likesValue = raw['likes'] ??
        raw['like_count'] ??
        raw['likeCount'] ??
        raw['favorite'] ??
        0;

    final likeCount = likesValue is int
        ? likesValue
        : int.tryParse(likesValue.toString()) ?? 0;

    return {
      'commentId': _firstValidInt([
        raw['id'],
        raw['commentId'],
        raw['comment_id'],
      ]),
      'nickname': nickname,
      'timeAgo': timeDisplay,
      'content': content,
      'likes': likeCount,
      'userId': userId,
      'raw': raw,
    };
  }

  void _onCommentMenuSelected(String action, Map<String, dynamic> comment) {
    switch (action) {
      case 'delete':
        _confirmDeleteComment(comment);
        break;
      case 'report':
        _confirmReportComment(comment);
        break;
    }
  }

  void _confirmDeleteComment(Map<String, dynamic> comment) {
    CommonDialogs.showConfirmation(
      context: context,
      title: '댓글 삭제',
      content: '댓글을 삭제하시겠습니까?',
      confirmText: '삭제',
      confirmButtonColor: Colors.red,
      onConfirm: () => _deleteComment(comment),
    );
  }

  Future<void> _deleteComment(Map<String, dynamic> comment) async {
    final postId = _resolvePostId();
    final commentId = _coerceToInt(comment['commentId']);
    final userId = TokenManager.userId;

    if (postId == null || commentId == null || userId == null) {
      _showSnackBar('댓글 정보를 찾을 수 없습니다.');
      return;
    }

    try {
      await CommunityService.deleteComment(postId.toString(), commentId.toString());
      if (!mounted) return;
      CommonDialogs.showSuccess(
        context: context,
        message: '댓글이 삭제되었습니다.',
      );
      setState(() {
        _detailFuture = _loadPostDetail();
      });
    } catch (e) {
      _showSnackBar('댓글 삭제에 실패했습니다. 다시 시도해주세요.');
    }
  }

  void _confirmReportComment(Map<String, dynamic> comment) {
    CommonDialogs.showReportConfirmation(
      context: context,
      title: '댓글 신고하기',
      content: '해당 댓글을 신고하시겠습니까?',
      onConfirm: () => _reportComment(comment),
    );
  }

  Future<void> _reportComment(Map<String, dynamic> comment) async {
    final userId = TokenManager.userId;
    final commentId = _coerceToInt(comment['commentId']);

    if (userId == null) {
      _showSnackBar('로그인이 필요합니다.');
      return;
    }

    if (commentId == null) {
      _showSnackBar('댓글 정보를 찾을 수 없습니다.');
      return;
    }

    try {
      await CommunityService.reportContent(
        userId,
        'comment',
        commentId.toString(),
        '부적절한 댓글 신고',
      );
      if (!mounted) return;
      CommonDialogs.showSuccess(
        context: context,
        message: '신고가 접수되었습니다.',
      );
    } catch (e) {
      _showSnackBar('신고에 실패했습니다. 다시 시도해주세요.');
    }
  }

  void _confirmDeletePost() {
    CommonDialogs.showConfirmation(
      context: context,
      title: '게시글 삭제',
      content: '게시글을 삭제하시겠습니까?',
      confirmText: '삭제',
      confirmButtonColor: Colors.red,
      onConfirm: _deletePost,
    );
  }

  Future<void> _deletePost() async {
    final postId = _resolvePostId();
    final userId = TokenManager.userId;

    if (postId == null || userId == null) {
      _showSnackBar('게시글 정보를 찾을 수 없습니다.');
      return;
    }

    try {
      await CommunityService.deletePost(postId, userId);
      if (!mounted) return;
      CommonDialogs.showSuccess(
        context: context,
        message: '게시글이 삭제되었습니다.',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      _showSnackBar('게시글 삭제에 실패했습니다. 다시 시도해주세요.');
    }
  }

  Widget _buildProfileAvatar(
    String name, {
    double radius = 20,
    double fontSize = 16,
  }) {
    final trimmed = name.trim();
    final initial = trimmed.isNotEmpty
        ? trimmed.characters.first.toUpperCase()
        : '?';
    final colors = _avatarColorsFor(initial);

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.background,
      child: Text(
        initial,
        style: TextStyle(
          color: colors.foreground,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
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

  int? _firstValidInt(List<dynamic> values) {
    for (final value in values) {
      final parsed = _coerceToInt(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  int? _coerceToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
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

  Widget _buildCommentsLoading() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildCommentsError(String message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: AppTheme.primaryColor,
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            '댓글을 불러오지 못했습니다.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _detailFuture = _loadPostDetail();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsEmpty() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: AppTheme.textSecondaryColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          const Text(
            '아직 댓글이 없습니다.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '첫 댓글을 작성해보세요!',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
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