import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/zavisnosti.dart';

void postaviTelefon(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

Future<void> otvoriAplikaciju(WidgetTester tester, ZavisnostiAplikacije zavisnosti) async {
  await tester.pumpWidget(ErasmusAplikacija(zavisnosti: zavisnosti));
  await tester.pump();
  await tester.tap(find.text('Uloguj se'));
  await tester.pump();
}
