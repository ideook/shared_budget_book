import 'dart:math';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // intl package should be added to your pubspec.yaml

class MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // If the first character is '.', prepend a zero
    if (newValue.text.startsWith('.')) {
      return TextEditingValue(
        text: '0.',
        selection: newValue.selection.copyWith(baseOffset: 2, extentOffset: 2),
      );
    }

    // If the new value is empty, clear the text field
    if (newValue.text.isEmpty) {
      return const TextEditingValue();
    }

    // 숫자와 소수점만 허용
    String numericOnly = newValue.text.replaceAll(RegExp('[^0-9.]'), '');

    // 숫자와 소수점을 분리
    List<String> parts = numericOnly.split('.');
    String integerPart = parts[0];
    String? decimalPart = parts.length > 1 ? parts[1] : null;

    // 정수 부분에 쉼표 추가
    String formattedIntegerPart = NumberFormat('#,##0', 'en_US').format(int.tryParse(integerPart) ?? 0);

    // 소수점 부분 처리
    String formattedDecimalPart = decimalPart != null ? '.$decimalPart' : '';
    // 소수점 두 자리로 제한
    if (formattedDecimalPart.length > 3) {
      formattedDecimalPart = formattedDecimalPart.substring(0, 3);
    }

    // 완성된 문자열
    String formatted = formattedIntegerPart + formattedDecimalPart;

    // 커서 위치 계산
    int cursorIndex = newValue.selection.end;
    int offset = formatted.length - numericOnly.length;

    // 커서 위치를 조정
    cursorIndex += offset;
    cursorIndex = min(formatted.length, cursorIndex);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorIndex),
    );
  }
}
