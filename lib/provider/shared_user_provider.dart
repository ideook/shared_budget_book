import 'package:flutter/material.dart';
import 'package:shared_budget_book/models/user_data.dart';

class SharedUserProvider with ChangeNotifier {
  List<UserInfo> _sharedUsers = [];

  List<UserInfo> get sharedUsers => _sharedUsers;

  void addSharedUser(UserInfo user) {
    _sharedUsers.add(user);
    notifyListeners();
  }

  void removeUser(UserInfo user) {
    _sharedUsers.remove(user);
    notifyListeners();
  }
}
