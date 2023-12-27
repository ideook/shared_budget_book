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

  int _counter = 0;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 다크 테마 색상 정의
    Color backgroundColor = const Color(0xFF121212); // 배경 색상
    Color foregroundColor = Colors.white; // 텍스트 색상
    Color accentColor = const Color(0xFF1F1F1F); // 입력 필드 배경 색상

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: backgroundColor,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Row(
                mainAxisSize: MainAxisSize.min, // Use minimum space required by children
                children: [
                  Text(DateFormat('yyyy년 M월 d일').format(selectedDate)),
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
                  });
                },
              ),
            // 날짜가 선택되었을 때 나타나는 '지출 입력' 버튼
            // ListTile(
            //   title: const Text('지출 입력'),
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => AddExpenseScreen(selectedDate: selectedDate),
            //       ),
            //     );
            //   },
            // ),
            // 나머지 UI 요소들...
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
}
