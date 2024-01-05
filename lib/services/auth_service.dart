import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_budget_book/main.dart';
import 'package:shared_budget_book/models/user_model.dart';
import 'package:shared_budget_book/screens/consent_verification_screen.dart';
import 'package:shared_budget_book/services/firebase_analytics_manager.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalyticsManager analyticsManager = FirebaseAnalyticsManager();

  // Google 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Facebook 로그인
  Future<UserCredential> signInWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login();
    final AuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.token);
    return await _firebaseAuth.signInWithCredential(credential);
  }

  // Apple 로그인
  Future<UserCredential> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    return await _firebaseAuth.signInWithCredential(oauthCredential);
  }

  // Firestore에서 사용자 정보를 확인하는 메소드
  Future<bool> _checkAdditionalInfoRequired(String userId) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      // 사용자 문서가 Firestore에 존재하지 않으면, 추가 정보가 필요하다고 가정
      return true;
    }

    // data()의 반환값을 Map<String, dynamic>으로 캐스팅
    var data = userDoc.data() as Map<String, dynamic>?;

    if (data != null) {
      // data가 null이 아닐 때만 필드에 접근
      bool emailVerified = data['emailVerified'] as bool? ?? false;
      bool consentGiven = data['consentGiven'] as bool? ?? false;

      // 필요한 필드가 비어있거나, 특정 조건을 만족하지 않는 경우 true 반환
      return !emailVerified || !consentGiven;
    } else {
      // data가 null인 경우, 추가 정보가 필요하다고 가정
      return true;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _firebaseAuth.signOut();
  }

  UserModel? registerUser() {
    User? firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      // UserModel 생성
      UserModel newUser = UserModel.fromFirebaseUser(firebaseUser);
      return newUser;
    } else {
      return null;
    }
  }
}
