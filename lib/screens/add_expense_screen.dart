import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:earnedon/provider/expense_item_provider.dart';
import 'package:earnedon/services/money_input_formatter.dart';
import 'package:earnedon/screens/select_category_screen.dart';

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
  bool isDatePickerShown = false;
  DateTime selectedDate = DateTime.now();

  // if (selectedDate.isAfter(DateTime.now())) {
  //   // selectedDate가 현재 시간보다 크다면 (미래 날짜라면)
  //   date = DateTime.now();
  // }

  String _msg = '얼마를 썼나요?';

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onTextChanged); // 리스너 추가
    selectedDate = widget.selectedDate;

    if (selectedDate.isAfter(DateTime.now())) {
      setState(() {
        _msg = "얼마를 쓸 건가요?";
      });
    }

    // _amountFocusNode에 리스너 추가
    _amountFocusNode.addListener(() {
      if (_amountFocusNode.hasFocus) {
        // _amountFocusNode가 포커스를 받았을 때 isDatePickerShown을 false로 설정
        setState(() {
          isDatePickerShown = false;
        });
      }
    });

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

  void _goToCategorySelection() {
    String input = _amountController.text.replaceAll(',', ''); // 쉼표 제거
    num amount;

    // 먼저 int로 변환을 시도합니다.
    int? amountAsInt = int.tryParse(input);
    if (amountAsInt != null) {
      amount = amountAsInt;
    } else {
      // int 변환이 실패하면 double로 변환을 시도합니다.
      double? amountAsDouble = double.tryParse(input);
      if (amountAsDouble != null) {
        amount = amountAsDouble;
      } else {
        // 입력값이 유효한 숫자가 아닐 경우 처리
        // 예: 사용자에게 오류 메시지 표시
        return;
      }
    }

    Provider.of<ExpenseItemProvider>(context, listen: false).updateData(
      newAmount: amount,
      newSelectedDate: selectedDate, // 선택한 날짜
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategorySelectionScreen(selectedDate: selectedDate, amount: amount),
      ),
    );
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
    //String formattedDate = DateFormat('yyyy년 M월 d일').format(selectedDate);

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
      body: SafeArea(
        child: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () {
                    // 달력이 표시되어 있는 경우, 화면의 다른 곳을 탭하면 달력을 숨깁니다.
                    if (isDatePickerShown) {
                      setState(() {
                        isDatePickerShown = false;
                      });
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      GestureDetector(
                          onTap: () {
                            setState(() {
                              _amountFocusNode.unfocus();
                              isDatePickerShown = !isDatePickerShown; // 달력 표시 상태 토글
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('yyyy년 M월 d일').format(selectedDate),
                                style: TextStyle(fontSize: 18.0, color: foregroundColor),
                              ),
                              const SizedBox(width: 8), // 텍스트와 아이콘 사이의 간격
                              const Icon(
                                Icons.keyboard_arrow_down, // 아래쪽 방향 아이콘
                                color: Colors.white,
                              ),
                            ],
                          )),
                      if (isDatePickerShown)
                        CalendarDatePicker(
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2101),
                          onDateChanged: (newDate) {
                            setState(() {
                              selectedDate = newDate;
                              isDatePickerShown = false;
                            });
                          },
                        ),
                      const SizedBox(height: 10),
                      Text(
                        _msg,
                        style: TextStyle(fontSize: 26.0, color: foregroundColor),
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
                ))),
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
                _isButtonVisible ? _goToCategorySelection() : null;
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
