class History {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final DateTime createdAt;

  History({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.createdAt,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      id: json['id'] ?? '',
      restaurantId: '', // 🔥 목록 조회에서는 category_id가 없음
      restaurantName: json['categories_name'] ?? '',
      createdAt: json['visited_at'] != null
          ? DateTime.parse(json['visited_at'])
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'History(id: $id, restaurantName: $restaurantName, createdAt: $createdAt)';
  }
}
