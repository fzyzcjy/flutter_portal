[![Build Status](https://travis-ci.org/rrousselGit/flutter_portal.svg?branch=master)](https://travis-ci.org/rrousselGit/flutter_portal)
[![pub package](https://img.shields.io/pub/v/flutter_portal.svg)](https://pub.dartlang.org/packages/flutter_portal) [![codecov](https://codecov.io/gh/rrousselGit/flutter_portal/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/flutter_portal)

## Call for maintainer


I (@rrousselGit) am sadly unable to maintain flutter_portal at the moment due to a lack of time, and would like to find
a new maintainer.  
If you are interested in taking over flutter_portal, open an issue saying that you are interested or reach out to me at darky12s@gmail.com.

Thanks!

## Motivation

A common use-case for UIs is to show "overlays". They come in all shapes and forms:

- tooltips
- contextual menus,
- dialogs
- etc

In Flutter, these are usually shown by using [Overlay]/[OverlayEntry].
The problem is, [OverlayEntry] is **not** a widget, and is manipulated using
imperative code.

This has a few issues:

- Implementing a custom tooltip/contextual menu is difficult.
  It is not trivial to align the tooltip/menu next to a widget.

- When our application is killed by the OS, the state of our modals are not restored.
  There are _some_ way to to that, but it is signicantly harder than using `RestorableProperty`.

- It causes issues with `Theme` and other context-based variables.
  For some confusing reasons, it is possible that the theme obtained by `Theme.of`
  inside dialogs/menus is different from the theme of the widget that showed these overlays.

Flutter_portal tries to fix all of these:

- It has built-in support for aligning an overlay next to a UI component.
  You can create a custom contextual menu from scratch in a few lines of code.

- Overlays are now showed declaratively, by inserting them in the widget tree.
  This makes showing an overlay as simple as doing a `setState` – which combines
  nicely with `RestorableProperty`.

- The overlay has access to the same Theme and the different providers than
  the widget that showed the overlay.

## Install

First, you will need to add `portal` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_portal: ^0.3.0
```

Then, run `flutter packages get` in your terminal.

## Examples

Make sure to check-out the `examples` folder for examples on how to use flutter_portal.

| Contextual menu                                                                                                                                                        | Onboarding view                                                                                                                                        |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| <img width="300px" alt="Screenshot 2020-10-04 at 22 20 30" src="https://user-images.githubusercontent.com/20165741/95027357-d21ae500-068f-11eb-8ab5-ddfe4c474f73.png"> | <img src="https://user-images.githubusercontent.com/20165741/95027648-1d35f780-0692-11eb-8315-5ca8b7f6ad9e.gif" alt="Discovery example" style="300px"> |

## Usage

### Add the [Portal] widget

Before doing anything, you must insert the [Portal] widget in your widget tree.
This widget enabled flutter_portal in your project.

You can place this [Portal] above `MaterialApp` or near the root of a route:

```dart
Portal(
  child: MaterialApp(
    ...
  )
)
```

### Showing a contextual menu

In this example, we will see how we can use flutter_portal to show a menu
after clicking on a `RaisedButton`.
The menu will be aligned to the left of our button.

First, we need to create a `StatefulWidget` that renders our `RaisedButton`:

```dart
class MenuExample extends StatefulWidget {
  @override
  _MenuExampleState createState() => _MenuExampleState();
}

class _MenuExampleState extends State<MenuExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: RaisedButton(
          onPressed: () {},
          child: Text('show menu'),
        ),
      ),
    );
  }
}
```

<img src="https://user-images.githubusercontent.com/20165741/95027014-3ee0b000-068d-11eb-8c65-a7a5ad8b71bd.png" alt="image" style="width=300px">

Then, we need to insert our [PortalEntry] in the widget tree.

We want our contextual menu to render right next to our `RaisedButton`.
As such, our [PortalEntry] should be the parent of `RaisedButton` like so:

```dart
Center(
  child: PortalEntry(
    visible: // TODO
    portal: // TODO
    child: RaisedButton(
      ...
    ),
  ),
)
```

We can pass our menu to [PortalEntry]:

```dart
PortalEntry(
  visible: true,
  portal: Material(
    elevation: 8,
    child: IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text('option 1')),
          ListTile(title: Text('option 2')),
        ],
      ),
    ),
  ),
  child: RaisedButton(...),
)
```

<img width="300px" alt="Screenshot 2020-10-04 at 22 07 12" src="https://user-images.githubusercontent.com/20165741/95027128-20c77f80-068e-11eb-9de9-5e35dd1e47de.png">

At this stage, you may notice two things:

- our menu is full-screen
- our menu is always visible (because `visible` is _true_)

Let's fix the full-screen issue first and change our code so that our
menu renders on the _right_ of our `RaisedButton`.

To align our menu around our button, we can specify the `childAnchor` and
`portalAnchor` parameters:

```dart
PortalEntry(
  visible: true,
  portalAnchor: Alignment.topLeft,
  childAnchor: Alignment.topRight,
  portal: Material(...),
  child: RaisedButton(...),
)
```

<img width="300px" alt="Screenshot 2020-10-04 at 22 16 02" src="https://user-images.githubusercontent.com/20165741/95027278-32f5ed80-068f-11eb-9cef-c1e5c00cf1d4.png">

What this code means is, this will align the top-left of our menu with the
top-right or the `RaisedButton`.
With this, our menu is no-longer full-screen and is now located to the right
of our button.

Finally, we can update our code such that the menu show only when clicking
on the button.

To do that, we need to declare a new boolean inside our `StatefulWidget`,
that says whether the menu is open or not:

```dart
class _MenuExampleState extends State<MenuExample> {
  bool isMenuOpen = false;
  ...
}
```

We then pass this `isMenuOpen` variable to our [PortalEntry]:

```dart
PortalEntry(
  visible: isMenuOpen,
  ...
)
```

Then, inside the `onPressed` callback of our `RaisedButton`, we can
update this `isMenuOpen` variable:

```dart
RaisedButton(
  onPressed: () {
    setState(() {
      isMenuOpen = true;
    });
  },
  child: Text('show menu'),
),
```

One final step is to close the menu when the user clicks randomly outside
of the menu.

This can be implemented with a second [PortalEntry] combined with [GestureDetector]
like so:

```dart
Center(
  child: PortalEntry(
    visible: isMenuOpen,
    portal: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          isMenuOpen = false;
        });
      },
    ),
    child: PortalEntry(
      // our previous PortalEntry
      portal: Material(...)
      child: RaisedButton(...),
    ),
  ),
)
```

[overlay]: https://api.flutter.dev/flutter/widgets/Overlay-class.html
[overlayentry]: https://api.flutter.dev/flutter/widgets/OverlayEntry-class.html
[addpostframecallback]: https://api.flutter.dev/flutter/scheduler/SchedulerBinding/addPostFrameCallback.html
[portal]: https://pub.dev/documentation/flutter_portal/latest/flutter_portal/Portal-class.html
[portalentry]: https://pub.dev/documentation/flutter_portal/latest/flutter_portal/PortalEntry-class.html
