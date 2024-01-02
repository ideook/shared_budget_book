import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('공유'),
      ),
      body: Center(
        child: Text('가계부 공유 화면'),
      ),
    );
  }
}
