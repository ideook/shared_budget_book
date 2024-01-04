import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  String id;
  String name;
  String email;
  String profilePicture;
  Map<String, dynamic> settings;
  String authType; // 인증 유형을 나타내는 필드 추가

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profilePicture,
    required this.settings,
    this.authType = 'unknown', // 기본값 설정
  });

  factory UserModel.fromFirebaseUser(User user) {
    // Firebase User에서 제공하는 ProviderData를 사용하여 인증 유형 파악
    String authType = 'unknown';
    if (user.providerData.isNotEmpty) {
      authType = user.providerData[0].providerId; // 예: "google.com", "facebook.com", "apple.com"
    }

    return UserModel(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      profilePicture: user.photoURL ?? '',
      settings: {}, // Firebase 인증에서 제공되지 않는 추가 설정은 여기서 초기화
      authType: authType,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profilePicture: map['profilePicture'] ?? '',
      settings: map['settings'] ?? {},
      authType: map['authType'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'settings': settings,
      'authType': authType, // 인증 유형을 맵에 포함
    };
  }
}
