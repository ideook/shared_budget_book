class ExpenseModel {
  String id;
  double amount;
  String categoryId;
  DateTime date;
  String userId;
  String description;

  ExpenseModel(
      {required this.id, required this.amount, required this.categoryId, required this.date, required this.userId, required this.description});

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseModel(
      id: id,
      amount: map['amount'] ?? 0.0,
      categoryId: map['categoryId'] ?? '',
      date: map['date'].toDate(), // Firestore의 Timestamp를 DateTime으로 변환
      userId: map['userId'] ?? '',
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'categoryId': categoryId,
      'date': date,
      'userId': userId,
      'description': description,
    };
  }
}
