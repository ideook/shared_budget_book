import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:earnedon/main.dart';
import 'package:earnedon/screens/add_expense_screen.dart';
import 'package:earnedon/screens/user_screen.dart';
import 'package:earnedon/services/firebase_analytics_manager.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _currentScreenIndex = 1; // 현재 화면 인덱스

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = const Color(0xFF121212); // 배경 색상

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('분석'),
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back),
        //   onPressed: () {
        //     Navigator.pop(context, 0); // 결과로 인덱스를 전달
        //   },
        // ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BarChart(
          BarChartData(
              // 여기에 차트 데이터 및 설정을 추가합니다.
              ),
        ),
      ),
      floatingActionButton: SafeArea(
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF3182F7),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddExpenseScreen(selectedDate: DateTime.now()),
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => AnalyticsScreen())).then((result) {
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
            _currentScreenIndex = 1;
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
}
