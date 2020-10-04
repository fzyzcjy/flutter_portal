import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool showModal = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => Portal(child: child),
      home: Scaffold(
        appBar: AppBar(title: const Text('Discovery example')),
        body: Center(
          child: Modal(
            visible: showModal,
            modal: const Dialog(
              child: Text('Hello world'),
            ),
            onClose: () => setState(() => showModal = false),
            child: RaisedButton(
              onPressed: () => setState(() => showModal = true),
              child: const Text('Show modal'),
            ),
          ),
        ),
      ),
    );
  }
}

class Modal extends StatelessWidget {
  const Modal({
    Key key,
    @required this.visible,
    @required this.onClose,
    @required this.modal,
    @required this.child,
  }) : super(key: key);

  final Widget child;
  final Widget modal;
  final bool visible;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Barrier(
      visible: visible,
      onClose: onClose,
      child: PortalEntry(
        visible: visible,
        closeDuration: kThemeAnimationDuration,
        portal: TweenAnimationBuilder<double>(
          duration: kThemeAnimationDuration,
          curve: Curves.easeOut,
          tween: Tween(begin: 0, end: visible ? 1 : 0),
          builder: (context, progress, child) {
            return Transform(
              transform: Matrix4.translationValues(0, (1 - progress) * 50, 0),
              child: Opacity(
                opacity: progress,
                child: child,
              ),
            );
          },
          child: Center(child: modal),
        ),
        child: child,
      ),
    );
  }
}

class Barrier extends StatelessWidget {
  const Barrier({
    Key key,
    @required this.onClose,
    @required this.visible,
    @required this.child,
  }) : super(key: key);

  final Widget child;
  final VoidCallback onClose;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return PortalEntry(
      visible: visible,
      closeDuration: kThemeAnimationDuration,
      portal: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: TweenAnimationBuilder<Color>(
          duration: kThemeAnimationDuration,
          tween: ColorTween(
            begin: Colors.transparent,
            end: visible ? Colors.black54 : Colors.transparent,
          ),
          builder: (context, color, child) {
            return ColoredBox(color: color);
          },
        ),
      ),
      child: child,
    );
  }
}
