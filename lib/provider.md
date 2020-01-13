Ok, so with "Pragmatic state management", we've seen the Flutter team use `provider` to "fix" their code.

But we didn't really have an explanation on "why" the outcome is better.
So we're going to do exactly that.

So our plan for today will be:

- see what the problems `provider` is trying to solve

  - reducing the boilerplate/complexity of InheritedWidgets

    - Nobody understands InheritedWidgets

      > InheritedWidgets but for humans – Scott

    - verbose & complex. They were the cause of many SO questions, usually about state loss.

      And the verbosity made people use globals

    - Let's fix InheritedWidgets by making one that people can understand, based on the questions on SO

      -> No state loss & no global

  - So, provider is a simple to understand variant of InheritedWidgets.

    - Don't have to define a new InheritedWidget everytimes we want to expose a new variable
      - less verbose
      - if a new feature is added on `provider` , all providers immediatly benefits from it
        - 4.0.0 -> Lazy loading

  - Why use provider == Why use InheritedWidgets
    the widget tradeoff:

    Cons:

    - Adds a dependency on Flutter

      Flutter is cross-platform, and
      Dart is used nearly exclusively for Flutter anyway.
      So, IMO, it doesn't matter.

    Pros:

    - Aware of the widgets life-cycles (knows when to create/dispose/update a value)
    - Can make widgets that depends on a value rebuild when the value changes
    - any value is overridable if needed
    - uni-directional data-flow
      - Don't fight against it, it's for your own good
    - testing is smooth (doesn't depend on global state, nothing to reset)
    - values can be inspected in the devtools or with `debugDumpApp()` in tests
    - Natural for a Flutter developer (the `of` pattern is omni-present in the framework)
      - We can have implicit animations too!

<!-- - There are two main paths for obtaining a service:

  + Constructor injection -> requires code-generation, implies always a single instance
  + service locator -> runtime behavior (potential exceptions)

* Theme/MediaQuery/Navigator/... so there most be a reason right?
* Why not globals/Singletons?
  + testing is hard/verbose (you have to clear their state everytimes)
    + It can't make testing hard if you don't test
    + https://giphy.com/gifs/Friends-episode-15-friends-tv-the-one-where-estelle-dies-W3a0zO282fuBpsqqyD
  + DIY
  + (that's what get_it is by default)
  + We can access everything from everywhere -> find "messy object graph" img
* Container based service locators
  + Testing is easier (each test use its own container)
  + we have to pass that container everywhere or make it a global/singleton -> circle back to the previous issue -->

- explain how it works

  - everything goes through one common InheritedWidget
  - lazy loading
  - MultiProvider does **nothing**. It just changes the appearance of the code.

    For the computer, the behavior is the same and will always be.

- General tips and tricks / Answer various popular questions about `provider`

  - "Do you have an example of a full app using provider"?

    No, because that question doesn't make sense. Provider is a tool not an architecture.

    You're confusing `provider` , the tool, with `scoped_model` a Google architecture that _can_ be implemented using `provider` + `ChangeNotifier` .

    Bear in mind that other architectures use `provider` :

    - `flutter_bloc`
    - `mobx`

  - It's more verbose than XX alternative!

    Bear in mind that it likely does more stuff at once:

    - creation
    - disposal
    - update

    Don't stop at what's inside the library.
    Again, `provider` is a tool not an architecture. You can continue to build on the top of it.

    - Don't hesitate to make your own provider

      To do so, simply compose/extends InheritedProvider/DeferredInheritedProvider

      -> They gives all the tools you need to make your custom provider.

      ```dart
      class ChangeNotifierProvider<T extends ChangeNotifier>
          extends InheritedProvider<T> {
        static final StartListening<ChangeNotifier> _startListening = (e, value) {
          value?.addListener(e.markNeedsNotifyDependents);
          return () => value?.removeListener(e.markNeedsNotifyDependents);
        };

        static final Dispose<ChangeNotifier> _dispose = (_, value) {
          value?.dispose();
        };

        ChangeNotifierProvider({
          Key key,
          @required Create<T> create,
          bool lazy,
          Widget child,
        }) : super(
                key: key,
                startListening: _startListening,
                create: create,
                dispose: _dispose,
                lazy: lazy,
                child: child,
              );

        ChangeNotifierProvider.value({
          Key key,
          @required T value,
          UpdateShouldNotify<T> updateShouldNotify,
          Widget child,
        }) : super.value(
                key: key,
                value: value,
                updateShouldNotify: updateShouldNotify,
                startListening: _startListening,
                child: child,
              );
      }
      ```

- consider adding your "global providers" directly in the `main.dart` instead of your `MyApp` widget.

  This way we can easily switch between environment my using a different main:

  ```dart
  // dev
  void main() {
    runApp(
      MultiProvider(
        providers: [
          Provider(create: (_) => Configurations(host: 'dev-host.fr')),
        ],
        child: MyApp(),
      ),
    );
  }
  ```

  vs:

  ```dart
  // release
  void main() {
    runApp(
      MultiProvider(
        providers: [
          Provider(create: (_) => Configurations(host: 'release-host.fr')),
        ],
        child: MyApp(),
      ),
    );
  }
  ```

  Of course, you could do it differently (like a custom constructor on `MyApp`).

* using both provider and another service locator together is discouraged
  - this ejects the uni-directional data-flow
  - consider using only one of them. You're free to _not_ use provider.
* "I want to read a `Provider` but I don't want my model to depend on Flutter/don't have a BuildContext, what to do?!"

  - functions are your friend

* Storing providers in a global variable is anti-pattern -> Fill Architecture
* Can I have multiple providers with the same type?

  - Yes but that's probably not the way you want -> can obtain only the nearest ancestor
  - there's an RFC about having a "scope" feature. Is it worth the added complexity? I need your opinion!

    Insert github link

* A state update rebuilds too many widgets. What can I do?
  - it doesn't matter
  - Consider `Selector`
