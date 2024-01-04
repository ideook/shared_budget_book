import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_budget_book/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserModel> getUser(String userId) async {
    var snapshot = await _db.collection('users').doc(userId).get();

    if (snapshot.data() != null) {
      return UserModel.fromMap(snapshot.data()!, snapshot.id);
    } else {
      // 데이터가 없을 경우 처리. 예를 들어 빈 UserModel을 반환하거나, 오류를 던질 수 있음.
      throw Exception('User not found');
      // 또는 빈 UserModel 반환: return UserModel(id: '', name: '', email: '', ...);
    }
  }

  Future<void> addUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  // 다른 메서드 추가 (예: 지출 내역 추가, 카테고리 가져오기 등)
}
