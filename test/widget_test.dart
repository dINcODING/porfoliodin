import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porfoliodin/main.dart';
import 'package:porfoliodin/portfolio_routes.dart';

void main() {
  test('portfolio routes stay inside a static hosting base path', () {
    final base = Uri.parse('https://dincoding.github.io/porfoliodin/');

    expect(
      uriForFace(CubeFace.skills, base).toString(),
      'https://dincoding.github.io/porfoliodin/#/skills',
    );
    expect(
      faceForUri(Uri.parse('https://example.com/portfolio/#/experience')),
      CubeFace.caseStudy,
    );
    expect(
      faceForUri(Uri.parse('https://example.com/work')),
      CubeFace.caseStudy,
    );
  });

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

  testWidgets('experience folder opens a readable dialog on phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PortfolioApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Experience').last);
    await tester.pumpAndSettle(const Duration(milliseconds: 900));
    await tester.tap(find.bySemanticsLabel('Open 2023 experience'));
    await tester.pumpAndSettle();

    expect(find.text('Software Developer'), findsOneWidget);
    expect(find.textContaining('2023 — Present'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('contact face exposes verified contact destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PortfolioApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contact').last);
    await tester.pumpAndSettle(const Duration(milliseconds: 900));

    expect(find.text('Send an email'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text(contactEmail), findsOneWidget);
    expect(find.text(contactPhone), findsOneWidget);
    expect(contactEmailUri.path, contactEmail);
    expect(contactPhoneUri.path, contactPhone);
    expect(whatsAppUri.toString(), 'https://wa.me/60133229619');
    expect(githubProfileUri.toString(), 'https://github.com/dINcODING');
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

      if (size.width < 900) {
        expect(
          find.byTooltip('Next project'),
          findsOneWidget,
          reason: 'Thumb navigator missing at ${size.width}×${size.height}',
        );

        final visual = tester.getRect(
          find.byKey(const ValueKey('project-visual-Solatiy')),
        );
        for (final label in [
          'Solatiy Android app preview',
          'Solatiy iOS app preview',
        ]) {
          final preview = tester.getRect(
            find.byKey(ValueKey('phone-preview-$label')),
          );
          expect(
            visual.contains(preview.topLeft) &&
                visual.contains(preview.bottomRight),
            isTrue,
            reason: '$label was clipped at ${size.width}×${size.height}',
          );
        }
      }

      expect(
        tester.takeException(),
        isNull,
        reason: 'Projects overflowed at ${size.width}×${size.height}',
      );
    }
  });
}
