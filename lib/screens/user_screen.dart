import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_budget_book/models/user_model.dart';
import 'package:shared_budget_book/provider/user_model_provider.dart';
import 'package:shared_budget_book/screens/login_screen.dart';
import 'package:shared_budget_book/screens/settings_screen.dart';
import 'package:shared_budget_book/services/auth_service.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({
    super.key,
  });

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final AuthService authService = AuthService();

  Color backgroundColor = const Color(0xFF121212); // 배경 색상
  Color foregroundColor = Colors.white; // 텍스트 색상
  Color accentColor = const Color(0xFF1F1F1F); // 입력 필드 배경 색상

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userModelProvider = Provider.of<UserModelProvider>(context, listen: false); // UserModel 가져오기
    final UserModel? userModel = userModelProvider.user;

    Color backgroundColor = const Color(0xFF121212); // 배경 색상

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (userModel != null) ...[
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(userModel.profilePicture),
                      radius: 30,
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userModel.name,
                            style: TextStyle(fontSize: 24, color: foregroundColor),
                          ),
                          Text(
                            userModel.email,
                            style: TextStyle(fontSize: 16, color: foregroundColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              Divider(height: 40, color: foregroundColor),
              InkWell(
                onTap: () async {
                  authService.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text(
                  '로그아웃',
                  style: TextStyle(color: Colors.red, fontSize: 20.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
