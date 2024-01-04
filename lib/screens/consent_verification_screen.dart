import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConsentAndVerificationScreen extends StatefulWidget {
  const ConsentAndVerificationScreen({
    super.key,
  });

  @override
  State<ConsentAndVerificationScreen> createState() => _ConsentAndVerificationScreenState();
}

class _ConsentAndVerificationScreenState extends State<ConsentAndVerificationScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Consent and Email Verification"),
      ),
      body: Column(
        children: <Widget>[
          // 개인정보 동의 섹션
          CheckboxListTile(
            title: Text("I agree to the privacy policy"),
            value: _isConsentGiven,
            onChanged: (bool? newValue) {
              setState(() {
                _isConsentGiven = newValue!;
              });
            },
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
                Navigator.pushReplacementNamed(context, '/main');
              },
              child: Text("Proceed to Main Screen"),
            ),
          ),
        ],
      ),
    );
  }
}
