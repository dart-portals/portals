import 'package:flutter/material.dart';

import 'package:portals/portals.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final portal = Portal();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('Tic Tac Toe')),
        floatingActionButton: FloatingActionButton.extended(
          icon: Icon(Icons.play_arrow),
          label: Text('Connect'),
          onPressed: () {},
        ),
      ),
    );
  }
}
