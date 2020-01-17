import 'package:flutter/material.dart';

import '../setup_portal.dart';

class DisplayPhrasePage extends StatefulWidget {
  @override
  _DisplayPhrasePageState createState() => _DisplayPhrasePageState();
}

class _DisplayPhrasePageState extends State<DisplayPhrasePage> {
  @override
  void initState() {
    super.initState();

    // context.portal.waitForPhrase().then(() => setState(() {}));
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
