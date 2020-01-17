import 'package:flutter/material.dart';

import '../setup_portal.dart';

class LinkingPage extends StatefulWidget {
  @override
  _LinkingPageState createState() => _LinkingPageState();
}

class _LinkingPageState extends State<LinkingPage> {
  @override
  void initState() {
    super.initState();

    context.portal.waitForLink().then((key) {
      // context.app.push(Com);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Display phrase.'),
        SizedBox(height: 32),
        Text(context.portal.phrase ?? 'no phrase yet'),
      ],
    );
  }
}
