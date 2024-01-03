import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_budget_book/models/user_data.dart';
import 'package:shared_budget_book/provider/shared_user_provider.dart';

class ShareScreen extends StatefulWidget {
  const ShareScreen({
    super.key,
  });

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _deleteUser(UserInfo user) {
    // 사용자 삭제 로직
    Provider.of<SharedUserProvider>(context, listen: false).removeUser(user);
  }

  void _confirmDelete(UserInfo user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('공유 해제'),
          content: Text('공유를 해제하겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
            ),
            TextButton(
              child: Text('해제'),
              onPressed: () {
                _deleteUser(user); // 사용자 삭제 처리
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sharedUsers = Provider.of<SharedUserProvider>(context).sharedUsers;

    return Scaffold(
      appBar: AppBar(
        title: Text('공유'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: sharedUsers.length,
              itemBuilder: (context, index) {
                var user = sharedUsers[index];
                String formattedDate = DateFormat('yyyy-MM-dd').format(user.datetime);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(user.iconPath),
                  ),
                  title: Text(user.name),
                  subtitle: Text(formattedDate),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _confirmDelete(user), // 삭제 확인 다이얼로그 호출
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // 공유 추가 버튼 로직
              },
              child: Text('공유 추가'),
            ),
          ),
        ],
      ),
    );
  }
}
