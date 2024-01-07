import 'package:flutter/material.dart';
import 'package:earnedon/models/expense_item.dart';

class SummaryDataProvider with ChangeNotifier {
  num _budget_montly = 200000.0;
  num _budget_weekly = 50000.0;
  num _expenses = 0.0;
  num _balance = 50000.0;
  DateTime _selectedDate = DateTime.now();
  final Map<String, num> _specificMonthlyBudgets = {};
  final Map<String, num> _specificWeeklyBudgets = {};

  num get budget_montly => _budget_montly;
  num get budget_weekly => _budget_weekly;
  num get expenses => _expenses;
  num get balance => _balance;
  DateTime get selectedDate => _selectedDate;

  /// 주별 예산을 설정합니다.
  /// [budget]은 주별로 할당된 총 예산 금액입니다.
  void setBudgetWeekly(num budget) {
    _budget_weekly = budget;
    notifyListeners();
  }

  /// 월별 예산을 설정합니다.
  /// [budget]은 월별로 할당된 총 예산 금액입니다.
  void setBudgetMontly(num budget) {
    _budget_montly = budget;
    notifyListeners();
  }

  /// 지출 목록을 설정하고, 현재 잔액을 업데이트합니다.
  /// [list]는 지출 항목들의 리스트입니다.
  /// [isWeeklyView]가 true이면 주별 잔액을, false이면 월별 잔액을 계산합니다.
  void setExpenses(List<ExpenseItem> list, bool isWeeklyView) {
    _expenses = list.fold(0.0, (total, item) => total + item.amount);
    if (isWeeklyView) {
      _balance = _budget_weekly - _expenses;
    } else {
      _balance = _budget_montly - _expenses;
    }
    notifyListeners();
  }

  /// 특정 주에 대한 예산을 설정합니다.
  /// [yearWeek]는 '년도-주차' 형식의 문자열 (예: '2024-15')입니다.
  /// [budget]은 해당 주에 할당된 예산 금액입니다.
  void setSpecificWeeklyBudget(String yearWeek, num budget) {
    _specificWeeklyBudgets[yearWeek] = budget;
    notifyListeners();
  }

  /// 특정 주의 예산을 가져옵니다.
  /// [yearWeek]는 '년도-주차' 형식의 문자열 (예: '2024-15')입니다.
  /// 설정된 특정 주의 예산이 없으면 기본 주별 예산을 반환합니다.
  num getSpecificWeeklyBudget(String yearWeek) {
    return _specificWeeklyBudgets[yearWeek] ?? _budget_weekly;
  }

  /// 특정 월의 예산을 설정합니다.
  /// [month]는 '년도-월' 형식의 문자열 (예: '2024-01')입니다.
  /// [budget]은 해당 월에 할당된 예산 금액입니다.
  void setSpecificMonthlyBudget(String month, num budget) {
    _specificMonthlyBudgets[month] = budget;
    notifyListeners();
  }

  void setCurrentDate(DateTime selectedDate) {
    _selectedDate = selectedDate;
    notifyListeners();
  }

  /// 특정 월의 예산을 가져옵니다.
  /// [month]는 '년도-월' 형식의 문자열 (예: '2024-01')입니다.
  /// 설정된 특정 월의 예산이 없으면 기본 월별 예산을 반환합니다.
  num getSpecificMonthlyBudget(String month) {
    return _specificMonthlyBudgets[month] ?? _budget_montly;
  }
}
