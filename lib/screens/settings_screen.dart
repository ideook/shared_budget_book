import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:earnedon/provider/summary_date_provider.dart';
import 'package:earnedon/provider/view_mode_provider.dart';
import 'package:earnedon/screens/share_screen.dart';
import 'package:earnedon/services/auth_service.dart';
import 'package:earnedon/services/money_input_formatter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService authService = AuthService();

  bool isWeeklyView = true; // 예산 단위 토글 상태
  num _weeklyBudget = 0.0;
  num _monthlyBudget = 0.0;
  // 다크 테마 색상 정의
  Color backgroundColor = const Color(0xFF121212); // 배경 색상
  Color foregroundColor = Colors.white; // 텍스트 색상
  Color accentColor = const Color(0xFF1F1F1F); // 입력 필드 배경 색상
  final TextEditingController _monthlyBudgetController = TextEditingController();
  final FocusNode _monthlyBudgetFocusNode = FocusNode();
  final TextEditingController _weeklyBudgetController = TextEditingController();
  final FocusNode _weeklyBudgetFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      var prov = Provider.of<SummaryDataProvider>(context, listen: false);

      _monthlyBudgetController.text = prov.budget_montly.toString();
      _weeklyBudgetController.text = prov.budget_weekly.toString();

      setState(() {
        _weeklyBudget = prov.budget_weekly;
        _monthlyBudget = prov.budget_montly;
      });
    });
  }

  void _showEditBudgetDialog(String budgetType) {
    // 해당 예산 유형에 따라 컨트롤러 및 변수 설정
    final TextEditingController controller = (budgetType == '주간') ? _weeklyBudgetController : _monthlyBudgetController;
    num budgetValue = (budgetType == '주간') ? _weeklyBudget : _monthlyBudget;

    controller.text = budgetValue.toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$budgetType 예산 설정'),
          content: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [MoneyInputFormatter()],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('저장'),
              onPressed: () {
                setState(() {
                  String input = controller.text.replaceAll(',', ''); // 쉼표 제거
                  num newValue = 0;
                  if (budgetType == '주간') {
                    newValue = double.tryParse(input) ?? _weeklyBudget;
                    Provider.of<SummaryDataProvider>(context, listen: false).setBudgetWeekly(newValue);
                  } else {
                    newValue = double.tryParse(input) ?? _monthlyBudget;
                    Provider.of<SummaryDataProvider>(context, listen: false).setBudgetMontly(newValue);
                  }
                });
                Navigator.of(context).pop();
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
    var prov = Provider.of<SummaryDataProvider>(context, listen: false);
    var provViewModeProvider = Provider.of<ViewModeProvider>(context, listen: false);

    _weeklyBudget = prov.budget_weekly;
    _monthlyBudget = prov.budget_montly;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('설정'),
        leading: IconButton(
          icon: const Icon(Icons.close), // 닫기 아이콘 사용
          onPressed: () {
            Navigator.popUntil(context, ModalRoute.withName('/'));
            //Navigator.pop(context, 0); // 현재 화면을 닫고 이전 화면으로 돌아감
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '예산 단위',
                    style: TextStyle(fontSize: 20.0),
                  ),
                  Row(
                    children: [
                      Text(
                        provViewModeProvider.isWeeklyView ? '주간' : '월간',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                      const SizedBox(width: 10),
                      Switch(
                        value: provViewModeProvider.isWeeklyView,
                        onChanged: (bool value) {
                          setState(() {
                            provViewModeProvider.toggleViewMode();
                            //isWeeklyView = !isWeeklyView;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                '예산 수정',
                style: TextStyle(fontSize: 20.0),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '주간',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    const SizedBox(width: 40),
                    InkWell(
                      onTap: () => _showEditBudgetDialog('주간'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // 텍스트 크기에 맞게 Row 크기 조정
                        children: <Widget>[
                          Stack(
                            children: <Widget>[
                              Text(
                                '${NumberFormat("#,###").format(_weeklyBudget)}원',
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
                          const SizedBox(width: 7),
                          const Icon(
                            Icons.edit,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '월간',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    const SizedBox(width: 40),
                    InkWell(
                      onTap: () => _showEditBudgetDialog('월간'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // 텍스트 크기에 맞게 Row 크기 조정
                        children: <Widget>[
                          Stack(
                            children: <Widget>[
                              Text(
                                '${NumberFormat("#,###").format(_monthlyBudget)}원',
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
                          const SizedBox(width: 7),
                          const Icon(
                            Icons.edit,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ShareScreen()),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '가계부 공유',
                      style: TextStyle(fontSize: 20.0),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '개요 펼치기',
                    style: TextStyle(fontSize: 20.0),
                  ),
                  Row(
                    children: [
                      Text(
                        provViewModeProvider.isExpanded ? '펼치기' : '닫기',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                      const SizedBox(width: 10),
                      Switch(
                        value: provViewModeProvider.isExpanded,
                        onChanged: (bool value) {
                          setState(() {
                            provViewModeProvider.toggleSummaryExpand();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
