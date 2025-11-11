class Review {
  final String? id;
  final String? categoryId;
  final String? categoryName;
  final String nickname;
  final double rating;
  final String content;
  final DateTime? createdAt;

  Review({
    this.id,
    this.categoryId,
    this.categoryName,
    required this.nickname,
    required this.rating,
    required this.content,
    this.createdAt,
  });

  static List<Review> fromList(dynamic src) {
    if (src is List) {
      return src.whereType<Map<String, dynamic>>().map((m) {
        final nickname =
            (m['nickname'] ?? m['user'] ?? m['user_nickname'] ?? '익명')
                .toString();
        final rating = _parseDouble(m['rating'] ?? m['stars']) ?? 0.0;
        final content =
            (m['content'] ?? m['comments'] ?? m['comment'] ?? m['text'] ?? '')
                .toString();
        final createdAt = _parseDateTime(
          m['created_at'] ?? m['createdAt'] ?? m['create_at'],
        );
        return Review(
          id: (m['review_id'] ?? m['id'])?.toString(),
          categoryId: (m['category_id'] ?? m['categoryId'])?.toString(),
          categoryName: (m['category_name'] ?? m['categoryName'])?.toString(),
          nickname: nickname,
          rating: rating,
          content: content,
          createdAt: createdAt,
        );
      }).toList();
    }
    return const [];
  }
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final s = v.toString();
  return double.tryParse(s);
}

DateTime? _parseDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  var s = v.toString();
  if (s.contains(' ') && !s.contains('T')) {
    s = s.replaceFirst(' ', 'T');
  }
  final parsed = DateTime.tryParse(s);
  if (parsed != null) {
    return parsed;
  }
  final match =
      RegExp(r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})')
          .firstMatch(s);
  if (match != null) {
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
  }
  return null;
}


