import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';

// a contextual menu

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
        body: Container(
          padding: const EdgeInsets.all(10),
          alignment: Alignment.centerLeft,
          child: ContextualMenuExample(),
        ),
      ),
    );
  }
}

class ContextualMenuExample extends StatefulWidget {
  ContextualMenuExample({Key key}) : super(key: key);

  @override
  _ContextualMenuExampleState createState() => _ContextualMenuExampleState();
}

class _ContextualMenuExampleState extends State<ContextualMenuExample> {
  bool showMenu = false;

  @override
  Widget build(BuildContext context) {
    return ModalEntry(
      visible: showMenu,
      onClose: () => setState(() => showMenu = false),
      childAnchor: Alignment.topRight,
      menuAnchor: Alignment.topLeft,
      menu: const Menu(
        children: [
          PopupMenuItem<void>(
            height: 42,
            child: Text('first'),
          ),
          PopupMenuItem<void>(
            height: 42,
            child: Text('second'),
          ),
        ],
      ),
      child: RaisedButton(
        onPressed: () => setState(() => showMenu = true),
        child: const Text('show menu'),
      ),
    );
  }
}

class Menu extends StatelessWidget {
  const Menu({
    Key key,
    @required this.children,
  }) : super(key: key);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Card(
        elevation: 8,
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}

class ModalEntry extends StatelessWidget {
  const ModalEntry({
    Key key,
    this.onClose,
    this.menu,
    this.visible,
    this.menuAnchor,
    this.childAnchor,
    this.child,
  }) : super(key: key);

  final VoidCallback onClose;
  final Widget menu;
  final bool visible;
  final Widget child;
  final Alignment menuAnchor;
  final Alignment childAnchor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: visible ? onClose : null,
      child: PortalEntry(
        visible: visible,
        portal: menu,
        portalAnchor: menuAnchor,
        childAnchor: childAnchor,
        child: IgnorePointer(
          ignoring: visible,
          child: child,
        ),
      ),
    );
  }
}
