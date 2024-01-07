import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class NotFoundScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Not Found'),
      ),
      body: Center(child: Text('This page does not exist')),
    );
  }
}
