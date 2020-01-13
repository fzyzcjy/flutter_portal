import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_portal/flutter_portal.dart';

void main() => runApp(MyApp());

// This is a rudimentary tooltip built using `portal`

class MyTooptip extends StatefulWidget {
  const MyTooptip({Key key, this.label, this.child}) : super(key: key);
  final Widget child;
  final String label;

  @override
  _MyTooptipState createState() => _MyTooptipState();
}

class _MyTooptipState extends State<MyTooptip> {
  bool visible = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('hello world');
        setState(() {
          visible = !visible;
        });
      },
      child: PortalEntry(
        visible: visible,
        portalAnchor: Alignment.bottomCenter,
        childAnchor: Alignment.topCenter,
        portal: Card(
          color: Colors.grey.shade700,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(widget.label),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (_, child) => Portal(child: child),
      home: Scaffold(
        appBar: AppBar(title: const Text('tooltip example')),
        body: Center(
          child: MyTooptip(
            label: 'Tooltip',
            child: Card(
              color: Colors.red,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('click me to show a tooltip'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
