import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_budget_book/services/money_input_formatter.dart';

class AddExpenseScreen extends StatefulWidget {
  final DateTime selectedDate; // 선택한 날짜를 저장할 변수

  const AddExpenseScreen({
    super.key,
    required this.selectedDate, // 날짜를 필수 인자로 받습니다.
  });
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  bool _isButtonVisible = false; // 버튼 가시성 상태

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onTextChanged); // 리스너 추가

    // 화면이 처음 빌드된 후에 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocusNode.requestFocus(); // 숫자 입력 필드에 자동 포커스
    });
  }

  void _onTextChanged() {
    if (_amountController.text.isEmpty && _isButtonVisible) {
      setState(() => _isButtonVisible = false);
    } else if (_amountController.text.isNotEmpty && !_isButtonVisible) {
      setState(() => _isButtonVisible = true);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 날짜를 '년월일' 형식으로 포맷하기
    String formattedDate = DateFormat('yyyy년 M월 d일').format(widget.selectedDate);

    // 다크 테마 색상 정의
    Color backgroundColor = const Color(0xFF121212); // 배경 색상
    Color foregroundColor = Colors.white; // 텍스트 색상
    Color accentColor = const Color(0xFF1F1F1F); // 입력 필드 배경 색상

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('지출 입력', style: TextStyle(color: foregroundColor)),
        backgroundColor: backgroundColor, // 앱바 색상
        iconTheme: IconThemeData(color: foregroundColor), // 앱바 아이콘 색상
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              formattedDate, // 여기에 날짜를 표시합니다.
              style: const TextStyle(fontSize: 16.0, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            const Text(
              '얼마를 썼나요?',
              style: TextStyle(fontSize: 24.0, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _amountController,
                focusNode: _amountFocusNode,
                style: TextStyle(color: foregroundColor, fontSize: 24),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '숫자 입력',
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  MoneyInputFormatter(),
                ],
              ),
            ),
            // 더 많은 위젯들이 위치할 수 있습니다.
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Visibility(
            // Visibility 위젯 사용
            visible: _isButtonVisible, // 버튼의 가시성 제어
            child: ElevatedButton(
              onPressed: () {
                // '저장하기' 버튼을 눌렀을 때의 로직을 작성하세요.
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3182F7),
                minimumSize: const Size.fromHeight(55), // 버튼 높이 설정
                elevation: 0, // 버튼의 그림자 제거
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // 모서리를 둥글지 않게
                ),
              ),
              child: const Text('다음', style: TextStyle(fontSize: 18.0, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}
