⚠️ **This package is still in technical preview**.
The API may change substantially in the future and it's not safe to use this package in production yet – several features like reconnecting when the network is lost, or using a transfer server if the two devices can't see each other still need to be implemented.

---

Portals are strongly encrypted peer-to-peer connections.
Inspired by [Magic Wormhole](https://github.com/warner/magic-wormhole/).

TODO: Flutter web & app demo

## Features

❤️ **Easy to use:**
Portals connect by letting users transcribe short human-readable codes from one device to another.
TODO: There's a beautiful pre-built UI for Flutter.

🔒 **Secure:**
Strong end-to-end encryption using Spake2 is built in.
Man-in-the-middle attacks are virtually impossible because both sides share a secret from the beginning.

⚡ **Fast:**
Data is transferred using peer-to-peer connections whenever possible.
That makes portals incredibly fast when used on the same wifi or in the same geographic area.

🎈 **Lightweight:**
There are no native dependencies.
That also means, portals work anywhere where Dart runs: on mobile, desktop & the web.
Portals use lightweight WebSockets to communicate.

## How to use

### Create a portal

To connect two devices, you need to create a portal on each of them.

```dart
var portal = Portal(appId: 'github.com/marcelgarus/portals');
```

The `appId` can be any arbitrary string used only by your application.
It's recommended to use a url.


Optionally you can pass in an `info` string containing meta-information like your app version or something else. It will be exchanged as soon as the portals are linked.

```dart
var portal = Portal(
  appId: 'github.com/marcelgarus/portals',
  info: json.encode({ 'app_version': '1.0.0', ... }),
);
// Later, when linked:
print(portal.remoteInfo);
```

### Set up the portal

<details>
<summary>💙 Flutter</summary>

There's a beautiful pre-built UI for Flutter that you can find nowhere yet.
TODO
</details>

<details>
<summary>🖥️ Command line</summary>

TODO
</details>

<details>
<summary>🎯 Pure Dart</summary>

On the first device, open the portal. It will return a phrase that uniquely identifies it among other portals using your `appId`:

```dart
String phrase = await portal.open();
// TODO: Show the phrase to the user.
String key = await portal.waitForLink();
```

Let the user transcribe the `phrase` to the second user in the real world.
The second user can then link the two portals:

```dart
// TODO: Let the user enter the phrase.
String key = await portal.openAndLinkTo(phrase);
```

Now the two portals are linked.
Optionally, you can let the users compare the `key` to completely rule out man-in-the-middle attacks.

In the background, both clients try to establish a peer-to-peer connection to each other.
Wait for it on both sides by calling:

```dart
await portal.waitUntilReady();
```
</details>

### Send stuff

Anything that goes into one of the two portals comes out the other.

```dart
portal.add(something);
var somethingElse = await portal.receive();
```

All primitive types are supported by default, including `int`, `double`, `bool`, `List`, `Map`, `Set`. 

To send arbitrary Dart objects, annotate them with `@...`.

TODO

## How it works

TODO

## How it relates to magic wormhole

TODO
