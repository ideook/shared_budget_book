import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Color backgroundColor = const Color(0xFF121212); // 배경 색상

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('알림'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('새 알림 1'),
            subtitle: Text('이것은 샘플 알림입니다.'),
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('새 알림 2'),
            subtitle: Text('다른 샘플 알림입니다.'),
          ),
          // 여기에 더 많은 알림 항목을 추가할 수 있습니다.
        ],
      ),
    );
  }
}
