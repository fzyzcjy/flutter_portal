// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal/portal.dart';

void main() {
  testWidgets('PortalProvider updates child', (WidgetTester tester) async {
    await tester.pumpWidget(
      Portal(
        child: const Text(
          'first',
          textDirection: TextDirection.ltr,
        ),
      ),
    );

    expect(find.text('first'), findsOneWidget);
    expect(find.text('second'), findsNothing);

    await tester.pumpWidget(
      Portal(
        child: const Text(
          'second',
          textDirection: TextDirection.ltr,
        ),
      ),
    );

    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
  });
  test('Portal requires a child', () {
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
  test('Portal required either portalBuilder or portal', () {});
  testWidgets('Portal synchronously add portals to PortalProvider',
      (tester) async {
    await tester.pumpWidget(
      Boilerplate(
        child: Portal(
          child: PortalEntry(
            visible: true,
            portal: const Text('firstPortal'),
            child: const Text('firstChild'),
          ),
        ),
      ),
    );

    expect(find.text('firstChild'), findsOneWidget);
    expect(find.text('firstPortal'), findsOneWidget);
  });
  testWidgets(
      "portals aren't inserted if visible is false, and visible can be changed any time",
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
  testWidgets("doesn't throw if no Portal in ancestors but visible is false",
      (tester) async {
    await tester.pumpWidget(
      PortalEntry(
        visible: false,
        portal: const Text('portal', textDirection: TextDirection.ltr),
        child: const Text('child', textDirection: TextDirection.ltr),
      ),
    );

    expect(find.text('child'), findsOneWidget);
    expect(find.text('portal'), findsNothing);
  });
  testWidgets('throws if no PortalEntry were found', (tester) async {
    await tester.pumpWidget(
      PortalEntry(
        visible: true,
        portal: const Text('portal', textDirection: TextDirection.ltr),
        child: const Text('child', textDirection: TextDirection.ltr),
      ),
    );

    final exception = tester.takeException();
    expect(exception, isA<PortalNotFoundError>());
    expect(exception.toString(), equals('''
Error: Could not find a Portal above this PortalEntry<Portal>(visible, portalAnchor: center, childAnchor: center, portal: Text, child: Text).
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
  });
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
  });
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
            child: PortalEntry(
              portalAnchor: Alignment.bottomCenter,
              childAnchor: Alignment.topCenter,
              portal: RaisedButton(
                key: Key('portal'),
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
  });
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
      equals(const Size(20, 20)),
    );
    expect(
      tester.getCenter(find.byKey(portalKey)),
      equals(const Offset(800 / 2, 600 / 2)),
    );
  });

  // TODO: clip overflow

  // TODO: Portal can be subclassed and PortalEntry can target it
  // TODO: test alignment
  // TODO: alignment defaults to center
  // TODO: portalEntries can fill the portal if desired
  // TODO: Portal handles reparenting (PortalProvider changing)
  // TODO: infinite number of portals
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
