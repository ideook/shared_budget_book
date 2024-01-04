import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_budget_book/main.dart';
import 'package:shared_budget_book/services/firebase_analytics_manager.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ConsentAndVerificationScreen extends StatefulWidget {
  const ConsentAndVerificationScreen({
    super.key,
  });

  @override
  State<ConsentAndVerificationScreen> createState() => _ConsentAndVerificationScreenState();
}

class _ConsentAndVerificationScreenState extends State<ConsentAndVerificationScreen> {
  final FirebaseAnalyticsManager analyticsManager = FirebaseAnalyticsManager();
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

  void _showPolicyDialog(String title, String markdownData) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
          MarkdownBody(
            data: markdownData,
            shrinkWrap: true,
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ])));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 다크 테마 색상 정의
    Color backgroundColor = const Color(0xFF121212); // 배경 색상
    Color foregroundColor = Colors.white; // 텍스트 색상
    Color accentColor = const Color(0xFF1F1F1F); // 입력 필드 배경 색상

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text("Consent and Email Verification"),
      ),
      body: Column(
        children: <Widget>[
          // 개인정보 동의 섹션
          CheckboxListTile(
            title: Row(
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      String markdownData = await rootBundle.loadString("assets/texts/terms_of_service.md");
                      _showPolicyDialog("Terms of Service", markdownData);
                    },
                    child: Text(
                      "Terms of Service",
                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
                Text(" and "),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      String markdownData = await rootBundle.loadString("assets/texts/privacy_policy.md");
                      _showPolicyDialog("Privacy Policy", markdownData);
                    },
                    child: Text(
                      "Privacy Policy",
                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
            ),
            value: _isConsentGiven,
            onChanged: (bool? newValue) {
              setState(() {
                _isConsentGiven = newValue!;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          // 이메일 인증 섹션
          Visibility(
            visible: _isConsentGiven,
            child: Column(
              children: <Widget>[
                Text("An email verification has been sent to your email."),
                ElevatedButton(
                  onPressed: _verifyEmail,
                  child: Text("I've Verified My Email"),
                ),
              ],
            ),
          ),
          // 모든 조건 충족 시 메인 화면으로 이동 버튼
          Visibility(
            visible: _isConsentGiven && _isEmailVerified,
            child: ElevatedButton(
              onPressed: () {
                // 메인 화면으로 이동
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MyHomePage(
                            analytics: analyticsManager.analytics,
                            observer: analyticsManager.observer,
                          )),
                  (Route<dynamic> route) => false,
                );
              },
              child: Text("Proceed to Main Screen"),
            ),
          ),
        ],
      ),
    );
  }
}
