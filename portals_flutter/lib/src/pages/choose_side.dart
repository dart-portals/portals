import 'package:flutter/material.dart';

import '../setup_portal.dart';
import 'display_phrase.dart';

class ChooseSidePage extends StatelessWidget {
  const ChooseSidePage({Key key}) : super(key: key);

  void _firstSideChosen(BuildContext context) {
    context
      ..portal.open()
      ..app.push(DisplayPhrasePage());
  }

  void _secondSideChosen() {
    // context.navigator.push(EnterPhrasePage());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Choose different colors on both devices.'),
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Spacer(),
            ActionButton(
              color: Color(0xff29339b),
              label: '1',
              onPressed: () => _firstSideChosen(context),
            ),
            Spacer(),
            ActionButton(
              color: Color(0xffff5964),
              label: '2',
              onPressed: _secondSideChosen,
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    Key key,
    @required this.color,
    @required this.label,
    @required this.onPressed,
  }) : super(key: key);

  final Color color;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Material(
          color: color,
          shape: CircleBorder(),
          child: Container(
            width: 52,
            height: 52,
            child: InkWell(
              onTap: onPressed,
              child: Center(
                child: Text(label, style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
