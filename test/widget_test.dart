// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// ignore_for_file: avoid_redundant_argument_values

import 'dart:io';
import 'dart:typed_data'; // ignore: unnecessary_import

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_portal/src/anchor.dart';
import 'package:flutter_portal/src/portal.dart';
import 'package:flutter_portal/src/portal_target.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Future<ByteData> fetchFont() async {
  final Uri fontUri;
  if (p.basename(Directory.current.path) == 'test') {
    fontUri =
        Uri.file('${Directory.current.path}/../assets/Roboto-Regular.ttf');
  } else {
    // We assume the test command is executed from the project root.
    fontUri = Uri.file('assets/Roboto-Regular.ttf');
  }

  final roboto = File.fromUri(fontUri);
  final bytes = Uint8List.fromList(await roboto.readAsBytes());
  return ByteData.view(bytes.buffer);
}

/// Fetch Roboto font from local cache, or from the internet, if it's not
/// found in the cache.
/// It needs to be done because flutter_test blocks access to package assets
/// (see https://github.com/flutter/flutter/issues/12999).

Future<void> main() async {
  final fontLoader = FontLoader('Roboto')..addFont(fetchFont());
  await fontLoader.load();

  testWidgets('can optionally delay close with a Duration', (tester) async {
    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            closeDuration: Duration(seconds: 5),
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    expect(find.text('portal'), findsOneWidget);

    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            visible: false,
            closeDuration: Duration(seconds: 6),
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    expect(find.text('portal'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));

    expect(find.text('portal'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('portal'), findsNothing);
  });

  testWidgets('can optionally delay close with a Duration (anchors)',
      (tester) async {
    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            closeDuration: Duration(seconds: 5),
            anchor: Aligned(
              target: Alignment.center,
              follower: Alignment.center,
            ),
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    expect(find.text('portal'), findsOneWidget);

    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            visible: false,
            closeDuration: Duration(seconds: 6),
            anchor: Aligned.center,
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    expect(find.text('portal'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));

    expect(find.text('portal'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('portal'), findsNothing);
  });

  testWidgets('handles dispose before timer end', (tester) async {
    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            closeDuration: Duration(seconds: 5),
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    expect(find.text('portal'), findsOneWidget);

    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            visible: false,
            closeDuration: Duration(seconds: 5),
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    expect(find.text('portal'), findsOneWidget);

    await tester.pumpWidget(Container());

    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('can update portal during close', (tester) async {
    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            closeDuration: Duration(seconds: 5),
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    expect(find.text('portal'), findsOneWidget);

    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            visible: false,
            closeDuration: Duration(seconds: 5),
            portalFollower: Text('portal2'),
            child: Text('child'),
          ),
        ),
      ),
    );

    expect(find.text('portal'), findsNothing);
    expect(find.text('portal2'), findsOneWidget);

    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            visible: false,
            closeDuration: Duration(seconds: 20),
            portalFollower: Text('portal3'),
            child: Text('child'),
          ),
        ),
      ),
    );

    expect(find.text('portal2'), findsNothing);
    expect(find.text('portal3'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));

    expect(find.text('portal3'), findsNothing);
  });

  testWidgets('can cancel leave timer by reverting visible', (tester) async {
    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            closeDuration: Duration(seconds: 5),
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    expect(find.text('portal'), findsOneWidget);

    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            visible: false,
            closeDuration: Duration(seconds: 5),
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    expect(find.text('portal'), findsOneWidget);

    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            closeDuration: Duration(seconds: 5),
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    expect(find.text('portal'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));

    expect(find.text('portal'), findsOneWidget);

    await tester.pumpWidget(Container());
  });

  testWidgets(
      'visible false > true > false resets the timer and works properly',
      (tester) async {
    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            closeDuration: Duration(seconds: 5),
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            visible: false,
            closeDuration: Duration(seconds: 5),
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    expect(find.text('portal'), findsOneWidget);

    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            closeDuration: Duration(seconds: 5),
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 2));

    expect(find.text('portal'), findsOneWidget);

    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            visible: false,
            closeDuration: Duration(seconds: 5),
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    expect(find.text('portal'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));

    expect(find.text('portal'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));

    expect(find.text('portal'), findsNothing);
  });

  testWidgets('child does not lose state when hiding portal', (tester) async {
    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    final childElement = tester.element(find.text('child'));

    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            visible: false,
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    expect(
      tester.element(find.text('child')),
      childElement,
    );

    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    expect(
      tester.element(find.text('child')),
      childElement,
    );
  });

  testWidgets('child does not lose state when hiding portal (anchors)',
      (tester) async {
    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            anchor: Aligned.center,
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    final childElement = tester.element(find.text('child'));

    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            visible: false,
            anchor: Aligned.center,
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    expect(
      tester.element(find.text('child')),
      childElement,
    );

    await tester.pumpWidget(
      const Boilerplate(
        child: Portal(
          child: PortalTarget(
            anchor: Aligned.center,
            portalFollower: Text('portal'),
            child: Text('child'),
          ),
        ),
      ),
    );

    expect(
      tester.element(find.text('child')),
      childElement,
    );
  });

  testWidgets('PortalProvider updates child', (tester) async {
    await tester.pumpWidget(
      const Portal(
        child: Text(
          'first',
          textDirection: TextDirection.ltr,
        ),
      ),
    );

    expect(find.text('first'), findsOneWidget);
    expect(find.text('second'), findsNothing);

    await tester.pumpWidget(
      const Portal(
        child: Text(
          'second',
          textDirection: TextDirection.ltr,
        ),
      ),
    );

    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
  });

  test('PortalEntry requires portal if visible is true ', () {
    expect(
      () => PortalTarget(child: Container()),
      throwsAssertionError,
    );
  });

  test('Portal required either portalBuilder or portal', () {
    // TODO:
  });

  testWidgets('Portal synchronously add portals to PortalProvider',
      (tester) async {
    final firstChild =
        Container(height: 42, width: 42, color: Colors.green.withOpacity(.5));
    final firstPortal =
        Container(height: 42, width: 42, color: Colors.red.withOpacity(.5));

    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          child: Center(
            child: PortalTarget(
              portalFollower: firstPortal,
              child: firstChild,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byWidget(firstPortal)),
      const Size(800, 600),
    );
    expect(
      tester.getCenter(find.byWidget(firstChild)),
      const Offset(400, 300),
    );

    await expectLater(find.byType(Portal), matchesGoldenFile('mounted.png'));
  });

  testWidgets(
      "portals aren't inserted if mounted is false, and visible can be changed any time",
      (tester) async {
    final portal = ValueNotifier(
      PortalTarget(
        visible: false,
        portalFollower: Builder(builder: (_) => throw Error()),
        child: const Text('firstChild'),
      ),
    );

    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          child: ValueListenableBuilder<Widget>(
            valueListenable: portal,
            builder: (_, value, __) => value,
          ),
        ),
      ),
    );

    expect(find.text('firstChild'), findsOneWidget);

    final portalChildElement = tester.element(find.text('firstChild'));

    portal.value = const PortalTarget(
      portalFollower: Text('secondPortal'),
      child: Text('secondChild'),
    );
    await tester.pump();

    expect(find.text('firstChild'), findsNothing);
    expect(find.text('secondPortal'), findsOneWidget);
    expect(find.text('secondChild'), findsOneWidget);

    expect(
      tester.element(find.text('secondChild')),
      equals(portalChildElement),
      reason: 'the child state must be preserved when toggling `visible`',
    );

    portal.value = PortalTarget(
      visible: false,
      portalFollower: Builder(builder: (_) => throw Error()),
      child: const Text('thirdChild'),
    );
    await tester.pump();

    expect(find.text('secondChild'), findsNothing);
    expect(find.text('secondPortal'), findsNothing);
    expect(find.text('thirdChild'), findsOneWidget);

    expect(
      tester.element(find.text('thirdChild')),
      equals(portalChildElement),
      reason: 'the child state must be preserved when toggling `visible`',
    );
  });

  testWidgets('Unmounting Portal removes it on PortalProvider synchronously',
      (tester) async {
    final child =
        Container(height: 42, width: 42, color: Colors.red.withOpacity(.5));
    final newChild =
        Container(height: 42, width: 42, color: Colors.purple.withOpacity(.5));
    final portalChild =
        Container(height: 42, width: 42, color: Colors.yellow.withOpacity(.5));

    final portal = ValueNotifier<Widget>(
      Center(
        child: PortalTarget(
          portalFollower: portalChild,
          child: Center(child: child),
        ),
      ),
    );

    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          child: ValueListenableBuilder<Widget>(
            valueListenable: portal,
            builder: (_, value, __) => value,
          ),
        ),
      ),
    );

    expect(find.byWidget(child), findsOneWidget);

    portal.value = Center(child: newChild);

    await tester.pump();

    expect(find.byWidget(child), findsNothing);
    expect(find.byWidget(portalChild), findsNothing);
    expect(find.byWidget(newChild), findsOneWidget);

    await expectLater(find.byType(Portal), matchesGoldenFile('unmounted.png'));
  });

  testWidgets('throws if no Portal was found', (tester) async {
    await tester.pumpWidget(
      const PortalTarget(
        closeDuration: Duration(seconds: 5),
        portalFollower: Text('portal', textDirection: TextDirection.ltr),
        child: Text('child', textDirection: TextDirection.ltr),
      ),
    );

    final dynamic exception = tester.takeException();
    expect(exception, isA<PortalNotFoundError>());
    expect(
      exception.toString(),
      equals('Error: Could not find a Portal above this '
          'PortalTarget(debugName: null, portalCandidateLabels=[PortalLabel.main]).\n'),
    );
  });

  testWidgets('hiding two entries at once', (tester) async {
    final notifier = ValueNotifier(true);

    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          child: ValueListenableBuilder<bool>(
            valueListenable: notifier,
            builder: (c, value, _) {
              return PortalTarget(
                visible: value,
                portalFollower: Container(
                  color: Colors.red.withAlpha(122),
                ),
                child: Center(
                  child: PortalTarget(
                    visible: value,
                    portalFollower: Container(
                      height: 50,
                      width: 50,
                      color: Colors.blue,
                    ),
                    anchor: const Aligned(
                      follower: Alignment.bottomCenter,
                      target: Alignment.topCenter,
                    ),
                    child: Container(
                      height: 50,
                      width: 50,
                      color: Colors.yellow,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await expectLater(find.byType(Boilerplate),
        matchesGoldenFile('hiding_multiple_entries/0.png'));

    notifier.value = false;

    await tester.pump();

    await expectLater(find.byType(Boilerplate),
        matchesGoldenFile('hiding_multiple_entries/1.png'));
  });

  testWidgets('visible defaults to true', (tester) async {
    final child =
        Container(height: 42, width: 42, color: Colors.red.withOpacity(.5));
    final portal =
        Container(height: 42, width: 42, color: Colors.yellow.withOpacity(.5));

    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          child: Center(
            child: PortalTarget(
              portalFollower: portal,
              child: child,
            ),
          ),
        ),
      ),
    );

    expect(find.byWidget(child), findsOneWidget);
    expect(find.byWidget(portal), findsOneWidget);

    await expectLater(
      find.byType(Portal),
      matchesGoldenFile('visible_default.png'),
    );
  });

  testWidgets(
      'can insert a portal without rebuilding PortalProvider at the same time',
      (tester) async {
    final first =
        Container(height: 42, width: 42, color: Colors.green.withOpacity(.5));
    final second =
        Container(height: 42, width: 42, color: Colors.red.withOpacity(.5));
    final portal =
        Container(height: 42, width: 42, color: Colors.yellow.withOpacity(.5));

    final child = ValueNotifier<Widget>(first);
    final builder = ValueListenableBuilder<Widget>(
      valueListenable: child,
      builder: (_, child, __) => child,
    );

    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          child: Center(child: builder),
        ),
      ),
    );

    expect(find.byWidget(first), findsOneWidget);

    child.value = PortalTarget(
      portalFollower: portal,
      child: second,
    );
    await tester.pump();

    expect(find.byWidget(first), findsNothing);
    expect(find.byWidget(second), findsOneWidget);
    expect(find.byWidget(portal), findsOneWidget);
    await expectLater(
      find.byType(Portal),
      matchesGoldenFile('mounted_no_rebuild.png'),
    );
  });

  testWidgets('clicking on portal if above child clicks only the portal',
      (tester) async {
    var portalClickCount = 0;
    var childClickCount = 0;

    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          child: PortalTarget(
            portalFollower: ElevatedButton(
              onPressed: () => portalClickCount++,
              child: const Text('portal'),
            ),
            child: ElevatedButton(
              onPressed: () => childClickCount++,
              child: const Text('child'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('child'));

    expect(portalClickCount, equals(1));
    expect(childClickCount, equals(0));
  });

  // #65
  testWidgets('localToGlobal when portal is shifted', (tester) async {
    tester.view.physicalSize = const Size(300, 300);
    addTearDown(tester.view.resetPhysicalSize);

    final containerKey = GlobalKey();
    final portalFollowerKey = GlobalKey();

    await tester.pumpWidget(
      Container(
        key: containerKey,
        color: Colors.white,
        padding: const EdgeInsets.all(10),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Portal(
            child: PortalTarget(
              anchor: const Aligned(
                target: Alignment.bottomLeft,
                follower: Alignment.bottomLeft,
              ),
              portalFollower: Container(
                key: portalFollowerKey,
                width: 20,
                height: 20,
                color: Colors.green,
              ),
              child: Container(
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(find.byKey(containerKey),
        matchesGoldenFile('local_to_global_when_shifted.png'));

    final portalFollowerRenderBox =
        portalFollowerKey.currentContext!.findRenderObject()! as RenderBox;
    expect(portalFollowerRenderBox.localToGlobal(Offset.zero),
        const Offset(10, 70));
    expect(portalFollowerRenderBox.globalToLocal(Offset.zero),
        const Offset(-10, -70));
  });

  // #64
  testWidgets('click when portal is shifted', (tester) async {
    tester.view.physicalSize = const Size(300, 300);
    addTearDown(tester.view.resetPhysicalSize);

    final containerKey = GlobalKey();
    final pointerDownEvents = <PointerDownEvent>[];

    await tester.pumpWidget(
      Container(
        key: containerKey,
        color: Colors.white,
        padding: const EdgeInsets.all(10),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Portal(
            child: PortalTarget(
              anchor: const Aligned(
                target: Alignment.bottomLeft,
                follower: Alignment.bottomLeft,
              ),
              portalFollower: Listener(
                onPointerDown: pointerDownEvents.add,
                child: Container(
                  width: 20,
                  height: 20,
                  color: Colors.green,
                ),
              ),
              child: Container(
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(const Offset(25, 85));

    await expectLater(
        find.byKey(containerKey), matchesGoldenFile('click_when_shifted.png'));

    final event = pointerDownEvents.single;
    expect(event.localPosition, const Offset(15, 15));
    expect(event.position, const Offset(25, 85));
  });

  testWidgets('if portal is not above child, we can click on both',
      (tester) async {
    var portalClickCount = 0;
    var childClickCount = 0;

    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          // center the entry otherwise the portal is outside the screen
          child: Center(
            child: PortalTarget(
              anchor: const Aligned(
                follower: Alignment.bottomCenter,
                target: Alignment.topCenter,
              ),
              portalFollower: ElevatedButton(
                onPressed: () => portalClickCount++,
                child: const Text('portal'),
              ),
              child: ElevatedButton(
                onPressed: () => childClickCount++,
                child: const Text('child'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('child'));

    expect(portalClickCount, equals(0));
    expect(childClickCount, equals(1));

    await tester.tap(find.text('portal'));

    expect(childClickCount, equals(1));
    expect(portalClickCount, equals(1));
  });

  testWidgets('alignment/size', (tester) async {
    const portalKey = Key('portal');
    const childKey = Key('child');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Portal(
          child: Align(
            alignment: Alignment.topLeft,
            child: PortalTarget(
              anchor: Aligned(
                  follower: Alignment.topLeft, target: Alignment.bottomLeft),
              portalFollower: SizedBox(key: portalKey, height: 42, width: 24),
              child: SizedBox(key: childKey, height: 10, width: 10),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(childKey)),
      equals(const Size(10, 10)),
    );
    expect(tester.getTopLeft(find.byKey(childKey)), Offset.zero);

    expect(
      tester.getSize(find.byKey(portalKey)),
      equals(const Size(24, 42)),
    );
    expect(
      tester.getTopLeft(find.byKey(portalKey)),
      equals(const Offset(0, 10)),
    );

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Portal(
          child: Align(
            alignment: Alignment.topRight,
            child: PortalTarget(
              anchor: Aligned(
                follower: Alignment.topRight,
                target: Alignment.bottomRight,
              ),
              portalFollower: SizedBox(key: portalKey, height: 24, width: 42),
              child: SizedBox(key: childKey, height: 20, width: 20),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(childKey)),
      equals(const Size(20, 20)),
    );
    expect(
      tester.getTopRight(find.byKey(childKey)),
      equals(const Offset(800, 0)),
    );

    expect(
      tester.getSize(find.byKey(portalKey)),
      equals(const Size(42, 24)),
    );
    expect(
      tester.getTopRight(find.byKey(portalKey)),
      equals(const Offset(800, 20)),
    );

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Portal(
          child: Align(
            alignment: Alignment.bottomRight,
            child: PortalTarget(
              anchor: Aligned(
                follower: Alignment.bottomRight,
                target: Alignment.topRight,
              ),
              portalFollower: SizedBox(key: portalKey, height: 20, width: 20),
              child: SizedBox(key: childKey, height: 10, width: 10),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(childKey)),
      equals(const Size(10, 10)),
    );
    expect(
      tester.getBottomRight(find.byKey(childKey)),
      equals(const Offset(800, 600)),
    );

    expect(
      tester.getSize(find.byKey(portalKey)),
      equals(const Size(20, 20)),
    );
    expect(
      tester.getBottomRight(find.byKey(portalKey)),
      equals(const Offset(800, 600 - 10.0)),
    );
  });

  testWidgets('defaults to fill if no anchor are specified', (tester) async {
    const portalKey = Key('portal');
    const childKey = Key('child');

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Portal(
          child: Align(
            child: PortalTarget(
              portalFollower: SizedBox(key: portalKey, height: 20, width: 20),
              child: SizedBox(key: childKey, height: 10, width: 10),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(childKey)),
      equals(const Size(10, 10)),
    );
    expect(
      tester.getCenter(find.byKey(childKey)),
      equals(const Offset(800 / 2, 600 / 2)),
    );

    expect(
      tester.getSize(find.byKey(portalKey)),
      equals(const Size(800, 600)),
    );
    expect(
      tester.getTopLeft(find.byKey(portalKey)),
      equals(Offset.zero),
    );
  });

  testWidgets('click works when switching between anchor/fill', (tester) async {
    const child = Text('a', textDirection: TextDirection.ltr);
    const portalKey = Key('portal');
    const childKey = Key('child');

    var portalClickCount = 0;
    var childClickCount = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Portal(
          child: Center(
            child: PortalTarget(
              portalFollower: GestureDetector(
                key: portalKey,
                onTap: () => portalClickCount++,
                child: child,
              ),
              child: GestureDetector(
                key: childKey,
                onTap: () => childClickCount++,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(childKey));

    expect(portalClickCount, equals(1));
    expect(childClickCount, equals(0));

    await tester.tapAt(Offset.zero);

    expect(portalClickCount, equals(2));
    expect(childClickCount, equals(0));

    portalClickCount = 0;
    childClickCount = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Portal(
          child: Center(
            child: PortalTarget(
              anchor: const Aligned(
                follower: Alignment.bottomCenter,
                target: Alignment.topCenter,
              ),
              portalFollower: GestureDetector(
                key: portalKey,
                onTap: () => portalClickCount++,
                child: child,
              ),
              child: GestureDetector(
                key: childKey,
                onTap: () => childClickCount++,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(childKey));

    expect(portalClickCount, equals(0));
    expect(childClickCount, equals(1));

    await tester.tapAt(Offset.zero);

    expect(portalClickCount, equals(0));
    expect(childClickCount, equals(1));

    await tester.tap(find.byKey(portalKey));

    expect(portalClickCount, equals(1));
    expect(childClickCount, equals(1));

    portalClickCount = 0;
    childClickCount = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Portal(
          child: Center(
            child: PortalTarget(
              portalFollower: GestureDetector(
                key: portalKey,
                onTap: () => portalClickCount++,
                child: child,
              ),
              child: GestureDetector(
                key: childKey,
                onTap: () => childClickCount++,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(childKey));

    expect(portalClickCount, equals(1));
    expect(childClickCount, equals(0));

    await tester.tapAt(Offset.zero);

    expect(portalClickCount, equals(2));
    expect(childClickCount, equals(0));
  });

  testWidgets('anchor not null then null still clicks', (tester) async {
    var didClickChild = false;
    var didClickPortal = false;

    final portal = GestureDetector(
      onTap: () => didClickPortal = true,
      child: const SizedBox(
        height: 40,
        width: 40,
        child: Text('portal'),
      ),
    );
    final child = GestureDetector(
      onTap: () => didClickChild = true,
      child: const SizedBox(
        height: 40,
        width: 40,
        child: Text('child'),
      ),
    );

    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          child: Center(
            child: PortalTarget(
              anchor: const Aligned(
                follower: Alignment.bottomCenter,
                target: Alignment.topCenter,
              ),
              portalFollower: portal,
              child: child,
            ),
          ),
        ),
      ),
    );

    expect(find.text('child'), findsOneWidget);
    expect(
      tester.getCenter(find.byWidget(child)),
      const Offset(800 / 2, 600 / 2),
    );
    expect(
      tester.getCenter(find.byWidget(portal)),
      const Offset(800 / 2, 600 / 2 - 40),
    );
    expect(didClickChild, isFalse);
    await tester.tap(find.text('child'));
    expect(didClickChild, isTrue);

    expect(didClickPortal, isFalse);
    await tester.tap(find.text('portal'));
    expect(didClickPortal, isTrue);

    didClickChild = false;
    didClickPortal = false;

    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          child: Center(
            child: PortalTarget(
              portalFollower:
                  Align(alignment: Alignment.topLeft, child: portal),
              child: child,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getCenter(find.byWidget(child)),
      const Offset(800 / 2, 600 / 2),
    );
    expect(
      tester.getTopLeft(find.byWidget(portal)),
      Offset.zero,
    );
    expect(tester.getSize(find.byWidget(portal)), const Size(40, 40));
    expect(find.text('child'), findsOneWidget);
    expect(didClickChild, isFalse);
    await tester.tap(find.text('child'));
    expect(didClickChild, isTrue);

    expect(didClickPortal, isFalse);
    await tester.tap(find.text('portal'));
    expect(didClickPortal, isTrue);
  });

  testWidgets('portals can fill the Portal', (tester) async {
    final portal = Container();
    await tester.pumpWidget(
      Portal(
        child: Center(
          child: PortalTarget(
            portalFollower: portal,
            child: const Text('child', textDirection: TextDirection.ltr),
          ),
        ),
      ),
    );

    expect(find.text('child'), findsOneWidget);
    final portalFinder = find.byWidget(portal);
    expect(portalFinder, findsOneWidget);
    expect(tester.getTopLeft(portalFinder), Offset.zero);
    expect(tester.getBottomRight(portalFinder), const Offset(800, 600));
  });

  testWidgets('Portal can be added above navigator but under MaterialApp',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => Portal(child: child!),
        home: const PortalTarget(
          portalFollower: Text('portal'),
          child: Text('child'),
        ),
      ),
    );

    expect(find.text('child'), findsOneWidget);
    expect(find.text('portal'), findsOneWidget);
  });

  testWidgets('Portal can be added above navigator but under CupertinoApp',
      (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        builder: (_, child) => Portal(child: child!),
        home: const PortalTarget(
          portalFollower: Text('portal'),
          child: Text('child'),
        ),
      ),
    );

    expect(find.text('child'), findsOneWidget);
    expect(find.text('portal'), findsOneWidget);
  });

  testWidgets(
      'both entry and modal rebuilds within the same frame with layoutbuilder between portal and entry',
      (tester) async {
    final entryNotifier = ValueNotifier(0);
    final mainNotifier = ValueNotifier(0);
    final entryBuild = EntryBuildSpy();

    await tester.pumpWidget(
      Portal(
        child: Center(
          child: ValueListenableBuilder<int>(
            valueListenable: mainNotifier,
            builder: (c, value, _) {
              return LayoutBuilder(
                builder: (_, __) {
                  return PortalTarget(
                    portalFollower: ValueListenableBuilder<int>(
                      valueListenable: entryNotifier,
                      builder: (_, value2, __) {
                        entryBuild(value, value2);
                        return Text(
                          '$value $value2',
                          textDirection: TextDirection.ltr,
                        );
                      },
                    ),
                    child: Text('$value', textDirection: TextDirection.ltr),
                  );
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
    expect(find.text('0 0'), findsOneWidget);
    expect(entryBuild.calls, const [EntryBuildSpyCall(0, 0)]);
    entryBuild.calls.clear();

    mainNotifier.value++;
    entryNotifier.value++;
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('1 1'), findsOneWidget);
    // https://github.com/fzyzcjy/flutter_portal/pull/113.
    // expect(entryBuild.calls, const [EntryBuildSpyCall(0, 1), EntryBuildSpyCall(1, 1)]);    
  });

  testWidgets('layout builder between portal and entry on first build',
      (tester) async {
    await tester.pumpWidget(Portal(
      child: LayoutBuilder(
        builder: (_, __) {
          return const PortalTarget(
            portalFollower: Text('portal', textDirection: TextDirection.ltr),
            child: Text('child', textDirection: TextDirection.ltr),
          );
        },
      ),
    ));

    expect(find.text('child'), findsOneWidget);
    expect(find.text('portal'), findsOneWidget);
  });

  testWidgets(
      'layout builder between portal and entry without rebuilding portl',
      (tester) async {
    final notifier = ValueNotifier<Widget>(
      const Text('child', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Portal(
        child: ValueListenableBuilder<Widget>(
          valueListenable: notifier,
          builder: (c, child, _) => child,
        ),
      ),
    );

    expect(find.text('child'), findsOneWidget);
    expect(find.text('child2'), findsNothing);
    expect(find.text('portal'), findsNothing);

    notifier.value = LayoutBuilder(
      builder: (_, __) {
        return const PortalTarget(
          portalFollower: Text('portal', textDirection: TextDirection.ltr),
          child: Text('child2', textDirection: TextDirection.ltr),
        );
      },
    );
    await tester.pump();

    expect(find.text('child'), findsNothing);
    expect(find.text('child2'), findsOneWidget);
    expect(find.text('portal'), findsOneWidget);
  });

  testWidgets('handles reparenting with GlobalKey', (tester) async {
    // final firstPortal = UniqueKey();
    // final secondPortal = UniqueKey();
    //
    // final entryKey = GlobalKey();
    //
    // await tester.pumpWidget(
    //   Row(
    //     textDirection: TextDirection.ltr,
    //     children: <Widget>[
    //       Portal(
    //         key: firstPortal,
    //         child: PortalTarget(
    //           key: entryKey,
    //           portalFollower: Container(),
    //           child: Container(),
    //         ),
    //       ),
    //       Portal(key: secondPortal, child: Container()),
    //     ],
    //   ),
    // );
    //
    // final firstPortalElement =
    //     tester.element(find.byKey(firstPortal)) as PortalElement;
    // final secondPortalElement =
    //     tester.element(find.byKey(secondPortal)) as PortalElement;
    //
    // expect(firstPortalElement.theater.entries.length, 1);
    // expect(firstPortalElement.theater.renderObject.builders.length, 1);
    // expect(firstPortalElement.theater.renderObject.childCount, 1);
    // expect(secondPortalElement.theater.entries.length, 0);
    // expect(secondPortalElement.theater.renderObject.builders.length, 0);
    // expect(secondPortalElement.theater.renderObject.childCount, 0);
    //
    // await tester.pumpWidget(
    //   Row(
    //     textDirection: TextDirection.ltr,
    //     children: <Widget>[
    //       Portal(
    //         key: firstPortal,
    //         child: Container(),
    //       ),
    //       Portal(
    //         key: secondPortal,
    //         child: PortalTarget(
    //           key: entryKey,
    //           portalFollower: Container(),
    //           child: Container(),
    //         ),
    //       ),
    //     ],
    //   ),
    // );
    //
    // expect(firstPortalElement.theater.entries.length, 0);
    // expect(firstPortalElement.theater.renderObject.builders.length, 0);
    // expect(firstPortalElement.theater.renderObject.childCount, 0);
    // expect(secondPortalElement.theater.entries.length, 1);
    // expect(secondPortalElement.theater.renderObject.builders.length, 1);
    // expect(secondPortalElement.theater.renderObject.childCount, 1);
    //
    // await tester.pumpWidget(
    //   Row(
    //     textDirection: TextDirection.ltr,
    //     children: <Widget>[
    //       Portal(
    //         key: firstPortal,
    //         child: PortalTarget(
    //           key: entryKey,
    //           portalFollower: Container(),
    //           child: Container(),
    //         ),
    //       ),
    //       Portal(key: secondPortal, child: Container()),
    //     ],
    //   ),
    // );
    //
    // expect(firstPortalElement.theater.entries.length, 1);
    // expect(firstPortalElement.theater.renderObject.builders.length, 1);
    // expect(firstPortalElement.theater.renderObject.childCount, 1);
    // expect(secondPortalElement.theater.entries.length, 0);
    // expect(secondPortalElement.theater.renderObject.builders.length, 0);
    // expect(secondPortalElement.theater.renderObject.childCount, 0);
  }, skip: true);

  testWidgets('clip overflow', (tester) async {}, skip: true);

  testWidgets('can have multiple portals', (tester) async {
    final topLeft = PortalTarget(
      portalFollower: const Align(alignment: Alignment.topLeft),
      child: Container(),
    );
    final topRight = PortalTarget(
      portalFollower: const Align(alignment: Alignment.topRight),
      child: Container(),
    );
    final bottomRight = PortalTarget(
      portalFollower: const Align(alignment: Alignment.bottomRight),
      child: Container(),
    );
    final bottomLeft = PortalTarget(
      portalFollower: const Align(alignment: Alignment.bottomLeft),
      child: Container(),
    );

    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          child: Stack(
            children: <Widget>[
              topLeft,
              topRight,
              bottomLeft,
              bottomRight,
            ],
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.byWidget(topLeft)), Offset.zero);
    expect(tester.getTopRight(find.byWidget(topRight)), const Offset(800, 0));
    expect(tester.getBottomRight(find.byWidget(bottomRight)),
        const Offset(800, 600));
    expect(
        tester.getBottomLeft(find.byWidget(bottomLeft)), const Offset(0, 600));
  });

  testWidgets(
      'click is applied in reverse order of portal addition (last click first)',
      (tester) async {
    var didClickFirst = false;
    var didClickSecond = false;
    await tester.pumpWidget(
      Portal(
        child: PortalTarget(
          portalFollower: GestureDetector(
            onTap: () => didClickFirst = true,
            child: const Text('first', textDirection: TextDirection.ltr),
          ),
          child: PortalTarget(
            portalFollower: Center(
              child: GestureDetector(
                onTap: () => didClickSecond = true,
                child: const Text('second', textDirection: TextDirection.ltr),
              ),
            ),
            child: const Text('child', textDirection: TextDirection.ltr),
          ),
        ),
      ),
    );

    expect(didClickFirst, isFalse);
    expect(didClickSecond, isFalse);

    await tester.tapAt(Offset.zero);

    expect(didClickFirst, isTrue);
    expect(didClickSecond, isFalse);

    didClickFirst = false;
    didClickSecond = false;
    await tester.tapAt(const Offset(800 / 2, 600 / 2));

    expect(didClickFirst, isFalse);
    expect(didClickSecond, isTrue);
  });

  // #17
  testWidgets('overlay partially follow the target in one axis',
      (tester) async {
    tester.view.physicalSize = const Size(300, 300);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          child: Container(
            color: Colors.white,
            child: Stack(
              children: [
                Positioned(
                  top: 20,
                  left: 20,
                  width: 100,
                  height: 20,
                  child: PortalTarget(
                    anchor: const Aligned(
                      follower: Alignment.center,
                      target: Alignment.center,
                      portal: Alignment.center,
                      alignToPortal: AxisFlag(x: true),
                    ),
                    portalFollower: Container(
                      width: 100,
                      height: 10,
                      color: Colors.green,
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 4,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                    child: Container(
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await expectLater(
        find.byType(Portal), matchesGoldenFile('partially_follow.png'));
  });

  // #67
  testWidgets('shift portal follower to be inside the bounds of portal',
      (tester) async {
    tester.view.physicalSize = const Size(300, 300);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          child: Container(
            color: Colors.blue.shade300,
            child: Stack(
              children: [
                Positioned(
                  top: -10,
                  left: 20,
                  width: 100,
                  height: 50,
                  child: PortalTarget(
                    anchor: const Aligned(
                      follower: Alignment.topCenter,
                      target: Alignment.topCenter,
                      shiftToWithinBound: AxisFlag(y: true),
                    ),
                    portalFollower: Container(
                      width: 100,
                      height: 20,
                      color: Colors.green,
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 4,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                    child: Container(
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await expectLater(
        find.byType(Portal), matchesGoldenFile('shift_to_within_bound.png'));
  });

  testWidgets('portals paints in order of addition (last paints last)',
      (tester) async {
    tester.view.physicalSize = const Size(300, 300);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      Portal(
        child: PortalTarget(
          portalFollower: Container(
            margin: const EdgeInsets.all(10),
            color: Colors.red,
          ),
          child: PortalTarget(
            portalFollower: Center(
              child: Container(
                height: 30,
                width: 30,
                color: Colors.blue,
              ),
            ),
            child: Container(color: Colors.yellow),
          ),
        ),
      ),
    );

    await expectLater(
        find.byType(Portal), matchesGoldenFile('paint_order.jpg'));
  });

  testWidgets('PortalTarget can choose non-nearest ancestor Portal',
      (tester) async {
    tester.view.physicalSize = const Size(300, 300);
    addTearDown(tester.view.resetPhysicalSize);

    const firstPortal = PortalLabel('first');
    const secondPortal = PortalLabel('second');
    expect(firstPortal != secondPortal, true);

    final containerKey = GlobalKey();

    Widget child = Container(color: Colors.purple.withAlpha(50));

    child = PortalTarget(
      // should put to [firstPortal], thus be higher than [secondPortal] in z-index
      portalCandidateLabels: const [firstPortal],
      anchor: const Aligned(
        follower: Alignment.topLeft,
        target: Alignment.topLeft,
      ),
      portalFollower: Container(
        height: 30,
        width: 20,
        color: Colors.yellow,
      ),
      child: child,
    );
    child = PortalTarget(
      // should put to [secondPortal]
      portalCandidateLabels: const [secondPortal],
      anchor: const Aligned(
        follower: Alignment.topLeft,
        target: Alignment.topLeft,
      ),
      portalFollower: Container(
        height: 25,
        width: 25,
        color: Colors.orange,
      ),
      child: child,
    );
    child = PortalTarget(
      // should put to [firstPortal], thus be higher than [secondPortal] in z-index
      portalCandidateLabels: const [firstPortal],
      anchor: const Aligned(
        follower: Alignment.topLeft,
        target: Alignment.topLeft,
      ),
      portalFollower: Container(
        height: 20,
        width: 30,
        color: Colors.red,
      ),
      child: child,
    );

    await tester.pumpWidget(
      Boilerplate(
        child: Container(
          key: containerKey,
          child: Portal(
            labels: const [firstPortal],
            child: Container(
              color: Colors.blue.withAlpha(50),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Portal(
                  labels: const [secondPortal],
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(find.byKey(containerKey),
        matchesGoldenFile('non_nearest_ancestor.png'));
  });

  testWidgets('PortalTarget understands main scope', (tester) async {
    tester.view.physicalSize = const Size(300, 300);
    addTearDown(tester.view.resetPhysicalSize);

    final containerKey = GlobalKey();

    final inner = Portal(
      labels: const [PortalLabel.main],
      child: PortalTarget(
        // should be bound to **inner** "main"
        anchor: const Aligned(
          follower: Alignment.topRight,
          target: Alignment.topRight,
        ),
        portalFollower: Container(
          height: 30,
          width: 30,
          color: Colors.yellow,
        ),
        child: PortalTarget(
          // should be bound to "non-main"
          portalCandidateLabels: const [PortalLabel<String>('non-main')],
          anchor: const Aligned(
            follower: Alignment.topRight,
            target: Alignment.topRight,
          ),
          portalFollower: Container(
            height: 35,
            width: 25,
            color: Colors.teal,
          ),
          child: Container(
            color: Colors.blue.withAlpha(50),
            padding: const EdgeInsets.all(10),
            child: Portal(
              labels: const [PortalLabel.main],
              child: Container(color: Colors.purple.withAlpha(50)),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      Boilerplate(
        child: Container(
          key: containerKey,
          child: Portal(
            labels: const [PortalLabel.main],
            child: Container(
              color: Colors.blue.withAlpha(50),
              padding: const EdgeInsets.all(10),
              child: Portal(
                labels: const [PortalLabel<String>('non-main')],
                child: PortalTarget(
                  // should be bound to "non-main"
                  portalCandidateLabels: const [
                    PortalLabel<String>('non-main')
                  ],
                  anchor: const Aligned(
                    follower: Alignment.topLeft,
                    target: Alignment.topLeft,
                  ),
                  portalFollower: Container(
                    height: 20,
                    width: 40,
                    color: Colors.red,
                  ),
                  child: PortalTarget(
                    // should be bound to outer "main"
                    anchor: const Aligned(
                      follower: Alignment.topLeft,
                      target: Alignment.topLeft,
                    ),
                    portalFollower: Container(
                      height: 25,
                      width: 35,
                      color: Colors.orange,
                    ),
                    child: Container(
                      color: Colors.blue.withAlpha(50),
                      padding: const EdgeInsets.all(10),
                      child: inner,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
        find.byKey(containerKey), matchesGoldenFile('main_scope.png'));
  });

  // https://github.com/fzyzcjy/flutter_portal/issues/57
  testWidgets(
      'multi-Portal and nested-PortalFollower: PortalA - PortalB - TargetToPortalA - TargetToPortalB',
      (tester) async {
    tester.view.physicalSize = const Size(300, 300);
    addTearDown(tester.view.resetPhysicalSize);

    const first = PortalLabel('first');
    const second = PortalLabel('second');

    final boilerplateKey = GlobalKey();

    await tester.pumpWidget(
      Boilerplate(
        key: boilerplateKey,
        child: Portal(
          labels: const [first],
          child: Container(
            color: Colors.purple,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Portal(
              labels: const [second],
              child: Container(
                color: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: PortalTarget(
                  portalCandidateLabels: const [first],
                  anchor: const Aligned(
                      follower: Alignment.topLeft, target: Alignment.topLeft),
                  debugName: 'OuterTargetToFirstPortal',
                  portalFollower: Container(
                    color: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    width: 200,
                    height: 200,
                    child: PortalTarget(
                      portalCandidateLabels: const [second],
                      debugName: 'InnerTargetToSecondPortal',
                      anchor: const Aligned(
                          follower: Alignment.topLeft,
                          target: Alignment.topLeft),
                      portalFollower: Container(
                        color: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        width: 10,
                        height: 10,
                      ),
                      child: Container(
                        color: Colors.red,
                      ),
                    ),
                  ),
                  child: Container(
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final exception = tester.takeException() as SanityCheckNestedPortalError;
    // print('exception: $exception');
    expect(exception.info.selfDebugLabel, 'InnerTargetToSecondPortal');
    expect(exception.info.followerParentDebugLabel, 'OuterTargetToFirstPortal');
    expect(exception.info.selfScope.portalLabels, [second]);
    expect(exception.info.followerParentScope.portalLabels, [first]);
    expect(exception.info.portalLinkScopeAncestors.map((e) => e.portalLabels), [
      [second],
      [first]
    ]);
  });

  testWidgets(
      'multi-Portal and nested-PortalFollower: PortalA - PortalB - TargetToPortalB - TargetToPortalA',
      (tester) async {
    tester.view.physicalSize = const Size(300, 300);
    addTearDown(tester.view.resetPhysicalSize);

    const first = PortalLabel('first');
    const second = PortalLabel('second');

    final boilerplateKey = GlobalKey();

    await tester.pumpWidget(
      Boilerplate(
        key: boilerplateKey,
        child: Portal(
          labels: const [first],
          child: Container(
            color: Colors.purple,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Portal(
              labels: const [second],
              child: Container(
                color: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: PortalTarget(
                  portalCandidateLabels: const [second],
                  anchor: const Aligned(
                      follower: Alignment.topLeft, target: Alignment.topLeft),
                  debugName: 'OuterTargetToSecondPortal',
                  portalFollower: Container(
                    color: Colors.teal,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    width: 200,
                    height: 200,
                    child: PortalTarget(
                      portalCandidateLabels: const [first],
                      debugName: 'InnerTargetToFirstPortal',
                      anchor: const Aligned(
                          follower: Alignment.topLeft,
                          target: Alignment.topLeft),
                      portalFollower: Container(
                        color: Colors.orange,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        width: 10,
                        height: 10,
                      ),
                      child: Container(
                        color: Colors.red,
                      ),
                    ),
                  ),
                  child: Container(
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(find.byKey(boilerplateKey),
        matchesGoldenFile('multi_portal_nested_follower_1.png'));
  });

  testWidgets(
      'multi-Portal and nested-PortalFollower: PortalA - TargetToPortalA - PortalB - TargetToPortalB',
      (tester) async {
    tester.view.physicalSize = const Size(300, 300);
    addTearDown(tester.view.resetPhysicalSize);

    const first = PortalLabel('first');
    const second = PortalLabel('second');

    final boilerplateKey = GlobalKey();

    await tester.pumpWidget(
      Boilerplate(
        key: boilerplateKey,
        child: Portal(
          labels: const [first],
          child: Container(
            color: Colors.purple,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: PortalTarget(
              portalCandidateLabels: const [first],
              anchor: const Aligned(
                  follower: Alignment.topLeft, target: Alignment.topLeft),
              debugName: 'OuterTargetToFirstPortal',
              portalFollower: Container(
                color: Colors.blue,
                margin:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Portal(
                  labels: const [second],
                  child: Container(
                    color: Colors.teal,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    width: 150,
                    height: 150,
                    child: PortalTarget(
                      portalCandidateLabels: const [second],
                      debugName: 'InnerTargetToSecondPortal',
                      anchor: const Aligned(
                          follower: Alignment.topLeft,
                          target: Alignment.topLeft),
                      portalFollower: Container(
                        color: Colors.orange,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        width: 10,
                        height: 10,
                      ),
                      child: Container(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
              child: Container(
                color: Colors.green,
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(find.byKey(boilerplateKey),
        matchesGoldenFile('multi_portal_nested_follower_2.png'));
  });
}

class Boilerplate extends StatelessWidget {
  const Boilerplate({Key? key, this.child}) : super(key: key);

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: false),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: child,
      ),
    );
  }
}

mixin Noop {}

class TestPortal = Portal with Noop;

@immutable
class EntryBuildSpyCall {
  const EntryBuildSpyCall(this.value1, this.value2);

  final int value1;
  final int value2;

  @override
  bool operator ==(Object o) =>
      o is EntryBuildSpyCall && o.value1 == value1 && o.value2 == value2;

  @override
  int get hashCode => Object.hash(value1, value2);

  @override
  String toString() {
    return 'EntryBuildSpyCall($value1, $value2)';
  }
}

class EntryBuildSpy {
  final List<EntryBuildSpyCall> calls = [];

  void call(int value1, int value2) {
    calls.add(EntryBuildSpyCall(value1, value2));
  }
}
