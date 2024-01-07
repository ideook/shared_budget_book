import 'dart:math';

import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:earnedon/provider/user_model_provider.dart';
import 'package:earnedon/screens/analytics_screen%20.dart';
import 'package:earnedon/screens/login_screen.dart';
import 'package:earnedon/screens/not_found_screen.dart';
import 'package:earnedon/screens/notification_screen.dart';
import 'package:earnedon/screens/user_screen.dart';
import 'package:earnedon/services/firebase_analytics_manager.dart';
import 'package:earnedon/services/firestore_service.dart';
import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:earnedon/provider/expense_item_provider.dart';
import 'package:earnedon/models/expense_item.dart';
import 'package:earnedon/models/user_data.dart';
import 'package:earnedon/models/user_model.dart';
import 'package:earnedon/provider/shared_user_provider.dart';
import 'package:earnedon/provider/summary_date_provider.dart';
import 'package:earnedon/provider/view_mode_provider.dart';
import 'package:earnedon/services/money_input_formatter.dart';
import 'package:sticky_grouped_list/sticky_grouped_list.dart';
import 'package:week_of_year/date_week_extensions.dart';
import 'package:earnedon/screens/add_expense_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (FirebaseAuth.instance.currentUser != null) {
    try {
      // 현재 로그인한 사용자의 상태를 갱신
      await FirebaseAuth.instance.currentUser!.reload();
    } catch (e) {
      // 예외 처리
    }

    // PendingDynamicLinkData? _data = await FirebaseDynamicLinks.instance.getInitialLink();
    // if (_data != null) {
    //   //logger.e(_data.link.path);
    // }

    // String? initialLink;
    // try {
    //   initialLink = await getInitialLink();
    //   // 초기 링크 처리
    //   if (initialLink != null) {
    //     // 초기 링크에 기반하여 특정 화면으로 이동
    //   }
    // } catch (e) {
    //   // 오류 처리
    // }

    // StreamSubscription? _sub;
    // _sub = uriLinkStream.listen((Uri? uri) {
    //   if (uri != null) {
    //     // Deep Link 처리 로직
    //     // 예: uri.queryParameters를 사용하여 필요한 데이터 추출 및 처리
    //     // 여기서는 예시로 콘솔에 URI를 출력
    //     print('Got uri: $uri');
    //   }
    // }, onError: (err) {
    //   // 오류 처리
    // });
  }
  final PendingDynamicLinkData? initialLink = await FirebaseDynamicLinks.instance.getInitialLink();
  final Uri? deepLink = initialLink?.link;

  runApp(MyApp(deepLink: deepLink));
  //runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final Uri? deepLink;

  const MyApp({super.key, this.deepLink});

  @override
  Widget build(BuildContext context) {
    FirebaseAnalyticsManager analyticsManager = FirebaseAnalyticsManager();
    Widget homeScreen;

    if (FirebaseAuth.instance.currentUser != null) {
      // 사용자가 이미 로그인한 경우
      homeScreen = MyHomePage(analytics: analyticsManager.analytics, observer: analyticsManager.observer, deepLink: deepLink);
    } else {
      //사용자가 로그인하지 않은 경우
      homeScreen = LoginScreen(deepLink: deepLink); // 로그인 화면으로 이동
    }

    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => UserModelProvider()),
          ChangeNotifierProvider(create: (context) => ExpenseItemProvider()),
          ChangeNotifierProvider(create: (context) => ViewModeProvider()),
          ChangeNotifierProvider(create: (context) => SummaryDataProvider()),
          ChangeNotifierProvider(create: (context) => SharedUserProvider()),
        ],
        child: MaterialApp(
          title: 'Share Budget Book',
          theme: ThemeData(
            brightness: Brightness.dark,
            //primaryColor: Colors.blueGrey[900], // AppBar의 기본 색상 설정
            appBarTheme: const AppBarTheme(
              color: Color(0xFF121212), // 원하는 AppBar 색상으로 변경하세요.
            ),
          ),
          navigatorObservers: <NavigatorObserver>[analyticsManager.observer],
          home: homeScreen,
          onGenerateRoute: (settings) {
            if (settings.name == '/') {
              // 초기 경로 설정
              bool isUserLoggedIn = FirebaseAuth.instance.currentUser != null;
              if (isUserLoggedIn) {
                return MaterialPageRoute(
                  builder: (context) => MyHomePage(
                    analytics: analyticsManager.analytics,
                    observer: analyticsManager.observer,
                  ),
                );
              } else {
                return MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                );
              }
            }
            return MaterialPageRoute(builder: (context) => NotFoundScreen());
          },
        ));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.analytics, required this.observer, this.deepLink});

  final String title = 'Share Budget Book';
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;
  final Uri? deepLink;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  int _currentScreenIndex = 0; // 현재 화면 인덱스

  final String _userId = 'user1_UID_123456';
  final int _initialPageCount = 1000;
  List<ExpenseItem> _allExpenseItems = [];
  List<ExpenseItem> _currentPageExpenseItems = [];
  //DateTime _selectedDate = DateTime(1900, 1, 1);
  bool _isWeeklyView = false; // 주간 또는 월간 보기 모드
  bool isExpanded = false; // 펼치기/접기 상태 관리 변수

  PageController _pageController = PageController();

  DateTime? currentVisibleSectionDate;

  TextEditingController _budgetController = TextEditingController();
  final FocusNode _budgetFocusNode = FocusNode();

  bool isDatePickerShown = false;

  int weekNumber = 1;

  Map<String, UserData> userInfos = {};
  List<Map<String, dynamic>> dataList = [];
  Map<String, bool> categoryChecked = {};
  Map<String, bool> userChecked = {};

  // 스크롤 이벤트 리스너에 _onScrollNotification 함수 추가
  @override
  void initState() {
    super.initState();
    _initDynamicLinks();

    _updateUserModel().then((_) async {
      await Future.delayed(Duration(seconds: 1)); // 예시를 위한 지연
      if (mounted) {
        setState(() {
          _isLoading = false;
          _pageController = PageController(initialPage: _initialPageCount);
        });
      }
    });

    //_pageController = PageController(initialPage: _initialPageCount); // 1000 = 약19년/주 또는 약83.3년/월, 이번주/달

    // setState(() {
    //   userInfos = {
    //     'user1_UID_123456': UserData(uid: 'user1_UID_123456', iconPath: 'assets/images/user1.jpg', name: 'Alice', datetime: DateTime(2022, 1, 20)),
    //     'user2_UID_789012': UserData(uid: 'user2_UID_789012', iconPath: 'assets/images/user2.png', name: 'Bob', datetime: DateTime(2023, 10, 20)),
    //     'user3_UID_345678': UserData(uid: 'user3_UID_345678', iconPath: 'assets/images/user3.png', name: 'Charlie', datetime: DateTime(2024, 1, 1)),
    //   };
    // });

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   addUsersToProvider(Provider.of<SharedUserProvider>(context, listen: false));
    // });

    //_loadInitialData(); // 6개월치 데이터 생성

    //_updateDataForPage(_currentPageIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _budgetFocusNode.requestFocus(); // 숫자 입력 필드에 자동 포커스
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      var list = getExpensesByPageIndex(_allExpenseItems, _isWeeklyView, _initialPageCount);
      Provider.of<SummaryDataProvider>(context, listen: false).setExpenses(list, _isWeeklyView);

      setState(() {
        Set<String> uniqueCategories = list.map((item) => item.category).toSet();
        categoryChecked.clear();
        for (String category in uniqueCategories) {
          categoryChecked[category] = false;
        }

        Set<String> uniqueUsers = list.map((item) => item.userId).toSet();
        userChecked.clear();
        for (String userId in uniqueUsers) {
          userChecked[userId] = false;
        }
      });

      print("addPostFrameCallback");
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => checkAndShowExpenseData());

    // _pageController.addListener(() {
    //   //var pageIndex = _pageController.page?.round();
    //   //_currentPageExpenseItems = getExpensesByPageIndex(_allExpenseItems, _isWeeklyView, pageIndex!);

    //   print("addListener");
    // });

    // 999-> 저번주/달
    // 1001-> 다음주/달

    //_selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _pageController.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isWeeklyView = Provider.of<ViewModeProvider>(context).isWeeklyView;
  }

  void _initDynamicLinks() {
    if (widget.deepLink != null) {
      _handleDeepLink(widget.deepLink!);
    }

    FirebaseDynamicLinks.instance.onLink.listen(
      (PendingDynamicLinkData dynamicLinkData) {
        final Uri? deepLink = dynamicLinkData.link;
        if (deepLink != null) {
          _handleDeepLink(deepLink);
        }
      },
    ).onError((error) {
      // 오류 처리
    });
  }

  void _handleDeepLink(Uri deepLink) {
    // Deep Link를 처리하는 로직
    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserScreen()));
  }

  Future<void> _updateUserModel() async {
    if (FirebaseAuth.instance.currentUser != null) {
      UserModel? userModel = await _firestoreService.getUser(FirebaseAuth.instance.currentUser!.uid);
      if (userModel != null) {
        if (mounted) {
          _allExpenseItems = await _firestoreService.getExpenseItems(userModel.id);
          Provider.of<UserModelProvider>(context, listen: false).setUser(userModel);
          Provider.of<ExpenseItemProvider>(context, listen: false).updateUser(newUserId: userModel.id, newProfilePicture: userModel.profilePicture);
        }
      }
    }
  }

  // void _loadInitialData() async {
  //   var userModel = Provider.of<UserModelProvider>(context, listen: false).user;
  //   if (userModel != null) {
  //     _allExpenseItems = await _firestoreService.getExpenseItems(userModel.id);
  //   }

  //   //_allExpenseItems = generateSixMonthsData();
  // }

  void addUsersToProvider(SharedUserProvider provider) {
    for (var userInfo in userInfos.values) {
      provider.addSharedUser(userInfo);
    }
  }

  List<ExpenseItem> generateSixMonthsData() {
    List<ExpenseItem> items = [];
    Random random = Random();
    List<String> categories = ["Food", "Transport", "Entertainment", "Education", "Health", "Shopping"];

    List<String> uids = userInfos.keys.toList(); // UID 리스트
    DateTime startDate = DateTime.now(); //.subtract(Duration(days: 180));

    int pageIndex = _initialPageCount;
    for (int day = 0; day < 180; day++) {
      int itemCount = random.nextInt(6) + 0;
      DateTime date = startDate.subtract(Duration(days: day)); //.add(Duration(days: day));

      for (int i = 0; i < itemCount; i++) {
        String category = categories[random.nextInt(categories.length)];
        String uid = uids[random.nextInt(uids.length)]; // 무작위 UID 선택
        String icon = userInfos[uid]!.iconPath; // UID에 해당하는 아이콘
        double rawAmount = random.nextInt(50000) + 5000;
        double amount = ((rawAmount / 100).round()) * 100;

        items.add(
          ExpenseItem(
            amount: amount,
            category: category,
            icon: icon,
            datetime: date,
            userId: uid, // UID 추가
          ),
        );
      }
    }

    items.sort((a, b) => a.datetime.compareTo(b.datetime));
    return items;
  }

  // 1900.1.1부터 index 생성
  int calculateInitialPageIndex(bool isWeeklyView) {
    DateTime startDate = DateTime(1900, 1, 1);
    DateTime today = DateTime.now();
    if (isWeeklyView) {
      return today.difference(startDate).inDays ~/ 7;
    } else {
      return ((today.year - startDate.year) * 12) + today.month - startDate.month;
    }
  }

  int calculateWeekIndex(DateTime targetDate) {
    DateTime baseDate = DateTime.now(); // 기준 날짜 (2024년 1주차)

    int isoWeekOfYear(DateTime date) {
      int dayOfYear = int.parse(DateFormat('D').format(date));
      int weekOfYear = ((dayOfYear - date.weekday + 10) / 7).floor();
      return weekOfYear;
    }

    int lastWeekOfYear(int year) {
      DateTime lastDay = DateTime(year, 12, 31);
      return isoWeekOfYear(lastDay);
    }

    int weekDifference(DateTime startDate, DateTime endDate) {
      if (startDate.isAfter(endDate)) {
        var temp = startDate;
        startDate = endDate;
        endDate = temp;
      }

      int totalWeeks = 0;
      for (int year = startDate.year; year < endDate.year; year++) {
        totalWeeks += lastWeekOfYear(year);
      }

      return totalWeeks + isoWeekOfYear(endDate) - isoWeekOfYear(startDate);
    }

    int weeksDiff = weekDifference(baseDate, targetDate);

    if (baseDate.isAfter(targetDate)) {
      return _initialPageCount - weeksDiff;
    } else {
      return _initialPageCount + weeksDiff;
    }
  }

  int calculateMonthIndex(DateTime targetDate) {
    DateTime baseDate = DateTime(2024, 1); // 기준 날짜 (2024년 1월)

    // 연도와 월의 차이를 기반으로 한 인덱스 계산
    int yearDifference = targetDate.year - baseDate.year;
    int monthDifference = targetDate.month - baseDate.month;

    // 총 월 차이 계산 (연도 차이를 월로 변환하여 더함)
    int totalMonthDifference = yearDifference * 12 + monthDifference;

    // 기준 인덱스에 월 차이를 더함
    return _initialPageCount + totalMonthDifference;
  }

  List<ExpenseItem> getExpensesByPageIndex(List<ExpenseItem> expenses, bool isWeeklyView, int index) {
    DateTime nowDate = DateTime.now();
    var subtract = _initialPageCount - index; // 1000 - 0 = 1000

    DateTime monday = nowDate.subtract(Duration(days: nowDate.weekday - 1)); // 월
    DateTime sunday = nowDate.subtract(Duration(days: nowDate.weekday - 7)); // 일

    DateTime startDate;
    DateTime endDate;

    if (isWeeklyView) {
      // index 1 차이가 1주
      startDate = monday.subtract(Duration(days: subtract * 7)); // 월
      endDate = sunday.subtract(Duration(days: subtract * 7)); // 일
    } else {
      // index 1 차이가 1달
      startDate = DateTime(nowDate.year, nowDate.month - subtract, 1);
      endDate = DateTime(nowDate.year, nowDate.month - subtract + 1, 0);
    }

    DateTime newStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    DateTime newEndDate = DateTime(endDate.year, endDate.month, endDate.day);

    var filteredList = expenses.where((expense) {
      // 날짜만 추출 (시간 정보 무시)
      DateTime expenseDateOnly = DateTime(expense.datetime.year, expense.datetime.month, expense.datetime.day);

      // 시작일 이후이고 종료일 이전(또는 동일)인 경우에만 true
      return expenseDateOnly.isAfter(newStartDate.subtract(Duration(days: 1))) && expenseDateOnly.isBefore(newEndDate);
    }).toList();

    // var list = expenses.where((expense) {
    //   DateTime expenseDate = DateTime(expense.datetime.year, expense.datetime.month, expense.datetime.day, 1);

    //   bool a = expenseDate.isAfter(startDate) && expenseDate.isBefore(endDate);

    //   return a;

    //   //return expenseDate.isAfter(startDate) && expenseDate.isBefore(endDate);
    // }).toList();

    return filteredList;
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

    //_expenses = list.fold(0.0, (total, item) => total + item.amount);
    //_balance = _budget - _expenses;

    return list;
  }

  void checkAndShowExpenseData() async {
    final expenseData = Provider.of<ExpenseItemProvider>(context, listen: false);

    // ExpenseData에 유효한 데이터가 있는 경우에만 SnackBar를 표시
    if (expenseData.amount != 0 && expenseData.category != null) {
      // 새로운 지출 항목 추가
      await expenseData.addExpenseItemToFirebase();
      final snackBar = SnackBar(
        content: Text('날짜: ${expenseData.selectedDate}, 금액: ${expenseData.amount}, 카테고리: ${expenseData.category ?? "없음"}'),
        duration: const Duration(seconds: 3),
      );

      // SnackBar 표시 후 ExpenseData 초기화
      expenseData.clearData();

      _allExpenseItems = await _firestoreService.getExpenseItems(expenseData.userId!);

      // // 새로운 데이터를 allExpenseItems에 추가
      // _allExpenseItems.add(ExpenseItem(
      //   amount: expenseData.amount,
      //   category: expenseData.category!,
      //   icon: userInfos[_userId]!.iconPath,
      //   datetime: expenseData.selectedDate,
      //   userId: _userId,
      //   // 기타 필요한 필드들...
      // ));

      //updateFilterDataList();

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
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

        // items.add(
        //   ExpenseItem(
        //     amount: amount,
        //     category: category,
        //     icon: icon,
        //     datetime: date,
        //   ),
        // );
      }
    }
    items.sort((a, b) => a.date.compareTo(b.date));

    return items;
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void toggleDatePicker() {
    setState(() {
      isDatePickerShown = !isDatePickerShown;
    });
  }

  // 새로운 메서드를 정의합니다.
  void _updateFinancialData() {
    String input = _budgetController.text.replaceAll(',', ''); // 쉼표 제거

    bool isWeeklyView = Provider.of<ViewModeProvider>(context).isWeeklyView;

    var provSumry = Provider.of<SummaryDataProvider>(context, listen: false);

    num budget = 0.0;
    if (isWeeklyView) {
      budget = num.tryParse(input) ?? provSumry.budget_weekly;
      provSumry.setBudgetWeekly(budget);
    } else {
      budget = num.tryParse(input) ?? provSumry.budget_montly;
      provSumry.setBudgetMontly(budget);
    }

    provSumry.setExpenses(_currentPageExpenseItems, isWeeklyView);
  }

  @override
  Widget build(BuildContext context) {
    bool _hasNotifications = true;
    bool isWeeklyView = Provider.of<ViewModeProvider>(context).isWeeklyView;
    DateTime selectedDate = Provider.of<SummaryDataProvider>(context).selectedDate;
    var prov = Provider.of<SummaryDataProvider>(context);

    if (_isWeeklyView != isWeeklyView) {
      setState(() {
        _isWeeklyView = isWeeklyView;
      });
      if (_pageController.positions.isNotEmpty) {
        _pageController.jumpToPage(_initialPageCount);
      }
    }

    // 다크 테마 색상 정의
    Color backgroundColor = const Color(0xFF121212); // 배경 색상
    Color foregroundColor = Colors.white; // 텍스트 색상
    Color accentColor = const Color(0xFF1F1F1F); // 입력 필드 배경 색상

    weekNumber = weekOfMonthForStandard(selectedDate);

    String formattedYear = DateFormat('yyyy').format(selectedDate);
    String formattedMonth = DateFormat('M').format(selectedDate);
    String formattedYearMonth = DateFormat('yyyy-MM').format(selectedDate);
    String formattedWeeknum = selectedDate.weekOfYear.toString().padLeft(2, '0');

    // 주간 또는 월간 레이블 표시
    String dateLabel = isWeeklyView ? '$formattedYear년 $formattedMonth월  ${selectedDate.weekOfYear}주차' : '$formattedYear년 $formattedMonth월';

    //_filterDataByPeriod(isWeeklyView);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        //title: Text(widget.title),
        backgroundColor: Colors.grey[900],
        title: GestureDetector(
          onTap: () {
            setState(() {
              isDatePickerShown = !isDatePickerShown;
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(width: 8), // 텍스트와 아이콘 사이의 간격
                Icon(
                  isDatePickerShown ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                )
              ],
            ),
          ),
        ),
        actions: <Widget>[
          Stack(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationScreen()),
                  );
                },
                tooltip: '알림',
              ),
              if (_hasNotifications) // 알림 유무에 따라 빨간 점 표시
                Positioned(
                  top: 10.0,
                  right: 10.0,
                  child: Container(
                    padding: EdgeInsets.all(1.0),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 7.0,
                      minHeight: 7.0,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),

      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // 로딩 인디케이터 표시
          : SafeArea(
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 5, bottom: 15),
                    //padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                    ),
                    child: Column(
                      children: <Widget>[
                        if (isDatePickerShown)
                          AnimatedOpacity(
                              opacity: isDatePickerShown ? 1.0 : 0.0, // 달력이 표시되면 불투명도 1, 아니면 0
                              duration: const Duration(milliseconds: 500), // 애니메이션 지속 시간
                              child: CalendarDatePicker(
                                initialDate: selectedDate,
                                firstDate: DateTime(1900),
                                lastDate: DateTime(2101),
                                onDateChanged: (newDate) {
                                  prov.setCurrentDate(newDate);
                                  var index = isWeeklyView ? calculateWeekIndex(newDate) : calculateMonthIndex(newDate);
                                  _pageController.jumpToPage(index);
                                  isDatePickerShown = false;
                                },
                              )),
                        _infoBox(isWeeklyView, selectedDate), // 달력, 개요
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '지출 목록',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Builder(
                          builder: (BuildContext context) {
                            return IconButton(
                              icon: const Icon(Icons.filter_list),
                              onPressed: () {
                                Scaffold.of(context).openEndDrawer(); // Drawer 열기
                              },
                              tooltip: '필터링',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Consumer<ViewModeProvider>(
                    builder: (context, viewModeProvider, child) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 0), // 하단에 padding 추가
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              print("onPageChanged");
                              updateSelectedDate(index, viewModeProvider.isWeeklyView);
                              //var pageIndex = _pageController.page?.round();
                              //_currentPageExpenseItems = getExpensesByPageIndex(_allExpenseItems, _isWeeklyView, pageIndex!);
                            },
                            itemBuilder: (_, index) {
                              print("itemBuilder");
                              var list = getExpensesByPageIndex(_allExpenseItems, viewModeProvider.isWeeklyView, index);

                              print(list.length);
                              return ExpensePage(expenseItems: list, onToggleDatePicker: toggleDatePicker, isDatePickerShown: isDatePickerShown);
                            },
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
      //floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: SafeArea(
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF3182F7),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddExpenseScreen(selectedDate: selectedDate),
              ),
            );
          },
          elevation: 4.0, // FloatingActionButton의 그림자 깊이
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterDocked,
      bottomNavigationBar: BottomAppBar(
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 25), // 위아래 패딩을 줄여 메뉴 바 높이 감소
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _buildBottomNavigationItem(0, Icons.home, "홈"),
              Spacer(flex: 1),
              _buildBottomNavigationItem(1, Icons.bar_chart, "분석"),
              Spacer(flex: 3),
              _buildBottomNavigationItem(2, Icons.person, "사용자"),
            ],
          ),
        ),
      ),
      endDrawer: SafeArea(
        child: Drawer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              AppBar(
                title: const Text('필터'),
                automaticallyImplyLeading: false,
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                ],
              ),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 15),
                    const Padding(
                      padding: EdgeInsets.only(left: 16, bottom: 10),
                      child: Text(
                        '카테고리',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListView.builder(
                      padding: const EdgeInsets.all(0),
                      shrinkWrap: true, // ListView의 크기를 내용물 크기에 맞게 조정
                      physics: const NeverScrollableScrollPhysics(), // ListView 스크롤 비활성화
                      itemCount: categoryChecked.length,
                      itemBuilder: (context, index) {
                        if (index >= categoryChecked.length) return Container();
                        String category = categoryChecked.keys.elementAt(index);
                        return CheckboxListTile(
                          title: Text(category),
                          value: categoryChecked[category],
                          onChanged: (bool? value) {
                            setState(() {
                              categoryChecked[category] = value!;
                            });
                          },
                          visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
                        );
                      },
                    ),
                    const SizedBox(height: 25),
                    const Padding(
                      padding: EdgeInsets.only(left: 16, bottom: 10),
                      child: Text(
                        '사용자',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListView.builder(
                      padding: const EdgeInsets.all(0),
                      shrinkWrap: true, // ListView의 크기를 내용물 크기에 맞게 조정
                      physics: const NeverScrollableScrollPhysics(), // ListView 스크롤 비활성화
                      itemCount: userChecked.length,
                      itemBuilder: (context, index) {
                        if (index >= userChecked.length) return Container();
                        String userId = userChecked.keys.elementAt(index);
                        UserData userInfo = userInfos[userId]!; // UID에 해당하는 UserInfo 객체를 얻습니다.
                        return CheckboxListTile(
                          title: Text(userInfo.name), // UserInfo의 name을 표시합니다.
                          value: userChecked[userId],
                          onChanged: (bool? value) {
                            setState(() {
                              userChecked[userId] = value!;
                            });
                          },
                          visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
                        );
                      },
                    ),
                    // 사용자에 대한 Padding과 ListView.builder 추가...
                    // 그 외 필요한 위젯들 추가...
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationItem(int index, IconData icon, String label) {
    bool isSelected = _currentScreenIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentScreenIndex = index;
          if (index == 0) {
            // 홈 아이콘 클릭 시 MyHomePage로 이동
            FirebaseAnalyticsManager analyticsManager = FirebaseAnalyticsManager();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => MyHomePage(
                        analytics: analyticsManager.analytics,
                        observer: analyticsManager.observer,
                      )),
              (Route<dynamic> route) => false,
            ).then((result) {
              // 결과를 통해 인덱스 업데이트
              if (result != null) {
                setState(() {
                  _currentScreenIndex = result;
                });
              }
            });
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AnalyticsScreen())).then((result) {
              // 결과를 통해 인덱스 업데이트
              if (result != null) {
                setState(() {
                  _currentScreenIndex = result;
                });
              }
            });
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => UserScreen())).then((result) {
              // 결과를 통해 인덱스 업데이트
              if (result != null) {
                setState(() {
                  _currentScreenIndex = result;
                });
              }
            });
            _currentScreenIndex = 0;
          }
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 25, color: isSelected ? Colors.blue : Colors.grey),
          SizedBox(height: 1),
          Text(label, style: TextStyle(fontSize: 10, color: isSelected ? Colors.blue : Colors.grey)),
        ],
      ),
    );
  }

// 예시: 카테고리 필터링 함수
  void filterByCategory(String category) {
    // 카테고리에 따라 아이템 필터링
  }

// 예시: 사용자 필터링 함수
  void filterByUser(String user) {
    // 사용자에 따라 아이템 필터링
  }

// 예시: 금액 범위 필터링 함수
  void filterByAmountRange(double minAmount, double maxAmount) {
    // 금액 범위에 따라 아이템 필터링
  }

  List<DateTime> generateDateList(DateTime startDate, DateTime endDate) {
    List<DateTime> dateList = [];

    for (DateTime date = startDate; date.isBefore(endDate) || date.isAtSameMomentAs(endDate); date = date.add(const Duration(days: 1))) {
      dateList.add(date);
    }

    return dateList;
  }

  void updateSelectedDate(int index, bool isWeeklyView) {
    DateTime nowDate = DateTime.now();
    var subtract = _initialPageCount - index; // 1000 - 0 = 1000

    DateTime monday = nowDate.subtract(Duration(days: nowDate.weekday - 1)); // 월
    DateTime sunday = nowDate.subtract(Duration(days: nowDate.weekday - 7)); // 일

    DateTime startDate;
    DateTime endDate;

    if (isWeeklyView) {
      // index 1 차이가 1주
      startDate = monday.subtract(Duration(days: subtract * 7)); // 월
      endDate = sunday.subtract(Duration(days: subtract * 7)); // 일
    } else {
      // index 1 차이가 1달
      startDate = DateTime(nowDate.year, nowDate.month - subtract, 1);
      endDate = DateTime(nowDate.year, nowDate.month - subtract + 1, 0);
    }

    var list = getExpensesByPageIndex(_allExpenseItems, _isWeeklyView, index);
    Provider.of<SummaryDataProvider>(context, listen: false).setExpenses(list, isWeeklyView);

    print("updateSelectedDate");
    //_currentPageExpenseItems = list;

    setState(() {
      Set<String> uniqueCategories = list.map((item) => item.category).toSet();
      categoryChecked.clear();
      for (String category in uniqueCategories) {
        categoryChecked[category] = false;
      }

      Set<String> uniqueUsers = list.map((item) => item.userId).toSet();
      userChecked.clear();
      for (String userId in uniqueUsers) {
        userChecked[userId] = false;
      }
    });

    Provider.of<SummaryDataProvider>(context, listen: false).setCurrentDate(startDate);
    // setState(() {
    //   _selectedDate = startDate;
    // });
  }

  DateInfo calculateDateInfoBasedOnIndex(int index, bool isWeeklyView) {
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
    DateTime firstDay = DateTime(date.year, date.month, 1);

    // 월중에 첫번째 월요일인 날짜.
    DateTime firstMonday = firstDay.add(Duration(days: (DateTime.monday + 7 - firstDay.weekday) % 7));

    // 첫번째 날짜와 첫번째 월요일인 날짜가 동일한지 판단.
    // 동일할 경우: 1, 동일하지 않은 경우: 2 를 마지막에 더한다.
    final bool isFirstDayMonday = firstDay == firstMonday;

    final different = calculateDaysBetween(from: firstMonday, to: date);

    // 주차 계산.
    int weekOfMonth = (different / 7 + (isFirstDayMonday ? 1 : 2)).toInt();
    return weekOfMonth;
  }

  // D-Day 계산.
  int calculateDaysBetween({required DateTime from, required DateTime to}) {
    return (to.difference(from).inHours / 24).round();
  }

  // 동일한 주차인지 확인.
  bool isSameWeek(DateTime dateTime1, DateTime dateTime2) {
    final int dateTime1WeekOfMonth = weekOfMonthForSimple(dateTime1);
    final int dateTime2WeekOfMonth = weekOfMonthForSimple(dateTime2);
    return dateTime1WeekOfMonth == dateTime2WeekOfMonth;
  }

  // 월 주차. (정식 규정에 따라서 계산)
  int weekOfMonthForStandard(DateTime date) {
    // 월 주차.
    late int weekOfMonth;

    // 선택한 월의 첫번째 날짜.
    final firstDay = DateTime(date.year, date.month, 1);

    // 선택한 월의 마지막 날짜.
    final lastDay = DateTime(date.year, date.month + 1, 0);

    // 첫번째 날짜가 목요일보다 작은지 판단.
    final isFirstDayBeforeThursday = firstDay.weekday <= DateTime.thursday;

    // 선택한 날짜와 첫번째 날짜가 같은 주에 위치하는지 판단.
    if (isSameWeek(date, firstDay)) {
      // 첫번째 날짜가 목요일보다 작은지 판단.
      if (isFirstDayBeforeThursday) {
        // 1주차.
        weekOfMonth = 1;
      }

      // 저번달의 마지막 날짜의 주차와 동일.
      else {
        final lastDayOfPreviousMonth = DateTime(date.year, date.month, 0);

        // n주차.
        weekOfMonth = weekOfMonthForStandard(lastDayOfPreviousMonth);
      }
    } else {
      // 선택한 날짜와 마지막 날짜가 같은 주에 위치하는지 판단.
      if (isSameWeek(date, lastDay)) {
        // 마지막 날짜가 목요일보다 큰지 판단.
        final isLastDayBeforeThursday = lastDay.weekday >= DateTime.thursday;
        if (isLastDayBeforeThursday) {
          // 주차를 단순 계산 후 첫번째 날짜의 위치에 따라서 0/-1 결합.
          // n주차.
          weekOfMonth = weekOfMonthForSimple(date) + (isFirstDayBeforeThursday ? 0 : -1);
        }

        // 다음달 첫번째 날짜의 주차와 동일.
        else {
          // 1주차.
          weekOfMonth = 1;
        }
      }

      // 첫번째주와 마지막주가 아닌 날짜들.
      else {
        // 주차를 단순 계산 후 첫번째 날짜의 위치에 따라서 0/-1 결합.
        // n주차.
        weekOfMonth = weekOfMonthForSimple(date) + (isFirstDayBeforeThursday ? 0 : -1);
      }
    }

    return weekOfMonth;
  }

  Widget _infoBox(bool isWeeklyView, DateTime selectedDate) {
    String formattedYear = DateFormat('yyyy').format(selectedDate);
    String formattedMonth = DateFormat('M').format(selectedDate);
    String formattedYearMonth = DateFormat('yyyy-MM').format(selectedDate);
    String formattedWeeknum = selectedDate.weekOfYear.toString().padLeft(2, '0');

    var prov = Provider.of<SummaryDataProvider>(context);
    var provViewMode = Provider.of<ViewModeProvider>(context, listen: false);

    num expenses = prov.expenses;
    num balance = prov.balance;
    num budget = 0.0;
    if (isWeeklyView) {
      budget = prov.getSpecificWeeklyBudget('$formattedYear-$formattedWeeknum');
    } else {
      budget = prov.getSpecificMonthlyBudget(formattedYearMonth);
    }

    String formattedBudget = NumberFormat("#,###").format(budget);
    String formattedExpenses = NumberFormat("#,###").format(expenses);
    String formattedBalance = NumberFormat("#,###").format(balance.abs());

    // 주간 또는 월간 레이블 표시
    //String dateLabel = isWeeklyView ? '$formattedYear년 $formattedMonth월  ${selectedDate.weekOfYear}주차' : '$formattedYear년 $formattedMonth월';

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              // 슬라이드 업 팝업을 여는 로직
              _showEditBudgetPopup(isWeeklyView, selectedDate);
            },
            child: Row(
              mainAxisSize: MainAxisSize.max, // 텍스트 크기에 맞게 Row 크기 조정
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Text(
                      '예산 $formattedBudget원',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      bottom: 0, // 텍스트와 밑줄 사이의 간격 조정
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1.5, // 밑줄의 두께
                        color: Colors.white, // 밑줄의 색상
                      ),
                    ),
                  ],
                ),
                const Text(
                  ' 중',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Spacer(flex: 1),
                if (!provViewMode.isExpanded)
                  Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: RichText(
                      text: TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: balance > 0 ? '$formattedBalance원' : '$formattedBalance원',
                            style: TextStyle(
                              fontSize: 20,
                              color: balance > 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: balance > 0 ? ' 남음' : ' 초과',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Spacer(flex: 4),
                IconButton(
                  icon: Icon(provViewMode.isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      provViewMode.toggleSummaryExpand();
                    });
                  },
                ),
              ],
            ),
          ),
          if (provViewMode.isExpanded)
            if (expenses > 0.0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '$formattedExpenses원 지출하여',
                    style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
          if (provViewMode.isExpanded)
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: balance > 0 ? '$formattedBalance원' : '$formattedBalance원',
                    style: TextStyle(
                      fontSize: 24,
                      color: balance > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: balance > 0 ? ' 남았습니다.' : ' 초과했습니다.',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showEditBudgetPopup(bool isWeeklyView, DateTime selectedDate) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '예산 수정',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          // 버튼 모서리 둥근 정도 조절
                          borderRadius: BorderRadius.circular(10.0), // 약간 둥근 모서리
                        ),
                      ),
                      child: Text(isWeeklyView ? '이번주 예산만' : '이번달 예산만', style: const TextStyle(fontSize: 16)),
                      onPressed: () => _editCurrentBudget(isWeeklyView, selectedDate),
                    ),
                  ),
                  const SizedBox(width: 20.0),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.grey,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          // 버튼 모서리 둥근 정도 조절
                          borderRadius: BorderRadius.circular(10.0), // 약간 둥근 모서리
                        ),
                      ),
                      child: const Text('전체 예산', style: TextStyle(fontSize: 16)),
                      onPressed: () => _editOverallBudget(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35.0),
          ],
        );
      },
    );
  }

  void _editCurrentBudget(bool isWeeklyView, DateTime selectedDate) {
    var provider = Provider.of<SummaryDataProvider>(context, listen: false);

    String formattedYear = DateFormat('yyyy').format(selectedDate);
    String formattedYearMonth = DateFormat('yyyy-MM').format(selectedDate);
    String formattedWeeknum = selectedDate.weekOfYear.toString().padLeft(2, '0');

    // 현재 선택된 주차 또는 월에 따라 예산 값을 가져옵니다.
    num currentBudget =
        isWeeklyView ? provider.getSpecificWeeklyBudget('$formattedYear-$formattedWeeknum') : provider.getSpecificMonthlyBudget(formattedYearMonth);
    // 현재 예산 값을 포맷합니다.

    String formattedBudget = NumberFormat('#,###').format(currentBudget);

    // TextEditingController를 현재 예산 값으로 초기화합니다.
    _budgetController = TextEditingController(text: formattedBudget);

    Navigator.pop(context); // 팝업 닫기
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('예산 수정'),
          content: TextField(
            controller: _budgetController,
            focusNode: _budgetFocusNode,
            style: const TextStyle(color: Colors.white, fontSize: 20),
            decoration: const InputDecoration(
              hintText: '새로운 예산을 입력하세요.',
              hintStyle: TextStyle(color: Colors.white70),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              MoneyInputFormatter(),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('저장'),
              onPressed: () {
                String input = _budgetController.text.replaceAll(',', ''); // 쉼표 제거
                num newBudget = num.tryParse(input) ?? currentBudget;
                // 현재 선택된 주차 또는 월에 새로운 예산을 적용합니다.
                if (isWeeklyView) {
                  // 주차별 예산 업데이트
                  provider.setSpecificWeeklyBudget('$formattedYear-$formattedWeeknum', newBudget);
                } else {
                  // 월별 예산 업데이트
                  provider.setSpecificMonthlyBudget(formattedYearMonth, newBudget);
                }

                Navigator.pop(context); // 대화상자 닫기
              },
            ),
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.pop(context); // 대화상자 닫기
              },
            ),
          ],
        );
      },
    );
  }

  void _editOverallBudget() {
    Navigator.pop(context); // 팝업 닫기
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('예산 수정'),
          content: TextField(
            controller: _budgetController,
            focusNode: _budgetFocusNode,
            style: const TextStyle(color: Colors.white, fontSize: 20),
            decoration: const InputDecoration(
              hintText: '새로운 예산을 입력하세요.',
              hintStyle: TextStyle(color: Colors.white70),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              MoneyInputFormatter(),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('저장'),
              onPressed: () {
                _updateFinancialData(); // 새로 정의한 메서드 호출
                Navigator.pop(context); // 대화상자 닫기
              },
            ),
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.pop(context); // 대화상자 닫기
              },
            ),
          ],
        );
      },
    );
  }

  int dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays;
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

  //List<ExpenseItem> expenseItems = [];

  // 스크롤 이벤트 리스너에 _onScrollNotification 함수 추가
  @override
  void initState() {
    super.initState();

    //expenseItems = widget.expenseItems;
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = const Color(0xFF121212); // 배경 색상
    Color foregroundColor = Colors.white; // 텍스트 색상
    Color accentColor = const Color(0xFF1F1F1F); // 입력 필드 배경 색상
    // expenseItems 리스트가 비어있는 경우 처리
    if (widget.expenseItems.isEmpty) {
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
          elements: widget.expenseItems,
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
            margin: const EdgeInsets.only(top: 5, bottom: 10),
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
        padding: const EdgeInsets.only(left: 25, right: 25, top: 0, bottom: 20),
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
        padding: const EdgeInsets.only(left: 25, right: 25, top: 0, bottom: 20),
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
            CircleAvatar(
              backgroundImage: NetworkImage(item.icon),
              radius: 18,
            ),
            // ClipOval(
            //   child: Image.asset(
            //     item.icon,
            //     width: 32,
            //     height: 32,
            //     fit: BoxFit.cover, // 이미지가 할당된 공간에 맞도록 조정
            //   ),
            // ),
          ],
        ),
      );
    }
  }
}
