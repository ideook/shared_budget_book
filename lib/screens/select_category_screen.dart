import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_budget_book/main.dart';
import 'package:shared_budget_book/provider/expense_item_provider.dart';
import 'package:shared_budget_book/models/category_data.dart';
import 'package:shared_budget_book/services/firebase_analytics_manager.dart';

import 'package:shared_budget_book/services/money_input_formatter.dart';

class CategorySelectionScreen extends StatefulWidget {
  final DateTime selectedDate;
  final num amount;

  const CategorySelectionScreen({
    super.key,
    required this.selectedDate,
    required this.amount,
  });

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  List<Category> categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
    List<Category> fetchedCategories = await fetchCategories();
    setState(() {
      categories = fetchedCategories;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 날짜 및 금액 포맷 설정
    String formattedDate = DateFormat('yyyy년 M월 d일').format(widget.selectedDate);
    String formattedAmount = NumberFormat('#,###').format(widget.amount);

    // 다크 테마 색상 정의
    Color backgroundColor = const Color(0xFF121212);
    Color foregroundColor = Colors.white;
    Color foregroundColor70 = Colors.white70;
    Color accentColor = const Color(0xFF1F1F1F);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('카테고리 선택', style: TextStyle(color: foregroundColor)),
        backgroundColor: backgroundColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$formattedDate,',
                style: TextStyle(fontSize: 18.0, color: foregroundColor),
              ),
              const SizedBox(height: 5),
              Text(
                '$formattedAmount원을',
                style: TextStyle(fontSize: 18, color: foregroundColor),
              ),
              const SizedBox(height: 8),
              Text(
                '어디에 썼나요?',
                style: TextStyle(fontSize: 26.0, color: foregroundColor),
              ),
              const SizedBox(height: 25),
              Expanded(
                  child: GridView.count(
                      padding: const EdgeInsets.only(top: 10, bottom: 50),
                      crossAxisCount: 4,
                      childAspectRatio: 1.0,
                      mainAxisSpacing: 20,
                      children: categories.map((category) => _categoryTile(category, context)).toList())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryTile(Category category, BuildContext context) {
    return GestureDetector(
      onTap: () => _selectCategory(category.name),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[200], // 연한 그레이 배경색 설정
            child: Padding(
              padding: const EdgeInsets.all(12.0), // 원과 이미지 사이의 패딩
              child: ClipOval(
                child: Image.asset(
                  category.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5.0), // 이미지와 텍스트 사이의 패딩
            child: Text(
              category.name,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Category>> fetchCategories() async {
    return [
      Category(name: '식비', nameEn: 'food'),
      Category(name: '교통', nameEn: 'transport'),
      Category(name: '문화', nameEn: 'culture'),
      Category(name: '오락', nameEn: 'entertainment'),
      Category(name: '교육', nameEn: 'education'),
      Category(name: '여행', nameEn: 'travel'),
      Category(name: '패션', nameEn: 'fashion'),
      Category(name: '미용', nameEn: 'beauty'),
      Category(name: '생필품', nameEn: 'groceries'),
      Category(name: '통신', nameEn: 'communication'),
      Category(name: '주거비', nameEn: 'housing'),
      Category(name: '대출이자', nameEn: 'interest'),
      Category(name: '공과금', nameEn: 'utilities'),
      Category(name: '편의점', nameEn: 'store'),
      Category(name: '건강', nameEn: 'health'),
      Category(name: '카페', nameEn: 'cafe'),
      Category(name: '담배', nameEn: 'tobacco'),
      Category(name: '술', nameEn: 'alcohol'),
      Category(name: '취미', nameEn: 'hobby'),
      Category(name: '회비', nameEn: 'membership'),
      Category(name: '회사', nameEn: 'work'),
      Category(name: '용돈', nameEn: 'allowance'),
      Category(name: '선물', nameEn: 'gifts'),
      Category(name: '데이트', nameEn: 'dating'),
      Category(name: '복권', nameEn: 'lottery'),
      Category(name: '기타', nameEn: 'miscellaneous'),
    ];
  }

  void _selectCategory(String category) {
    Provider.of<ExpenseItemProvider>(context, listen: false).updateData(newCategory: category);

    // 메인 화면으로 직접 이동하기
    FirebaseAnalyticsManager analyticsManager = FirebaseAnalyticsManager();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => MyHomePage(
                analytics: analyticsManager.analytics,
                observer: analyticsManager.observer,
              )),
      (Route<dynamic> route) => false,
    );

    // Navigator.pushAndRemoveUntil(
    //   context,
    //   MaterialPageRoute(builder: (context) => const MyHomePage()), // 메인 화면 위젯
    //   (Route<dynamic> route) => false, // 모든 이전 라우트 제거
    // );
  }
}
