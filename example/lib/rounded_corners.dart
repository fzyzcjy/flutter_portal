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
          body: const Padding(
            padding: EdgeInsets.all(16),
            child: RoundedCornersExample(),
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
    return _ModalEntry(
      visible: _showPopup,
      onClose: () => setState(() => _showPopup = false),
      popup: _Popup(
        children: [
          for (var i = 0; i < 12; i++)
            ListTile(
              onTap: () => setState(() => _showPopup = false),
              title: Text('$i'),
            ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => setState(() => _showPopup = true),
        child: const Text('show popup'),
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
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: IntrinsicWidth(
          child: ListView(
            shrinkWrap: true,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _ModalEntry extends StatelessWidget {
  const _ModalEntry({
    Key? key,
    required this.onClose,
    required this.visible,
    required this.popup,
    required this.child,
  }) : super(key: key);

  final VoidCallback onClose;
  final bool visible;
  final Widget popup;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: visible ? onClose : null,
      child: PortalTarget(
        visible: visible,
        portalFollower: popup,
        // todo: implement anchor that sizes the follower based on the available space within the portal at the calculated offset.
        anchor: const Aligned(
          follower: Alignment.topLeft,
          target: Alignment.bottomLeft,
          widthFactor: 1,
        ),
        child: IgnorePointer(
          ignoring: visible,
          child: child,
        ),
      ),
    );
  }
}
