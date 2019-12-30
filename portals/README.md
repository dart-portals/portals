

Portals are strongly encrypted peer-to-peer connections.
Inspired by [Magic Wormhole](https://github.com/warner/magic-wormhole/).

> Welcome to the portals package!
> "With it, you can create your own portals.
> These intra-dimensional gates have proven to be completely safe."
> ~ GLaDOS

TODO: Flutter web & app demo

⚠️ **This package is still in technical preview**.
The API may change substantially in the future and it's not safe to use this package in production yet – several features like reconnecting when the network is lost, or using a transfer server if the two devices can't see each other still need to be implemented.

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

To connect two devices, you need to create a portal on each of them.

```dart
var portal = Portal(appId: 'my.app.example.com');
```

On the first device, open the portal. It will return a phrase that uniquely identifies it:

```dart
String phrase = await portal.open();
// TODO: Show the phrase to the user.
String key = await portal.waitForLink();
```

Let the user transcribes the `phrase` to the second user in the real world.
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

Now, anything that goes into one of the two portals comes out the other.

```dart
portal.add(something);
var somethingElse = await portal.receive();
```

## Send objects

TODO

## How it works

TODO

## How it relates to magic wormhole

TODO
