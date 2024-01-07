import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:week_of_year/date_week_extensions.dart';

class ExpenseItem {
  final String? id; // 문서 ID 추가
  final num amount;
  final String category;
  final String icon;
  final DateTime datetime;
  final bool isHaveToAdd;
  final String userId;

  ExpenseItem({
    this.id,
    required this.amount,
    required this.category,
    required this.icon,
    required this.datetime,
    required this.userId, // 생성자에서 userId를 요구합니다.
    this.isHaveToAdd = false, // 기본값을 false로 설정
  });

  String get date => DateFormat('yyyy-MM-dd').format(datetime);
  int get year => datetime.year;
  int get month => datetime.month;
  int get weekOfYear => datetime.weekOfYear;

  // Firestore 데이터 형식으로 변환
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'icon': icon,
      'datetime': Timestamp.fromDate(datetime), // DateTime을 Timestamp로 변환
      'userId': userId,
      'isHaveToAdd': isHaveToAdd,
    };
  }

  // Firestore 데이터로부터 객체 생성 (수정됨)
  factory ExpenseItem.fromMap(Map<String, dynamic> map, String documentId) {
    return ExpenseItem(
      id: documentId, // 문서 ID 추가
      amount: map['amount'],
      category: map['category'],
      icon: map['icon'],
      datetime: (map['datetime'] as Timestamp).toDate(),
      userId: map['userId'],
      isHaveToAdd: map['isHaveToAdd'] ?? false,
    );
  }
}
