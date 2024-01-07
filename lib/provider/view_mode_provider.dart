import 'package:flutter/material.dart';

class ViewModeProvider with ChangeNotifier {
  bool _isWeeklyView = true;
  bool _isExpanded = false;

  bool get isWeeklyView => _isWeeklyView;
  bool get isExpanded => _isExpanded;

  void toggleViewMode() {
    _isWeeklyView = !_isWeeklyView;
    notifyListeners(); // 상태 변경을 알림
  }

  void toggleSummaryExpand() {
    _isExpanded = !_isExpanded;
    notifyListeners(); // 상태 변경을 알림
  }
}
