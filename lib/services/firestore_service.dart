import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:earnedon/models/expense_item.dart';
import 'package:earnedon/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserModel?> getUser(String userId) async {
    var snapshot = await _db.collection('users').doc(userId).get();

    if (snapshot.exists) {
      return UserModel.fromMap(snapshot.data()!, snapshot.id);
    } else {
      // 데이터가 없을 경우 처리. 예를 들어 빈 UserModel을 반환하거나, 오류를 던질 수 있음.
      return null;
      // 또는 빈 UserModel 반환: return UserModel(id: '', name: '', email: '', ...);
    }
  }

  Future<void> addUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<void> updateLastSignInTime(String userId) async {
    await _db.collection('users').doc(userId).update({
      'lastSignInAt': FieldValue.serverTimestamp(), // 서버 시간으로 설정
    });
  }

  Future<void> addExpenseItem(ExpenseItem expenseItem) async {
    await _db.collection('expenseItems').add(expenseItem.toMap());
  }

  Future<List<ExpenseItem>> getExpenseItems(String userId) async {
    var snapshot = await _db.collection('expenseItems').where('userId', isEqualTo: userId).get();

    return snapshot.docs.map((doc) => ExpenseItem.fromMap(doc.data(), doc.id)).toList();
  }
}
