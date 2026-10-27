# React Native

Architecture, Expo, lists, animations, rendering and shipping.

## RN-013: What is the New Architecture, and what replaced the bridge?

**Level:** mid

The old architecture passed every call between JavaScript and native code as JSON messages over an
asynchronous **bridge**, which added serialisation cost and made synchronous calls impossible. The
New Architecture replaces it with:

- **JSI** (JavaScript Interface): a C++ API that lets JavaScript hold references to native objects
  and call them directly, synchronously when needed.
- **Turbo Native Modules**: native modules built on JSI, loaded lazily on first use, with typed
  interfaces.
- **Fabric**: the renderer, written in C++, which can render synchronously and supports React's
  concurrent features (transitions, Suspense) and layout reads in `useLayoutEffect`.
- **Codegen**: generates the native glue from TypeScript or Flow specs, so a type mismatch between
  JavaScript and native fails at build time.

It has been the default for new apps since React Native 0.76, and since 0.82 the old architecture
can no longer be turned back on. When interviewing for an older codebase, expect questions about
migrating native modules and checking library compatibility.

**Reference:** [About the New Architecture](https://reactnative.dev/architecture/landing-page)

## RN-014: What is Hermes, and why is it the default engine?

**Level:** junior

Hermes is a JavaScript engine built for React Native. Its main difference from browser engines is
**ahead-of-time compilation to bytecode** at build time: the app ships bytecode instead of source,
so there is no parsing or compiling on the device at start-up. That improves launch time and
lowers memory use, which matters most on low-end Android phones. It also has a garbage collector
designed for mobile memory limits.

Hermes has been the default since React Native 0.70. Practical points: debugging uses the React
Native DevTools connected to Hermes; `global.HermesInternal` exists when it is running; and a few
less common features may lag behind the latest JavaScript engines, so check the Hermes
documentation before relying on something new.

**Reference:** [Using Hermes](https://reactnative.dev/docs/hermes)

## RN-015: What is Expo, and what do prebuild and config plugins do?

**Level:** junior

Expo is a framework and set of tools on top of React Native: a library of native modules (camera,
notifications, secure store), Expo Router for file-based navigation, and EAS services for builds,
submissions and updates. The React Native docs recommend starting new apps with a framework such
as Expo.

The `ios` and `android` folders do not have to be edited by hand. With **Continuous Native
Generation**, `npx expo prebuild` generates them from `app.json` (or `app.config.js`) and the
installed packages. A **config plugin** is a function that changes the generated native project:
adding an Info.plist key, an Android permission, or a Gradle setting. Because the native folders
can be regenerated at any time, upgrades are mostly a matter of updating packages and running
prebuild again.

You can still write your own native code (with the Expo Modules API, or any React Native library)
and use a **development build** instead of the Expo Go app, which only contains Expo's built-in
modules.

**References:** [Expo: Continuous Native Generation](https://docs.expo.dev/workflow/continuous-native-generation/) · [Expo: Config plugins](https://docs.expo.dev/config-plugins/introduction/)

## RN-016: How do you make a long `FlatList` scroll smoothly?

**Level:** mid

- Give every row a stable `keyExtractor` based on the item's ID, never the index for data that
  changes.
- Make rows cheap: wrap the row component in `React.memo`, pass primitive props, and keep
  `renderItem` stable with `useCallback`, so unrelated state changes do not re-render every row.
- If rows have a fixed height, provide `getItemLayout` so the list can skip measuring and jump to
  any offset.
- Tune the windowing props when needed: `initialNumToRender`, `maxToRenderPerBatch`,
  `windowSize` (how many screens of content stay rendered).
- Resize images to their display size on the server or with an image library that caches decoded
  images.
- For very long or complex lists, use a list that **recycles** row views, such as Shopify's
  FlashList, instead of creating and destroying them.

Measure with the React Native DevTools profiler and the performance monitor in a release build;
development builds are much slower.

**References:** [Optimizing FlatList configuration](https://reactnative.dev/docs/optimizing-flatlist-configuration) · [FlatList](https://reactnative.dev/docs/flatlist)

## RN-017: Why do some animations stutter, and how do you run them on the UI thread?

**Level:** senior

An animation driven from JavaScript computes every frame on the JS thread. If that thread is busy
(rendering a list, parsing JSON, handling a gesture) frames are missed.

Two ways to move the work off it:

- `Animated` with `useNativeDriver: true` sends the whole animation description to native once,
  and native code runs it frame by frame. It supports non-layout properties such as `transform`
  and `opacity`, not `width` or `height`.
- **Reanimated** runs small JavaScript functions marked as _worklets_ on the UI thread. Shared
  values, `useAnimatedStyle` and gesture handlers from React Native Gesture Handler stay on the UI
  thread from touch to frame, so a drag keeps following the finger even while the JS thread is
  blocked.

Keep the JS thread free during animations (start heavy work when the navigation transition has
ended), animate `transform` instead of layout properties where possible, and test on a
low-end Android device, where the problem shows first.

**References:** [Animations](https://reactnative.dev/docs/animations) · [React Native Reanimated](https://docs.swmansion.com/react-native-reanimated/)

## RN-018: How do you prevent unnecessary re-renders?

**Level:** mid

A component re-renders when its state changes, its parent re-renders, or a context it reads
changes. Re-rendering is usually cheap; optimise when profiling shows a problem.

- `React.memo(Component)` skips rendering when props are shallowly equal (`Object.is` per prop).
- `useMemo` keeps a computed value and `useCallback` keeps a function between renders, so memoized
  children receive the same references.
- Split contexts by how often they change, and keep fast-changing values (a timer, scroll
  position) out of a context that many components read.
- Keep state as low in the tree as possible.

The **React Compiler** applies this memoization automatically at build time for components and
hooks that follow the Rules of React, which removes most hand-written `useMemo` and `useCallback`.
It has a stable release and works with React Native and Expo. The React DevTools profiler's
"Why did this render?" information shows which prop or state caused a render.

**References:** [React: memo](https://react.dev/reference/react/memo) · [React Compiler](https://react.dev/learn/react-compiler)

## RN-019: How do navigation and deep links work in a React Native app?

**Level:** mid

The two main libraries are **React Navigation** (navigators declared in code: stack, tabs,
drawer) and **Expo Router**, which is built on React Navigation and maps files in the `app/`
folder to routes, so every screen has a URL automatically.

Deep links need two parts:

1. **The operating system** must open the app for the link: a custom scheme in the app
   configuration, and for `https` links, Universal Links on iOS (an `apple-app-site-association`
   file and the Associated Domains entitlement) and App Links on Android (an `assetlinks.json` file
   and an intent filter with `autoVerify`).
2. **The navigator** must turn the URL into screens: React Navigation's `linking` configuration
   maps paths to screens; Expo Router does this from the file names.

Test links on both platforms with `npx uri-scheme open <url> --ios` or `adb shell am start -W -a
android.intent.action.VIEW -d <url>`, including the case where the app is not running, and handle
links that need sign-in by storing the target and navigating after login.

**References:** [React Navigation: Deep linking](https://reactnavigation.org/docs/deep-linking/) · [Expo Router: Introduction](https://docs.expo.dev/router/introduction/)

## RN-020: What are over-the-air updates, and what are their limits?

**Level:** senior

An over-the-air (OTA) update replaces the JavaScript bundle and assets of an installed app without
a store release; EAS Update is the common service. The app checks for an update at launch and
applies it on the next start (or immediately, if you choose).

Limits and responsibilities:

- Only JavaScript and assets can change. Any change to native code, native dependencies,
  permissions or the app configuration needs a new binary.
- Each update must target a compatible native build. Expo uses a **runtime version** for this; an
  update sent to binaries with different native code crashes them.
- Store rules still apply: an update may fix bugs and adjust features but must not change the
  app's purpose or bypass review.
- Plan for failure: roll out to a percentage first, monitor crashes, and keep a way to roll back;
  `expo-updates` falls back to the embedded bundle if an update fails to launch.

**References:** [Expo: EAS Update](https://docs.expo.dev/eas-update/introduction/) · [Expo: Runtime versions](https://docs.expo.dev/eas-update/runtime-versions/)

## RN-021: Where do you store a token in a React Native app?

**Level:** junior

In storage backed by the platform's secure hardware: the iOS Keychain and, on Android, values
encrypted with a key in the Android Keystore. `expo-secure-store` and `react-native-keychain`
provide that.

`AsyncStorage` (and MMKV without its encryption option) stores plain data in the app's sandbox. It
is fine for preferences and caches, not for secrets: it is readable on rooted or jailbroken devices
and can end up in backups.

Also keep secrets out of the JavaScript bundle: API keys in `.env` files or `app.config.js` are
compiled into the app and can be extracted. Anything truly secret belongs on your server, and the
app should hold only short-lived tokens that the server can revoke.

**References:** [Expo: SecureStore](https://docs.expo.dev/versions/latest/sdk/securestore/) · [React Native: Security](https://reactnative.dev/docs/security)

## RN-022: How do you test a React Native app?

**Level:** junior

- **Unit tests** with Jest for functions, reducers and hooks. The `react-native` Jest preset mocks
  the native parts.
- **Component tests** with React Native Testing Library: render a component, find elements the way
  a user would (`getByRole`, `getByText`), fire events and assert on the result, without testing
  implementation details.
- **End-to-end tests** on a simulator or device with Maestro (flows in YAML) or Detox (gray-box,
  waits for the app to be idle), for sign-in, purchase and other critical flows.
- **Type checking** with TypeScript and linting with ESLint catch a large class of errors before
  any test runs.

Mock the network at the boundary (a fake API client or a request interceptor) rather than mocking
`fetch` in every test, and keep end-to-end tests few and stable, since they are the slowest and
most fragile layer.

**References:** [React Native: Testing](https://reactnative.dev/docs/testing-overview) · [React Native Testing Library](https://callstack.github.io/react-native-testing-library/)
