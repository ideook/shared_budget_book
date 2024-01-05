import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_budget_book/main.dart';
import 'package:shared_budget_book/models/user_model.dart';
import 'package:shared_budget_book/provider/user_model_provider.dart';
import 'package:shared_budget_book/services/firebase_analytics_manager.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_budget_book/services/firestore_service.dart';

class ConsentAndVerificationScreen extends StatefulWidget {
  const ConsentAndVerificationScreen({
    super.key,
  });

  @override
  State<ConsentAndVerificationScreen> createState() => _ConsentAndVerificationScreenState();
}

class _ConsentAndVerificationScreenState extends State<ConsentAndVerificationScreen> {
  final FirebaseAnalyticsManager analyticsManager = FirebaseAnalyticsManager();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool _isConsentGiven = false;
  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  void _checkEmailVerification() async {
    User? user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  void _verifyEmail() async {
    User? user = _firebaseAuth.currentUser;
    await user?.reload();
    if (user != null && user.emailVerified) {
      setState(() {
        _isEmailVerified = true;
      });
    }
  }

  bool _isGoogleSignIn() {
    User? user = _firebaseAuth.currentUser;
    return user?.providerData.any((userInfo) => userInfo.providerId == 'google.com') ?? false;
  }

  void _showPolicyDialog(String title, String markdownData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        var size = MediaQuery.of(context).size;
        return Dialog(
          insetPadding: EdgeInsets.all(15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Dialog의 둥근 모서리 설정
          ),
          child: Container(
            width: size.width * 1.0, // Dialog의 너비 설정
            height: size.height * 0.7, // Dialog의 너비 설정
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15), // Dialog 내부의 여백 설정
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 0, right: 0, left: 0, bottom: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 35), // 'X' 버튼과 내용 사이의 간격
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 30), // 'X' 버튼과 내용 사이의 간격
                          MarkdownBody(
                            data: markdownData,
                            shrinkWrap: true,
                          ),
                          SizedBox(height: 10), // 'X' 버튼과 내용 사이의 간격
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              '확인',
                              style: TextStyle(fontSize: 16),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blue, // 버튼 배경색
                              primary: Colors.white, // 버튼 텍스트 색상
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 5), // 패딩
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8), // 모서리 둥글기
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 다크 테마 색상 정의
    Color backgroundColor = const Color(0xFF121212); // 배경 색상
    Color foregroundColor = Colors.white; // 텍스트 색상
    Color accentColor = const Color(0xFF1F1F1F); // 입력 필드 배경 색상

    bool isGoogleUser = _isGoogleSignIn();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text("Consent and Email Verification"),
        backgroundColor: backgroundColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 개인정보 동의 섹션
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: RichText(
                  text: TextSpan(
                    style: TextStyle(color: foregroundColor, fontSize: 16),
                    children: [
                      TextSpan(text: "I agree to the "),
                      TextSpan(
                        text: "Terms of Service",
                        style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            String markdownData = await rootBundle.loadString("assets/texts/terms_of_service.md");
                            _showPolicyDialog("Terms of Service", markdownData);
                          },
                      ),
                      TextSpan(text: " and "),
                      TextSpan(
                        text: "Privacy Policy",
                        style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            String markdownData = await rootBundle.loadString("assets/texts/privacy_policy.md");
                            _showPolicyDialog("Privacy Policy", markdownData);
                          },
                      ),
                    ],
                  ),
                ),
                value: _isConsentGiven,
                onChanged: (bool? newValue) {
                  setState(() {
                    _isConsentGiven = newValue!;
                  });
                },
                controlAffinity: ListTileControlAffinity.trailing,
              ),
              SizedBox(height: 30),
              // 이메일 인증 섹션
              Visibility(
                visible: _isConsentGiven && !isGoogleUser,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text("An email verification has been sent to your email.", style: TextStyle(color: foregroundColor, fontSize: 16)),
                    SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: _verifyEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF333333),
                            elevation: 0, // 버튼의 그림자 제거
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)), // 모서리를 둥글지 않게
                            ),
                          ),
                          child: Text(
                            "I've Verified My Email",
                            style: TextStyle(color: foregroundColor),
                          ),
                        ),
                        Spacer(),
                        Visibility(
                          visible: _isEmailVerified,
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(width: 8),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Visibility(
          visible: _isConsentGiven && (isGoogleUser || _isEmailVerified),
          child: Padding(
            padding: EdgeInsets.only(bottom: 25, top: 20, left: 20, right: 20),
            child: ElevatedButton(
              onPressed: () async {
                User? firebaseUser = _firebaseAuth.currentUser;
                if (firebaseUser != null) {
                  UserModel newUser = UserModel.fromFirebaseUser(firebaseUser);
                  await _firestoreService.addUser(newUser);

                  // async 작업 후, 위젯이 여전히 마운트되어 있는지 확인
                  if (mounted) {
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3182F7),
                minimumSize: const Size.fromHeight(55), // 버튼 높이 설정
                elevation: 0, // 버튼의 그림자 제거
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)), // 모서리를 둥글지 않게
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min, // Row의 크기를 자식 요소에 맞춤
                children: [
                  Text('회원가입', style: TextStyle(fontSize: 16.0, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
