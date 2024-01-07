import 'package:flutter/material.dart';
import 'package:earnedon/models/user_data.dart';

class SharedUserProvider with ChangeNotifier {
  final List<UserData> _sharedUsers = [];

  List<UserData> get sharedUsers => _sharedUsers;

  void addSharedUser(UserData user) {
    _sharedUsers.add(user);
    notifyListeners();
  }

  void removeUser(UserData user) {
    _sharedUsers.remove(user);
    notifyListeners();
  }
}
