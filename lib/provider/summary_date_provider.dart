import 'package:flutter/material.dart';
import 'package:shared_budget_book/models/expense_item.dart';

class SummaryDataProvider with ChangeNotifier {
  num _budget_montly = 200000.0;
  num _budget_weekly = 50000.0;
  num _expenses = 0.0;
  num _balance = 50000.0;

  num get budget_montly => _budget_montly;
  num get budget_weekly => _budget_weekly;
  num get expenses => _expenses;
  num get balance => _balance;

  void setBudgetWeekly(num budget) {
    _budget_weekly = budget;
    notifyListeners();
  }

  void setBudgetMontly(num budget) {
    _budget_montly = budget;
    notifyListeners();
  }

  void setExpenses(List<ExpenseItem> list, bool isWeeklyView) {
    _expenses = list.fold(0.0, (total, item) => total + item.amount);
    if (isWeeklyView) {
      _balance = _budget_weekly - _expenses;
    } else {
      _balance = _budget_montly - _expenses;
    }
    notifyListeners();
  }
}
