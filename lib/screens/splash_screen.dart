import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_budget_book/main.dart';
import 'package:shared_budget_book/services/firebase_analytics_manager.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  void _checkAuthentication() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: CircularProgressIndicator(), // 로딩 인디케이터 표시
        ),
      ),
    );
  }
}
