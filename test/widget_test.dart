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
    print('');

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
  // TODO: visible defaults to true
  // TODO: Portal can be subclassed and PortalEntry can target it
  // TODO: test alignment
  // TODO: alignment defaults to center
  // TODO: portalEntries can fill the portal if desired
  // TODO: Portal handles reparenting (PortalProvider changing)
  // TODO: can insert a portal without rebuilding PortalProvider at the same time
  // TODO: click handling
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
