import 'package:flutter/material.dart';

class ViewModeProvider with ChangeNotifier {
  bool _isWeeklyView = true;

  bool get isWeeklyView => _isWeeklyView;

  void toggleViewMode() {
    _isWeeklyView = !_isWeeklyView;
    notifyListeners(); // 상태 변경을 알림
  }
}
