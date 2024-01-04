// firebase_analytics_manager.dart

import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseAnalyticsManager {
  static final FirebaseAnalyticsManager _instance = FirebaseAnalyticsManager._internal();

  FirebaseAnalytics analytics;
  FirebaseAnalyticsObserver observer;

  factory FirebaseAnalyticsManager() {
    return _instance;
  }

  FirebaseAnalyticsManager._internal()
      : analytics = FirebaseAnalytics.instance, // 생성자 내에서 초기화
        observer = FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance); // 생성자 내에서 초기화
}
