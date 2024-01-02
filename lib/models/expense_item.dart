import 'package:intl/intl.dart';

class ExpenseItem {
  final num amount;
  final String category;
  final String icon;
  final DateTime datetime;
  final bool isHaveToAdd;
  final String userId; // 사용자 ID 추가

  ExpenseItem({
    required this.amount,
    required this.category,
    required this.icon,
    required this.datetime,
    required this.userId, // 생성자에서 userId를 요구합니다.
    this.isHaveToAdd = false, // 기본값을 false로 설정
  });

  String get date => DateFormat('yyyy-MM-dd').format(datetime);
}
