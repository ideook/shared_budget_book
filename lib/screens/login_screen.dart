import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_budget_book/main.dart';
import 'package:shared_budget_book/screens/consent_verification_screen.dart';
import 'package:shared_budget_book/services/auth_service.dart';
import 'package:shared_budget_book/services/firebase_analytics_manager.dart';

class LoginScreen extends StatelessWidget {
  final AuthService _authService = AuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalyticsManager analyticsManager = FirebaseAnalyticsManager();

  void _handleLogin(BuildContext context) async {
    var userCredential = await _authService.signInWithGoogle();

    if (userCredential != null && userCredential.user != null) {
      // 로그인 성공: 추가 정보 입력이 필요한지 확인
      bool isAdditionalInfoRequired = await _checkAdditionalInfoRequired(userCredential.user!.uid);
      if (isAdditionalInfoRequired) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ConsentAndVerificationScreen()));
      } else {
        // 메인 화면으로 직접 이동하기
        FirebaseAnalyticsManager analyticsManager = FirebaseAnalyticsManager();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => MyHomePage(
                    analytics: analyticsManager.analytics,
                    observer: analyticsManager.observer,
                  )),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      // 로그인 실패: 오류 메시지 표시 등의 처리
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Welcome to the App', style: TextStyle(fontSize: 24.0)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _authService.signInWithGoogle(),
              child: Text('Sign in with Google'),
            ),
            ElevatedButton(
              onPressed: () => _authService.signInWithFacebook(),
              child: Text('Sign in with Facebook'),
            ),
            ElevatedButton(
              onPressed: () => _authService.signInWithApple(),
              child: Text('Sign in with Apple'),
            ),
          ],
        ),
      ),
    );
  }
}
