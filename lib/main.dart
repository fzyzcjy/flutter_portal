import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'portal.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Portal(
        child: MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Offset offset = Offset(100, 100);

  @override
  Widget build(BuildContext context) {
    bool condition = offset.dy < 300;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            offset += d.delta;
          });
        },
        child: PortalEntry(
          visible: true,
          portal: Center(
            child: Card(
              elevation: 20,
              color: Colors.lightBlue,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'this is a contextual overlay',
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ),
          child: const Card(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('drag me'),
            ),
          ),
        ),
      ),
    );
  }
}
