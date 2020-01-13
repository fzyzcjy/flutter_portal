import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemBuilder: (_, index) {
          return PortalEntry(
            portalAnchor: Alignment.centerLeft,
            childAnchor: Alignment.centerLeft,
            portal: RaisedButton(
              child: const Text('portal'),
              onPressed: () {
                print('portal clidk');
              },
            ),
            child: RaisedButton(
              onPressed: () {
                print('child clidk');
              },
              child: const Text('child'),
            ),
          );
        },
      ),
    );
  }
}
