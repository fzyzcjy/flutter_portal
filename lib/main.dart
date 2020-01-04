import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'portal.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PortalProvider(
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Flutter Demo Home Page'),
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
        child: Stack(
          children: [
            Positioned(
              top: offset.dy,
              left: offset.dx,
              child: Portal.builder(
                visible: true,
                portalBuilder: (c, providerSize, wrappedSize, offset) {
                  print(offset);
                  return DefaultTextStyle(
                    style: DefaultTextStyle.of(c).style,
                    child: Stack(
                      textDirection: TextDirection.ltr,
                      children: [
                        Positioned(
                          top: offset.dy - 40,
                          left: offset.dx,
                          child: Card(
                            elevation: 20,
                            color: Colors.lightBlue,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'this is a contextual overlay',
                                textDirection: TextDirection.ltr,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('drag me'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
