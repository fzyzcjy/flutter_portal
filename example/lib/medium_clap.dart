import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';

// This implements Medium's clap button

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (_, child) => Portal(child: child),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Example'),
        ),
        body: Center(
          child: ClapButton(),
        ),
      ),
    );
  }
}

class ClapButton extends StatefulWidget {
  ClapButton({Key key}) : super(key: key);

  @override
  _ClapButtonState createState() => _ClapButtonState();
}

class _ClapButtonState extends State<ClapButton> {
  int clapCount = 0;
  bool hasClappedRecently = false;
  Timer resetHasClappedRecentlyTimer;

  @override
  Widget build(BuildContext context) {
    return PortalEntry(
      visible: hasClappedRecently,
      // aligns the top-center of `child` with the bottom-center of `portal`
      childAnchor: Alignment.topCenter,
      portalAnchor: Alignment.bottomCenter,
      portal: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(40),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('$clapCount'),
        ),
      ),
      child: RaisedButton(
        onPressed: _clap,
        child: const Icon(Icons.plus_one),
      ),
    );
  }

  void _clap() {
    resetHasClappedRecentlyTimer?.cancel();

    resetHasClappedRecentlyTimer = Timer(
      const Duration(seconds: 2),
      () => setState(() => hasClappedRecently = false),
    );

    setState(() {
      hasClappedRecently = true;
      clapCount++;
    });
  }
}
