import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
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

  void _deleteUser(UserData user) {
    // 사용자 삭제 로직
    Provider.of<SharedUserProvider>(context, listen: false).removeUser(user);
  }

  void _confirmDelete(UserData user) {
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
    Color backgroundColor = const Color(0xFF121212); // 배경 색상
    final sharedUsers = Provider.of<SharedUserProvider>(context).sharedUsers;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('공유'),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 20.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: sharedUsers.length,
                itemBuilder: (context, index) {
                  var user = sharedUsers[index];
                  String formattedDate = DateFormat('yyyy-MM-dd').format(user.datetime);
                  return Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage(user.iconPath),
                      ),
                      title: Text(user.name),
                      subtitle: Text(formattedDate),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _confirmDelete(user), // 삭제 확인 다이얼로그 호출
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 25, top: 20, left: 20, right: 20),
          child: Visibility(
            // Visibility 위젯 사용
            child: ElevatedButton(
              onPressed: () {
                Share.share('공유예산가계부 함께쓰기');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3182F7),
                minimumSize: const Size.fromHeight(55), // 버튼 높이 설정
                elevation: 0, // 버튼의 그림자 제거
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)), // 모서리를 둥글지 않게
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min, // Row의 크기를 자식 요소에 맞춤
                children: [
                  Text('공유 추가', style: TextStyle(fontSize: 20.0, color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 15), // 텍스트와 아이콘 사이의 공간
                  Icon(Icons.send, color: Colors.white), // SNS 공유 아이콘 추가
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
