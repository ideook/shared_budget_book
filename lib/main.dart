import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_budget_book/models/expense_data.dart';
import 'package:sticky_grouped_list/sticky_grouped_list.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:week_of_year/date_week_extensions.dart';
import 'firebase_options.dart';
import 'package:shared_budget_book/screens/add_expense_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ExpenseData()),
        ],
        child: MaterialApp(
          title: '공유예산가계부',
          theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.blueGrey[900],
          ),
          home: const MyHomePage(),
        ));
  }
}

class ExpenseItem {
  final double amount;
  final String category;
  final String icon;
  final DateTime datetime;
  final bool isHaveToAdd;

  ExpenseItem({
    required this.amount,
    required this.category,
    required this.icon,
    required this.datetime,
    this.isHaveToAdd = false, // 기본값을 false로 설정
  });

  String get date => DateFormat('yyyy-MM-dd').format(datetime);
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  final String title = "공유예산가계부";

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isWeeklyView = true; // 주간 또는 월간 보기 모드
  PageController? pageController;

  DateTime? currentVisibleSectionDate;
  //DateTime? topVisibleItemDate = DateTime.now();

  double _budget = 50000.0;
  double _expenses = 0.0;
  double _balance = 50000.0;

  DateTime selectedDate = DateTime.now();
  bool isDatePickerShown = false;
  ScrollController _scrollController = ScrollController();
  GroupedItemScrollController itemScrollController = GroupedItemScrollController();
  List<ExpenseItem> allExpenseItems = []; // 6개월치 전체 데이터
  List<ExpenseItem> expenseItems = [];
  bool _isLoading = false;
  int weekNumber = 1;
  final int _pageSize = 30;
  List<Map<String, dynamic>> dataList = [];

  // 스크롤 이벤트 리스너에 _onScrollNotification 함수 추가
  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: calculateInitialPageIndex());

    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => checkAndShowExpenseData());
    _loadInitialData();
    _filterDataByPeriod();
  }

  int calculateInitialPageIndex() {
    DateTime startDate = DateTime(1900, 1, 1);
    DateTime today = DateTime.now();
    if (isWeeklyView) {
      return today.difference(startDate).inDays ~/ 7;
    } else {
      return ((today.year - startDate.year) * 12) + today.month - startDate.month;
    }
  }

  void toggleViewMode() {
    setState(() {
      isWeeklyView = !isWeeklyView;

      // isWeeklyView 값이 변경되었을 때 필요한 로직 실행
      int newPageIndex = calculateInitialPageIndex();
      pageController!.jumpToPage(newPageIndex); // 페이지 컨트롤러를 새 인덱스로 이동

      _filterDataByPeriod(); // 날짜 범위에 따라 데이터 필터링
      // 필요한 경우 여기에 추가적인 데이터 갱신 로직 추가
    });
  }

  void _loadInitialData() {
    allExpenseItems = generateSixMonthsData(); // 6개월치 데이터 생성
    _loadMoreData(); // 초기 2주치 데이터 로드
  }

  List<ExpenseItem> filterExpensesByDateInfo(List<ExpenseItem> expenses, DateInfo dateInfo) {
    var list = expenses.where((expense) {
      // ExpenseItem의 날짜를 구합니다.
      DateTime expenseDate = expense.datetime;

      // DateInfo 객체에 따라 시작일과 종료일을 결정합니다.
      DateTime startDate;
      DateTime endDate;

      if (dateInfo.isWeeklyView) {
        // 주간 뷰일 경우
        startDate = DateTime(dateInfo.year, dateInfo.month, dateInfo.startDay);
        endDate = DateTime(dateInfo.year, dateInfo.month, dateInfo.endDay);
      } else {
        // 월간 뷰일 경우
        startDate = DateTime(dateInfo.year, dateInfo.month, 1);
        endDate = DateTime(dateInfo.year, dateInfo.month + 1, 0);
      }

      return expenseDate.isAfter(startDate) && expenseDate.isBefore(endDate);
    }).toList();

    _expenses = list.fold(0.0, (total, item) => total + item.amount);
    _balance = _budget - _expenses;

    return list;
  }

  void _filterDataByPeriod() {
    DateTime lastDate = allExpenseItems.last.datetime;
    DateTime startDate, endDate;

    if (isWeeklyView) {
      // 주간 보기: 해당 주의 시작과 끝 날짜 계산
      int weekday = lastDate.weekday;
      startDate = lastDate.subtract(Duration(days: weekday - 1)); // 주의 첫째 날
      endDate = startDate.add(Duration(days: 6)); // 주의 마지막 날
    } else {
      // 월간 보기: 해당 월의 시작과 끝 날짜 계산
      startDate = DateTime(lastDate.year, lastDate.month, 1); // 월의 첫째 날
      endDate = DateTime(lastDate.year, lastDate.month + 1, 0); // 월의 마지막 날
    }

    // allExpenseItems에서 startDate와 endDate 사이의 데이터 필터링
    List<ExpenseItem> filteredItems = allExpenseItems.where((item) {
      return item.datetime.isAfter(startDate) && item.datetime.isBefore(endDate);
    }).toList();

    // 필터링된 데이터로 화면 업데이트
    setState(() {
      expenseItems = filteredItems;
    });
  }

  List<ExpenseItem> generateSixMonthsData() {
    List<ExpenseItem> items = [];
    Random random = Random();
    List<String> categories = ["Food", "Transport", "Entertainment", "Education", "Health", "Shopping"];
    List<String> userIcons = ['assets/images/user1.jpg', 'assets/images/user2.png', 'assets/images/user3.png']; // 이미지 경로
    DateTime startDate = DateTime.now().subtract(Duration(days: 180));

    for (int day = 0; day < 180; day++) {
      int itemCount = random.nextInt(6) + 0;
      DateTime date = startDate.add(Duration(days: day));

      for (int i = 0; i < itemCount; i++) {
        String category = categories[random.nextInt(categories.length)];
        String icon = userIcons[random.nextInt(userIcons.length)];
        double rawAmount = random.nextInt(50000) + 5000;
        double amount = ((rawAmount / 100).round()) * 100;

        items.add(
          ExpenseItem(
            amount: amount,
            category: category,
            icon: icon,
            datetime: date,
          ),
        );
      }
    }

    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  void _scrollToDate(DateTime selectedDate) {
    // final String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    // int groupStartIndex = allExpenseItems.indexWhere((item) => item.date == formattedDate);

    // if (groupStartIndex == -1) {
    //   // 가상 데이터 생성
    //   ExpenseItem virtualItem =
    //       ExpenseItem(amount: 0, category: '지출이 없습니다. 추가하려면 탭하세요.', icon: 'assets/images/user3.png', datetime: selectedDate, isHaveToAdd: true);

    //   // 가상 데이터를 리스트에 추가하고 정렬
    //   setState(() {
    //     allExpenseItems.add(virtualItem);
    //     allExpenseItems.sort((a, b) => a.datetime.compareTo(b.datetime));
    //   });

    //   // // 프레임 렌더링이 완료된 후 스크롤 조정
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     itemScrollController.jumpToElement(identifier: formattedDate);
    //   });
    // } else {
    //   // 이미 데이터가 존재하는 경우, 바로 스크롤
    //   itemScrollController.jumpToElement(identifier: formattedDate);
    // }
  }

  void checkAndShowExpenseData() {
    final expenseData = Provider.of<ExpenseData>(context, listen: false);

    // ExpenseData에 유효한 데이터가 있는 경우에만 SnackBar를 표시
    if (expenseData.amount != 0 || expenseData.category != null) {
      final snackBar = SnackBar(
        content: Text('날짜: ${expenseData.selectedDate}, 금액: ${expenseData.amount}, 카테고리: ${expenseData.category ?? "없음"}'),
        duration: Duration(seconds: 3),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      // SnackBar 표시 후 ExpenseData 초기화
      expenseData.clearData();
    }
  }

  void _loadMoreData({bool isLoadMoreRecent = true}) {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(Duration(seconds: 0), () {
      List<ExpenseItem> newItems;
      DateTime? targetDate; // 새로 로드된 데이터 중 가장 늦은 날짜

      if (isLoadMoreRecent) {
        // 더 최신 데이터 로드
        DateTime latestDate = expenseItems.isNotEmpty ? expenseItems.last.datetime : DateTime.now();
        newItems = generateDataFrom(latestDate.add(Duration(days: 1)), 14);
        expenseItems.addAll(newItems);
      } else {
        // 과거 데이터 로드
        DateTime earliestDate = expenseItems.isNotEmpty ? expenseItems.first.datetime : DateTime.now();
        newItems = generateDataFrom(earliestDate.subtract(Duration(days: 14)), 14);
        expenseItems.insertAll(0, newItems); // 과거 데이터는 리스트의 시작 부분에 추가

        // 가장 늦은 날짜 찾기
        targetDate = newItems.last.datetime;
      }

      setState(() {
        _isLoading = false;
        // 과거 데이터 로드 후 해당 날짜로 스크롤
      });
    });
  }

  List<ExpenseItem> generateDataFrom(DateTime startDate, int days) {
    List<ExpenseItem> items = [];
    Random random = Random();
    List<String> categories = ["Food", "Transport", "Entertainment", "Education", "Health", "Shopping"];
    List<String> userIcons = ['assets/images/user1.jpg', 'assets/images/user2.png', 'assets/images/user3.png'];

    for (int day = 0; day < days; day++) {
      int itemCount = random.nextInt(6) + 0;
      DateTime date = startDate.add(Duration(days: day));

      for (int i = 0; i < itemCount; i++) {
        String category = categories[random.nextInt(categories.length)];
        String icon = userIcons[random.nextInt(userIcons.length)];
        double amount = ((random.nextInt(50000) + 5000) / 100).round() * 100;

        items.add(
          ExpenseItem(
            amount: amount,
            category: category,
            icon: icon,
            datetime: date,
          ),
        );
      }
    }
    items.sort((a, b) => a.date.compareTo(b.date));

    return items;
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _onScroll() {}

  void toggleDatePicker() {
    setState(() {
      isDatePickerShown = !isDatePickerShown;
    });
  }

  Widget _expenseItem(ExpenseItem item) {
    if (item.isHaveToAdd) {
      // 가상 데이터에 대한 스타일
      return Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 20),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddExpenseScreen(selectedDate: item.datetime),
              ),
            );
          },
          child: const Text(
            '지출이 없습니다. 지출을 추가하려면 탭하세요.',
            style: TextStyle(
              fontSize: 16.0,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 비용과 카테고리 (왼쪽 정렬)
            Row(
              children: [
                Text(
                  '${NumberFormat("#,###").format(item.amount)}원',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            // 이미지 아이콘 (오른쪽 정렬)
            ClipOval(
              child: Image.asset(
                item.icon,
                width: 32,
                height: 32,
                fit: BoxFit.cover, // 이미지가 할당된 공간에 맞도록 조정
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 다크 테마 색상 정의
    Color backgroundColor = const Color(0xFF121212); // 배경 색상
    Color foregroundColor = Colors.white; // 텍스트 색상
    Color accentColor = const Color(0xFF1F1F1F); // 입력 필드 배경 색상
    // 주차 계산

    weekNumber = weekOfMonthForStandard(selectedDate);
    //weekNumber = _getWeekNumber(selectedDate, true); // true: Monday is the start of the week

    // 지출 합계 계산 (여기서는 예시 데이터를 사용)
    //expenses = List.generate(10, (index) => index * 100.0).reduce((a, b) => a + b);
    // 잔액 계산
    //balance = budget - expenses;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(isWeeklyView ? Icons.calendar_view_month : Icons.calendar_view_week),
            onPressed: toggleViewMode,
            tooltip: '주간/월간 보기 전환',
          ),
        ],
      ),
      body: Column(children: <Widget>[
        _infoBox(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '지출목록',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
            child: PageView.builder(
          controller: pageController,
          onPageChanged: (index) {
            updateSelectedDate(index);
          },
          itemBuilder: (context, index) {
            DateInfo dateInfo = calculateDateInfoBasedOnIndex(index);
            var filteredItems = filterExpensesByDateInfo(allExpenseItems, dateInfo);

            return ExpensePage(expenseItems: filteredItems, onToggleDatePicker: toggleDatePicker, isDatePickerShown: isDatePickerShown);
          },
        )),
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3182F7),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(selectedDate: selectedDate),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  List<DateTime> generateDateList(DateTime startDate, DateTime endDate) {
    List<DateTime> dateList = [];

    for (DateTime date = startDate; date.isBefore(endDate) || date.isAtSameMomentAs(endDate); date = date.add(Duration(days: 1))) {
      dateList.add(date);
    }

    return dateList;
  }

  void updateSelectedDate(int index) {
    DateInfo dateInfo = calculateDateInfoBasedOnIndex(index);
    setState(() {
      selectedDate = DateTime(dateInfo.year, dateInfo.month, dateInfo.baseDay);
    });
  }

  DateInfo calculateDateInfoBasedOnIndex(int index) {
    DateTime baseDate = DateTime(1900, 1, 1);
    //DateTime monDay = baseDate.subtract(Duration(days: baseDate.weekday - 1));
    DateTime thursDay = baseDate.subtract(Duration(days: baseDate.weekday - 4));
    //DateTime SunDay = baseDate.subtract(Duration(days: baseDate.weekday - 7));
    DateTime calculatedDate;

    if (isWeeklyView) {
      calculatedDate = thursDay.add(Duration(days: index * 7));
    } else {
      calculatedDate = DateTime(thursDay.year, thursDay.month + index, 1);
    }

    int week = isWeeklyView ? weekOfMonthForStandard(calculatedDate) : 1;
    return DateInfo(calculatedDate, week, isWeeklyView);
  }

  // 월 주차. (단순하게 1일이 1주차 시작).
  int weekOfMonthForSimple(DateTime date) {
    // 월의 첫번째 날짜.
    DateTime _firstDay = DateTime(date.year, date.month, 1);

    // 월중에 첫번째 월요일인 날짜.
    DateTime _firstMonday = _firstDay.add(Duration(days: (DateTime.monday + 7 - _firstDay.weekday) % 7));

    // 첫번째 날짜와 첫번째 월요일인 날짜가 동일한지 판단.
    // 동일할 경우: 1, 동일하지 않은 경우: 2 를 마지막에 더한다.
    final bool isFirstDayMonday = _firstDay == _firstMonday;

    final _different = calculateDaysBetween(from: _firstMonday, to: date);

    // 주차 계산.
    int _weekOfMonth = (_different / 7 + (isFirstDayMonday ? 1 : 2)).toInt();
    return _weekOfMonth;
  }

  // D-Day 계산.
  int calculateDaysBetween({required DateTime from, required DateTime to}) {
    return (to.difference(from).inHours / 24).round();
  }

  // 동일한 주차인지 확인.
  bool isSameWeek(DateTime dateTime1, DateTime dateTime2) {
    final int _dateTime1WeekOfMonth = weekOfMonthForSimple(dateTime1);
    final int _dateTime2WeekOfMonth = weekOfMonthForSimple(dateTime2);
    return _dateTime1WeekOfMonth == _dateTime2WeekOfMonth;
  }

  // 월 주차. (정식 규정에 따라서 계산)
  int weekOfMonthForStandard(DateTime date) {
    // 월 주차.
    late int _weekOfMonth;

    // 선택한 월의 첫번째 날짜.
    final _firstDay = DateTime(date.year, date.month, 1);

    // 선택한 월의 마지막 날짜.
    final _lastDay = DateTime(date.year, date.month + 1, 0);

    // 첫번째 날짜가 목요일보다 작은지 판단.
    final _isFirstDayBeforeThursday = _firstDay.weekday <= DateTime.thursday;

    // 선택한 날짜와 첫번째 날짜가 같은 주에 위치하는지 판단.
    if (isSameWeek(date, _firstDay)) {
      // 첫번째 날짜가 목요일보다 작은지 판단.
      if (_isFirstDayBeforeThursday) {
        // 1주차.
        _weekOfMonth = 1;
      }

      // 저번달의 마지막 날짜의 주차와 동일.
      else {
        final _lastDayOfPreviousMonth = DateTime(date.year, date.month, 0);

        // n주차.
        _weekOfMonth = weekOfMonthForStandard(_lastDayOfPreviousMonth);
      }
    } else {
      // 선택한 날짜와 마지막 날짜가 같은 주에 위치하는지 판단.
      if (isSameWeek(date, _lastDay)) {
        // 마지막 날짜가 목요일보다 큰지 판단.
        final _isLastDayBeforeThursday = _lastDay.weekday >= DateTime.thursday;
        if (_isLastDayBeforeThursday) {
          // 주차를 단순 계산 후 첫번째 날짜의 위치에 따라서 0/-1 결합.
          // n주차.
          _weekOfMonth = weekOfMonthForSimple(date) + (_isFirstDayBeforeThursday ? 0 : -1);
        }

        // 다음달 첫번째 날짜의 주차와 동일.
        else {
          // 1주차.
          _weekOfMonth = 1;
        }
      }

      // 첫번째주와 마지막주가 아닌 날짜들.
      else {
        // 주차를 단순 계산 후 첫번째 날짜의 위치에 따라서 0/-1 결합.
        // n주차.
        _weekOfMonth = weekOfMonthForSimple(date) + (_isFirstDayBeforeThursday ? 0 : -1);
      }
    }

    return _weekOfMonth;
  }

  Widget _infoBox() {
    final String formattedExpenses = '${NumberFormat("#,###").format(_expenses)}원';
    final String formattedBalance = '${NumberFormat("#,###").format(_balance)}원';
    final String formattedBudget = '${NumberFormat("#,###").format(_budget)}원';
    String formattedYear = DateFormat('yyyy').format(selectedDate);
    String formattedMonth = DateFormat('M').format(selectedDate);

    if (selectedDate != null) {
      setState(() {
        weekNumber = weekOfMonthForStandard(selectedDate);
      });
    }

    // 주간 또는 월간 레이블 표시
    String dateLabel = isWeeklyView ? '$formattedYear년 $formattedMonth월  $weekNumber주차' : '$formattedYear년 $formattedMonth월';

    return Container(
      //margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      child: Column(
        children: <Widget>[
          GestureDetector(
              onTap: () {
                setState(() {
                  isDatePickerShown = !isDatePickerShown; // 달력 표시 상태 토글
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    dateLabel,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 8), // 텍스트와 아이콘 사이의 간격
                  const Icon(
                    Icons.keyboard_arrow_down, // 아래쪽 방향 아이콘
                    color: Colors.white,
                  ),
                ],
              )),
          if (isDatePickerShown)
            AnimatedOpacity(
                opacity: isDatePickerShown ? 1.0 : 0.0, // 달력이 표시되면 불투명도 1, 아니면 0
                duration: const Duration(milliseconds: 500), // 애니메이션 지속 시간
                child: CalendarDatePicker(
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2101),
                  onDateChanged: (newDate) {
                    setState(() {
                      selectedDate = newDate;
                      isDatePickerShown = false;
                      _scrollToDate(newDate); // 날짜 선택 시 호출
                    });
                  },
                )),
          // 달력 뜨는 부분
          const SizedBox(height: 10),
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
          const SizedBox(height: 10),
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

  List<ExpenseItem> _getVisibleItems() {
    // 주간 또는 월간 데이터를 반환하는 로직 구현

    return expenseItems;
  }

  void _navigateToPreviousPeriod() {
    // 이전 주 또는 월로 이동하는 로직 구현
    if (isWeeklyView) {
      // 주간 보기: 현재 선택된 날짜에서 일주일을 뺀다
      setState(() {
        selectedDate = selectedDate!.subtract(Duration(days: 7));
      });
    } else {
      // 월간 보기: 현재 선택된 날짜의 월을 하나 줄인다
      setState(() {
        selectedDate = DateTime(selectedDate!.year, selectedDate!.month - 1, selectedDate!.day);
      });
    }
  }

  void _navigateToNextPeriod() {
    // 다음 주 또는 월로 이동하는 로직 구현
    if (isWeeklyView) {
      // 주간 보기: 현재 선택된 날짜에 일주일을 더한다
      setState(() {
        selectedDate = selectedDate!.add(Duration(days: 7));
      });
    } else {
      // 월간 보기: 현재 선택된 날짜의 월을 하나 늘린다
      setState(() {
        selectedDate = DateTime(selectedDate!.year, selectedDate!.month + 1, selectedDate!.day);
      });
    }
  }

  int _getWeekNumber(DateTime? date, bool startIsMonday) {
    if (startIsMonday) {
      int daysToAdd = DateTime.thursday - date!.weekday;
      DateTime thursdayDate = daysToAdd > 0 ? date.add(Duration(days: daysToAdd)) : date.subtract(Duration(days: daysToAdd.abs()));
      int dayOfYearThursday = dayOfYear(thursdayDate);
      return 1 + ((dayOfYearThursday - 1) / 7).floor();
    } else {
      // 일요일을 주의 시작으로 설정합니다.
      // 일요일이면 '0', 그 외에는 'weekday - 1'을 사용합니다.
      int correctedWeekday = (date!.weekday % 7);

      // 연중 일수에서 수정된 요일 값을 뺀 후, 7로 나누고 1을 더합니다.
      int dayOfYear = int.parse(DateFormat("D").format(date));
      int weekNumber = ((dayOfYear - correctedWeekday) / 7).ceil();
      return weekNumber;
    }
  }

  int dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays;
  }

  int _getWeekOfMonth(DateTime date) {
    // 월의 첫째 날 설정
    DateTime firstDayOfMonth = DateTime(date.year, date.month, 1);

    // 주의 시작 요일 설정 (0: 일요일, 1: 월요일)
    int startDayOfWeek = DateTime.sunday;

    // 첫째 날의 요일 찾기
    int firstWeekdayOfMonth = firstDayOfMonth.weekday;

    // 첫째 주에 속한 일 수 계산
    int daysInFirstWeek = 8 - firstWeekdayOfMonth;

    // 해당 날짜가 첫째 주에 있는지 확인
    if (date.day <= daysInFirstWeek) {
      return 1;
    }

    // 남은 일수 계산 및 주 계산
    int remainingDays = date.day - daysInFirstWeek;
    return 1 + ((remainingDays + startDayOfWeek - 1) / 7).ceil();
  }
}

class DateInfo {
  DateTime date;
  int week;
  bool isWeeklyView;

  DateInfo(this.date, this.week, this.isWeeklyView);

  int get year => date.year;
  int get month => date.month;

  int get startDay {
    DateTime monDay = date.subtract(Duration(days: date.weekday - 1));
    return isWeeklyView ? monDay.day : 1;
  }

  int get baseDay {
    DateTime thursDay = date.subtract(Duration(days: date.weekday - 4));
    return isWeeklyView ? thursDay.day : 1;
  }

  int get endDay {
    DateTime sunDay = date.subtract(Duration(days: date.weekday - 7));
    return isWeeklyView ? sunDay.day : DateTime(date.year, date.month + 1, 0).day;
  }

  @override
  String toString() {
    if (isWeeklyView) {
      return "$year년 $month월 $week주 (${date.weekOfYear}주차) ($startDay일 - $endDay일)";
    } else {
      return "$year년 $month월 ($startDay일 - $endDay일)";
    }
  }
}

class ExpensePage extends StatefulWidget {
  final List<ExpenseItem> expenseItems;
  final VoidCallback onToggleDatePicker;
  final bool isDatePickerShown;

  const ExpensePage({super.key, required this.expenseItems, required this.onToggleDatePicker, required this.isDatePickerShown});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  GroupedItemScrollController itemScrollController = GroupedItemScrollController();

  List<ExpenseItem> expenseItems = [];

  // 스크롤 이벤트 리스너에 _onScrollNotification 함수 추가
  @override
  void initState() {
    super.initState();
    expenseItems = widget.expenseItems;
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = const Color(0xFF121212); // 배경 색상
    Color foregroundColor = Colors.white; // 텍스트 색상
    Color accentColor = const Color(0xFF1F1F1F); // 입력 필드 배경 색상
    // expenseItems 리스트가 비어있는 경우 처리
    if (expenseItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          '지출이 없습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18.0,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          // 달력이 활성화되었고, 사용자가 위로 스와이프할 때
          //print(notification.metrics.extentBefore);
          if (widget.isDatePickerShown && notification.metrics.extentBefore > 0) {
            widget.onToggleDatePicker(); // 달력을 닫습니다.
          }
          return true;
        },
        child: StickyGroupedListView<ExpenseItem, String>(
          elements: expenseItems,
          groupBy: (item) => item.date,
          groupComparator: (String value1, String value2) => value2.compareTo(value1),
          itemComparator: (item1, item2) => item1.date.compareTo(item2.date),
          floatingHeader: false,
          stickyHeaderBackgroundColor: backgroundColor,
          order: StickyGroupedListOrder.DESC,
          elementIdentifier: (element) => element.date,
          itemScrollController: itemScrollController,
          groupSeparatorBuilder: (ExpenseItem item) => Container(
            color: backgroundColor,
            margin: const EdgeInsets.only(top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              item.date,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
          itemBuilder: (context, item) => _expenseItem(context, item),
        ));
  }

  Widget _expenseItem(BuildContext context, ExpenseItem item) {
    if (item.isHaveToAdd) {
      // 가상 데이터에 대한 스타일
      return Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 20),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddExpenseScreen(selectedDate: item.datetime),
              ),
            );
          },
          child: const Text(
            '지출이 없습니다. 지출을 추가하려면 탭하세요.',
            style: TextStyle(
              fontSize: 16.0,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 비용과 카테고리 (왼쪽 정렬)
            Row(
              children: [
                Text(
                  '${NumberFormat("#,###").format(item.amount)}원',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            // 이미지 아이콘 (오른쪽 정렬)
            ClipOval(
              child: Image.asset(
                item.icon,
                width: 32,
                height: 32,
                fit: BoxFit.cover, // 이미지가 할당된 공간에 맞도록 조정
              ),
            ),
          ],
        ),
      );
    }
  }
}
