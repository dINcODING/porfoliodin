import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porfoliodin/main.dart';

void main() {
  testWidgets('portfolio opens on the home face', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const PortfolioApp());
    await tester.pump();

    expect(find.text('Nuruddin\nMahmud'), findsOneWidget);
    expect(find.text('View Projects'), findsOneWidget);
  });

  testWidgets('all destinations fit and navigate at phone size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PortfolioApp());
    await tester.pumpAndSettle();

    for (final label in [
      'Projects',
      'Experience',
      'Skills',
      'About',
      'Contact',
      'Home',
    ]) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull, reason: '$label overflowed');
    }
  });

  testWidgets('skills explorer fits and switches categories on desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PortfolioApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skills').last);
    await tester.pumpAndSettle(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);

    for (final label in [
      'MOBILE & FRONTEND',
      'API & INTEGRATION',
      'BACKEND',
      'DATABASE',
      'DEVELOPMENT TOOLS',
      'PRODUCT / UI',
    ]) {
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$label overflowed');
    }
  });

  testWidgets('project showcase stays clear across responsive viewports', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [
      const Size(360, 800),
      const Size(390, 844),
      const Size(412, 915),
      const Size(768, 1024),
      const Size(1440, 1000),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        KeyedSubtree(key: ValueKey(size), child: const PortfolioApp()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Projects').last);
      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.tap(find.text('Scroll to explore').last);
      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(
        tester.takeException(),
        isNull,
        reason: 'Projects overflowed at ${size.width}×${size.height}',
      );
    }
  });
}
