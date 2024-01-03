import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_budget_book/provider/summary_date_provider.dart';
import 'package:shared_budget_book/provider/view_mode_provider.dart';
import 'package:shared_budget_book/screens/share_screen.dart';
import 'package:shared_budget_book/services/money_input_formatter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('저장'),
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
    var prov = Provider.of<SummaryDataProvider>(context, listen: false);

    _weeklyBudget = prov.budget_weekly;
    _monthlyBudget = prov.budget_montly;

    return Scaffold(
      appBar: AppBar(
        title: Text('설정'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
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
                      isWeeklyView ? '주간' : '월간',
                      style: const TextStyle(fontSize: 16.0),
                    ),
                    const SizedBox(width: 10),
                    Switch(
                      value: Provider.of<ViewModeProvider>(context, listen: false).isWeeklyView,
                      onChanged: (bool value) {
                        setState(() {
                          Provider.of<ViewModeProvider>(context, listen: false).toggleViewMode();
                          isWeeklyView = !isWeeklyView;
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
              padding: EdgeInsets.only(left: 0),
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
                    child: Container(
                      padding: const EdgeInsets.all(0.0),
                      child: Text(
                        '$_weeklyBudget원',
                        style: const TextStyle(
                          fontSize: 16.0,
                        ),
                      ),
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
                    child: Container(
                      padding: const EdgeInsets.all(0.0),
                      child: Text('$_monthlyBudget원', style: const TextStyle(fontSize: 16.0)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
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
                  Icon(Icons.arrow_forward_ios),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
