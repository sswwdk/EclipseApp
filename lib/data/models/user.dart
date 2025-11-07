// User 모델 정의
class User {
  final String? id;
  final String? username;
  final String? nickname;
  final String? email;
  final String? phone;
  final String? address;
  final int? sex;
  final String? birth;

  User({
    this.id,
    this.username,
    this.nickname,
    this.email,
    this.phone,
    this.address,
    this.sex,
    this.birth,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      username: json['username']?.toString(),
      nickname: json['nickname']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      sex: json['sex'] is int ? json['sex'] : (json['sex'] is String ? int.tryParse(json['sex']) : null),
      birth: json['birth']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'email': email,
      'phone': phone,
      'address': address,
      'sex': sex,
      'birth': birth,
    };
  }
}

