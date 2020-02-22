import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_portal/flutter_portal.dart';

// This implements Medium's clap button

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    debugPaintLayerBordersEnabled = false;
    debugCheckElevationsEnabled = true;
    return MaterialApp(
      builder: (_, child) => Portal(child: child),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Example'),
        ),
        body: Center(
          child: PortalEntry(
            portalAnchor: Alignment.center,
            childAnchor: Alignment.center,
            portal: Material(
              elevation: 9999,
              shadowColor: Colors.transparent,
              child: Container(
                height: 800,
                width: 100,
                child: const Material(
                  elevation: 2,
                  child: Text('21'),
                ),
              ),
            ),
            child: Container(),
          ),
        ),
      ),
    );
  }
}

// // portal has elevation smaller than child

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     debugPaintLayerBordersEnabled = false;
//     debugCheckElevationsEnabled = true;
//     return MaterialApp(
//       builder: (_, child) => Portal(child: child),
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('Example'),
//         ),
//         body: Center(
//           child: PortalEntry(
//             portal: Padding(
//               padding: const EdgeInsets.all(100.0),
//               child: const Material(
//                 elevation: 2,
//                 child: Text('21'),
//               ),
//             ),
//             child: const Material(
//               elevation: 3,
//               child: Text('42'),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
