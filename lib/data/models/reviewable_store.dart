class ReviewableStore {
  final String categoryId;
  final String categoryName;
  final String categoryType;
  final String? imageUrl;
  final String address; // 🔥 주소 필드 추가
  final int visitCount;
  final int reviewCount;
  final DateTime lastVisitDate;

  ReviewableStore({
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    this.imageUrl,
    required this.address, // 🔥 필수 파라미터로 추가
    required this.visitCount,
    required this.reviewCount,
    required this.lastVisitDate,
  });

  /// 일부 필드만 변경한 새 객체 생성
  ReviewableStore copyWith({
    String? categoryId,
    String? categoryName,
    String? categoryType,
    String? imageUrl,
    String? address, // 🔥 추가
    int? visitCount,
    int? reviewCount,
    DateTime? lastVisitDate,
  }) {
    return ReviewableStore(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryType: categoryType ?? this.categoryType,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address, // 🔥 추가
      visitCount: visitCount ?? this.visitCount,
      reviewCount: reviewCount ?? this.reviewCount,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
    );
  }

  @override
  String toString() {
    return 'ReviewableStore(categoryName: $categoryName, address: $address, visitCount: $visitCount)';
  }
}
