class Review {
  final String nickname;
  final double rating;
  final String content;

  Review({required this.nickname, required this.rating, required this.content});

  static List<Review> fromList(dynamic src) {
    if (src is List) {
      return src.whereType<Map<String, dynamic>>().map((m) => Review(
        nickname: (m['nickname'] ?? m['user'] ?? '익명').toString(),
        rating: _parseDouble(m['rating']) ?? 0.0,
        content: (m['content'] ?? m['text'] ?? '').toString(),
      )).toList();
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

