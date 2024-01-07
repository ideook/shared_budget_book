import 'package:flutter/material.dart';
import 'package:earnedon/models/expense_item.dart';
import 'package:earnedon/services/firestore_service.dart';

class ExpenseItemProvider extends ChangeNotifier {
  num amount = 0;
  DateTime selectedDate = DateTime.now();
  String? category;
  String? userId;
  String? profilePicture;

  void updateUser({String? newUserId, String? newProfilePicture}) {
    if (newUserId != null) userId = newUserId;
    if (newProfilePicture != null) profilePicture = newProfilePicture;
    notifyListeners();
  }

  void updateData({num? newAmount, DateTime? newSelectedDate, String? newCategory}) {
    if (newAmount != null) amount = newAmount;
    if (newSelectedDate != null) selectedDate = newSelectedDate;
    if (newCategory != null) category = newCategory;
    notifyListeners();
  }

  // ExpenseData 객체를 초기화하는 메소드
  void clearData() {
    amount = 0;
    selectedDate = DateTime.now();
    category = null;
    notifyListeners(); // 리스너에게 변경 사항 알림
  }

  Future<void> addExpenseItemToFirebase() async {
    if (category == null || userId == null) {
      return;
      //throw Exception("Category or UserId is not set.");
    }

    // ExpenseItem 객체 생성
    ExpenseItem newItem = ExpenseItem(
      amount: amount,
      category: category!,
      icon: profilePicture!, // 예시, 실제 앱에서는 적절한 아이콘 설정 필요
      datetime: selectedDate,
      userId: userId!,
      isHaveToAdd: false, // 기본값 설정
    );

    // Firebase에 데이터 추가
    await FirestoreService().addExpenseItem(newItem);

    // 데이터 초기화
    clearData();
  }
}
