import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool showDiscovery = false;
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Portal(
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Discovery example')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('You have clicked the button this many times:'),
                // Text('$count', style: Theme.of(context).textTheme.headline4),
                Text('$count'),
                ElevatedButton(
                  onPressed: () => setState(() => showDiscovery = true),
                  child: const Text('Show discovery'),
                )
              ],
            ),
          ),
          floatingActionButton: Discovery(
            visible: showDiscovery,
            description: const Text('Click to increment the counter'),
            onClose: () => setState(() => showDiscovery = false),
            child: FloatingActionButton(
              onPressed: _increment,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    );
  }

  void _increment() {
    setState(() {
      showDiscovery = false;
      count++;
    });
  }
}

class Discovery extends StatelessWidget {
  const Discovery({
    Key? key,
    required this.visible,
    required this.onClose,
    required this.description,
    required this.child,
  }) : super(key: key);

  final Widget child;
  final Widget description;
  final bool visible;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Barrier(
      visible: visible,
      onClose: onClose,
      child: PortalTarget(
        visible: visible,
        closeDuration: kThemeAnimationDuration,
        anchor: const Aligned(
          target: Alignment.center,
          follower: Alignment.center,
        ),
        portalFollower: Stack(
          children: [
            CustomPaint(
              painter: HolePainter(Theme.of(context).colorScheme.secondary),
              child: TweenAnimationBuilder<double>(
                duration: kThemeAnimationDuration,
                curve: Curves.easeOut,
                tween: Tween(begin: 50, end: visible ? 200 : 50),
                builder: (context, radius, _) {
                  return Padding(
                    padding: EdgeInsets.all(radius),
                    child: child,
                  );
                },
              ),
            ),
            Positioned(
              top: 100,
              left: 50,
              width: 200,
              // child: DefaultTextStyle(
              // style: Theme.of(context).textTheme.headline5!,
              child: TweenAnimationBuilder<double>(
                duration: kThemeAnimationDuration,
                curve: Curves.easeOut,
                tween: Tween(begin: 0, end: visible ? 1 : 0),
                builder: (context, opacity, _) {
                  return Opacity(
                    opacity: opacity,
                    child: description,
                  );
                },
              ),
            )
          ],
        ),
        child: child,
      ),
    );
  }
}

class HolePainter extends CustomPainter {
  const HolePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = color;

    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()
          ..addOval(Rect.fromCircle(center: center, radius: size.width / 2)),
        Path()
          ..addOval(Rect.fromCircle(center: center, radius: 40))
          ..close(),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(HolePainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

class Barrier extends StatelessWidget {
  const Barrier({
    Key? key,
    required this.onClose,
    required this.visible,
    required this.child,
  }) : super(key: key);

  final Widget child;
  final VoidCallback onClose;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return PortalTarget(
      visible: visible,
      closeDuration: kThemeAnimationDuration,
      portalFollower: GestureDetector(
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

/// Non-nullable version of ColorTween.
class ColorTween extends Tween<Color> {
  ColorTween({required Color begin, required Color end})
      : super(begin: begin, end: end);

  @override
  Color lerp(double t) => Color.lerp(begin, end, t)!;
}
