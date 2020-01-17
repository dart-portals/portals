import 'package:flutter/material.dart';

class CompareKeysPage extends StatefulWidget {
  @override
  _CompareKeysPageState createState() => _CompareKeysPageState();
}

class _CompareKeysPageState extends State<CompareKeysPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Check if the key is the same on both devices.'),
        SizedBox(height: 32),
        // Text(context.portal),
      ],
    );
  }
}
