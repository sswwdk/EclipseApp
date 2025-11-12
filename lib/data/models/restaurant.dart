import 'review.dart';

class Restaurant {
  final String id;
  final String name;
  final String? do_;
  final String? si;
  final String? gu;
  final String? detailAddress;
  final String? subCategory;
  final String? businessHour;
  final String? phone;
  final String? type;
  final String? image;
  final String? latitude;
  final String? longitude;
  final String? lastCrawl;
  final double? rating;
  final double? averageStars;
  final List<Review> reviews;
  final List<String> tags;
  final bool isFavorite;

  Restaurant({
    required this.id,
    required this.name,
    this.do_,
    this.si,
    this.gu,
    this.detailAddress,
    this.subCategory,
    this.businessHour,
    this.phone,
    this.type,
    this.image,
    this.latitude,
    this.longitude,
    this.lastCrawl,
    double? rating,
    double? averageStars,
    this.reviews = const [],
    this.tags = const [],
    this.isFavorite = false,
  })  : rating = rating ?? averageStars,
        averageStars = averageStars ?? rating;

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      do_: json['do'],
      si: json['si'],
      gu: json['gu'],
      detailAddress: json['detail_address'],
      subCategory: json['sub_category'],
      businessHour: json['business_hour'],
      phone: json['phone'],
      type: json['type'],
      image: json['image'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      lastCrawl: json['last_crawl'],
      rating: _parseDouble(json['rating']),
      averageStars: _parseDouble(json['average_stars']),
      reviews: Review.fromList(json['reviews']),
      tags: _parseStringList(json['tags']),
      isFavorite: (json['is_like'] == true),
    );
  }

  // 서버 응답 형식에 맞는 팩토리 메서드
  factory Restaurant.fromMainScreenJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id']?.toString() ?? '',
      name: json['title']?.toString() ?? '',
      image: json['image_url']?.toString(),
      subCategory: json['sub_category']?.toString(),
      detailAddress: json['detail_address']?.toString(),
      phone: json['phone']?.toString(),
      do_: null,
      si: null,
      gu: null,
      businessHour: null,
      type: null,
      latitude: null,
      longitude: null,
      lastCrawl: null,
      rating: _parseDouble(json['rating']),
      averageStars: _parseDouble(json['average_stars']),
      reviews: Review.fromList(json['reviews']),
      tags: _parseStringList(json['tags']),
      isFavorite: (json['is_like'] == true),
    );
  }

  // 기존 코드와의 호환성을 위한 getter들
  String? get address => detailAddress != null ? '${si ?? ''} ${gu ?? ''} ${detailAddress ?? ''}' : null;
  String? get imageUrl => image;
  String? get description => subCategory;
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final s = v.toString();
  return double.tryParse(s);
}

List<String> _parseStringList(dynamic v) {
  if (v is List) {
    return v.map((e) => e.toString()).toList();
  }
  return const [];
}

