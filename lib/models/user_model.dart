import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  String id;
  String name;
  String email;
  String profilePicture;
  Map<String, dynamic> settings;
  String authType; // 인증 유형
  bool emailVerified; // 이메일 인증 여부
  DateTime createdAt; // 가입일시
  DateTime lastSignInAt; // 마지막 로그인 일시

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profilePicture,
    required this.settings,
    this.authType = 'unknown',
    this.emailVerified = false,
    DateTime? createdAt,
    DateTime? lastSignInAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastSignInAt = lastSignInAt ?? DateTime.now();

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      profilePicture: user.photoURL ?? '',
      settings: {},
      authType: user.providerData.isNotEmpty ? user.providerData[0].providerId : 'unknown',
      emailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastSignInAt: DateTime.now(), // 현재 시간으로 마지막 로그인 시간 설정
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
      emailVerified: map['emailVerified'] as bool? ?? false,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      lastSignInAt: map['lastSignInAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'settings': settings,
      'authType': authType,
      'emailVerified': emailVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastSignInAt': lastSignInAt.toIso8601String(), // ISO 8601 포맷으로 변환
    };
  }
}
