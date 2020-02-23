import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_portal/flutter_portal.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final notifier = ValueNotifier<Widget>(const Text('first'));

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      notifier.value = PortalEntry(
        portal: const Text('overlay'),
        child: const Text('second'),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final builder = ValueListenableBuilder<Widget>(
      valueListenable: notifier,
      builder: (_, child, __) => child,
    );
    return Boilerplate(
      child: Portal(
        child: Center(child: builder),
      ),
    );
  }
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
