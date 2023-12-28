import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'package:shared_budget_book/screens/add_expense_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

// 날짜
// 달력
// 주차
// 예산
// 지출
// 잔액

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '공유예산가계부',
      theme: ThemeData(
        // Define the default brightness and colors.
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey[900],

        // Define the default font family.
        //fontFamily: 'Georgia',

        // textTheme: const TextTheme(
        //   displayLarge: TextStyle(color: Colors.white, fontSize: 72.0, fontWeight: FontWeight.bold),
        //   displayMedium: TextStyle(color: Colors.white, fontSize: 72.0, fontWeight: FontWeight.bold),
        //   displaySmall: TextStyle(color: Colors.white, fontSize: 72.0, fontWeight: FontWeight.bold),
        //   titleLarge: TextStyle(color: Colors.white, fontSize: 36.0, fontWeight: FontWeight.bold),
        //   titleMedium: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.bold),
        //   // Define other styles as needed
        // ),
      ),
      home: const MyHomePage(title: '공유예산가계부'),
    );
  }
}

class ExpenseItem {
  final int amount;
  final String category;
  final IconData icon;
  final DateTime date;

  ExpenseItem({required this.amount, required this.category, this.icon = Icons.account_circle, required this.date});
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime selectedDate = DateTime.now();
  bool isDatePickerShown = false;
  PageController _pageController = PageController();
  int budget = 50000; // 예산 설정 (기본값)
  int expenses = 0; // 지출 합계
  int balance = 50000; // 잔액 (예산 - 지출)
  String locale = 'ko_KR'; // 로케일 설정 (한국 원화)

// 예시를 위한 지출 항목 목록
  List<ExpenseItem> expenseItems = [];

  @override
  void initState() {
    super.initState();
    expenseItems = generateSampleData();
    _calculateExpenses();
  }

  List<ExpenseItem> generateSampleData() {
    List<ExpenseItem> items = [];
    Random random = Random();

    for (int day = 0; day < 30; day++) {
      // 30일 동안의 데이터
      int itemCount = random.nextInt(6) + 5; // 5~10개의 항목

      for (int i = 0; i < itemCount; i++) {
        items.add(
          ExpenseItem(
            amount: random.nextInt(1000) + 100, // 100 ~ 1100 사이의 금액
            category: "카테고리 ${random.nextInt(10) + 1}",
            date: DateTime.now().subtract(Duration(days: day)),
          ),
        );
      }
    }

    return items;
  }

  void _calculateExpenses() {
    expenses = expenseItems.fold(0, (sum, item) => sum + item.amount);
    balance = budget - expenses;
  }

  void _changeDate(int index) {
    if (index >= 0 && index < expenseItems.length) {
      setState(() {
        selectedDate = expenseItems[index].date;
      });
    }
  }

  void _selectDate(DateTime date) {
    int pageIndex = expenseItems.indexWhere((item) => isSameDay(item.date, date));
    if (pageIndex != -1) {
      int currentPageIndex = _pageController.page?.round() ?? 0;

      if (currentPageIndex < pageIndex) {
        // 현재 페이지보다 선택된 날짜가 미래에 위치한 경우
        _pageController
            .animateToPage(
              currentPageIndex + 1, // 한 페이지씩만 이동
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            )
            .then((_) => _updateSelectedDate(date));
      } else if (currentPageIndex > pageIndex) {
        // 현재 페이지보다 선택된 날짜가 과거에 위치한 경우
        _pageController
            .animateToPage(
              currentPageIndex - 1, // 한 페이지씩만 이동
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            )
            .then((_) => _updateSelectedDate(date));
      }
    }
  }

  void _updateSelectedDate(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  Widget _infoBox() {
    final String formattedExpenses = '${NumberFormat("#,###").format(expenses)}원';
    final String formattedBalance = '${NumberFormat("#,###").format(balance)}원';
    final String formattedBudget = '${NumberFormat("#,###").format(budget)}원';

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 첫 번째 줄: 지출 및 잔액
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$formattedExpenses 지출하여',
                style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                '$formattedBalance 남음',
                style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15), // 첫 줄과 두 번째 줄 사이 간격 추가
          // 두 번째 줄: 예산
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '예산 $formattedBudget',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    // 다크 테마 색상 정의
    Color backgroundColor = const Color(0xFF121212); // 배경 색상
    Color foregroundColor = Colors.white; // 텍스트 색상
    Color accentColor = const Color(0xFF1F1F1F); // 입력 필드 배경 색상
    // 주차 계산
    int weekNumber = _getWeekNumber(selectedDate, false); // true: Monday is the start of the week
    // 지출 합계 계산 (여기서는 예시 데이터를 사용)
    expenses = List.generate(10, (index) => index * 100).reduce((a, b) => a + b);
    // 잔액 계산
    balance = budget - expenses;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 예산, 지출, 잔액을 보여주는 박스
            _infoBox(),
            ListTile(
              title: Row(
                mainAxisSize: MainAxisSize.min, // Use minimum space required by children
                children: [
                  Text('${DateFormat('yyyy년 M월 d일').format(selectedDate)} ($weekNumber주차)'),
                  const Icon(Icons.arrow_drop_down), // Icon right next to the text
                ],
              ),
              onTap: () {
                // 달력 표시 상태를 토글합니다.
                setState(() {
                  isDatePickerShown = !isDatePickerShown;
                });
              },
            ),
            // CalendarDatePicker를 표시하거나 숨깁니다.
            if (isDatePickerShown)
              CalendarDatePicker(
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                onDateChanged: (newDate) {
                  setState(() {
                    selectedDate = newDate;
                    isDatePickerShown = false;
                    _selectDate(newDate);
                  });
                },
              ),
            // Expense Items List
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _changeDate,
                itemBuilder: (context, index) {
                  // 각 페이지에 해당 날짜의 모든 지출 항목을 표시합니다.
                  return _expenseItem(expenseItems[index].date);
                },
                itemCount: expenseItems.length,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        //onPressed: _incrementCounter,
        backgroundColor: const Color(0xFF3182F7),
        onPressed: () {
          // Navigate to the AddExpenseScreen when the button is pressed
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(selectedDate: selectedDate), // 여기에 선택된 날짜를 전달합니다.
            ),
          );
        },
        tooltip: 'Increment',
        child: const Icon(
          Icons.add,
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _expenseItem(DateTime date) {
    // 해당 날짜에 해당하는 모든 지출 항목을 필터링합니다.
    List<ExpenseItem> dailyItems = expenseItems.where((item) => isSameDay(item.date, date)).toList();

    return ListView.builder(
      itemCount: dailyItems.length,
      itemBuilder: (context, index) {
        ExpenseItem item = dailyItems[index];
        return ListTile(
          leading: Icon(item.icon),
          title: Text(item.category),
          subtitle: Text('${NumberFormat("#,###").format(item.amount)}원'),
        );
      },
    );
  }

  Widget _datePickerKey(DateTime date) {
    return KeyedSubtree(
      key: ValueKey<DateTime>(date),
      child: ListTile(
        title: Text(DateFormat('yyyy년 M월 d일').format(date)),
        onTap: () {
          setState(() {
            isDatePickerShown = !isDatePickerShown;
          });
        },
      ),
    );
  }

  int _getWeekNumber(DateTime date, bool startIsMonday) {
    if (startIsMonday) {
      int daysToAdd = DateTime.thursday - date.weekday;
      DateTime thursdayDate = daysToAdd > 0 ? date.add(Duration(days: daysToAdd)) : date.subtract(Duration(days: daysToAdd.abs()));
      int dayOfYearThursday = dayOfYear(thursdayDate);
      return 1 + ((dayOfYearThursday - 1) / 7).floor();
    } else {
      // 일요일을 주의 시작으로 설정합니다.
      // 일요일이면 '0', 그 외에는 'weekday - 1'을 사용합니다.
      int correctedWeekday = (date.weekday % 7);

      // 연중 일수에서 수정된 요일 값을 뺀 후, 7로 나누고 1을 더합니다.
      int dayOfYear = int.parse(DateFormat("D").format(date));
      int weekNumber = ((dayOfYear - correctedWeekday) / 7).ceil();
      return weekNumber;
    }
  }

  int dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays;
  }
}
