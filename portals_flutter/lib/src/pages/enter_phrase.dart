import 'package:flutter/material.dart';

import '../setup_portal.dart';
import 'linking.dart';

class EnterPhrasePage extends StatefulWidget {
  @override
  _EnterPhrasePageState createState() => _EnterPhrasePageState();
}

class _EnterPhrasePageState extends State<EnterPhrasePage> {
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    // context.portal.waitForPhrase().then(() => setState(() {}));
  }

  void _onDone() {
    context
      ..portal.openAndLinkTo(controller.text)
      ..app.push(LinkingPage());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Display phrase.'),
        SizedBox(height: 32),
        TextField(
          controller: controller,
          autofocus: true,
        ),
        RaisedButton.icon(
          icon: Icon(Icons.done),
          label: Text('Done'),
          onPressed: _onDone,
        ),
      ],
    );
  }
}
