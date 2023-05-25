// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_import, directives_ordering

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../step/the_app_is_running.dart';
import '../step/i_do_not_see_text.dart';
import 'package:bdd_widget_test/step/i_see_text.dart';
import 'package:bdd_widget_test/step/i_tap_icon.dart';
import '../step/i_tap_icon_times.dart';

void main() {
  group('''Counter''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await theAppIsRunning(tester);
    }

    Future<void> bddTearDown(WidgetTester tester) async {
      await iDoNotSeeText(tester, 'surprise');
    }

    testWidgets('''Add button increments the counter''', (tester) async {
      try {
        await bddSetUp(tester);
        await iTapIcon(tester, Icons.add);
        await iSeeText(tester, '1');
      } finally {
        await bddTearDown(tester);
      }
    });
  });
}
