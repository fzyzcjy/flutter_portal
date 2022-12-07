[![Build](https://github.com/fzyzcjy/flutter_portal/actions/workflows/build.yml/badge.svg)](https://github.com/fzyzcjy/flutter_portal/actions/workflows/build.yml)
[![pub package](https://img.shields.io/pub/v/flutter_portal.svg)](https://pub.dartlang.org/packages/flutter_portal)
[![codecov](https://codecov.io/gh/fzyzcjy/flutter_portal/branch/master/graph/badge.svg)](https://codecov.io/gh/fzyzcjy/flutter_portal)

# [flutter_portal](https://github.com/fzyzcjy/flutter_portal): Evolved `Overlay`/`OverlayEntry` - declarative not imperative, intuitive-context, and easy-alignment

Want to show floating overlays - tooltips, contextual menus, dialogs, bubbles, etc? This library is an enhancement and replacement to Flutter's built-in [Overlay]/[OverlayEntry].

## 🚀 Advantages

Why using `flutter_portal` instead of built-in [Overlay]/[OverlayEntry]?

* **Declarative, not imperative**: Like everything else in the Flutter world, overlays (portals) are declarative now. Simply put your floating UI in the normal widget tree. <sub>Compare: The [OverlayEntry] is **not** a widget, and is manipulated imperatively using `.insert()` etc.</sub>
* **Alignment, done easily**: Built-in support for aligning an overlay next to a UI component. <sub>Compare: A custom contextual menu from scratch in a few lines of code; while [Overlay] makes it nontrivial to align the tooltip/menu next to a widget.</sub>
* **The intuitive `Context`**: The overlay entry is build with its intuitive parent as its `context`. <sub>Compare The [Overlay] approach uses the far-away overlay as its `context`.</sub>

As a consequence, also have the following pros:

* **Easy restorable property**: Since showing an overlay as simple as doing a `setState`, `RestorableProperty` works nicely. <sub>Compare: When using the [Overlay] approach, the state of our modals are not restored when our application is killed by the OS.</sub>
* **Correct `Theme`/`provider`**: Since the overlay entry has the intuitive `context`, it has access to the same `Theme` and the different `provider`s as the widget that shows the overlay. <sub>Compare: The [Overlay] approach will yield confusing Themes and providers.</sub>

### 👀 Show me the code

```dart
PortalTarget(
  // 1. Declarative: Just provide `portalFollower` as a normal widget
  // 2. Intuitive BuildContext inside
  portalFollower: MyAwesomeOverlayWidget(),
  // 3. Align the "follower" relative to the "child" anywhere you like
  anchor: Aligned.center,
  child: MyChildWidget(),
)
```

To migrate from 0.x to 1.x, see the last section of the readme.

## 🪜 Examples

Check-out the `examples` folder for examples on how to use flutter_portal:

* [Contextual menu](example/lib/contextual_menu.dart)
* [Date picker](example/lib/date_picker.dart)
* [Discovery (Onboarding view)](example/lib/discovery.dart)
* [Medium clap](example/lib/medium_clap.dart)
* [Modal](example/lib/modal.dart)
* [Rounded corners](example/lib/rounded_corners.dart)

Partial screenshots:

| Contextual menu                                                                                                                                                        | Onboarding view                                                                                                                                        |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| <img width="300px" src="https://github.com/fzyzcjy/flutter_portal/raw/master/doc/contextual_menu.png"> | <img src="https://github.com/fzyzcjy/flutter_portal/raw/master/doc/onboarding_view.gif" alt="Discovery example" style="300px"> |

## 🧭 Usage

1. Install it. Follow the [standard](https://docs.flutter.dev/development/packages-and-plugins/using-packages) procedure of installing this package. The simplest way may be `flutter pub add flutter_portal`.
2. Add the [Portal] widget. For example, place it above `MaterialApp`. Only one [Portal] is needed per app.
3. Use [PortalTarget]s whenever you want to show some overlays.

## 📚 Tutorial: Show a contextual menu

In this example, we will see how we can use flutter_portal to show a menu
after clicking on a `RaisedButton`.

### Add the [Portal] widget

Before doing anything, you must insert the [Portal] widget in your widget tree. The follower widgets will behave as if they are inserted as children of this widget.

You can place this [Portal] above `MaterialApp` or near the root of a route:

```dart
Portal(
  child: MaterialApp(...)
)
```

### The button

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

<p align="center">
<img src="https://github.com/fzyzcjy/flutter_portal/raw/master/doc/usage_a.png" alt="image" width="200px">
</p>

### The menu - initial iteration

Then, we need to insert our [PortalTarget] in the widget tree.

We want our contextual menu to render right next to our `RaisedButton`.
As such, our [PortalTarget] should be the parent of `RaisedButton` like so:

```dart
child: PortalTarget(
  visible: // TODO
  anchor: // TODO
  portalFollower: // TODO
  child: RaisedButton(...),
),
```

We can pass our menu to [PortalTarget]:

```dart
PortalTarget(
  visible: true,
  anchor: Filled(),
  portalFollower: Material(
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

<p align="center">
<img width="200px" src="https://github.com/fzyzcjy/flutter_portal/raw/master/doc/usage_b.png">
</p>

At this stage, you may notice two things:

- our menu is full-screen (because `anchor` is `Filled`)
- our menu is always visible (because `visible` is _true_)

### Change alignment

Let's fix the full-screen issue first and change our code so that our menu renders on the _right_ of our `RaisedButton`.

To align our menu around our button, we can change the `anchor` parameter:

```dart
PortalTarget(
  visible: true,
  anchor: const Aligned(
    follower: Alignment.topLeft,
    target: Alignment.topRight,
  ),
  portalFollower: Material(...),
  child: RaisedButton(...),
)
```

<p align="center">
<img width="200px" src="https://github.com/fzyzcjy/flutter_portal/raw/master/doc/usage_c.png">
</p>
What this code means is, this will align the top-left of our menu with the
top-right or the `RaisedButton`. With this, our menu is no-longer full-screen and is now located to the right of our button.

### Show the menu

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
PortalTarget(
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

### Hide the menu

One final step is to close the menu when the user clicks randomly outside
of the menu.

This can be implemented with a second [PortalEntry] combined with [GestureDetector] like so:

```dart
PortalTarget(
  visible: isMenuOpen,
  portalFollower: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      setState(() {
        isMenuOpen = false;
      });
    },
  ),
  ...
),
```

## 🎼 Concepts

There are a few concepts that are useful to fully understand when using
`flutter_portal`. That is especially true if you want to support custom use
cases, which is easily possible with the abstract API provided.

In the following, each of the abstract concepts you need to understand are
explained on a high level. You will find them both in class names (e.g. the
`Portal` widget or the `PortalTarget` widget as well as in parameter names).

### Portal

A portal (or the portal if you only have one) is the space used for doing all
of the portal work. On a low level, this means that you have one widget that
allows its subtree to place targets and followers that are connected.

The portal also defines the area (rectangle bounds) that are available to any
followers to be rendered onto the screen.

In detail, you might wrap your whole `MaterialApp` in a single `Portal` widget,
which would mean that you can use the whole area of your app to render followers
attached to targets that are children of the `Portal` widget.

### Target

A target is any place within a portal that can be followed by a follower. This
allows you to attach whatever you want to overlay to a specific place in your
UI, no matter where it moves dynamically.

On a low level, this means that you wrap the part of your UI that you want to
follow in a `PortalTarget` widget and configure it.

#### Example

Imagine you want to display tooltips when an avatar is hovered in your app. In
that case, the avatar would be the portal **target** and could be used to anchor
the tooltip that is overlayed.

Another example would be a dropdown menu. The widget that shows the current
selection is the *target* and when tapping on it, the dropdown options would be
overlayed through the portal as the follower.

### Follower

A follower can only be used in combination with a target. You can use it for
anything that you want to overlay on top of your UI, attached to a target.

Specifically, this means that you can pass one `follower` to every
`PortalTarget`, which will be displayed above your UI within the portal when
you specify so.

#### Example

If you wanted to display an autocomplete text field using `flutter_portal`,
you would want to follow the text field to overlay your autocomplete
suggestions. The widget for the autocomplete suggestions would be the portal
**follower** in that case.

### Anchor

Anchors define the layout connection between targets and followers. In general,
anchors are implemented as an abstract API that provides all the information
necessary to support any positioning you want. That means that anchors can be
defined based on the attributes of the associated portal, target, and follower.

There are a few anchors that are implemented by default, e.g. `Aligned` or
`Filled`.

## ⛵ Migration from 0.x

There are some breaking changes (mostly introduced by [#44](https://github.com/fzyzcjy/flutter_portal/pull/44)) from 0.x to 1.0, but it can be easily migrated. The following:

```dart
PortalEntry(
  portalAnchor: Alignment.topLeft,
  childAnchor: Alignment.topRight,
  portal: MyAwesomePortalWidget(),
  child: MyAwesomeChildWidget(),
)
```

Becomes:

```dart
PortalTarget(
  anchor: const Aligned(
    follower: Alignment.topLeft,
    target: Alignment.topRight,
  ),
  portalFollower: MyAwesomePortalWidget(),
  child: MyAwesomeChildWidget(),
)
```

If you originally use `PortalEntry` without `portalAnchor`/`childAnchor` (i.e. make it fullscreen), then you can write as:

```dart
PortalTarget(
  anchor: const Filled(),
  ...
)
```

## ✨ Acknowledgement

Owners

* [@rrousselGit](https://github.com/rrousselGit): The former owner of this package. Create this package in December 2019, and majorly maintain until early 2022. Contributions include: Implementation of the package, including code, documentations, examples, etc. Change algorithms of rendering. Remove PortalEntry's generic. Allow delaying the disappearance of PortalEntry, useful for leave animations. 
* [@fzyzcjy](https://github.com/fzyzcjy): The current owner of this package. See `CHANGELOG.md` for contributions.

Contributors

* [@creativecreatorormaybenot](https://github.com/creativecreatorormaybenot): New anchoring logic for advanced use cases, making anchors more flexible, improving code quality, and enhancing non-fragility without additional layout/paint calls.
* [@Jjagg](https://github.com/Jjagg): Migrate to NNBD.
* [@CaseyHillers](https://github.com/CaseyHillers): Make example compatible with Dart 3.
* [@mono0926](https://github.com/mono0926): Update dependencies and doc.
* [@tepcii](https://github.com/tepcii) and [@nilsreichardt](https://github.com/nilsreichardt): Fix doc.
* [@mityax](https://github.com/mityax): Fix export.

[overlay]: https://api.flutter.dev/flutter/widgets/Overlay-class.html
[overlayentry]: https://api.flutter.dev/flutter/widgets/OverlayEntry-class.html
[portal]: https://pub.dev/documentation/flutter_portal/latest/flutter_portal/Portal-class.html
[portalentry]: https://pub.dev/documentation/flutter_portal/latest/flutter_portal/PortalEntry-class.html
[portaltarget]: https://pub.dev/documentation/flutter_portal/latest/flutter_portal/PortalTarget-class.html
