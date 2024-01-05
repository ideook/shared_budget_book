import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_budget_book/main.dart';
import 'package:shared_budget_book/models/user_model.dart';
import 'package:shared_budget_book/provider/user_model_provider.dart';
import 'package:shared_budget_book/screens/consent_verification_screen.dart';
import 'package:shared_budget_book/services/auth_service.dart';
import 'package:shared_budget_book/services/firebase_analytics_manager.dart';
import 'package:shared_budget_book/services/firestore_service.dart';
import 'package:shared_budget_book/services/navigate_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // 아이콘 사용을 위해 필요

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAnalyticsManager analyticsManager = FirebaseAnalyticsManager();
  final NavigateService navigateService = NavigateService();

  void handleLoginGoogle() async {
    var userCredential = await _authService.signInWithGoogle();

    if (userCredential != null && userCredential.user != null) {
      // 로그인 성공: 추가 정보 입력이 필요한지 확인
      bool isAdditionalInfoRequired = await _checkAdditionalInfoRequired(userCredential.user!.uid);

      if (!isAdditionalInfoRequired) await _firestoreService.updateLastSignInTime(userCredential.user!.uid);

      UserModel newUser = UserModel.fromFirebaseUser(userCredential.user!);

      navigateAfterLogin(isAdditionalInfoRequired, newUser);
    } else {
      // 로그인 실패: 오류 메시지 표시 등의 처리
    }
  }

  // Firestore에서 사용자 정보를 확인하는 메소드
  Future<bool> _checkAdditionalInfoRequired(String userId) async {
    //UserModel? userModel = await _firestoreService.getUser(userId);
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      // 사용자 문서가 Firestore에 존재하지 않으면, 추가 정보가 필요하다고 가정
      return true;
    }

    // data()의 반환값을 Map<String, dynamic>으로 캐스팅
    var data = userDoc.data() as Map<String, dynamic>?;

    if (data != null) {
      // data가 null이 아닐 때만 필드에 접근
      // 이메일 인증은 데이터가 있으면 일단 무조건 true 이지만, 인증을 정기적으로 해야하는 시나리오가 생길수있으므로 유지한다.
      bool emailVerified = data['emailVerified'] as bool? ?? false;

      // 필요한 필드가 비어있거나, 특정 조건을 만족하지 않는 경우 true 반환
      return !emailVerified;
    } else {
      // data가 null인 경우, 추가 정보가 필요하다고 가정
      return true;
    }
  }

  void navigateAfterLogin(bool isAdditionalInfoRequired, UserModel newUser) {
    if (isAdditionalInfoRequired) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ConsentAndVerificationScreen()));
    } else {
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
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = const Color(0xFF121212);
    Color foregroundColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor, // 배경색 변경
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // 위젯을 화면 상단과 하단으로 분배
          children: <Widget>[
            // 로고가 있는 부분
            const Expanded(
              child: Center(
                child: FlutterLogo(size: 100), // 로고, 실제 앱 로고로 교체 필요
              ),
            ),
            // 로그인 버튼들이 있는 부분
            Column(
              children: <Widget>[
                // Google 로그인 버튼
                _buildLoginButton(
                  iconData: FontAwesomeIcons.google,
                  text: 'Sign in with Google',
                  color: Color(0xFFDB4437), // 구글 버튼 색상
                  onPressed: () => handleLoginGoogle(),
                ),
                SizedBox(height: 16), // 버튼 사이의 간격
                // Facebook 로그인 버튼
                _buildLoginButton(
                    iconData: FontAwesomeIcons.facebook,
                    text: 'Sign in with Facebook',
                    color: Color(0xFF1877F2), // Facebook 버튼 색상
                    onPressed: () {}),
                SizedBox(height: 16),
                // Apple 로그인 버튼
                _buildLoginButton(
                    iconData: FontAwesomeIcons.apple,
                    text: 'Sign in with Apple',
                    color: Colors.black, // Apple 버튼 색상
                    onPressed: () {}),
                SizedBox(height: 32), // 하단 여백
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton({
    required IconData iconData,
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Padding(
        padding: const EdgeInsets.only(right: 8.0), // 아이콘과 텍스트 사이 간격
        child: FaIcon(iconData, color: Colors.white),
      ),
      label: Text(
        text,
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        alignment: Alignment.centerLeft,
        primary: color,
        minimumSize: Size(250, 50), // 버튼 크기 조정
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // 버튼 모서리 둥글기
          side: BorderSide(color: Colors.grey[850]!, width: 2), // 흰색 테두리 추가
        ),
        //elevation: 4.0, // 그림자 높이를 더 강조
        //shadowColor: Colors.grey[600], // 그림자 색상을 조금 더 어둡게 설정
      ),
    );
  }
}
