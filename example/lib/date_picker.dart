import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';

// A minimalistic date picker

void main() => runApp(const MyApp());

class DeclarativeDatePicker extends StatelessWidget {
  const DeclarativeDatePicker({
    Key key,
    this.visible,
    this.onDismissed,
    this.onClose,
    this.child,
  }) : super(key: key);

  final bool visible;
  final Widget child;
  final VoidCallback onDismissed;
  final void Function(DateTime date) onClose;

  @override
  Widget build(BuildContext context) {
    return PortalEntry(
      visible: visible,
      portal: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: ModalBarrier(color: Colors.black38),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismissed,
            child: Center(
              child: Card(
                elevation: 16,
                child: RaisedButton(
                  onPressed: () => onClose(DateTime.now()),
                  child: const Text('today'),
                ),
              ),
            ),
          )
        ],
      ),
      child: child,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (_, child) => Portal(child: child),
      home: Scaffold(
        appBar: AppBar(title: const Text('Example')),
        body: LayoutBuilder(
          builder: (_, __) {
            return LayoutBuilder(builder: (_, __) {
              return const DatePickerUsageExample();
            });
          },
        ),
      ),
    );
  }
}

class DatePickerUsageExample extends StatefulWidget {
  const DatePickerUsageExample({Key key}) : super(key: key);

  @override
  _DatePickerUsageExampleState createState() => _DatePickerUsageExampleState();
}

class _DatePickerUsageExampleState extends State<DatePickerUsageExample> {
  DateTime pickedDate;
  bool showDatePicker = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DeclarativeDatePicker(
        visible: showDatePicker,
        onClose: (date) => setState(() {
          showDatePicker = false;
          pickedDate = date;
        }),
        onDismissed: () => setState(() => showDatePicker = false),
        child: pickedDate == null
            ? RaisedButton(
                onPressed: () => setState(() => showDatePicker = true),
                child: const Text('pick a date'),
              )
            : Text('The date picked: $pickedDate'),
      ),
    );
  }
}
