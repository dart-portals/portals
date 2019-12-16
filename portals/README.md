A pure Dart implementation of the Magic Wormhole client, designed for easy peer to peer connections.

## How to use

To connect two devices, you need to create a portal on each of them.

```dart
var portal = Portal('my_app.example.com');
```

One client needs to open a new portal.
The portal returns a code that uniquely identifies the portal and can be used by the second client to link the portals.

```dart
String code = await portal.open();
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
