// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/src/portal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:mockito/mockito.dart';

void main() {
  testWidgets('PortalProvider updates child', (WidgetTester tester) async {
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
  test('PortalEntry requires a child', () {
    expect(
      () => PortalEntry(
        portal: Container(),
        child: null,
      ),
      throwsAssertionError,
    );
  });
  test('PortalEntry requires portal if visible is true ', () {
    expect(
      () => PortalEntry(
        visible: true,
        portal: null,
        child: Container(),
      ),
      throwsAssertionError,
    );
  });
  test('Portal required either portalBuilder or portal', () {
    // TODO:
  });
  testWidgets('Portal synchronously add portals to PortalProvider',
      (tester) async {
    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          child: Center(
            child: PortalEntry(
              visible: true,
              portal: const Text('firstPortal'),
              child: const Text('firstChild'),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.text('firstPortal')),
      const Size(800, 600),
    );
    expect(
      tester.getCenter(find.text('firstChild')),
      const Offset(400, 300),
    );
    expect(
      tester.getSize(find.text('firstChild')),
      const Size(140, 14),
    );
  });
  testWidgets(
      "portals aren't inserted if mounted is false, and visible can be changed any time",
      (tester) async {
    final portal = ValueNotifier(
      PortalEntry(
        visible: false,
        portal: Builder(builder: (_) => throw Error()),
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

    portal.value = PortalEntry(
      visible: true,
      portal: const Text('secondPortal'),
      child: const Text('secondChild'),
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

    portal.value = PortalEntry(
      visible: false,
      portal: Builder(builder: (_) => throw Error()),
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
    final portal = ValueNotifier<Widget>(
      Center(
        child: PortalEntry(
          visible: true,
          portal: const Text('portal'),
          child: const Center(child: Text('child')),
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

    expect(find.text('child'), findsOneWidget);

    portal.value = const Center(child: Text('newChild'));

    await tester.pump();

    expect(find.text('child'), findsNothing);
    expect(find.text('portal'), findsNothing);
    expect(find.text('newChild'), findsOneWidget);
  });
  testWidgets('throws if no PortalEntry were found', (tester) async {
    await tester.pumpWidget(
      PortalEntry(
        visible: true,
        portal: const Text('portal', textDirection: TextDirection.ltr),
        child: const Text('child', textDirection: TextDirection.ltr),
      ),
    );

    final dynamic exception = tester.takeException();
    expect(exception, isA<PortalNotFoundError>());
    expect(exception.toString(), equals('''
Error: Could not find a Portal above this PortalEntry<Portal>(portalAnchor: null, childAnchor: null, portal: Text, child: Text).
'''));
  });
  testWidgets('visible defaults to true', (tester) async {
    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          child: PortalEntry(
            portal: const Text('portal', textDirection: TextDirection.ltr),
            child: const Text('child', textDirection: TextDirection.ltr),
          ),
        ),
      ),
    );

    expect(find.text('child'), findsOneWidget);
    expect(find.text('portal'), findsOneWidget);
  }, skip: true);
  testWidgets(
      'can insert a portal without rebuilding PortalProvider at the same time',
      (tester) async {
    Widget child = const Text('first');
    final builder = Builder(builder: (_) => child);

    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          child: builder,
        ),
      ),
    );
    final element = tester.element(find.byWidget(builder));

    expect(find.text('first'), findsOneWidget);

    element.markNeedsBuild();
    child = PortalEntry(
      portal: const Text('portal'),
      child: const Text('second'),
    );

    await tester.pump();

    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
    expect(find.text('portal'), findsOneWidget);
  }, skip: true);
  testWidgets('clicking on portal if above child clicks only the portal',
      (tester) async {
    var portalClickCount = 0;
    var childClickCount = 0;

    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          child: PortalEntry(
            portal: RaisedButton(
              onPressed: () => portalClickCount++,
              child: const Text('portal'),
            ),
            child: RaisedButton(
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
  }, skip: true);
  testWidgets('if portal is not above child, we can click on both',
      (tester) async {
    var portalClickCount = 0;
    var childClickCount = 0;

    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          // center the entry otherwise the portal is outside the screen
          child: Center(
            child: PortalEntry(
              portalAnchor: Alignment.bottomCenter,
              childAnchor: Alignment.topCenter,
              portal: RaisedButton(
                onPressed: () => portalClickCount++,
                child: const Text('portal'),
              ),
              child: RaisedButton(
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
  }, skip: true);
  testWidgets('alignment/size', (tester) async {
    const portalKey = Key('portal');
    const childKey = Key('child');
    await tester.pumpWidget(
      Portal(
        child: Align(
          alignment: Alignment.topLeft,
          child: PortalEntry(
            portalAnchor: Alignment.topLeft,
            childAnchor: Alignment.bottomLeft,
            portal: Container(key: portalKey, height: 42, width: 24),
            child: Container(key: childKey, height: 10, width: 10),
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
      Portal(
        child: Align(
          alignment: Alignment.topRight,
          child: PortalEntry(
            portalAnchor: Alignment.topRight,
            childAnchor: Alignment.bottomRight,
            portal: Container(key: portalKey, height: 24, width: 42),
            child: Container(key: childKey, height: 20, width: 20),
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
      Portal(
        child: Align(
          alignment: Alignment.bottomRight,
          child: PortalEntry(
            childAnchor: Alignment.topRight,
            portalAnchor: Alignment.bottomRight,
            portal: Container(key: portalKey, height: 20, width: 20),
            child: Container(key: childKey, height: 10, width: 10),
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
  }, skip: true);

  testWidgets('defaults to fill if no anchor are specified', (tester) async {
    const portalKey = Key('portal');
    const childKey = Key('child');

    await tester.pumpWidget(
      Portal(
        child: Align(
          alignment: Alignment.center,
          child: PortalEntry(
            portal: Container(key: portalKey, height: 20, width: 20),
            child: Container(key: childKey, height: 10, width: 10),
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
  }, skip: true);
  testWidgets('click works when switching between anchor/fill', (tester) async {
    final child = const Text('a', textDirection: TextDirection.ltr);
    const portalKey = Key('portal');
    const childKey = Key('child');

    var portalClickCount = 0;
    var childClickCount = 0;

    await tester.pumpWidget(
      Portal(
        child: Center(
          child: PortalEntry(
            portal: GestureDetector(
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
      Portal(
        child: Center(
          child: PortalEntry(
            childAnchor: Alignment.bottomCenter,
            portalAnchor: Alignment.topCenter,
            portal: GestureDetector(
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
      Portal(
        child: Center(
          child: PortalEntry(
            portal: GestureDetector(
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
    );

    await tester.tap(find.byKey(childKey));

    expect(portalClickCount, equals(1));
    expect(childClickCount, equals(0));

    await tester.tapAt(Offset.zero);

    expect(portalClickCount, equals(2));
    expect(childClickCount, equals(0));
  }, skip: true);
  testWidgets('anchor not null then null still clicks', (tester) async {
    var didClickChild = false;
    var didClickPortal = false;

    final portal = GestureDetector(
      onTap: () => didClickPortal = true,
      child: Container(
        height: 40,
        width: 40,
        child: const Text('portal'),
      ),
    );
    final child = GestureDetector(
      onTap: () => didClickChild = true,
      child: Container(
        height: 40,
        width: 40,
        child: const Text('child'),
      ),
    );

    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          child: Center(
            child: PortalEntry(
              childAnchor: Alignment.topCenter,
              portalAnchor: Alignment.bottomCenter,
              portal: portal,
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
            child: PortalEntry(
              portal: Align(alignment: Alignment.topLeft, child: portal),
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
  }, skip: true);
  testWidgets('PortalEntry target its generic parameter', (tester) async {
    final portalKey = UniqueKey();

    await tester.pumpWidget(
      TestPortal(
        child: Center(
          child: Portal(
            child: PortalEntry<TestPortal>(
              // Fills the portal so that if it's added to TestPortal it'll be on the top-left
              // but if it's added to Portal, it'll start in the center of the screen.
              portal: Container(key: portalKey),
              child: const Text('child', textDirection: TextDirection.ltr),
            ),
          ),
        ),
      ),
    );

    expect(find.text('child'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(portalKey)),
      equals(Offset.zero),
    );
  }, skip: true);

  testWidgets(
      "PortalEntry doesn't fallback to Portal if generic doesn't exists",
      (tester) async {
    await tester.pumpWidget(
      Portal(
        child: PortalEntry<TestPortal>(
          portal: const Text('portal', textDirection: TextDirection.ltr),
          child: Container(),
        ),
      ),
    );

    expect(tester.takeException(), isA<PortalNotFoundError>());
  }, skip: true);

  testWidgets('portals can fill the Portal', (tester) async {
    final portal = Container();
    await tester.pumpWidget(
      Portal(
        child: Center(
          child: PortalEntry<Portal>(
            portal: portal,
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
  }, skip: true);

  testWidgets('Portal can be added above navigator but under MaterialApp',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => Portal(child: child),
        home: PortalEntry(
          portal: const Text('portal'),
          child: const Text('child'),
        ),
      ),
    );

    expect(find.text('child'), findsOneWidget);
    expect(find.text('portal'), findsOneWidget);
  }, skip: true);
  testWidgets('Portal can be added above navigator but under CupertinoApp',
      (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        builder: (_, child) => Portal(child: child),
        home: PortalEntry(
          portal: const Text('portal'),
          child: const Text('child'),
        ),
      ),
    );

    expect(find.text('child'), findsOneWidget);
    expect(find.text('portal'), findsOneWidget);
  }, skip: true);
  testWidgets('is one anchor is null, the other one must be', (tester) async {
    expect(
      () => PortalEntry(
        portalAnchor: null,
        childAnchor: Alignment.center,
        portal: Container(),
        child: Container(),
      ),
      throwsAssertionError,
    );
    expect(
      () => PortalEntry(
        portalAnchor: Alignment.center,
        childAnchor: null,
        portal: Container(),
        child: Container(),
      ),
      throwsAssertionError,
    );

    PortalEntry(
      childAnchor: null,
      portalAnchor: null,
      portal: Container(),
      child: Container(),
    );
  }, skip: true);

  testWidgets(
      'both entry and modal rebuilds withint the same frame with layoutbuilder between portal and entry',
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
                  return PortalEntry(
                    portal: ValueListenableBuilder<int>(
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
    verify(entryBuild(0, 0)).called(1);
    verifyNoMoreInteractions(entryBuild);

    mainNotifier.value++;
    entryNotifier.value++;
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('1 1'), findsOneWidget);
    verifyInOrder([
      entryBuild(0, 1),
      entryBuild(1, 1),
    ]);
    verifyNoMoreInteractions(entryBuild);
  }, skip: true);
  testWidgets('layout builder between portal and entry on first build',
      (tester) async {
    await tester.pumpWidget(Portal(
      child: LayoutBuilder(
        builder: (_, __) {
          return PortalEntry(
            portal: const Text('portal', textDirection: TextDirection.ltr),
            child: const Text('child', textDirection: TextDirection.ltr),
          );
        },
      ),
    ));

    expect(find.text('child'), findsOneWidget);
    expect(find.text('portal'), findsOneWidget);
  }, skip: true);
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
        return PortalEntry(
          portal: const Text('portal', textDirection: TextDirection.ltr),
          child: const Text('child2', textDirection: TextDirection.ltr),
        );
      },
    );
    await tester.pump();

    expect(find.text('child'), findsNothing);
    expect(find.text('child2'), findsOneWidget);
    expect(find.text('portal'), findsOneWidget);
  }, skip: true);
  testWidgets('handles reparenting with GlobalKey', (tester) async {
    // final firstPortal = UniqueKey();
    // final secondPortal = UniqueKey();

    // final entryKey = GlobalKey();

    // await tester.pumpWidget(
    //   Row(
    //     textDirection: TextDirection.ltr,
    //     children: <Widget>[
    //       Portal(
    //         key: firstPortal,
    //         child: PortalEntry(
    //           key: entryKey,
    //           portal: Container(),
    //           child: Container(),
    //         ),
    //       ),
    //       Portal(key: secondPortal, child: Container()),
    //     ],
    //   ),
    // );

    // final firstPortalElement =
    //     tester.element(find.byKey(firstPortal)) as PortalElement;
    // final secondPortalElement =
    //     tester.element(find.byKey(secondPortal)) as PortalElement;

    // expect(firstPortalElement.theater.entries.length, 1);
    // expect(firstPortalElement.theater.renderObject.builders.length, 1);
    // expect(firstPortalElement.theater.renderObject.childCount, 1);
    // expect(secondPortalElement.theater.entries.length, 0);
    // expect(secondPortalElement.theater.renderObject.builders.length, 0);
    // expect(secondPortalElement.theater.renderObject.childCount, 0);

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
    //         child: PortalEntry(
    //           key: entryKey,
    //           portal: Container(),
    //           child: Container(),
    //         ),
    //       ),
    //     ],
    //   ),
    // );

    // expect(firstPortalElement.theater.entries.length, 0);
    // expect(firstPortalElement.theater.renderObject.builders.length, 0);
    // expect(firstPortalElement.theater.renderObject.childCount, 0);
    // expect(secondPortalElement.theater.entries.length, 1);
    // expect(secondPortalElement.theater.renderObject.builders.length, 1);
    // expect(secondPortalElement.theater.renderObject.childCount, 1);

    // await tester.pumpWidget(
    //   Row(
    //     textDirection: TextDirection.ltr,
    //     children: <Widget>[
    //       Portal(
    //         key: firstPortal,
    //         child: PortalEntry(
    //           key: entryKey,
    //           portal: Container(),
    //           child: Container(),
    //         ),
    //       ),
    //       Portal(key: secondPortal, child: Container()),
    //     ],
    //   ),
    // );

    // expect(firstPortalElement.theater.entries.length, 1);
    // expect(firstPortalElement.theater.renderObject.builders.length, 1);
    // expect(firstPortalElement.theater.renderObject.childCount, 1);
    // expect(secondPortalElement.theater.entries.length, 0);
    // expect(secondPortalElement.theater.renderObject.builders.length, 0);
    // expect(secondPortalElement.theater.renderObject.childCount, 0);
  }, skip: true);
  // TODO: clip overflow
  testWidgets('can have multiple portals', (tester) async {
    var topLeft = PortalEntry(
      portal: Align(alignment: Alignment.topLeft),
      child: Container(),
    );
    var topRight = PortalEntry(
      portal: Align(alignment: Alignment.topRight),
      child: Container(),
    );
    var bottomRight = PortalEntry(
      portal: Align(alignment: Alignment.bottomRight),
      child: Container(),
    );
    var bottomLeft = PortalEntry(
      portal: Align(alignment: Alignment.bottomLeft),
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
  }, skip: true);

  testWidgets(
      'click is applied in reverse order of portal addition (last click first)',
      (tester) async {
    var didClickFirst = false;
    var didClickSecond = false;
    await tester.pumpWidget(
      Portal(
        child: PortalEntry(
          portal: GestureDetector(
            onTap: () => didClickFirst = true,
            child: const Text('first', textDirection: TextDirection.ltr),
          ),
          child: PortalEntry(
            portal: Center(
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
  }, skip: true);
  testWidgets('portals paints in order of addition (last paints last)',
      (tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(300, 300);
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    await tester.pumpWidget(
      Portal(
        child: PortalEntry(
          portal: Container(color: Colors.red),
          child: PortalEntry(
            portal: Center(
              child: Container(
                height: 42,
                width: 42,
                color: Colors.blue,
              ),
            ),
            child: const Text('child', textDirection: TextDirection.ltr),
          ),
        ),
      ),
    );

    await expectLater(
        find.byType(Portal), matchesGoldenFile('paint_order.jpg'));
  }, skip: true);
}

class Boilerplate extends StatelessWidget {
  final Widget child;

  const Boilerplate({Key key, this.child}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }
}

mixin Noop {}
class TestPortal = Portal with Noop;

class EntryBuildSpy extends Mock {
  void call(int value1, int value2);
}
