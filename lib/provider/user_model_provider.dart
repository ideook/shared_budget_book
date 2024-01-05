import 'package:flutter/material.dart';
import 'package:shared_budget_book/models/user_data.dart';
import 'package:shared_budget_book/models/user_model.dart';

class UserModelProvider with ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
