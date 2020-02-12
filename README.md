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
Data is compressed and transferred using peer-to-peer connections whenever possible.
That makes portals incredibly fast when used on the same wifi or in the same geographic area.

🎈 **Lightweight:**
There are no native dependencies and portals use lightweight standardized WebSockets to communicate.
That also means, portals work anywhere where Dart runs: on mobile, desktop & the web.

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
portal.send(something);
var somethingElse = await portal.receive();
```

All primitive types are supported by default, including `int`, `double`, `bool`, `List`, `Map`, `Set`, `Duration`, `DateTime`, `RegExp`, `StackTrace`, `Uint8List` and many more.
Under the hood, the binary serializer is used – see its documentation for more information.
Here's a quick summary:

TODO: The following doesn't work yet – adapters still need to be written by hand.

To send arbitrary Dart objects, annotate them with `@BinaryType()` and the fields with `@BinaryField(id)`:

```dart
part 'my_file.g.dart';

@BinaryType()
class MyClass {
  @BinaryField(0, defaultValue: <int>[])
  List<int> someThings;

  @BinaryField(1)
  Duration duration;
}
```

Then, run `pub run build_runner build` in the command line to generate the `AdapterForMyClass`. Finally, register it at the beginning of your `main` method:

```dart
AdapterForMyClass().registerWithId(0);
```

Now, you can send `MyClass`es through portals!

## How it works

Sadly, true peer-to-peer connection establishment is impossible to realize – if you're looking for another running portal, you can't just try talking to all the devices in the internet.  
Also, it's not even guaranteed that two devices see each other – they might be in different wifis which usually block incoming connection attempts.  
That's why a central public server is needed for connection establishment. It merely offers clients the feature to leave messages for each other, thus it's called the *mailbox server*.
By default, portals use the mailbox server at `ws://relay.magic-wormhole.io:4000/v1`, but especially if you generate a lot of traffic, you're welcome to [run your own server](https://github.com/warner/magic-wormhole-mailbox-server).

The mailbox server manages multiple communication channels between clients, intuitively called *mailboxes*.
The first portal asks for a new mailbox and gets a unique id identifying the mailbox on the server for the client's app id.  
The mailbox id and a randomly generated shared key are converted into a human-readable phrase that's shown to the user.  
The second portal lets the user input the same phrase.
It then extracts both the mailbox id as well as the shared key.
After connecting to the mailbox server and requesting to join the mailbox with the given id, both portals talk to each other over the mailbox server.

That's when the encryption phase begins – to make transcribing the phrase as easy as possible, the shared key is pretty small.
For a strong encryption, both portals will need to agree on a much larger key.
Here's how it works:  
Imagine you can multiply numbers easily, but dividing is really hard. (Actually, elements of the Edwards curve group are used instead of numbers and they have these properties.)  
Having the small shared key *s*, portals generate huge random private keys *m* and *n*.
They calculate *M = s×m* and *N = s×n* and exchange *M* and *N*.
Then they multiply these with their private keys – the first portal calculates *kₘ = m×N* and the second one *kₙ = n×M*. Because *kₘ = m×N = m×s×n = n×s×m = n×M = kₙ*, both keys are equal.  
An attacker not knowing *s* can only observe *M* and *N* being exchanged, but can't derive the resulting key, making man-in-the-middle-attacks virtually impossible.

Now, clients can use the mailbox to exchange encrypted messages.
They exchange their ip addresses and try to connect to the other client.
For each succeeding connection, they exchange a short message to verify that whoever is connected knows the encryption key.
The first connection where this encryption verification succeeds gets chosen.  
Now, both portals can directly talk over an encrypted peer-to-peer connection.

## How it relates to Magic Wormhole

The interface to the mailbox server conforms to the Magic Wormhole protocol.
The rest doesn't.
