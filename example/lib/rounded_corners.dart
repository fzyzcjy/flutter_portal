import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Portal(
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Example'),
          ),
          body: Container(
            padding: const EdgeInsets.all(10),
            alignment: Alignment.centerLeft,
            child: const RoundedCornersExample(),
          ),
        ),
      ),
    );
  }
}

class RoundedCornersExample extends StatefulWidget {
  const RoundedCornersExample({Key? key}) : super(key: key);

  @override
  _RoundedCornersExampleState createState() => _RoundedCornersExampleState();
}

class _RoundedCornersExampleState extends State<RoundedCornersExample> {
  bool _showPopup = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _ModalEntry(
        visible: _showPopup,
        onClose: () => setState(() => _showPopup = false),
        childAnchor: Alignment.topRight,
        menuAnchor: Alignment.topLeft,
        menu: const _Popup(
          children: [
            PopupMenuItem<void>(
              height: 42,
              child: Text('first'),
            ),
            PopupMenuItem<void>(
              height: 42,
              child: Text('second'),
            ),
            PopupMenuItem<void>(
              height: 42,
              child: Text('third'),
            ),
            PopupMenuItem<void>(
              height: 42,
              child: Text('forth'),
            ),
            PopupMenuItem<void>(
              height: 42,
              child: Text('fifth'),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => setState(() => _showPopup = true),
          child: const Text('show popup'),
        ),
      ),
    );
  }
}

class _Popup extends StatelessWidget {
  const _Popup({
    Key? key,
    required this.children,
  }) : super(key: key);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

class _ModalEntry extends StatelessWidget {
  const _ModalEntry({
    Key? key,
    required this.onClose,
    required this.menu,
    required this.visible,
    required this.menuAnchor,
    required this.childAnchor,
    required this.child,
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
      child: PortalTarget(
        visible: visible,
        portalFollower: menu,
        anchor: const Aligned(
          follower: Alignment.topLeft,
          target: Alignment.bottomLeft,
          widthFactor: 1,
          backup: Aligned(
            follower: Alignment.bottomLeft,
            target: Alignment.topLeft,
            widthFactor: 1,
          ),
        ),
        child: IgnorePointer(
          ignoring: visible,
          child: child,
        ),
      ),
    );
  }
}
