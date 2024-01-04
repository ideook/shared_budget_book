import 'package:flutter/material.dart';

class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("추가 정보 동의")),
      body: Column(
        children: <Widget>[
          // 개인정보 처리방침, 이용약관 등에 대한 동의 체크박스 구현
          // ...
          ElevatedButton(
            onPressed: () {
              // 사용자가 모든 동의를 완료했을 때 이메일 인증 화면으로 이동
              // Navigator.push(...) 또는 적절한 방식으로 화면 이동
            },
            child: Text("동의하고 계속하기"),
          ),
        ],
      ),
    );
  }
}
