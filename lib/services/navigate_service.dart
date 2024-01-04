import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_budget_book/main.dart';
import 'package:shared_budget_book/screens/consent_verification_screen.dart';
import 'package:shared_budget_book/services/auth_service.dart';
import 'package:shared_budget_book/services/firebase_analytics_manager.dart';

class NavigateService {
  final AuthService _authService = AuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalyticsManager analyticsManager = FirebaseAnalyticsManager();

  void navigateAfterLogin(BuildContext context, bool isAdditionalInfoRequired) {
    if (isAdditionalInfoRequired) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ConsentAndVerificationScreen()));
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
}
