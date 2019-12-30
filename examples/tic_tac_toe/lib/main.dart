import 'package:flutter/material.dart';

import 'package:portals/portals.dart';
import 'package:portals_flutter/portals_flutter.dart';
import 'package:version/version.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TicTacToe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  final portal = Portal(
    appId: 'tictactoe.marcelgarus',
    version: Version.parse('1.0.0'),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('TicTacToe')),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton.extended(
          icon: Icon(Icons.play_arrow),
          label: Text('Connect'),
          onPressed: () {
            context.setupPortal(portal);
          },
        ),
      ),
    );
  }
}
