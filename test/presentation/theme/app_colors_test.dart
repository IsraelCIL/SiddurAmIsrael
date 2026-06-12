import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siddur_am_israel_chai/presentation/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    test('scaffold background is pure opaque white', () {
      expect(AppColors.background, const Color(0xFFFFFFFF));
    });
  });
}
