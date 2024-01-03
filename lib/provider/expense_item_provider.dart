import 'package:flutter/material.dart';

class ExpenseItemProvider extends ChangeNotifier {
  num amount;
  DateTime selectedDate;
  String? category;

  ExpenseItemProvider({
    this.amount = 0,
    DateTime? selectedDate,
    this.category,
  }) : selectedDate = selectedDate ?? DateTime.now(); // 현재 시간으로 초기화

  // ExpenseData 객체를 업데이트하는 메소드
  void updateData({num? newAmount, DateTime? newSelectedDate, String? newCategory}) {
    if (newAmount != null) {
      amount = newAmount;
    }
    if (newSelectedDate != null) {
      selectedDate = newSelectedDate;
    }
    if (newCategory != null) {
      category = newCategory;
    }
    notifyListeners(); // 리스너에게 변경 사항 알림
  }

  // ExpenseData 객체를 초기화하는 메소드
  void clearData() {
    amount = 0;
    selectedDate = DateTime.now();
    category = null;
    notifyListeners(); // 리스너에게 변경 사항 알림
  }
}
