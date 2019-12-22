TODO: header

Portals are strongly encrypted peer-to-peer connections.
Inspired by [Magic Wormhole](https://github.com/warner/magic-wormhole/).

TOOD: Flutter web & app demo

## Features

❤️ **Easy to use:**
Portals connect by letting users transcribe short human-readable codes from one device into another.
There's beautiful pre-built UI for Flutter.

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

## Getting started

TODO: add portals as a dependency

## How to use

To connect two devices, you need to create a portal on each of them.

```dart
var portal = Portal(appId: 'my.app.example.com', version: '1.0.0');
```

One client needs to open a new portal.
The portal returns a code that uniquely identifies the portal and can be used by the second client to link the portals.

```dart
String code = await portal.open();
// TODO: Show the code to the user.
await portal.waitForLink();
```

The first user transcribes the portal code to the second user in the real world or via existing communication channels.
The second user can then link the two portals:

```dart
await portal.linkTo(code);
```

Now the two portals are linked.
Anything that goes into one of the two portals comes out the other.

```dart
portal.add(something);
var somethingElse = await portal.receive();
portal.listen(print);
```

## Send objects

## How it works

## How it relates to magic wormhole
